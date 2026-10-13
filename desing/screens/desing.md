---
name: Bandwise
colors:
  surface: '#fcf8ff'
  surface-dim: '#dad7f4'
  surface-bright: '#fcf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f2ff'
  surface-container: '#efebff'
  surface-container-high: '#e9e5ff'
  surface-container-highest: '#e3dffd'
  on-surface: '#25243A'
  on-surface-variant: '#474553'
  inverse-surface: '#2f2e45'
  inverse-on-surface: '#f2eeff'
  outline: '#787585'
  outline-variant: '#c8c4d6'
  surface-tint: '#594bc6'
  primary: '#4c3db9'
  on-primary: '#ffffff'
  primary-container: '#6558d3'
  on-primary-container: '#eee9ff'
  inverse-primary: '#c6bfff'
  secondary: '#516527'
  on-secondary: '#ffffff'
  secondary-container: '#d3ec9e'
  on-secondary-container: '#576b2c'
  tertiary: '#7b4400'
  on-tertiary: '#ffffff'
  tertiary-container: '#9e5900'
  on-tertiary-container: '#ffe7d5'
  error: '#E5484D'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e4dfff'
  primary-fixed-dim: '#c6bfff'
  on-primary-fixed: '#160066'
  on-primary-fixed-variant: '#4130ad'
  secondary-fixed: '#d3ec9e'
  secondary-fixed-dim: '#b7d084'
  on-secondary-fixed: '#141f00'
  on-secondary-fixed-variant: '#3a4d10'
  tertiary-fixed: '#ffdcc0'
  tertiary-fixed-dim: '#ffb876'
  on-tertiary-fixed: '#2d1600'
  on-tertiary-fixed-variant: '#6b3b00'
  background: '#fcf8ff'
  on-background: '#1a192f'
  surface-variant: '#e3dffd'
  background-surface: '#F7F6FC'
  success: '#38A169'
  success-tint: '#EBF8F1'
  warning: '#E29A36'
  warning-tint: '#FEF6EB'
  error-tint: '#FDF0F0'
  skill-listening: '#7BA7F7'
  skill-listening-tint: '#EEF4FE'
  skill-reading: '#70C2B4'
  skill-reading-tint: '#EDF8F6'
  skill-writing: '#F69E7B'
  skill-writing-tint: '#FEF4EF'
  skill-speaking: '#A07BE6'
  skill-speaking-tint: '#F4EFFF'
typography:
  headline-xl:
    fontFamily: Inter
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.025em
  headline-xl-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.015em
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
    letterSpacing: -0.005em
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: 0em
  body-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0.005em
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-tablet: 1.25rem
  gutter-desktop: 1.5rem
  margin: 1rem
  margin-tablet: 2rem
  margin-desktop: 3rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

The design system drives an IELTS preparation platform tailored for learners spanning beginner to advanced stages aiming for target scores between Band 6.0 and 8.0+. It delivers an experience that is calm, clean, authoritative, and tactfully gamified without turning juvenile or inducing academic anxiety.

- **Audience:** Global test takers, academic aspirants, and professionals seeking structured, high-stakes language proficiency.
- **Tone:** Methodical, reassuring, focused, and motivating.
- **Emotional Response:** Quiet competence, structured momentum, and low cognitive fatigue.
- **Visual Style:** Soft modernism blended with clean functional UI. A single, unified background canvas throughout every screen prevents jarring context shifts, complemented by pure white container cards, tactile rounded controls, and energizing accent moments.

## Colors

The system operates strictly in a light visual hierarchy designed for sustained study sessions, zero optical fatigue, and clear functional distinctions.

### Structural Palette
- **Canvas / Background (`#F7F6FC`):** A single, consistent background applied across all screens and views. No alternating canvas values.
- **Primary (`#6558D3`):** Vibrant iris purple. Used for principal interactive components, selected states, and core navigational affordances.
- **Secondary / Accent (`#DDF6A7`):** Electric soft lime. Reserved for positive reinforcement, high-value incentives, streak highlights, and celebration chips. Must always pair with `#25243A` text for WCAG accessibility.
- **On-Surface (`#25243A`):** Deep indigo slate. Serves as the primary typographic color, replacing pure black with a softer yet high-contrast tone.

### Semantic Status
- **Success:** `#38A169` (tint surface: `#EBF8F1`)
- **Warning:** `#E29A36` (tint surface: `#FEF6EB`)
- **Error:** `#E5484D` (tint surface: `#FDF0F0`)

### Skill Competency Tokens
Each IELTS discipline carries an explicit paired color and background tint for badges, tags, icons, and surface card containers:
- **Listening:** Primary `#7BA7F7`, Tint `#EEF4FE`
- **Reading:** Primary `#70C2B4`, Tint `#EDF8F6`
- **Writing:** Primary `#F69E7B`, Tint `#FEF4EF`
- **Speaking:** Primary `#A07BE6`, Tint `#F4EFFF`

## Typography

The typography is built entirely on **Inter** to ensure maximum academic clarity, clean glyph geometries, and high-density legibility during rigorous test preparation.

- **Body Copy & Reading Passages:** Extended reading modules utilize `body-lg` (16px / 26px line height) in `#25243A` to support reading comprehension and minimize line fatigue.
- **Headings & Actions:** Headings use Semibold (`600`) and Bold (`700`) weights to produce a decisive information hierarchy.
- **Numbers & Scores:** All active counters, timers, and score metrics must use tabular figures (`font-variant-numeric: tabular-nums`) to prevent layout shifts.

## Layout & Spacing

The layout architecture employs a mobile-first philosophy that transitions into centered multi-column layouts on larger screens.

- **Mobile (< 640px):** Single-column fluid view with `1rem` (16px) margins and `1rem` gutters for multi-item rows.
- **Tablet (640px – 1024px):** 6-column grid with `2rem` margins and `1.25rem` gutters, facilitating two-column comparative split views for reading passages alongside question inputs.
- **Desktop (≥ 1024px):** Centered layout with a max container width of 1120px, framed by `3rem` margins and `1.5rem` gutters.
- **Spacing Rhythm:** Internal card padding is standardized at `1.25rem` (20px) to `1.5rem` (24px) for cards, and tightly paired item gaps leverage `space-xs` (4px) and `space-sm` (8px).

## Elevation & Depth

Visual hierarchy is maintained through soft, ambient surface separation over the universal `#F7F6FC` backdrop.

- **Canvas Foundation:** `#F7F6FC` flat background across all views.
- **Resting Cards:** `#FFFFFF` fill with an ambient shadow `0 4px 16px rgba(37, 36, 58, 0.05)` and a micro-border `1px solid rgba(37, 36, 58, 0.04)`.
- **Interactive / Hover Surfaces:** Elevated with `0 8px 24px rgba(37, 36, 58, 0.08)`.
- **Modals & Drawers:** Positioned above with `0 -8px 32px rgba(37, 36, 58, 0.12)`, masked with an overlay of `rgba(37, 36, 58, 0.35)`.
- **Skill Cards & Gauges:** Skill surfaces sit flat on their designated surface tint tokens rather than utilizing heavy dropped shadows, keeping the aesthetic light and organized.

## Shapes

The design uses an explicit four-tier corner radius hierarchy:

- **Cards & Primary Modules:** `18px` (`rounded-[18px]`) to establish friendly, distinct containment for major content areas.
- **Buttons & Input Fields:** `14px` (`rounded-[14px]`) for primary touch targets and text entry fields.
- **Nested Inner Elements:** `12px` (`rounded-[12px]`) for controls, nested cards, list rows, and sub-panels residing inside a primary container.
- **Pills & Badges:** `9999px` (`rounded-full`) for status chips, skill indicators, and tags.

## Components

### Buttons
- **Primary:** Background `#6558D3`, text `#FFFFFF`, border-radius 14px, height 48px to 52px, font-weight 600.
- **Secondary / Gamified Accent:** Background `#DDF6A7`, text `#25243A`, border-radius 14px, font-weight 700. Reserved for milestone completions, reward claims, and high-energy CTAs.
- **Subtle / Ghost:** Background transparent, text `#25243A`, hover state with `#F4EFFF` or 5% `#25243A` fill, border-radius 14px.

### Input Fields & Controls
- **Inputs:** Height 50px, border-radius 14px, background `#FFFFFF`, border `1.5px solid rgba(37, 36, 58, 0.12)`. Focus state: border `#6558D3` with an outer ring `0 0 0 3px rgba(101, 88, 211, 0.15)`.
- **Checkboxes & Radios:** 20px size with 6px radius for checkboxes, full circle for radios. Active state fill `#6558D3` with `#FFFFFF` checkmark or center pip.
- **Selection Quiz Cards:** Border-radius 14px, background `#FFFFFF`, border `1.5px solid rgba(37, 36, 58, 0.08)`. Selected state applies `2px solid #6558D3` with `#F4EFFF` background. Feedback states apply Success (`#38A169` border, `#EBF8F1` tint) or Error (`#E5484D` border, `#FDF0F0` tint).

### Skill Cards & Badges
- **Skill Badges:** Height 26px to 30px, `rounded-full`, paired with the exact skill background tint and solid skill text color (e.g., Reading: `#70C2B4` text on `#EDF8F6` tint).
- **Skill Containers:** Built with `rounded-[18px]`, pure `#FFFFFF` or tinted backgrounds (`#EEF4FE`, `#EDF8F6`, `#FEF4EF`, `#F4EFFF`), carrying 12px inner components.

### Cards
- Standard modules utilize `rounded-[18px]`, background `#FFFFFF`, border `1px solid rgba(37, 36, 58, 0.04)`, and ambient shadow.
- Inner elements (progress bars, item tiles) maintain concentricity with `rounded-[12px]`.

### Band Score Gauges (Strict Constraint)
- **Constraint Policy:** Band score circular gauges appear **only** on AI feedback screens and mock exam result screens.
- **Labeling Requirement:** Every band score gauge must explicitly display the label **"Practice estimate"** directly adjacent to or beneath the numerical band score (e.g., "Band 7.5 • Practice estimate").
- **Exclusion:** Band score gauges must never appear on lessons, curriculum pathways, syllabus navigation, or skill shortcuts.












