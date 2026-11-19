---
name: FindMyDoc Design System
colors:
  surface: '#fbf9f9'
  surface-dim: '#dbdad9'
  surface-bright: '#fbf9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f3f3'
  surface-container: '#efeded'
  surface-container-high: '#e9e8e7'
  surface-container-highest: '#e3e2e2'
  on-surface: '#1b1c1c'
  on-surface-variant: '#40493d'
  inverse-surface: '#303031'
  inverse-on-surface: '#f2f0f0'
  outline: '#707a6c'
  outline-variant: '#bfcaba'
  surface-tint: '#1b6d24'
  primary: '#0d631b'
  on-primary: '#ffffff'
  primary-container: '#2e7d32'
  on-primary-container: '#cbffc2'
  inverse-primary: '#88d982'
  secondary: '#006e1c'
  on-secondary: '#ffffff'
  secondary-container: '#91f78e'
  on-secondary-container: '#00731e'
  tertiary: '#0054a7'
  on-tertiary: '#ffffff'
  tertiary-container: '#246dc8'
  on-tertiary-container: '#edf1ff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#a3f69c'
  primary-fixed-dim: '#88d982'
  on-primary-fixed: '#002204'
  on-primary-fixed-variant: '#005312'
  secondary-fixed: '#94f990'
  secondary-fixed-dim: '#78dc77'
  on-secondary-fixed: '#002204'
  on-secondary-fixed-variant: '#005313'
  tertiary-fixed: '#d6e3ff'
  tertiary-fixed-dim: '#a9c7ff'
  on-tertiary-fixed: '#001b3d'
  on-tertiary-fixed-variant: '#00468c'
  background: '#fbf9f9'
  on-background: '#1b1c1c'
  surface-variant: '#e3e2e2'
typography:
  display-sm:
    fontFamily: Inter
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 26px
    fontWeight: '600'
    lineHeight: 34px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  title-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.03em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

The design system establishes a calm, trustworthy, and civic-minded digital environment for recovering critical personal documents (passports, national IDs, academic degrees, driver's licenses). Users interacting with this product are often experiencing acute stress or high anxiety regarding lost identification; the interface must therefore project absolute competence, clarity, and safety.

Synthesizing modern Material Design 3 ergonomics with utilitarian minimalism, the visual tone avoids playful decoration in favor of clarity, purposeful whitespace, and reassuring organic green accents. Every interaction reinforces security, data integrity, and swift resolution.

Key visual pillars:
- **Reassurance & Credibility:** Restrained deep green palettes evoking official verification, safety, and legitimacy.
- **Cognitive Ease:** Generous tap targets, low visual friction, and prominent scannable status trackers.
- **Structural Legibility:** Explicit card containers with clean segmentation, letting users quickly distinguish between "Lost", "Found", and "Claimed" records.

## Colors

The palette is engineered around Material Design 3 color logic, prioritizing accessible contrast, civic trust, and unambiguous status communication.

### Palette Architecture
- **Primary (`#2E7D32`):** Grounded forest green representing trust, resolution, and security. Used for critical CTAs, active navigation items, app bars, and high-emphasis verified badges.
- **Primary Container (`#E8F5E9`):** Soft organic tint applied to input backgrounds, card containers, selected chip backgrounds, and pill badge bases. Ensures comfortable contrast with dark text.
- **Secondary (`#4CAF50`):** Vibrant leaf green used for positive progress states, success notifications, switch active thumbs, and secondary action highlights.
- **Tertiary (`#1565C0`):** Authoritative information blue dedicated to document classification tags, legal disclaimers, and government verification workflows.
- **Surface & Background (`#F9FBF9` & `#FFFFFF`):** Base canvas utilizes `#F9FBF9` (an ultra-subtle off-white with an organic cool green cast), while elevated cards, sheets, and dialogs sit on pure `#FFFFFF`.
- **Text & Neutral (`#212121` on `#757575`):** Text hierarchy follows strict contrast ratios. Primary text uses near-black `#212121` for crisp legibility; secondary body, metadata, and timestamps utilize `#757575`. Outlines and dividers rely on `#E0E0E0`.
- **Status Accents:**
  - *Reported Lost / Pending:* Warning Amber (`#ED6C02` on `#FFF3E0`)
  - *Matched / Verifying:* Info Blue (`#0288D1` on `#E1F5FE`)
  - *Handed Over / Resolved:* Success Green (`#2E7D32` on `#E8F5E9`)

## Typography

The type system uses **Inter** across all roles to ensure universal screen clarity, neutral character rendering, and distinct optical distinction between numerals and capital letters (vital for document serial numbers and tracking codes).

Guidelines:
- **Document Numbers & Identification Codes:** Render all passport, serial, and reference numbers with tabular numeral figures or tracking-optimized `label-lg` weights to prevent misreading characters like `0`/`O` and `1`/`I`.
- **Vertical Rhythm:** Headings enforce tight negative tracking for high-impact presence on compact mobile widths, while labels maintain subtle positive tracking for instantaneous readability on pills and chips.
- **Hierarchy Mapping:**
  - `display-sm` & `headline-lg`: Top-level overview screens, onboarding value propositions, and success confirmation views.
  - `headline-md` & `title-md`: Document item titles, modal sheet titles, and form section headers.
  - `body-md`: Primary narrative description, user instructions, and lost location details.
  - `label-md` & `label-sm`: Status pills, timestamp markers, and filter chips.

## Layout & Spacing

The layout is built for fluid touch screens with strict adherence to a 4px/8px incremental grid.

- **Mobile Canvas Margins:** Screen edge padding enforces a strict `1rem` (16px) margin on phones, stepping up to `1.5rem` (24px) on compact tablets.
- **Vertical Rhythm:** Form inputs, summary cards, and detail sections maintain `space-md` (16px) separation. Tightly coupled items (such as input labels and text fields, or document icons and document names) use `space-xs` (4px) to `space-sm` (8px).
- **Safe Areas & Modals:** Bottom app bars and Floating Action Buttons (FABs) observe safe area insets with minimum `space-lg` (24px) floating buffer from screen bottoms. Modal bottom sheets use an internal inset of `1.25rem` (20px).

## Elevation & Depth

This design system avoids harsh, muddy drop shadows in favor of Material 3 tinted atmospheric elevation and crisp surface tonal separation.

- **Base Layer (Elevation 0):** Canvas `#F9FBF9`. Used for primary backgrounds and full-bleed list layouts.
- **Surface Cards (Elevation 1):** `#FFFFFF` surface paired with an ultra-light chromatic shadow: `0px 2px 8px -2px rgba(46, 125, 50, 0.06), 0px 1px 3px 0px rgba(0, 0, 0, 0.04)`. Card boundaries can be complemented with a subtle border (`1px solid #E8EFE8`) to maintain crisp boundaries without shadow dependence.
- **Raised Interactive Cards & App Bar (Elevation 2):** Scrolled app bars and dragged items: `0px 4px 14px -3px rgba(33, 33, 33, 0.08)`.
- **Bottom Sheets & Floating Menus (Elevation 3):** Modal document filers and filters: `0px 8px 24px -4px rgba(33, 33, 33, 0.12)`.
- **Floating Action Buttons (FAB) & Critical Alerts (Elevation 4):** Primary "+ Report Lost/Found" trigger: `0px 6px 18px 0px rgba(46, 125, 50, 0.28)`.

## Shapes

The shape architecture harmonizes structured containers with fluid, approachable touch targets.

- **Cards & Surfaces (`rounded-lg` / 16px):** Document listings, preview containers, photo verification frames, and dialog boxes use a uniform 16px corner radius.
- **Action Controls (`rounded-full` / Pill):** Primary action buttons, status indicator badges, filter tags, and floating search bars use full pill styling (`9999px` / 50% radius) to deliver distinct affordance against rectangular cards.
- **Form Text Fields (`rounded-md` / 12px):** Input boxes implement a 12px rounded contour to strike a balance between structural form alignment and friendly softness.

## Components

### Buttons
- **Primary Action (Pill Button):** Solid `#2E7D32` fill, `#FFFFFF` text (`label-lg`), height 52px. Full pill radius (`rounded-full`). On tap/hover: tint overlay with 8% white.
- **Secondary / Container Button:** `#E8F5E9` background, `#2E7D32` text, no border. Height 48px or 52px.
- **Outlined Button:** Border `1.5px solid #2E7D32`, transparent background, `#2E7D32` text.
- **FAB (Floating Action Button):** Extended pill or rounded square (16px) in `#2E7D32` with `#FFFFFF` icon and label, anchored at bottom-right with standard 16px margins.

### Cards & Document Tiles
- **Standard Document Card:** White `#FFFFFF` surface, 16px border-radius, 1px border `#E8EFE8`, elevation-1 shadow. Internal padding `16px`. Left side includes a 44x44px document type container (`#E8F5E9` rounded-12 with deep green SVG iconography), middle contains document title, masked ID number (`*** *** 9283`), and discovery city/date. The top-right corner reserves space for status badges.

### Status Badges & Chips
- **Status Pills:** Height 24px-28px, rounded-full, horizontal padding 10px.
  - *Lost:* Amber fill (`#FFF3E0`), text `#B25E00`.
  - *Found:* Mint green fill (`#E8F5E9`), text `#2E7D32`.
  - *Claim In Progress:* Blue fill (`#E1F5FE`), text `#0277BD`.
- **Filter Chips:** Height 36px, rounded-full. Unselected: `#FFFFFF` background with `1px solid #E0E0E0`, `#757575` text. Selected: `#E8F5E9` fill, `1px solid #2E7D32`, `#2E7D32` text with active checkmark icon.

### Form Inputs
- **Text Fields:** Height 56px, background `#FFFFFF` or `#F9FBF9`, border `1px solid #CFD8DC`, corner radius 12px. Internal padding 16px horizontal.
- **Focus State:** 2px border `#2E7D32` without layout shift, floating label recolored to `#2E7D32`.
- **Helper & Error States:** Error triggers 1.5px border `#D32F2F` with helper text transitioning to `#D32F2F` alongside a leading warning icon.

### Selection Controls
- **Checkboxes & Radios:** Active state filled in `#2E7D32` with white checkmark/dot. Inactive state features a `#757575` outline (2px) against a transparent background.
- **Switches:** Thumb colored `#2E7D32` on active track `#C8E6C9`. Inactive thumb `#BDBDBD` on track `#E0E0E0`.

### Document Specific Patterns
- **Photo Upload Thumbnail:** Dashed boundary (`1.5px dashed #4CAF50`), soft background `#E8F5E9`, corner radius 12px, centered icon with caption "Tap to upload ID scan / snapshot".
- **Verification Confidence Meter:** Linear bar indicator (height 6px, rounded-full) filled with `#4CAF50` over `#E0E0E0` background with `label-sm` displaying percentage match against reported criteria.