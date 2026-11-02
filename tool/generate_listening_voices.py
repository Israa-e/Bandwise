"""Generates every Listening line as assets/listening/<set>/audio/<lineId>.wav.

    <python> tool/generate_listening_voices.py [set ...] [--redo id,id]

<python> needs sherpa-onnx, faster-whisper, soundfile and numpy. VoiceStudio's
bundled environment has them all:

    ~/.config/VoiceStudio/runtime/project/.venv/bin/python

- Engine: Kokoro-82M (hexgrad, Apache-2.0), run locally with sherpa-onnx
  (Apache-2.0) from the "kokoro-en-v0_19" model package, which is downloaded
  to build/tts_models/ if missing. Each speaker's built-in voice and speed
  are in script.json ("voice"). No voice is cloned.
- Lines are spoken as their `direction` asks: spelled words letter by letter,
  phone numbers digit by digit.
- Every take is transcribed (faster-whisper large-v3, MIT) and checked: the
  script's words must be there, and a line that gives an answer must contain
  it. A failed line is generated again a little slower, up to 3 attempts; the
  best take is kept and listed for checking by ear.
- Resume-safe: progress is saved after each line to
  build/listening_voices/<set>.json and finished lines are skipped. --redo
  generates the given line ids again; --recheck re-scores the saved
  transcripts without generating.
"""

import json
import re
import sys
import tarfile
import time
import urllib.request
from pathlib import Path

import numpy as np
import soundfile as sf

ROOT = Path("assets/listening")
WORK = Path("build/listening_voices")
MODELS = Path("build/tts_models")
MODEL = "kokoro-en-v0_19"
MODEL_URL = ("https://github.com/k2-fsa/sherpa-onnx/releases/download/"
             f"tts-models/{MODEL}.tar.bz2")
WHISPER = "large-v3"

# Kokoro speaker ids in kokoro-en-v0_19 (sherpa-onnx's documented order).
# "a" voices are American, "b" voices British.
VOICES = {"af": 0, "af_bella": 1, "af_nicole": 2, "af_sarah": 3,
          "af_sky": 4, "am_adam": 5, "am_michael": 6, "bf_emma": 7,
          "bf_isabella": 8, "bm_george": 9, "bm_lewis": 10}

# Speed multipliers per attempt: a retry speaks a little slower.
ATTEMPT_SPEEDS = [1.0, 0.94, 0.88]

# Share of the script's words the transcript must contain, in order.
MIN_MATCH = 0.8

DIGIT_WORDS = ["oh", "one", "two", "three", "four", "five", "six", "seven",
               "eight", "nine"]


def log(message):
    print(message, flush=True)


# ---------------------------------------------------------------- kokoro


def model_dir():
    folder = MODELS / MODEL
    if not (folder / "model.onnx").exists():
        MODELS.mkdir(parents=True, exist_ok=True)
        archive = MODELS / f"{MODEL}.tar.bz2"
        log(f"Downloading {MODEL_URL}…")
        urllib.request.urlretrieve(MODEL_URL, archive)
        with tarfile.open(archive) as tar:
            tar.extractall(MODELS, filter="data")
    return folder


def load_kokoro():
    import sherpa_onnx

    folder = model_dir()
    return sherpa_onnx.OfflineTts(sherpa_onnx.OfflineTtsConfig(
        model=sherpa_onnx.OfflineTtsModelConfig(
            kokoro=sherpa_onnx.OfflineTtsKokoroModelConfig(
                model=str(folder / "model.onnx"),
                voices=str(folder / "voices.bin"),
                tokens=str(folder / "tokens.txt"),
                data_dir=str(folder / "espeak-ng-data"),
            ),
            num_threads=4,
        )))


def write_take(tts, text, voice, speed, path):
    """Speaks [text] with the Kokoro [voice] and saves it to [path]."""
    audio = tts.generate(text, sid=VOICES[voice], speed=speed)
    sf.write(path, np.asarray(audio.samples, dtype=np.float32),
             audio.sample_rate, subtype="PCM_16")


# ---------------------------------------------------------------- text


def spoken_text(text):
    """[text] as the voice should say it: "H-A-L" letter by letter, and phone
    numbers (5+ digits) digit by digit with "oh" for 0, pausing between digit
    groups."""
    text = re.sub(r"\b[A-Z](?:-[A-Z])+\b",
                  lambda m: ", ".join(m[0].split("-")), text)
    return re.sub(
        r"\b\d{5,}(?: \d{3,})*\b",
        lambda m: ", ".join(" ".join(DIGIT_WORDS[int(d)] for d in group)
                            for group in m[0].split(" ")),
        text,
    )


NUMBER_WORDS = {
    "zero": "0", "oh": "0", "one": "1", "two": "2", "three": "3",
    "four": "4", "five": "5", "six": "6", "seven": "7", "eight": "8",
    "nine": "9", "ten": "10", "sixth": "6th", "ninety": "90",
    "hundred": "00",
}


def words(text, o_is_zero=False):
    """Lower case words without punctuation; number words become digits and
    "double seven" becomes "7 7", so a transcript compares with the script
    however the recogniser writes them. With [o_is_zero], a lone "o" is 0
    (as in "O seven seven"); otherwise it's the letter (as in a spelling)."""
    raw = re.sub(r"[’']", "", text.lower())
    # "£120" and "120 pounds" compare the same.
    raw = re.sub(r"£(\d+)", r"\1 pounds", raw)
    raw = re.sub(r"[^a-z0-9£]+", " ", raw).split()
    out = []
    i = 0
    while i < len(raw):
        w = raw[i]
        if w == "double" and i + 1 < len(raw):
            nxt = NUMBER_WORDS.get(raw[i + 1], raw[i + 1])
            out += [nxt, nxt]
            i += 2
            continue
        out.append("0" if o_is_zero and w == "o" else NUMBER_WORDS.get(w, w))
        i += 1
    # Digit groups count as one number however they were spaced:
    # "07723 418590" and "07723418590" match.
    merged = []
    for w in out:
        if merged and w.isdigit() and merged[-1].isdigit():
            merged[-1] += w
        else:
            merged.append(w)
    return merged


def squashed(text, o_is_zero=False):
    """Everything joined, so spelled letters and digit groups compare however
    they were spaced."""
    return "".join(words(text, o_is_zero))


def heard_in(option, transcript):
    """Whether [option] (an answer or evidence words) is in [transcript],
    reading a lone "o" either as the letter or as zero."""
    return any(squashed(option) in squashed(transcript, z)
               for z in (False, True))


def match(script, transcript):
    """Share of the script's words found in the transcript, in order (LCS)."""
    a, b = words(script), words(transcript)
    if not a:
        return 1.0
    prev = [0] * (len(b) + 1)
    for x in a:
        cur = [0]
        for j, y in enumerate(b, 1):
            cur.append(prev[j - 1] + 1 if x == y else max(prev[j], cur[j - 1]))
        prev = cur
    return prev[-1] / len(a)


# ---------------------------------------------------------------- set


def generate_set(set_id, redo, tts, asr):
    folder = ROOT / set_id
    script = json.loads((folder / "script.json").read_text())
    questions = json.loads((folder / "questions.json").read_text())
    speakers = {s["id"]: s for s in script["speakers"]}
    lines = script["lines"]

    # What each answer line must contain: the answer (or a variant) for
    # completion questions, the evidence words for the others.
    must_hear = {}
    for q in questions["questions"]:
        options = ([q["evidence"]] if q["wordLimit"] is None
                   else [q["answer"], *q["acceptedVariants"]])
        must_hear.setdefault(q["evidenceLineId"], []).append(options)

    status_file = WORK / f"{set_id}.json"
    status = json.loads(status_file.read_text()) if status_file.exists() else {}
    (folder / "audio").mkdir(parents=True, exist_ok=True)
    takes = WORK / "takes" / set_id
    takes.mkdir(parents=True, exist_ok=True)

    log(f"{set_id}: {len(lines)} lines")
    for i, line in enumerate(lines):
        line_id = line["id"]
        out = folder / "audio" / f"{line_id}.wav"
        if line_id not in redo and line_id in status and out.exists():
            continue
        voice = speakers[line["speaker"]]["voice"]
        text = line["text"]
        spoken = spoken_text(text)
        best = None
        for attempt, factor in enumerate(ATTEMPT_SPEEDS, 1):
            speed = round(voice["speed"] * factor, 3)
            started = time.time()
            take = takes / f"{line_id}.{attempt}.wav"
            write_take(tts, spoken, voice["preset"], speed, take)
            segments, _ = asr.transcribe(str(take), language="en",
                                         beam_size=5)
            heard = " ".join(s.text.strip() for s in segments)
            score = round(match(text, heard), 2)
            missing = [opts[0] for opts in must_hear.get(line_id, [])
                       if not any(heard_in(o, heard) for o in opts)]
            result = {
                "attempts": attempt, "preset": voice["preset"],
                "speed": speed, "take": str(take), "transcript": heard,
                "match": score, "missing": missing,
                "ok": score >= MIN_MATCH and not missing,
            }
            if (best is None or result["ok"]
                    or len(missing) < len(best["missing"])
                    or (len(missing) == len(best["missing"])
                        and score > best["match"])):
                best = result
            log(f"  [{i + 1}/{len(lines)}] {line_id} try {attempt}: "
                f"{'ok' if result['ok'] else 'retry'} (match {score}"
                f"{', missing ' + str(missing) if missing else ''}, "
                f"{time.time() - started:.0f}s)")
            if result["ok"]:
                break
        out.write_bytes(Path(best["take"]).read_bytes())
        status[line_id] = best
        status_file.write_text(json.dumps(status, indent=2) + "\n")

    review = [k for k, v in status.items() if not v["ok"]]
    log(f"{set_id}: done. "
        + (f"Check by ear: {', '.join(review)}" if review
           else "Every line passed."))


def recheck(set_id):
    """Scores the saved transcripts again (after a change to the checks)
    without generating anything."""
    folder = ROOT / set_id
    script = json.loads((folder / "script.json").read_text())
    texts = {line["id"]: line["text"] for line in script["lines"]}
    status_file = WORK / f"{set_id}.json"
    status = json.loads(status_file.read_text())
    for line_id, s in status.items():
        s["match"] = round(match(texts[line_id], s["transcript"]), 2)
        s["ok"] = s["match"] >= MIN_MATCH and not s["missing"]
    status_file.write_text(json.dumps(status, indent=2) + "\n")
    review = [k for k, v in status.items() if not v["ok"]]
    log(f"{set_id}: " + (f"check by ear: {', '.join(review)}" if review
                         else "every line passed."))


def main(args):
    redo, sets = set(), []
    it = iter(args)
    for a in it:
        if a == "--redo":
            redo |= set(next(it).split(","))
        elif not a.startswith("--"):
            sets.append(a)
    if "--recheck" in args:
        for set_id in sets or ["set_a", "set_b"]:
            recheck(set_id)
        return
    from faster_whisper import WhisperModel

    log(f"Loading Kokoro ({MODEL}) and faster-whisper {WHISPER}…")
    tts = load_kokoro()
    asr = WhisperModel(WHISPER, device="cpu", compute_type="int8")
    WORK.mkdir(parents=True, exist_ok=True)
    for set_id in sets or ["set_a", "set_b"]:
        generate_set(set_id, redo, tts, asr)


if __name__ == "__main__":
    main(sys.argv[1:])
