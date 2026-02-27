//
//  CanvasViewModel.swift
//  PlanktonSpriteApp
//
//  Created by Andreas Pelczer on 27.02.26.
//


import SwiftUI

/// Steuert alles rund ums Zeichnen auf dem Canvas.
/// Die View bindet sich an die @Published Properties,
/// das ViewModel ruft Operationen auf dem Model auf.
class CanvasViewModel: ObservableObject {

    // MARK: - Werkzeuge
    
    /// Die drei verfügbaren Zeichenwerkzeuge
    enum Tool: String, CaseIterable {
        case pen = "Stift"
        case eraser = "Radierer"
        case fill = "Füllen"
        
        /// SF Symbol Name für die Toolbar-Icons
        var iconName: String {
            switch self {
            case .pen:    return "pencil"
            case .eraser: return "eraser"
            case .fill:   return "drop.fill"
            }
        }
    }
    
    // MARK: - Published State
    
    /// Aktuell gewähltes Werkzeug
    @Published var currentTool: Tool = .pen
    
    /// Aktuell gewählte Zeichenfarbe
    @Published var currentColor: Color = .cyan
    
    /// Rasterlinien anzeigen ja/nein
    @Published var showGrid: Bool = true
    
    /// Undo-Stack: speichert vorherige Canvas-Zustände
    @Published private(set) var canUndo: Bool = false
    
    /// Redo-Stack: speichert rückgängig gemachte Zustände
    @Published private(set) var canRedo: Bool = false
    
    // MARK: - Undo/Redo Stacks
    
    /// Vorherige Zustände – maximal 20, damit der Speicher nicht explodiert
    private var undoStack: [PixelCanvas] = []
    
    /// Rückgängig gemachte Zustände
    private var redoStack: [PixelCanvas] = []
    
    /// Maximale Anzahl gespeicherter Undo-Schritte
    private let maxUndoSteps = 20
    
    // MARK: - Referenz zum Projekt
    
    /// Das FrameViewModel besitzt das Projekt.
    /// Wir bekommen eine Referenz, um den aktiven Frame zu bearbeiten.
    private weak var frameViewModel: FrameViewModel?
    
    // MARK: - Init
    
    init() {}
    
    /// Verbindet dieses ViewModel mit dem FrameViewModel.
    /// Wird einmal beim App-Start aufgerufen.
    func connect(to frameViewModel: FrameViewModel) {
        self.frameViewModel = frameViewModel
    }
    
    // MARK: - Aktuelles Canvas
    
    /// Holt das Canvas des aktuell aktiven Frames.
    /// Convenience-Zugriff, damit wir nicht jedes Mal
    /// durch frameViewModel navigieren müssen.
    var currentCanvas: PixelCanvas {
        frameViewModel?.activeCanvas ?? PixelCanvas()
    }
    
    // MARK: - Zeichenoperationen
    
    /// Wird aufgerufen wenn der Finger/Stift das Canvas BERÜHRT.
    /// Speichert den Zustand für Undo, dann malt den ersten Pixel.
    func beginStroke(at x: Int, y: Int) {
        saveUndoState()
        applyTool(at: x, y: y)
    }
    
    /// Wird aufgerufen wenn der Finger/Stift sich BEWEGT.
    /// Malt weitere Pixel ohne neuen Undo-Zustand.
    func continueStroke(at x: Int, y: Int) {
        applyTool(at: x, y: y)
    }
    
    /// Wendet das aktuelle Werkzeug auf die Koordinate an.
    private func applyTool(at x: Int, y: Int) {
        guard var canvas = frameViewModel?.activeCanvas else { return }
        
        switch currentTool {
        case .pen:
            canvas.setPixel(at: x, y: y, color: currentColor)
            
        case .eraser:
            canvas.setPixel(at: x, y: y, color: nil)
            
        case .fill:
            floodFill(canvas: &canvas, x: x, y: y, newColor: currentColor)
        }
        
        frameViewModel?.updateActiveCanvas(canvas)
    }
    
    // MARK: - Flood Fill
    
    /// Füllt zusammenhängende Pixel gleicher Farbe.
    /// Klassischer Stack-basierter Algorithmus, keine Rekursion
    /// (Rekursion würde bei 32×32 = 1024 Pixeln den Stack sprengen können).
    private func floodFill(canvas: inout PixelCanvas, x: Int, y: Int, newColor: Color) {
        let targetColor = canvas.pixel(at: x, y: y)
        
        // Wenn Zielfarbe = neue Farbe → nichts zu tun
        if targetColor == newColor { return }
        
        // Stack statt Rekursion
        var stack: [(Int, Int)] = [(x, y)]
        
        while let (cx, cy) = stack.popLast() {
            // Grenzen prüfen
            guard canvas.isValid(x: cx, y: cy) else { continue }
            
            // Nur Pixel mit der Zielfarbe füllen
            guard canvas.pixel(at: cx, y: cy) == targetColor else { continue }
            
            // Pixel setzen
            canvas.setPixel(at: cx, y: cy, color: newColor)
            
            // Nachbarn auf den Stack
            stack.append((cx + 1, cy))
            stack.append((cx - 1, cy))
            stack.append((cx, cy + 1))
            stack.append((cx, cy - 1))
        }
    }
    
    // MARK: - Undo / Redo
    
    /// Speichert den aktuellen Canvas-Zustand auf den Undo-Stack.
    /// Wird VOR jeder Zeichenoperation aufgerufen.
    private func saveUndoState() {
        let current = currentCanvas
        undoStack.append(current)
        
        // Stack begrenzen
        if undoStack.count > maxUndoSteps {
            undoStack.removeFirst()
        }
        
        // Redo-Stack leeren – nach einer neuen Aktion
        // gibt es keinen "Zukunftsstrang" mehr
        redoStack.removeAll()
        
        updateUndoRedoState()
    }
    
    /// Macht die letzte Aktion rückgängig
    func undo() {
        guard let previous = undoStack.popLast() else { return }
        
        // Aktuellen Zustand auf Redo-Stack schieben
        redoStack.append(currentCanvas)
        
        // Vorherigen Zustand wiederherstellen
        frameViewModel?.updateActiveCanvas(previous)
        
        updateUndoRedoState()
    }
    
    /// Stellt die letzte rückgängig gemachte Aktion wieder her
    func redo() {
        guard let next = redoStack.popLast() else { return }
        
        // Aktuellen Zustand auf Undo-Stack schieben
        undoStack.append(currentCanvas)
        
        // Nächsten Zustand wiederherstellen
        frameViewModel?.updateActiveCanvas(next)
        
        updateUndoRedoState()
    }
    
    /// Aktualisiert die Published Booleans für die UI
    private func updateUndoRedoState() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }
    
    // MARK: - Canvas leeren
    
    /// Löscht alle Pixel des aktiven Frames
    func clearCanvas() {
        saveUndoState()
        var canvas = currentCanvas
        canvas.clear()
        frameViewModel?.updateActiveCanvas(canvas)
    }
}

