---
name: Prodovo
description: Quote & Budget Management System for Argentine businesses
colors:
  primary: "#4f46e5"
  primary-hover: "#4338ca"
  accent-blue: "#3b82f6"
  accent-blue-hover: "#2563eb"
  neutral-bg: "#f9fafb"
  neutral-surface: "#ffffff"
  neutral-border: "#e5e7eb"
  neutral-text: "#111827"
  neutral-muted: "#6b7280"
  neutral-subtle: "#374151"
  sidebar-bg: "#0f172a"
  sidebar-active: "rgba(255, 255, 255, 0.1)"
  status-success: "#16a34a"
  status-warning: "#ca8a04"
  status-danger: "#dc2626"
typography:
  body:
    fontFamily: "Inter, system-ui, -apple-system, sans-serif"
    fontSize: "1rem"
    fontWeight: 400
    lineHeight: 1.5
  heading:
    fontFamily: "Inter, system-ui, -apple-system, sans-serif"
    fontSize: "1.875rem"
    fontWeight: 700
    lineHeight: 1.2
  label:
    fontFamily: "Inter, system-ui, -apple-system, sans-serif"
    fontSize: "0.75rem"
    fontWeight: 600
    lineHeight: 1
    letterSpacing: "0.05em"
    textTransform: "uppercase"
rounded:
  sm: "4px"
  md: "6px"
  lg: "8px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "#ffffff"
    rounded: "{rounded.md}"
    padding: "8px 16px"
  button-primary-hover:
    backgroundColor: "{colors.primary-hover}"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.neutral-text}"
    rounded: "{rounded.md}"
    padding: "8px 16px"
    border: "1px solid {colors.neutral-border}"
  input-field:
    backgroundColor: "{colors.neutral-surface}"
    textColor: "{colors.neutral-text}"
    rounded: "{rounded.md}"
    padding: "12px 16px"
    border: "1px solid {colors.neutral-border}"
  card:
    backgroundColor: "{colors.neutral-surface}"
    rounded: "{rounded.lg}"
    padding: "{spacing.lg}"
    shadow: "0 1px 3px 0 rgba(0, 0, 0, 0.1)"
  table-header:
    backgroundColor: "#f9fafb"
    textColor: "{colors.neutral-muted}"
    rounded: "0"
    padding: "12px 24px"
  sidebar-item:
    backgroundColor: "transparent"
    textColor: "rgba(255, 255, 255, 0.7)"
    rounded: "{rounded.lg}"
    padding: "8px 16px"
  sidebar-item-active:
    backgroundColor: "{colors.sidebar-active}"
    textColor: "#ffffff"
---

# Design System: Prodovo

## 1. Overview

**Creative North Star: "The Professional's Desk"**

Prodovo is a business tool for Argentine business owners managing quotes, clients, and payments. The design gets out of the way and lets users focus on their work. Clarity and efficiency matter more than visual spectacle. The system is calm, organized, and predictable—like a well-ordered desk where everything has its place.

This system explicitly rejects consumer-app playfulness, marketing-site patterns, and excessive motion. It's not a social app, not a landing page, not a pitch. It's a daily-use tool that respects the user's time and attention.

**Key Characteristics:**
- Data-first: tables, forms, and status indicators are immediately scannable
- Minimal decoration: no gradients, no glassmorphism, no flashy reveals
- Predictable patterns: consistent spacing, clear feedback, no surprises
- Argentine locale: Spanish UI, number formatting with `.` thousands separator and `,` decimal

## 2. Colors

The palette is restrained and professional: cool grays for structure, a single indigo accent for primary actions, and semantic colors for status.

### Primary
- **Cool Professional Blue** (#4f46e5): The primary action color. Used sparingly for primary buttons, active states, and key links. Its rarity is the point—when everything is blue, nothing is.

### Neutral
- **Page Background** (#f9fafb): The canvas. Cool-tinted, not warm. Provides subtle contrast against white cards without competing.
- **Surface White** (#ffffff): Cards, tables, modals. The primary content container.
- **Border** (#e5e7eb): Dividers, input borders, card edges. Subtle enough to recede, visible enough to define structure.
- **Primary Text** (#111827): Headings, key data, labels. High contrast for readability.
- **Muted Text** (#6b7280): Secondary information, timestamps, metadata. Lower contrast but still legible (4.5:1 minimum).
- **Sidebar** (#0f172a): Dark slate for the navigation panel. Creates clear separation from the main content area.

### Semantic
- **Success** (#16a34a): Positive balances, completed actions, confirmed states.
- **Warning** (#ca8a04): Pending actions, cancellation states, attention needed.
- **Danger** (#dc2626): Destructive actions, negative balances, errors.

**The One Accent Rule.** Indigo is used on ≤10% of any given screen. Primary buttons, active nav items, key links. When everything is blue, nothing is.

## 3. Typography

**Body Font:** Inter (with system-ui fallback)
**Display Font:** Inter (same family, heavier weight)

**Character:** A single sans-serif family in multiple weights. Clean, modern, highly legible at small sizes. No font pairing complexity—just weight and size doing the work.

### Hierarchy
- **Page Title** (700, 1.875rem / 30px, line-height 1.2): Page headings. Bold, clear, immediate.
- **Section Heading** (600, 1.25rem / 20px, line-height 1.3): Section titles within pages.
- **Body** (400, 1rem / 16px, line-height 1.5): Default text. Comfortable reading, max line length 65–75ch.
- **Small** (400, 0.875rem / 14px, line-height 1.5): Secondary text, metadata, timestamps.
- **Label** (600, 0.75rem / 12px, line-height 1, letter-spacing 0.05em, uppercase): Table headers, form labels, status badges. Uppercase for scannability.

**The No-Decoration Rule.** No gradient text, no decorative fonts, no script faces. Typography is functional. Emphasis comes from weight and size, not ornament.

## 4. Elevation

The system is flat by default with minimal lift. Shadows appear only as a response to state (cards, modals, dropdowns) or interaction (hover). Depth is conveyed through background color contrast (page gray vs. surface white) rather than shadow depth.

### Shadow Vocabulary
- **Card** (`box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1)`): Subtle lift for cards and containers. Barely visible at rest, just enough to define the edge.
- **Modal** (`box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1)`): Stronger shadow for modals and dropdowns. Signals "this is above everything else."

**The Flat-By-Default Rule.** Surfaces are flat at rest. Shadows appear only as a response to state (hover, elevation, focus). If it looks like a 2014 app with heavy drop shadows, the shadow is too dark.

## 5. Components

### Buttons
- **Shape:** Gently curved edges (6px radius). Not pill-shaped, not sharp.
- **Primary:** Indigo background (#4f46e5), white text, 8px vertical / 16px horizontal padding. Hover darkens to #4338ca.
- **Secondary:** Transparent background, gray-700 text, 1px gray-300 border. Hover lightens background to gray-50.
- **Focus:** 2px indigo ring with 2px offset for keyboard navigation.
- **Transitions:** Background color 150ms ease-out. No transform, no scale.

### Inputs / Fields
- **Style:** White background, 1px gray-300 border, 6px radius. Padding 12px vertical / 16px horizontal.
- **Focus:** Border shifts to indigo-500, subtle indigo ring (focus:ring-indigo-500). No glow, no scale.
- **Error:** Border shifts to red-500, red ring. Error message below the field in red-600.
- **Placeholder:** Gray-400, not gray-300. Must meet 4.5:1 contrast against white.

### Cards / Containers
- **Corner Style:** 8px radius. Consistent across all card-like containers.
- **Background:** White (#ffffff) on gray-50 page background.
- **Shadow Strategy:** Minimal card shadow (see Elevation section). Just enough to define the edge.
- **Border:** None by default. Shadow does the work.
- **Internal Padding:** 24px (1.5rem) for cards, 16px for tighter containers like search forms.

### Tables
- **Header:** Gray-50 background, uppercase labels in gray-500 (12px, 600 weight, 0.05em letter-spacing). 12px vertical / 24px horizontal padding.
- **Rows:** White background, 1px gray-200 divider. Hover shifts to gray-50.
- **Cells:** 16px vertical / 24px horizontal padding. Text left-aligned by default, right-aligned for numeric data.
- **Links:** Indigo-600, hover darkens to indigo-900. No underline by default.

### Navigation (Sidebar)
- **Style:** Dark slate (#0f172a) background, white text. 256px width, fixed on desktop, collapsible on mobile.
- **Typography:** 14px, 500 weight. Uppercase labels for section headers.
- **Default State:** White text at 70% opacity.
- **Hover:** Background shifts to white at 10% opacity, text becomes fully opaque.
- **Active:** Background white at 10% opacity with subtle inner shadow. Text fully opaque.
- **Transitions:** Background and text color 150ms ease-out.

### Status Badges
- **Style:** Small pill (4px radius), uppercase label (12px, 600 weight). Background is a tinted version of the semantic color (e.g., green-100 for success), text is the semantic color (e.g., green-800).
- **Purpose:** Quote status (draft, sent, paid, cancelled), payment status, balance indicators.

## 6. Do's and Don'ts

### Do:
- **Do** use indigo sparingly. Primary buttons, active nav, key links. ≤10% of any screen.
- **Do** maintain 4.5:1 contrast for all text. Muted text is not an excuse for low contrast.
- **Do** use consistent spacing. 4px base unit: 4, 8, 16, 24, 32. No arbitrary values.
- **Do** make tables scannable. Uppercase labels, right-aligned numbers, hover states for rows.
- **Do** provide clear feedback. Hover states, focus rings, loading indicators, success/error messages.
- **Do** respect the Argentine locale. Spanish UI, number formatting (`.` thousands, `,` decimal), date formatting (dd/mm/yyyy).

### Don't:
- **Don't** use gradient text, glassmorphism, or decorative blurs. This is a business tool, not a landing page.
- **Don't** add excessive motion. No bounce, no elastic, no choreographed entrances. State changes only.
- **Don't** use dark mode as default. Office environments, varied lighting. Light theme is the default.
- **Don't** use marketing-site patterns. No hero sections, no scroll-driven storytelling, no flashy reveals.
- **Don't** use border-left or border-right greater than 1px as a colored accent. Rewrite with full borders, background tints, or nothing.
- **Don't** use identical card grids with icon + heading + text repeated endlessly. Use cards only when they're the best affordance.
- **Don't** use tiny uppercase tracked eyebrows above every section. One deliberate kicker is voice; eyebrows on every section is AI grammar.
- **Don't** make it look like a social app or a startup landing page. This is a professional desk, not a pitch.
