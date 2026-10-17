# Bandwise — Flutter app

Independent IELTS Academic prep app. Not affiliated with IELTS, British Council, IDP, or Cambridge.

## Stack
- Flutter (latest stable), Dart null-safe
- State: Riverpod. Routing: go_router with a ShellRoute for the 5-tab bottom nav.
- Feature-first folders: lib/core (theme, widgets, utils), lib/features/<feature>/{data,domain,presentation}
- All data behind repository interfaces with mock implementations first; real backend comes later.
- No API keys in the app. AI calls will go through a server function.

## Design source of truth
- design/screens/*.md are Stitch exports (HTML inside Markdown): use them for LAYOUT and CONTENT only.
- Do NOT copy colors from their tailwind config (it is wrong). Use only these tokens in lib/core/theme:
  - primary #6558D3, accent/lime #DDF6A7, background #F7F6FC, card #FFFFFF, text #25243A
  - success #38A169 / #EDFDF5, warning #E29A36 / #FEF9EE, error #E5484D (borders, icons) and #B42318 (error text)
  - skills: listening #7BA7F7 / #EEF4FE, reading #70C2B4 / #EDF8F5, writing #F69E7B / #FEF4F0, speaking #A07BE6 / #F5F1FD
  - radius: card 18, button/input 14, nested 12, pill full
  - font: Inter; tabular figures for timers and scores
- Card shadow: 0 4 16 rgba(37,36,58,0.06). Selected card: bg #F5F3FF + 2px primary border.
- Never hardcode a color or radius in a screen; always use theme tokens.

## Product rules (never break these)
- Band scores appear ONLY in AI writing/speaking feedback and mock exam results, always labeled "Practice estimate — not an official IELTS score".
- No band on lessons, units, skill cards, placement, or the study plan. Use accuracy %, "Mastered", or levels.
- Placement gives a recommended starting point, not a level or band.
- Official band descriptors: 6 Competent, 7 Good, 8 Very good, 9 Expert.
- The user's own chosen target may be shown as "Goal X.X". It is a goal, not a score.
- A streak day = any day with at least one completed activity. The daily goal is tracked separately and does not affect the streak.
- Writing Task 1 uses Task Achievement; Task 2 uses Task Response.
- Don't claim AI where logic is rule-based.
- Consent checkboxes are unchecked by default.
- Password reset copy must not reveal whether an account exists.
- Dates in mock data are in the future relative to today.
- Timed exam screens hide the bottom nav and have no hints or animations.

## Working rules
- Build shared widgets before screens; reuse them.
- Every screen supports loading, empty, and error states where relevant.
- Prepare for Arabic: use Directionality-safe padding (EdgeInsetsDirectional), no hardcoded left/right.
- After each phase: flutter analyze passes, app runs, commit.