//
//  SpriteFrame.swift
//  PlanktonSpriteApp
//
//  Created by Andreas Pelczer on 27.02.26.
//


import SwiftUI

/// Ein einzelner Frame in der Animation.
/// Jeder Frame hat eine eigene Identität (für SwiftUI-Listen und Drag & Drop)
/// und trägt sein eigenes PixelCanvas.
struct SpriteFrame: Identifiable {
    
    // MARK: - Identität
    
    /// Eindeutige ID – wird automatisch erzeugt.
    /// Wichtig für ForEach, onMove, onDelete in SwiftUI.
    let id: UUID
    
    // MARK: - Daten
    
    /// Das Pixel-Raster dieses Frames
    var canvas: PixelCanvas
    
    // MARK: - Init
    
    /// Erzeugt einen neuen leeren Frame
    init() {
        self.id = UUID()
        self.canvas = PixelCanvas()
    }
    
    /// Erzeugt einen Frame mit bestehendem Canvas.
    /// Nützlich beim Duplizieren: du kopierst das Canvas,
    /// aber der Frame bekommt eine NEUE id.
    init(canvas: PixelCanvas) {
        self.id = UUID()
        self.canvas = canvas
    }
}
import UniformTypeIdentifiers

// MARK: - Drag & Drop Support

/// Eigener UTType für unsere Frames.
/// Das System braucht einen eindeutigen Typ-Identifier
/// um zu wissen, was gezogen wird.
extension UTType {
    static let spriteFrame = UTType(
        exportedAs: "com.planktonsprite.frame"
    )
}

/// Transferable macht SpriteFrame Drag & Drop-fähig.
/// Wir übertragen nur die ID als String –
/// die eigentlichen Pixeldaten bleiben im Array.
extension SpriteFrame: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .spriteFrame)
    }
}

/// Codable-Konformität – wird nur für den Transfer gebraucht.
/// Wir kodieren nur die ID, nicht die Pixel.
/// Die Pixel bewegen sich nirgendwohin – wir sortieren
/// nur die Reihenfolge im Array um.
extension SpriteFrame: Codable {
    enum CodingKeys: String, CodingKey {
        case id
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.canvas = PixelCanvas()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
    }
}

