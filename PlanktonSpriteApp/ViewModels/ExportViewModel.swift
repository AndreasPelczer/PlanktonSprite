//
//  ExportViewModel.swift
//  PlanktonSpriteApp
//
//  Created by Andreas Pelczer on 27.02.26.
//

import SwiftUI
import ImageIO
import UniformTypeIdentifiers
#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

/// Zuständig für alle Export-Operationen:
/// Animiertes GIF und PNG-Spritesheet.
/// Stellt die Daten bereit, die der ShareSheet braucht.
class ExportViewModel: ObservableObject {

    // MARK: - Published State
    
    /// Ist gerade ein Export am Laufen?
    @Published var isExporting: Bool = false
    
    /// Soll das Share Sheet angezeigt werden?
    @Published var showShareSheet: Bool = false
    
    /// Die exportierte Datei als URL – wird dem ShareSheet übergeben
    @Published var exportedFileURL: URL?
    
    /// Fehlermeldung falls der Export schiefgeht
    @Published var errorMessage: String?
    
    // MARK: - Referenz
    
    private weak var frameViewModel: FrameViewModel?
    
    // MARK: - Init
    
    init() {}
    
    func connect(to frameViewModel: FrameViewModel) {
        self.frameViewModel = frameViewModel
    }
    
    // MARK: - GIF Export
    
    /// Erzeugt ein animiertes GIF aus allen Frames.
    /// Der Ablauf:
    /// 1. Jeden Frame in ein CGImage wandeln
    /// 2. Alle CGImages in eine GIF-Datei schreiben
    /// 3. URL ans ShareSheet übergeben
    func exportGIF() {
        guard let frameVM = frameViewModel else { return }

        isExporting = true
        errorMessage = nil

        // Capture frame data on main thread to avoid race condition
        let frames = frameVM.frames
        let fps = frameVM.project.fps
        let name = frameVM.project.name

        // Auf Background-Thread, damit die UI nicht einfriert
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                let url = try self.createGIF(
                    frames: frames,
                    fps: fps,
                    name: name
                )
                
                DispatchQueue.main.async {
                    self.exportedFileURL = url
                    self.showShareSheet = true
                    self.isExporting = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "GIF-Export fehlgeschlagen: \(error.localizedDescription)"
                    self.isExporting = false
                }
            }
        }
    }
    
    /// Baut die GIF-Datei zusammen.
    /// Verwendet ImageIO – Apples Low-Level Framework für Bildformate.
    private func createGIF(frames: [SpriteFrame], fps: Int, name: String) throws -> URL {
        // Temporäre Datei im Cache-Verzeichnis
        let fileName = "\(name)_animation.gif"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // GIF Destination erstellen
        // kUTTypeGIF sagt ImageIO: "Ich will eine GIF-Datei"
        guard let destination = CGImageDestinationCreateWithURL(
            fileURL as CFURL,
            UTType.gif.identifier as CFString,
            frames.count,
            nil
        ) else {
            throw ExportError.destinationCreationFailed
        }
        
        // Globale GIF-Eigenschaften: Endlosschleife
        let gifProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0  // 0 = unendlich
            ]
        ]
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)
        
        // Frame-Verzögerung aus FPS berechnen
        let delay = 1.0 / Double(fps)
        
        // Jeden Frame als Bild hinzufügen
        for frame in frames {
            guard let cgImage = renderFrameToCGImage(frame.canvas) else {
                throw ExportError.frameRenderFailed
            }
            
            // Pro-Frame Eigenschaften: wie lange wird dieser Frame angezeigt
            let frameProperties: [String: Any] = [
                kCGImagePropertyGIFDictionary as String: [
                    kCGImagePropertyGIFDelayTime as String: delay
                ]
            ]
            
            CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
        }
        
        // Datei finalisieren und schreiben
        guard CGImageDestinationFinalize(destination) else {
            throw ExportError.finalizationFailed
        }
        
        return fileURL
    }
    
    // MARK: - Spritesheet Export
    
    /// Erzeugt ein PNG-Spritesheet: alle Frames nebeneinander in einer Reihe.
    /// Perfekt für SpriteKit, Unity, oder jede andere Game Engine.
    func exportSpritesheet() {
        guard let frameVM = frameViewModel else { return }

        isExporting = true
        errorMessage = nil

        // Capture frame data on main thread to avoid race condition
        let frames = frameVM.frames
        let name = frameVM.project.name

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                let url = try self.createSpritesheet(
                    frames: frames,
                    name: name
                )
                
                DispatchQueue.main.async {
                    self.exportedFileURL = url
                    self.showShareSheet = true
                    self.isExporting = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Spritesheet-Export fehlgeschlagen: \(error.localizedDescription)"
                    self.isExporting = false
                }
            }
        }
    }
    
    /// Baut das Spritesheet: ein breites Bild mit allen Frames nebeneinander.
    private func createSpritesheet(frames: [SpriteFrame], name: String) throws -> URL {
        let size = PixelCanvas.gridSize
        let totalWidth = size * frames.count
        
        // Bitmap-Kontext erstellen: RGBA, 8 Bit pro Kanal
        guard let context = CGContext(
            data: nil,
            width: totalWidth,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: totalWidth * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ExportError.contextCreationFailed
        }
        
        // Hintergrund transparent lassen (ist default bei CGContext)
        
        // Jeden Frame an seine Position malen
        for (index, frame) in frames.enumerated() {
            let offsetX = index * size
            
            for y in 0..<size {
                for x in 0..<size {
                    if let color = frame.canvas.pixel(at: x, y: y),
                       let components = color.cgColorComponents {
                        context.setFillColor(red: components.r,
                                             green: components.g,
                                             blue: components.b,
                                             alpha: components.a)
                        // CGContext hat y=0 unten, wir wollen y=0 oben
                        context.fill(CGRect(x: offsetX + x, y: size - 1 - y, width: 1, height: 1))
                    }
                }
            }
        }
        
        guard let cgImage = context.makeImage() else {
            throw ExportError.imageCreationFailed
        }
        
        // Als PNG speichern
        let fileName = "\(name)_spritesheet.png"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        guard let pngData = cgImageToPNGData(cgImage) else {
            throw ExportError.pngEncodingFailed
        }
        
        try pngData.write(to: fileURL)
        
        return fileURL
    }
    
    // MARK: - Frame zu CGImage rendern
    
    /// Wandelt ein PixelCanvas in ein CGImage um.
    /// Jeder Pixel wird 1:1 übertragen – keine Skalierung.
    /// Das ergibt ein 32×32 Pixel Bild.
    private func renderFrameToCGImage(_ canvas: PixelCanvas) -> CGImage? {
        let size = PixelCanvas.gridSize
        
        guard let context = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        for y in 0..<size {
            for x in 0..<size {
                if let color = canvas.pixel(at: x, y: y),
                   let components = color.cgColorComponents {
                    context.setFillColor(red: components.r,
                                         green: components.g,
                                         blue: components.b,
                                         alpha: components.a)
                    context.fill(CGRect(x: x, y: size - 1 - y, width: 1, height: 1))
                }
            }
        }
        
        return context.makeImage()
    }
    
    // MARK: - PNG Konvertierung
    
    /// Wandelt ein CGImage in PNG-Daten um.
    /// Plattformunabhängig – funktioniert auf macOS und iOS.
    private func cgImageToPNGData(_ image: CGImage) -> Data? {
        #if canImport(UIKit)
        return UIImage(cgImage: image).pngData()
        #elseif canImport(AppKit)
        let rep = NSBitmapImageRep(cgImage: image)
        return rep.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }
    
    // MARK: - Aufräumen
    
    /// Löscht die temporäre Datei nach dem Teilen
    func cleanup() {
        if let url = exportedFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        exportedFileURL = nil
        showShareSheet = false
        errorMessage = nil
    }
}

// MARK: - Fehlertypen

/// Eigene Error-Typen für aussagekräftige Fehlermeldungen
enum ExportError: LocalizedError {
    case destinationCreationFailed
    case frameRenderFailed
    case finalizationFailed
    case contextCreationFailed
    case imageCreationFailed
    case pngEncodingFailed
    
    var errorDescription: String? {
        switch self {
        case .destinationCreationFailed: return "GIF-Datei konnte nicht erstellt werden"
        case .frameRenderFailed:         return "Frame konnte nicht gerendert werden"
        case .finalizationFailed:        return "GIF konnte nicht gespeichert werden"
        case .contextCreationFailed:     return "Grafik-Kontext konnte nicht erstellt werden"
        case .imageCreationFailed:       return "Bild konnte nicht erzeugt werden"
        case .pngEncodingFailed:         return "PNG-Kodierung fehlgeschlagen"
        }
    }
}

// MARK: - Color Extension

/// Hilfsfunktion um SwiftUI Color in CGColor-Komponenten zu zerlegen.
/// Auf macOS geht das über NSColor.
extension Color {
    
    /// Extrahiert RGBA-Werte aus einer SwiftUI Color.
    /// Konvertiert erst in den sRGB-Farbraum, damit die Werte
    /// konsistent sind – macOS arbeitet intern mit verschiedenen
    /// Farbräumen (Display P3, Generic RGB, etc.).
    var cgColorComponents: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)? {
        #if canImport(UIKit)
        let color = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard color.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return (r, g, b, a)
        #elseif canImport(AppKit)
        // NSColor muss erst in sRGB konvertiert werden,
        // sonst crasht getRed() bei manchen Farbräumen
        guard let color = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
        #else
        return nil
        #endif
    }
}
