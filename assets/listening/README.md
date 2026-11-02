# Listening audio

Original practice recordings written for Bandwise. They are not IELTS
recordings or scripts, and every voice is synthetic.

## Engine

| | |
| --- | --- |
| Speech | Kokoro-82M (hexgrad), the `kokoro-en-v0_19` package run locally on CPU with sherpa-onnx (the same engine as the Speaking examiner) |
| Licence | Apache-2.0 (Kokoro-82M weights; sherpa-onnx). Commercial use is allowed. |
| Voices | Kokoro built-in voices only. No voice is cloned from anyone. |
| Checking | Every take is transcribed with faster-whisper `Systran/faster-whisper-large-v3` (MIT). It is only used to check takes, and nothing from it is shipped. |
| Runtime | The Python environment bundled with VoiceStudio 0.5.6 (`~/.config/VoiceStudio/runtime/project/.venv`), called directly, not through VoiceStudio's API |

The model package is downloaded to `build/tts_models/` the first time the
generator runs.

### Why not VoiceStudio's default engine

VoiceStudio's default engine, OmniVoice (`k2-fsa/OmniVoice`), can design
British and Australian voices. Its pre-trained model, however, is licensed
**CC-BY-NC** (non-commercial), and its audio tokenizer is under the Boson
Higgs Audio 2 Community License. It also ran very slowly on this machine's
CPU. Audio from it should not ship in the app, so it was not used.

### Accents

The real test has British, Australian and North American speakers. Kokoro
has British (`bf_`, `bm_`) and American (`af_`, `am_`) English voices but
no Australian one, so every speaker has a British voice except Maya, who is
North American. Each set's README lists the accent each speaker was written for
next to the voice used. The app reads only `listening.mp3` and
`timestamps.json`, so replacing a voice later only needs new
`audio/<lineId>.wav` files and a rebuild.

## Voices

| Set | Speaker | Voice (speed) | Accent |
| --- | --- | --- | --- |
| A, B | Narrator | `bm_george` (0.95) | British |
| A | Joanna (receptionist) | `bf_emma` (1.0) | British |
| A | Daniel (caller) | `bm_lewis` (1.0) | British |
| B | Dr Price (tutor) | `bf_isabella` (1.0) | British |
| B | Maya (student) | `af_bella` (1.05) | North American |
| B | Liam (student) | `bm_lewis` (1.0) | British |

The voice for each speaker is set in `<set>/script.json` (`speakers[].voice`).
The narrator uses the same voice as the Speaking examiner.

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
