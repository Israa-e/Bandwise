"""Generates the examiner's audio as assets/speaking/audio/<id>.wav, one file
per line in assets/speaking/content.json (questions and examiner lines).

    <python> tool/generate_speaking_voices.py [--redo id,id] [--recheck]

<python> needs sherpa-onnx, faster-whisper, soundfile and numpy; VoiceStudio's
bundled environment has them:

    ~/.config/VoiceStudio/runtime/project/.venv/bin/python

The same pipeline as Listening (tool/generate_listening_voices.py):

- Engine: Kokoro-82M (hexgrad, Apache-2.0), run locally with sherpa-onnx
  (Apache-2.0) from the "kokoro-en-v0_19" model package, which is downloaded
  to build/tts_models/ if missing. Voice: the built-in British male voice
  "bm_george". No voice is cloned.
- Every take is transcribed (faster-whisper large-v3, MIT) and must contain
  the script's words; a failed line is generated again a little slower, up
  to 3 attempts, and the best take is kept and listed for checking by ear.
- Resume-safe: progress is saved after each line to
  build/speaking_voices/status.json and finished lines are skipped.
"""

import json
import sys
import tarfile
import time
import urllib.request
from pathlib import Path

import numpy as np
import soundfile as sf

sys.path.insert(0, str(Path(__file__).parent))
from generate_listening_voices import ATTEMPT_SPEEDS, MIN_MATCH, WHISPER, log, match  # noqa: E402

CONTENT = Path("assets/speaking/content.json")
OUT = Path("assets/speaking/audio")
WORK = Path("build/speaking_voices")
MODELS = Path("build/tts_models")
MODEL = "kokoro-en-v0_19"
MODEL_URL = ("https://github.com/k2-fsa/sherpa-onnx/releases/download/"
             f"tts-models/{MODEL}.tar.bz2")

# Kokoro speaker ids in kokoro-en-v0_19 (sherpa-onnx's documented order).
VOICES = {"bf_emma": 7, "bf_isabella": 8, "bm_george": 9, "bm_lewis": 10}
EXAMINER_VOICE = "bm_george"
EXAMINER_SPEED = 0.95


def lines(content):
    """Every line with audio, in the app's order (SpeakingContent.allLines)."""
    out = list(content["examiner"])
    for topic in content["part1"]:
        out += [topic["intro"], *topic["questions"]]
    for card in content["part2"]:
        out += [card["topic"], card["roundingOff"], card["part3"]["intro"],
                *card["part3"]["questions"]]
    return out


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


def main(args):
    redo = set()
    if "--redo" in args:
        redo = set(args[args.index("--redo") + 1].split(","))
    content = json.loads(CONTENT.read_text())
    todo = lines(content)
    status_file = WORK / "status.json"
    status = json.loads(status_file.read_text()) if status_file.exists() else {}

    if "--recheck" in args:
        texts = {line["id"]: line["text"] for line in todo}
        for line_id, s in status.items():
            s["match"] = round(match(texts[line_id], s["transcript"]), 2)
            s["ok"] = s["match"] >= MIN_MATCH
        status_file.write_text(json.dumps(status, indent=2) + "\n")
    else:
        import sherpa_onnx
        from faster_whisper import WhisperModel

        folder = model_dir()
        log(f"Loading Kokoro ({MODEL}) and faster-whisper {WHISPER}…")
        tts = sherpa_onnx.OfflineTts(sherpa_onnx.OfflineTtsConfig(
            model=sherpa_onnx.OfflineTtsModelConfig(
                kokoro=sherpa_onnx.OfflineTtsKokoroModelConfig(
                    model=str(folder / "model.onnx"),
                    voices=str(folder / "voices.bin"),
                    tokens=str(folder / "tokens.txt"),
                    data_dir=str(folder / "espeak-ng-data"),
                ),
                num_threads=4,
            )))
        asr = WhisperModel(WHISPER, device="cpu", compute_type="int8")
        OUT.mkdir(parents=True, exist_ok=True)
        takes = WORK / "takes"
        takes.mkdir(parents=True, exist_ok=True)

        for i, line in enumerate(todo):
            line_id, text = line["id"], line["text"]
            out = OUT / f"{line_id}.wav"
            if line_id not in redo and line_id in status and out.exists():
                continue
            best = None
            for attempt, factor in enumerate(ATTEMPT_SPEEDS, 1):
                speed = round(EXAMINER_SPEED * factor, 3)
                started = time.time()
                audio = tts.generate(text, sid=VOICES[EXAMINER_VOICE],
                                     speed=speed)
                take = takes / f"{line_id}.{attempt}.wav"
                sf.write(take, np.asarray(audio.samples, dtype=np.float32),
                         audio.sample_rate, subtype="PCM_16")
                segments, _ = asr.transcribe(str(take), language="en",
                                             beam_size=5)
                heard = " ".join(s.text.strip() for s in segments)
                score = round(match(text, heard), 2)
                result = {"attempts": attempt, "voice": EXAMINER_VOICE,
                          "speed": speed, "take": str(take),
                          "transcript": heard, "match": score,
                          "ok": score >= MIN_MATCH}
                if best is None or result["ok"] or score > best["match"]:
                    best = result
                log(f"  [{i + 1}/{len(todo)}] {line_id} try {attempt}: "
                    f"{'ok' if result['ok'] else 'retry'} (match {score}, "
                    f"{time.time() - started:.0f}s)")
                if result["ok"]:
                    break
            out.write_bytes(Path(best["take"]).read_bytes())
            status[line_id] = best
            WORK.mkdir(parents=True, exist_ok=True)
            status_file.write_text(json.dumps(status, indent=2) + "\n")

    review = [k for k, v in status.items() if not v["ok"]]
    log("speaking: done. " + (f"Check by ear: {', '.join(review)}" if review
                               else "Every line passed."))


if __name__ == "__main__":
    main(sys.argv[1:])
