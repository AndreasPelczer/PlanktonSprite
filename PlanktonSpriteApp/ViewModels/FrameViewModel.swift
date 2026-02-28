//
//  FrameViewModel.swift
//  PlanktonSpriteApp
//
//  Created by Andreas Pelczer on 27.02.26.
//


import SwiftUI
import Combine

/// Verwaltet alle Frames des Projekts.
/// Zuständig für: aktiver Frame, hinzufügen, löschen,
/// duplizieren, umsortieren.
class FrameViewModel: ObservableObject {

    // MARK: - Published State
    
    /// Das komplette Animationsprojekt mit allen Frames
    @Published var project: AnimationProject
    
    /// Index des aktuell bearbeiteten Frames
    @Published var activeFrameIndex: Int = 0

    /// Pfad der aktuell geöffneten Datei (nil = noch nicht gespeichert)
    @Published var currentFileURL: URL?
    
    // MARK: - Limits
    
    /// Maximale Anzahl erlaubter Frames
    let maxFrames = 24
    
    // MARK: - Init
    
    init() {
        self.project = AnimationProject()
    }
    
    // MARK: - Computed Properties
    
    /// Alle Frames – Convenience für die View
    var frames: [SpriteFrame] {
        project.frames
    }
    
    /// Anzahl der Frames
    var frameCount: Int {
        project.frameCount
    }
    
    /// Kann noch ein Frame hinzugefügt werden?
    var canAddFrame: Bool {
        frameCount < maxFrames
    }
    
    /// Das Canvas des aktiven Frames.
    /// Wird vom CanvasViewModel gelesen und geschrieben.
    var activeCanvas: PixelCanvas {
        project.frame(at: activeFrameIndex)?.canvas ?? PixelCanvas()
    }
    
    /// Der aktive Frame selbst
    var activeFrame: SpriteFrame? {
        project.frame(at: activeFrameIndex)
    }
    
    // MARK: - Canvas aktualisieren
    
    /// Schreibt ein verändertes Canvas zurück in den aktiven Frame.
    /// Das ist die Brücke zwischen CanvasViewModel und dem Projekt.
    func updateActiveCanvas(_ canvas: PixelCanvas) {
        guard project.isValidIndex(activeFrameIndex) else { return }
        project.frames[activeFrameIndex].canvas = canvas
    }
    
    // MARK: - Frame-Operationen
    
    /// Fügt einen leeren Frame nach dem aktiven ein
    /// und wechselt sofort dorthin.
    func addFrame() {
        guard canAddFrame else { return }
        let newIndex = project.insertFrame(after: activeFrameIndex)
        activeFrameIndex = newIndex
    }
    
    /// Dupliziert den aktiven Frame.
    /// Die Kopie wird zum neuen aktiven Frame.
    func duplicateActiveFrame() {
        guard canAddFrame else { return }
        if let newIndex = project.duplicateFrame(at: activeFrameIndex) {
            activeFrameIndex = newIndex
        }
    }
    
    /// Löscht einen Frame am angegebenen Index.
    /// Passt den aktiven Index an, damit er gültig bleibt.
    func deleteFrame(at index: Int) {
        // Merken ob wir den aktiven oder einen davor löschen
        let wasActive = index == activeFrameIndex
        let wasBefore = index < activeFrameIndex
        
        guard project.deleteFrame(at: index) else { return }
        
        if wasBefore {
            // Frame vor dem aktiven gelöscht → Index rutscht eins runter
            activeFrameIndex -= 1
        } else if wasActive {
            // Aktiver Frame gelöscht → auf gültigen Bereich klemmen
            activeFrameIndex = min(activeFrameIndex, frameCount - 1)
        }
        // Frame nach dem aktiven gelöscht → aktiver Index bleibt
    }
    
    /// Löscht den aktuell aktiven Frame
    func deleteActiveFrame() {
        deleteFrame(at: activeFrameIndex)
    }
    
    // MARK: - Umsortieren (Drag & Drop)
    
    /// Verschiebt einen Frame von einer Position zur anderen.
    /// Passt den aktiven Index mit an, damit der gleiche Frame
    /// aktiv bleibt – nicht der gleiche INDEX.
    func moveFrame(from source: Int, to destination: Int) {
        guard project.isValidIndex(source) else { return }
        
        // Merken welcher Frame aktiv ist (nicht welcher Index)
        let activeID = activeFrame?.id
        
        project.moveFrame(from: source, to: destination)
        
        // Aktiven Frame wiederfinden nach dem Verschieben
        if let activeID,
           let newIndex = project.frames.firstIndex(where: { $0.id == activeID }) {
            activeFrameIndex = newIndex
        }
    }
    
    /// SwiftUI-kompatible Move-Funktion für .onMove Modifier.
    /// Bekommt ein IndexSet (kann theoretisch mehrere Indizes enthalten,
    /// in der Praxis ist es bei Drag & Drop immer genau einer).
    func moveFrames(from source: IndexSet, to destination: Int) {
        guard let sourceIndex = source.first else { return }
        
        // SwiftUI's destination-Index ist "vor welchem Element einfügen".
        // Wenn wir nach hinten verschieben, müssen wir 1 abziehen,
        // weil das entfernte Element die Indizes verschiebt.
        let adjustedDest = sourceIndex < destination ? destination - 1 : destination
        
        moveFrame(from: sourceIndex, to: adjustedDest)
    }
    
    // MARK: - Projekt: Neu / Speichern / Laden

    /// Erstellt ein neues leeres Projekt
    func newProject() {
        project = AnimationProject()
        activeFrameIndex = 0
        currentFileURL = nil
    }

    /// Speichert das Projekt als .plankton JSON-Datei
    func saveProject(to url: URL) throws {
        // Security-scoped Access für iOS Sandbox
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer { if didStartAccess { url.stopAccessingSecurityScopedResource() } }

        let file = ProjectFile(from: project)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(file)
        try data.write(to: url)
        currentFileURL = url
        // Projektname aus Dateiname übernehmen
        project.name = url.deletingPathExtension().lastPathComponent
    }

    /// Lädt ein Projekt aus einer .plankton Datei
    func loadProject(from url: URL) throws {
        // Security-scoped Access für iOS Sandbox
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer { if didStartAccess { url.stopAccessingSecurityScopedResource() } }

        let data = try Data(contentsOf: url)
        let file = try JSONDecoder().decode(ProjectFile.self, from: data)
        project = file.toProject()
        activeFrameIndex = 0
        currentFileURL = url
    }

    // MARK: - Navigation
    
    /// Wechselt zum nächsten Frame (mit Wraparound)
    func nextFrame() {
        activeFrameIndex = (activeFrameIndex + 1) % frameCount
    }
    
    /// Wechselt zum vorherigen Frame (mit Wraparound)
    func previousFrame() {
        activeFrameIndex = (activeFrameIndex - 1 + frameCount) % frameCount
    }
    
    /// Wechselt zu einem bestimmten Frame
    func selectFrame(at index: Int) {
        guard project.isValidIndex(index) else { return }
        activeFrameIndex = index
    }
}

