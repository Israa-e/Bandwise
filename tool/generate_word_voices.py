"""Generates the pronunciation of every flashcard word in the course as
build/word_voices/wav/<word>.wav, and writes assets/audio/words/README.md.

    <python> tool/generate_word_voices.py [--redo word,word]
    dart run tool/build_word_audio.dart     # then: wav -> assets/audio/words/*.mp3

<python> needs sherpa-onnx, faster-whisper, soundfile and numpy; VoiceStudio's
bundled environment has them:

    ~/.config/VoiceStudio/runtime/project/.venv/bin/python

The same pipeline as Listening and Speaking (tool/generate_listening_voices.py):

- Words: every `word:` of a FlashcardExercise in
  lib/features/learn/data/unit*_content.dart.
- Engine: Kokoro-82M (hexgrad, Apache-2.0), run locally with sherpa-onnx
  (Apache-2.0) from the "kokoro-en-v0_19" model package. Voice: the built-in
  British female voice "bf_emma" at normal speed (1.0). No voice is cloned.
- Every take is transcribed (faster-whisper large-v3, MIT) and the transcript
  must EQUAL the word (ignoring case and punctuation). Recognisers often
  misread a word spoken on its own ("assert" becomes "A 30"), so when the
  bare take fails it is transcribed again after a spoken carrier phrase ("The
  word is ...", same voice), and what follows the carrier must equal the
  word. Either check passes the take; the shipped file is always the bare
  word. A failed take is made again from a different spelling of the same
  word ("word", "word.", "Word.", "WORD", "word!", "Word!") at the same
  speed, up to 6 attempts; a word that never passes stops the run, so nothing unchecked
  is shipped.
- Resume-safe: progress is saved after each word to
  build/word_voices/status.json and finished words are skipped.
"""

import json
import re
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import numpy as np  # noqa: E402
import soundfile as sf  # noqa: E402
from generate_listening_voices import (  # noqa: E402
    MODEL, VOICES, WHISPER, load_kokoro, log, write_take)

CONTENT = sorted(Path("lib/features/learn/data").glob("unit*_content.dart"))
WORK = Path("build/word_voices")
OUT = WORK / "wav"
README = Path("assets/audio/words/README.md")
VOICE = "bf_emma"
SPEED = 1.0


def flashcard_words():
    """Course words in path order."""
    out = []
    for file in CONTENT:
        out += re.findall(r"word:\s*'([^']+)'", file.read_text())
    if len(set(out)) != len(out):
        raise SystemExit("Duplicate flashcard words in the course.")
    return out


def transcribe(asr, path):
    segments, _ = asr.transcribe(str(path), language="en", beam_size=5)
    return " ".join(s.text.strip() for s in segments)


_carrier_audio = {}


def carrier_take(tts, take, word):
    """The carrier phrase, a short pause, then [take], for transcription."""
    if "audio" not in _carrier_audio:
        audio = tts.generate(CARRIER, sid=VOICES[VOICE], speed=SPEED)
        _carrier_audio["audio"] = (np.asarray(audio.samples, dtype=np.float32),
                                   audio.sample_rate)
    lead, rate = _carrier_audio["audio"]
    data, take_rate = sf.read(take, dtype="float32")
    assert take_rate == rate
    out = WORK / "takes" / f"{word}.carrier.wav"
    sf.write(out, np.concatenate([lead, np.zeros(rate // 2, np.float32), data]),
             rate, subtype="PCM_16")
    return out


def spellings(word):
    return [word, f"{word}.", f"{word.capitalize()}.", word.upper(),
            f"{word}!", f"{word.capitalize()}!"]


CARRIER = "The word is"


def heard_word(transcript):
    return re.sub(r"[^a-z]+", "", transcript.lower())


def write_readme(words, status):
    rows = "\n".join(
        f"| {i} | `{w}` | {status[w]['transcript'].strip()} | "
        f"{status[w]['check']} | {status[w]['attempts']} |"
        for i, w in enumerate(words, 1))
    README.parent.mkdir(parents=True, exist_ok=True)
    README.write_text(f"""# Word pronunciation audio

One recording per flashcard word in the course, `<word>.mp3`: what the
pronunciation button plays on flashcards in lessons, in review and in the
vocabulary notebook. A word without a file simply has no button.

> The word list is read from the course content by
> `tool/generate_word_voices.py`, which also writes this file. Do not edit it
> by hand.

## Engine and licences

| | |
| --- | --- |
| Speech | Kokoro-82M (hexgrad), the `{MODEL}` package run locally with sherpa-onnx |
| Licence | Apache-2.0 (Kokoro-82M weights; sherpa-onnx). Commercial use is allowed. |
| Voice | Built-in British female voice `{VOICE}`, normal speed ({SPEED}). No voice is cloned. |
| Checking | Every take is transcribed with faster-whisper `Systran/faster-whisper-{WHISPER}` (MIT) and the transcript must equal the word. A recogniser often misreads a word spoken on its own, so a take that fails alone is transcribed again after a spoken carrier phrase ("The word is …"); what follows must equal the word (Check: `carrier`, with the transcript of the whole phrase). The recordings themselves are the bare word. It is only used to check takes; nothing from it is shipped. |
| Format | Mono MP3, about 48 kbps, silence trimmed at both ends, loudness normalised (see `tool/build_word_audio.dart`) |
| Runtime | The Python environment bundled with VoiceStudio, called directly (not through its API), as for Listening and Speaking |

VoiceStudio's default engine (OmniVoice) was not used: its model is licensed
CC-BY-NC (non-commercial). See ../../listening/README.md.

## Rebuilding

```sh
# 1. build/word_voices/wav/<word>.wav, checked by transcription
#    (resume-safe; --redo word,word to regenerate)
~/.config/VoiceStudio/runtime/project/.venv/bin/python tool/generate_word_voices.py
# 2. assets/audio/words/<word>.mp3 (needs ffmpeg)
dart run tool/build_word_audio.dart
```

The WAVs in `build/` are not committed; the MP3s are.

## Words

| # | Word | Transcript | Check | Attempts |
| --- | --- | --- | --- | --- |
{rows}
""")


def main(args):
    redo = set()
    if "--redo" in args:
        redo = set(args[args.index("--redo") + 1].split(","))
    words = flashcard_words()
    status_file = WORK / "status.json"
    status = json.loads(status_file.read_text()) if status_file.exists() else {}
    OUT.mkdir(parents=True, exist_ok=True)
    (WORK / "takes").mkdir(parents=True, exist_ok=True)

    todo = [w for w in words
            if w in redo or w not in status or not (OUT / f"{w}.wav").exists()]
    if todo:
        from faster_whisper import WhisperModel

        log(f"Loading Kokoro ({MODEL}) and faster-whisper {WHISPER}…")
        tts = load_kokoro()
        asr = WhisperModel(WHISPER, device="cpu", compute_type="int8")
        for i, word in enumerate(todo, 1):
            result = None
            for attempt, text in enumerate(spellings(word), 1):
                started = time.time()
                take = WORK / "takes" / f"{word}.{attempt}.wav"
                write_take(tts, text, VOICE, SPEED, take)
                heard = transcribe(asr, take)
                check = "plain" if heard_word(heard) == word else None
                if check is None:
                    carried = transcribe(asr, carrier_take(tts, take, word))
                    if heard_word(carried) == heard_word(CARRIER) + word:
                        check, heard = "carrier", carried
                ok = check is not None
                log(f"  [{i}/{len(todo)}] {word} try {attempt} ({text!r}): "
                    f"{'ok, ' + check if ok else 'heard ' + repr(heard)} "
                    f"({time.time() - started:.0f}s)")
                result = {"attempts": attempt, "text": text, "voice": VOICE,
                          "speed": SPEED, "transcript": heard, "ok": ok,
                          "check": check}
                if ok:
                    (OUT / f"{word}.wav").write_bytes(take.read_bytes())
                    break
            status[word] = result
            status_file.write_text(json.dumps(status, indent=2) + "\n")
            if not result["ok"]:
                raise SystemExit(
                    f"'{word}' never matched its transcript; fix by hand "
                    "(see build/word_voices/takes) before continuing.")

    failed = [w for w in words if not status.get(w, {}).get("ok")]
    if failed:
        raise SystemExit(f"Not checked: {', '.join(failed)}")
    write_readme(words, status)
    log(f"words: done. {len(words)} words, every transcript equals its word.")


if __name__ == "__main__":
    main(sys.argv[1:])
