//
//  PixelCanvas.swift
//  PlanktonSpriteApp
//
//  Created by Andreas Pelczer on 27.02.26.
//


import SwiftUI

/// Ein 32×32 Pixel-Raster.
/// Jeder Pixel ist entweder eine Farbe oder nil (transparent).
struct PixelCanvas {
    
    // MARK: - Konstante
    
    /// Rastergröße – bei uns immer 32×32
    static let gridSize = 32
    
    // MARK: - Daten
    
    /// 2D-Array: pixels[y][x] – Zeile zuerst, dann Spalte.
    /// nil bedeutet: dieser Pixel ist transparent.
    var pixels: [[Color?]]
    
    // MARK: - Init
    
    /// Erzeugt ein leeres Canvas – alle Pixel transparent
    init() {
        pixels = Array(
            repeating: Array(repeating: nil as Color?, count: Self.gridSize),
            count: Self.gridSize
        )
    }
    
    // MARK: - Zugriff
    
    /// Sicherer Zugriff auf einen Pixel.
    /// Gibt nil zurück wenn x/y außerhalb des Rasters liegen.
    func pixel(at x: Int, y: Int) -> Color? {
        guard isValid(x: x, y: y) else { return nil }
        return pixels[y][x]
    }
    
    /// Setzt einen Pixel auf eine Farbe (oder nil zum Löschen).
    /// Ignoriert ungültige Koordinaten still – kein Crash.
    mutating func setPixel(at x: Int, y: Int, color: Color?) {
        guard isValid(x: x, y: y) else { return }
        pixels[y][x] = color
    }
    
    /// Löscht das komplette Canvas – alles wieder transparent
    mutating func clear() {
        pixels = Array(
            repeating: Array(repeating: nil as Color?, count: Self.gridSize),
            count: Self.gridSize
        )
    }
    
    // MARK: - Validierung
    
    /// Prüft ob Koordinaten innerhalb des 32×32 Rasters liegen
    func isValid(x: Int, y: Int) -> Bool {
        x >= 0 && x < Self.gridSize && y >= 0 && y < Self.gridSize
    }
}