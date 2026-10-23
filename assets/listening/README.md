# Listening audio

Original practice recordings written for Bandwise. They are not IELTS
recordings or scripts, and every voice is synthetic.

## Engine

| | |
| --- | --- |
| Speech | KittenTTS, model `KittenML/kitten-tts-mini-0.8` (package `kittentts` 0.8.1), run locally on CPU |
| Licence | Apache-2.0 (model weights and package) |
| Voices | KittenTTS built-in presets only. No voice is cloned from anyone. |
| Checking | Every take is transcribed with faster-whisper `Systran/faster-whisper-large-v3` (MIT). It is only used to check takes, and nothing from it is shipped. |
| Runtime | The Python environment bundled with VoiceStudio 0.5.6 (`~/.config/VoiceStudio/runtime/project/.venv`), called directly, not through VoiceStudio's API |

### Why not VoiceStudio's default engine

VoiceStudio's default engine, OmniVoice (`k2-fsa/OmniVoice`), can design
British and Australian voices. Its pre-trained model, however, is licensed
**CC-BY-NC** (non-commercial), and its audio tokenizer is under the Boson
Higgs Audio 2 Community License. It also ran very slowly on this machine's
CPU. Audio from it should not ship in the app, so it was not used.

### Accents

The scripts were written for British, Australian and North American
speakers, as the real test has. KittenTTS has no accent control: all its
presets sound North American. Each set's README lists the accent each
speaker was written for next to the voice used. Replacing the audio with
accented voices later only needs new `audio/<lineId>.wav` files and a
rebuild; the app reads only `listening.mp3` and `timestamps.json`.

## Voices

| Set | Speaker | Voice |
| --- | --- | --- |
| A, B | Narrator | `expr-voice-3-m` |
| A | Joanna (receptionist) | `expr-voice-4-f` |
| A | Daniel (caller) | `expr-voice-2-m` |
| B | Dr Price (tutor) | `expr-voice-3-f` |
| B | Maya (student) | `expr-voice-5-f` |
| B | Liam (student) | `expr-voice-4-m` |

The voice for each speaker is set in `<set>/script.json` (`speakers[].voice`).

## Rebuilding

```sh
# 1. Generate audio/<lineId>.wav for every line (resume-safe; progress in
#    build/listening_voices/). --redo a014,a018 regenerates given lines.
~/.config/VoiceStudio/runtime/project/.venv/bin/python tool/generate_listening_voices.py

# 2. Join, normalise and encode listening.mp3 + timestamps.json (needs ffmpeg).
dart run tool/build_listening_audio.dart
```

The `audio/` folders are not committed; `listening.mp3` and
`timestamps.json` are.
