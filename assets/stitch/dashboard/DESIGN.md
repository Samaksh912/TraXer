# Design System Strategy: The Obsidian Lens

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"Tactile Fluidity."** 

We are moving away from the rigid, "boxed-in" nature of traditional financial dashboards. Instead, we are treating the interface as a high-end editorial piece viewed through a series of precision-cut glass lenses. This system rejects the "template" aesthetic by favoring intentional asymmetry, varying levels of transparency, and a hierarchy defined by light and depth rather than lines and borders. 

By leveraging **Obsidian Depth** (our deep background tones) and **Liquid Glass** (our blur-heavy containers), we create an environment that feels both mathematically precise and organically fluid.

---

## 2. Colors & The Surface Philosophy
The palette is rooted in a deep, nocturnal base (`#060e20`) punctuated by high-energy, bioluminescent accents.

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders for sectioning. 
Boundaries must be defined solely through background color shifts. Use the `surface-container` tokens to distinguish between areas. For example, a `surface-container-low` side panel sitting on a `surface` background provides enough contrast to be felt without being seen as a "line."

### Surface Hierarchy & Nesting
Treat the UI as a physical stack of materials. 
*   **The Void (`surface-container-lowest`):** Used for recessed areas, like input fields or background wells.
*   **The Base (`surface`):** The primary canvas.
*   **The Plate (`surface-container` / `high`):** For primary content cards.
*   **The Lens (`surface-variant` + blur):** For floating overlays and navigation.

### The "Glass & Gradient" Rule
Standard flat colors lack soul. Main CTAs and high-level financial visualizations must utilize a signature "Liquid" gradient, transitioning from `primary` (#9effc8) to `primary-container` (#1dfba5) at a 135-degree angle. This mimics the refraction of light through a fluid medium.

---

## 3. Typography: Editorial Precision
The system uses a tri-font architecture to balance authority with technical data.

*   **The Statement (Manrope):** Used for `display` and `headline` scales. This is our "Editorial" voice—wide, modern, and confident. Use `display-lg` (3.5rem) with tighter tracking (-0.02em) for hero data points to create a high-end magazine feel.
*   **The Workhorse (Inter):** Used for `title` and `body` scales. Inter provides the legibility required for dense financial ledgers.
*   **The Technical (Space Grotesk):** Reserved for `label` scales. Its tabular-friendly qualities make it perfect for secondary data, timestamps, and micro-metadata.

---

## 4. Elevation & Depth: The Layering Principle
We do not use elevation to "lift" objects; we use it to "refract" them.

*   **Tonal Layering:** Instead of a drop shadow, place a `surface-container-highest` card atop a `surface` background. This creates a soft, sophisticated lift.
*   **Ambient Shadows:** If a floating element (like a modal) requires a shadow, use a large blur (32px+) and a color tinted with `on-surface` at 6% opacity. Avoid pure black shadows; they feel "dirty" on our deep blue base.
*   **The Glassmorphism Formula:** 
    *   **Fill:** `surface-variant` at 40% opacity.
    *   **Effect:** Backdrop Blur at 20px–40px.
    *   **The Ghost Border:** A 1px stroke using `outline-variant` at 15% opacity to catch "specular highlights" on the edge of the glass.

---

## 5. Components & Primitive Styling

### Buttons: The Tactile Pill
*   **Primary:** Pill-shaped (`rounded-full`), using the `primary` to `primary_container` gradient. No border. Text is `on_primary_fixed` (Deep Green).
*   **Secondary:** `surface_variant` at 20% opacity with a 40px backdrop blur. This creates a "Ghost Glass" button that feels integrated into the background.

### Cards: The Liquid Lens
*   **Styling:** Use `rounded-lg` (2rem) or `xl` (3rem) for dashboard containers. 
*   **Constraint:** Forbid the use of divider lines. Separate content using `body-sm` labels in `on_surface_variant` and increased vertical whitespace from the spacing scale.
*   **Interaction:** On hover, a card should shift from `surface-container` to `surface-container-high` to provide a tactile "swell" effect.

### Input Fields: Recessed Wells
*   **Styling:** Inputs should look like they are carved into the interface. Use `surface-container-lowest` for the fill and a `rounded-sm` (0.5rem) corner.
*   **Focus State:** Instead of a heavy border, use a 1px `ghost border` of `primary` at 40% and a soft outer glow of `primary_dim`.

### Financial Data Visualization
*   **Growth:** Use `primary` (#9effc8) with a soft glow effect.
*   **Loss/Alert:** Use `error` (#ff716c).
*   **Trend Lines:** Must be "fluid"—use bezier curves with a 2px stroke width and a gradient fade-to-transparent under the line to simulate liquid depth.

---

## 6. Do’s and Don’ts

### Do
*   **Do** use `space-grotesk` for all numerical data to ensure technical alignment.
*   **Do** use generous padding. If a layout feels "cramped," double the whitespace. High-end design requires "breathing room."
*   **Do** use overlapping elements. Let a glass card partially obscure a background gradient to showcase the backdrop blur.

### Don’t
*   **Don’t** use 100% opaque borders. They break the "Liquid Glass" illusion.
*   **Don’t** use standard "FinTech Blue." Stick to our `surface` (#060e20) and `primary` (#9effc8) ecosystem.
*   **Don’t** use sharp corners. Use `DEFAULT` (1rem) as your minimum baseline for containers to maintain the "fluid" aesthetic.