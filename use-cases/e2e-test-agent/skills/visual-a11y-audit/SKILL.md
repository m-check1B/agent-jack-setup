---
name: visual-a11y-audit
description: Use this when auditing responsive layout across 360/390/1280 viewports, light and dark themes, locale consistency, WCAG contrast and accessibility trees, and visual screenshots.
---

Inspect the real rendered UI across viewports, color schemes, languages, and accessibility surfaces so layout collapse, clipped controls, unreadable contrast, and broken translations never ship unnoticed.

## Viewport, Theme, and Locale Matrix

Always test the minimum responsive matrix unless the app explicitly omits a dimension (document omitted dimensions as `N/A` with reason):

1. **Viewports**:
   - Phone narrow: `360x800`
   - Phone standard: `390x844`
   - Desktop standard: `1280x800`
2. **Color schemes**:
   - `light` (`prefers-color-scheme: light` or app light toggle)
   - `dark` (`prefers-color-scheme: dark` or app dark toggle)
3. **Locales** (where the app is multilingual, e.g. `en` / `cs`):
   - Verify primary navigation, CTAs, cookie banner, error pages, legal footer, and validation messages stay in the selected locale with zero untranslated leaks or raw i18n keys.

Use Jack's `browser.set_viewport` and `browser.snapshot` when advertised by `browser.inventory`, or clean-profile Playwright on a Paired Mac route when running full viewport/theme/locale sweeps.

## Automated Geometry and Layout Checks

Do not rely solely on `document.documentElement.scrollWidth <= window.innerWidth` — `overflow: hidden` masks clipped controls! Measure actual element geometry on every viewport:

1. **Horizontal clipping and off-screen controls**:
   - Check visible interactive controls (`a`, `button`, `input`, `select`, `[role="button"]`, `[role="menuitem"]`) inside header, nav, and primary panes: `getBoundingClientRect().right <= window.innerWidth + 1`, `left >= -1`, and `width > 0 && height > 0`.
2. **Pane height collapse on phone**:
   - Measure primary content panes (`main`, lesson/editor/chat containers, dialogs). Flag any primary working pane whose visible height collapses below usable bounds (e.g. `< 160px` on a `>= 700px` viewport).
3. **Text overlap and sticky obstruction**:
   - Flag overlapping sibling buttons/badges, clipped button labels, and sticky headers or cookie banners that cover primary CTAs or focused inputs above the fold.

## Accessibility (WCAG 2.1 AA) Checks

1. **Color contrast**:
   - Normal text contrast ratio `>= 4.5:1`; large text (`>= 18pt` or `>= 14pt bold`) and UI components `>= 3.0:1` in both `light` and `dark` themes. Verify the page actually honors `prefers-color-scheme: dark` on first paint rather than staying light white.
2. **Accessible names and semantics**:
   - Every icon-only button has an `aria-label` or visually hidden text.
   - Every form input has an associated `<label>`, `aria-label`, or `aria-labelledby`.
   - Document uses a logical `<h1>`, ordered headings, landmark regions (`header`, `nav`, `main`, `footer`), and meaningful `alt` text on non-decorative images.
3. **Keyboard focus and modal traps**:
   - Verify visible focus ring on `Tab` traversal, `Escape` closes dialogs/menus, and focus is not lost behind open drawers.

## Visual Screenshot Inspection

1. Capture durable PNG screenshots via `browser.screenshot` (persisted to `TalkMediaStore` with downscaled vision preview) or Playwright into `outputs/screenshots/<app>-<env>-<viewport>-<theme>-<locale>.png` for every failure and representative desktop (`1280`) + phone (`390`) light/dark views.
2. Inspect captured screenshots directly using vision to catch defects DOM metrics miss: ignored dark mode, cookie banners covering primary CTAs, broken SVGs, misaligned icons, or clipped logos.
3. If a surface omits screenshot bytes and provides no persisted media ref, record visual inspection as `BLOCKED` instead of guessing.

## Output Contract

Report each visual or a11y finding with exact viewport (`WxH`), theme (`light`/`dark`), locale, URL, selector/element description, measured value vs threshold (e.g. `contrast 2.1:1 < 4.5:1`, `right=418px > viewport 390px`, `pane height 50px`, `renders light under prefers-color-scheme: dark`), and screenshot filename.
