# Word pronunciation audio

One recording per flashcard word in the course, `<word>.mp3`: what the
pronunciation button plays on flashcards in lessons, in review and in the
vocabulary notebook. A word without a file simply has no button.

> The word list is read from the course content by
> `tool/generate_word_voices.py`, which also writes this file. Do not edit it
> by hand.

## Engine and licences

| | |
| --- | --- |
| Speech | Kokoro-82M (hexgrad), the `kokoro-en-v0_19` package run locally with sherpa-onnx |
| Licence | Apache-2.0 (Kokoro-82M weights; sherpa-onnx). Commercial use is allowed. |
| Voice | Built-in British female voice `bf_emma`, normal speed (1.0). No voice is cloned. |
| Checking | Every take is transcribed with faster-whisper `Systran/faster-whisper-large-v3` (MIT) and the transcript must equal the word. A recogniser often misreads a word spoken on its own, so a take that fails alone is transcribed again after a spoken carrier phrase ("The word is …"); what follows must equal the word (Check: `carrier`, with the transcript of the whole phrase). The recordings themselves are the bare word. It is only used to check takes; nothing from it is shipped. |
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
| 1 | `fluctuate` | The word is fluctuate. | carrier | 1 |
| 2 | `considerable` | Considerable. | plain | 1 |
| 3 | `maintain` | Maintain | plain | 1 |
| 4 | `concede` | Concede. | plain | 1 |
| 5 | `implication` | Implication | plain | 1 |
| 6 | `correlation` | Correlation | plain | 1 |
| 7 | `consequence` | Consequence | plain | 1 |
| 8 | `conduct` | The word is CONDUCT. | carrier | 2 |
| 9 | `widespread` | Widespread | plain | 1 |
| 10 | `clause` | The word is... Clause. | carrier | 1 |
| 11 | `paraphrase` | Paraphrase. | plain | 1 |
| 12 | `approximately` | Approximately | plain | 1 |
