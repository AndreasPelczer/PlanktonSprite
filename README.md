# PlanktonSprite

**Game-ready pixel animation. Mobile. Fast.**

PlanktonSprite is a native SwiftUI sprite animation tool built for indie game developers.  
Draw pixel-perfect frames, animate with onion skin, and export directly into your game engine — no desktop required.

---

## ✨ Why PlanktonSprite?

Most pixel apps are drawing tools.

PlanktonSprite is a **production tool**.

It focuses on:
- Animation workflow
- Precise frame control
- Engine-ready export
- Clean, fast mobile UX

No subscriptions. No accounts. Just pixels.

---

## 🎨 Canvas & Drawing

- Canvas sizes: **16×16, 32×32, 64×64**
- Pixel-perfect Pencil Tool
- Bresenham Line Tool
- Rectangle Tool (outline)
- Zoom: **0.5× – 4×**
- Grid toggle
- Saved custom palettes
- Undo / Redo (configurable limit)

---

## 🎬 Animation System

- Up to **24 frames**
- Drag & reorder timeline
- Per-frame duration (milliseconds)
- Loop toggle (once / infinite)
- Onion Skin (previous & next frame)
- Adjustable onion opacity
- Haptic feedback (iOS)

---

## 📦 Export

### GIF Export
- Transparent background support
- Per-frame duration respected
- Loop control applied

### Spritesheet Export
- Layouts:
  - Horizontal
  - Vertical
  - Grid
- Padding & pivot support
- PNG + JSON metadata

### Engine Presets
- Unity (pixelsPerUnit, filterMode)
- Godot (AtlasTexture, region)
- SpriteKit (normalized textureRect)
- Generic JSON format

Exports are designed for direct integration into game pipelines.

---

## 💾 Project System

- `.plankton` JSON-based project format
- `formatVersion` for future migrations
- Autosave support
- Atomic file writing
- Cross-platform (iPhone, iPad, macOS)

---

## 🧪 Testing

~80 unit tests covering:

- Variable canvas sizes
- Bresenham line algorithm
- Rectangle drawing
- Zoom scaling
- Onion skin logic
- Per-frame duration handling
- Spritesheet layouts
- Engine preset JSON output
- Palette persistence

---

## 🛠 Tech Stack

- Swift
- SwiftUI
- CoreGraphics
- ImageIO (GIF encoding)
- Codable-based project model
- MainActor UI state management

---

## 🎯 Target Audience

- Indie game developers
- Game jam creators
- Pixel artists building animated sprites
- Developers who want a mobile-first sprite workflow

---

## 🚀 Roadmap

- Performance optimizations (pixel storage backend)
- Additional engine presets
- Extended export formats
- Advanced animation features

---

## 📄 License

(Choose your license here — MIT recommended for open source.)

---

## 👤 Author

Built by Andreas Pelczer  
Focused on clean architecture and developer-first tools.

---

> Build sprites. Export to engine. Ship your game.
