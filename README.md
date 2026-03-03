# Daumenkino-GIF (ehem. PlanktonSprite)

Pixel-Sprite-Animator — zeichne Sprites auf einem variablen Canvas (16x16 bis 64x64), animiere Frame für Frame und exportiere als GIF oder Spritesheet mit Engine-Presets.

## Features

- **Variable Canvas-Groessen** — 16x16, 32x32, 64x64 (oder Custom bis 128x128)
- **5 Zeichenwerkzeuge** — Stift, Radierer, Fuellwerkzeug, Linie (Bresenham), Rechteck (Outline)
- **Multi-Frame Animation** — bis zu 24 Frames, einstellbare FPS (1-24), per-Frame Duration (ms)
- **Onion Skin** — vorheriges/naechstes Frame als Overlay mit konfigurierbarer Transparenz
- **Zoom** — 0.5x bis 4x fuer praezises Arbeiten
- **GIF-Export** — animiertes GIF mit Loop-Toggle, per-Frame Timing, transparentem Hintergrund
- **PNG-Spritesheet-Export** — Horizontal, Vertikal oder Grid-Layout mit konfigurierbarem Padding
- **Engine-Presets** — JSON-Meta fuer Unity (pivot/border/pixelsPerUnit), Godot (region/AtlasTexture), SpriteKit (textureRect), Generic
- **Saved Palettes** — eigene Farbpaletten speichern, laden, loeschen
- **Autosave** — automatisch alle 60s + bei Frame-Operationen + bei App-Background, 2-Slot Rotation in Application Support
- **Universal App** (iPad + macOS) — adaptives Layout, ein Codebase
- **Undo/Redo** — Stack-basiert mit bis zu 50 Schritten
- **Projektdateien** — eigenes .plankton-Format (JSON-basiert, versioniert)
- **Drag & Drop** — Frames per Drag umsortieren

## Tech Stack

Swift, SwiftUI, CoreGraphics, ImageIO, UniformTypeIdentifiers

## Architektur

MVVM mit EnvironmentObject-Injection:

- **CanvasViewModel** — Zeichentools, Undo/Redo, Zoom, Onion Skin
- **FrameViewModel** — Projekt-/Frame-Verwaltung, Save/Load, Autosave
- **ExportViewModel** — GIF/Spritesheet/JSON-Export mit Progress-Feedback
- **PaletteManager** — Saved Palettes mit UserDefaults-Persistenz

## Export-Formate

| Format | Beschreibung |
|--------|-------------|
| `.gif` | Animiertes GIF (Loop/No-Loop, per-Frame Duration, transparent BG) |
| `.png` | Spritesheet (Horizontal/Vertikal/Grid, konfigurierbares Padding) |
| `.json` | Meta-Daten mit Engine-spezifischen Feldern (formatVersion: 1) |
| `.plankton` | Projektdatei (JSON, alle Frames + Settings + Canvas-Daten) |

## Status

In Entwicklung — wird zu **Daumenkino-GIF** umbenannt.
