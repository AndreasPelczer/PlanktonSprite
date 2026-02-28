//
//  PlanktonSpriteApp.swift
//  PlanktonSpriteApp
//
//  Created by Andreas Pelczer on 27.02.26.
//


import SwiftUI
import UniformTypeIdentifiers
#if canImport(AppKit)
import AppKit
#endif

/// Entry Point der App.
/// Hier werden alle ViewModels erzeugt und miteinander verbunden.
/// Enthält die macOS-Menüleiste (Datei/Bearbeiten/Bild).
@main
struct PlanktonSpriteApp: App {

    // MARK: - ViewModels

    /// Die drei ViewModels als @StateObject – sie leben so lange wie die App.
    @StateObject private var frameVM = FrameViewModel()
    @StateObject private var canvasVM = CanvasViewModel()
    @StateObject private var exportVM = ExportViewModel()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(frameVM)
                .environmentObject(canvasVM)
                .environmentObject(exportVM)
                .onAppear {
                    canvasVM.connect(to: frameVM)
                    exportVM.connect(to: frameVM)
                }
        }
        .commands {
            // MARK: - Datei-Menü

            CommandGroup(replacing: .newItem) {
                Button("Neues Projekt") {
                    frameVM.newProject()
                    canvasVM.resetUndoHistory()
                }
                .keyboardShortcut("n")

                Button("Öffnen…") {
                    openFile()
                }
                .keyboardShortcut("o")

                Divider()

                Button("Speichern") {
                    saveFile()
                }
                .keyboardShortcut("s")

                Button("Speichern unter…") {
                    saveFileAs()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Divider()

                Button("GIF exportieren…") {
                    exportVM.exportGIF()
                }
                .disabled(exportVM.isExporting)

                Button("PNG Spritesheet exportieren…") {
                    exportVM.exportSpritesheet()
                }
                .disabled(exportVM.isExporting)
            }

            // MARK: - Bearbeiten-Menü (Undo/Redo)

            CommandGroup(replacing: .undoRedo) {
                Button("Rückgängig") {
                    canvasVM.undo()
                }
                .keyboardShortcut("z")
                .disabled(!canvasVM.canUndo)

                Button("Wiederherstellen") {
                    canvasVM.redo()
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(!canvasVM.canRedo)
            }

            // MARK: - Bild-Menü

            CommandMenu("Bild") {
                Button("Neuer Frame") {
                    frameVM.addFrame()
                }
                .keyboardShortcut("f", modifiers: [.command])
                .disabled(!frameVM.canAddFrame)

                Button("Frame kopieren") {
                    frameVM.duplicateActiveFrame()
                }
                .keyboardShortcut("d", modifiers: [.command])
                .disabled(!frameVM.canAddFrame)

                Button("Frame löschen") {
                    frameVM.deleteActiveFrame()
                }
                .keyboardShortcut(.delete, modifiers: [.command])
                .disabled(frameVM.frameCount <= 1)

                Divider()

                Button("Canvas leeren") {
                    canvasVM.clearCanvas()
                }
                .keyboardShortcut(.delete, modifiers: [.command, .shift])
            }
        }
    }

    // MARK: - Datei-Dialoge

    /// Speichern: wenn schon ein Pfad bekannt ist, direkt überschreiben.
    /// Sonst "Speichern unter" aufrufen.
    private func saveFile() {
        if let url = frameVM.currentFileURL {
            do {
                try frameVM.saveProject(to: url)
            } catch {
                print("Speichern fehlgeschlagen: \(error.localizedDescription)")
            }
        } else {
            saveFileAs()
        }
    }

    /// Speichern unter: NSSavePanel anzeigen
    private func saveFileAs() {
        #if os(macOS)
        let panel = NSSavePanel()
        panel.title = "Projekt speichern"
        panel.nameFieldStringValue = "\(frameVM.project.name).plankton"
        panel.allowedContentTypes = [
            UTType(filenameExtension: "plankton") ?? .json
        ]
        // runModal() statt begin() – zuverlässiger aus SwiftUI commands
        let response = panel.runModal()
        if response == .OK, let url = panel.url {
            do {
                try frameVM.saveProject(to: url)
            } catch {
                print("Speichern fehlgeschlagen: \(error.localizedDescription)")
            }
        }
        #endif
    }

    /// Öffnen: NSOpenPanel anzeigen
    private func openFile() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.title = "Projekt öffnen"
        panel.allowedContentTypes = [
            UTType(filenameExtension: "plankton") ?? .json
        ]
        panel.allowsMultipleSelection = false
        // runModal() statt begin() – zuverlässiger aus SwiftUI commands
        let response = panel.runModal()
        if response == .OK, let url = panel.url {
            do {
                try frameVM.loadProject(from: url)
                canvasVM.resetUndoHistory()
            } catch {
                print("Öffnen fehlgeschlagen: \(error.localizedDescription)")
            }
        }
        #endif
    }
}
