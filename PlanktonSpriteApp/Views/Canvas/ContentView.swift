//
//  ContentView.swift
//  PlanktonSpriteApp
//
//  Created by Andreas Pelczer on 27.02.26.
//

import SwiftUI

/// Root View der App.
/// Dreispaltiges Layout: Links Canvas mit Tools,
/// Rechts Frames und Preview.
struct ContentView: View {
    
    @EnvironmentObject var frameVM: FrameViewModel
    @EnvironmentObject var canvasVM: CanvasViewModel
    @EnvironmentObject var exportVM: ExportViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            
            // MARK: - Linke Seite: Canvas-Bereich
            
            VStack(spacing: 12) {
                // Toolbar: Werkzeuge, Undo/Redo, Grid
                ToolBarView()
                
                // Das 32×32 Pixel-Canvas
                PixelCanvasView()
                
                // Farbpalette
                ColorPaletteView()
            }
            .padding(16)
            
            // Trennlinie
            Rectangle()
                .fill(.quaternary)
                .frame(width: 1)
            
            // MARK: - Rechte Seite: Frames + Preview
            
            VStack(spacing: 0) {
                // Obere Hälfte: Frame-Thumbnails
                // (Platzhalter bis FrameStripView fertig ist)
                VStack(spacing: 10) {
                    sectionHeader("FRAMES", count: frameVM.frameCount)
                    
                    HStack(spacing: 6) {
                        Button("+ Neu") { frameVM.addFrame() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(!frameVM.canAddFrame)
                        
                        Button("⧉ Kopie") { frameVM.duplicateActiveFrame() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(!frameVM.canAddFrame)
                    }
                    
                    // Einfache Frame-Liste
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(frameVM.frames.enumerated()), id: \.element.id) { index, frame in
                                frameThumb(index: index, frame: frame)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    
                    Spacer()
                }
                .padding(12)
                
                Rectangle()
                    .fill(.quaternary)
                    .frame(height: 1)
                
                // Untere Hälfte: Animation Preview
                // (Platzhalter bis AnimationPreviewView fertig ist)
                VStack(spacing: 10) {
                    sectionHeader("VORSCHAU", fps: frameVM.project.fps)
                    
                    // FPS Slider
                    HStack(spacing: 8) {
                        Text("1")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.tertiary)
                        
                        Slider(
                            value: Binding(
                                get: { Double(frameVM.project.fps) },
                                set: { frameVM.project.fps = Int($0) }
                            ),
                            in: 1...24,
                            step: 1
                        )
                        .controlSize(.small)
                        
                        Text("24")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                    
                    // Preview-Fläche (einfache Frame-Anzeige)
                    previewCanvas
                    
                    Spacer()
                    
                    // Export-Buttons
                    HStack(spacing: 8) {
                        Button {
                            exportVM.exportGIF()
                        } label: {
                            Label("GIF", systemImage: "square.and.arrow.up")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.pink)
                        .disabled(exportVM.isExporting)
                        
                        Button {
                            exportVM.exportSpritesheet()
                        } label: {
                            Label("PNG", systemImage: "rectangle.split.3x1")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(exportVM.isExporting)
                    }
                }
                .padding(12)
            }
            .frame(width: 240)
            .background(.background.opacity(0.5))
        }
        .frame(minWidth: 750, minHeight: 580)
        .background(Color(red: 0.1, green: 0.1, blue: 0.14))
        .preferredColorScheme(.dark)
        // Keyboard Shortcuts
        .keyboardShortcut("z", modifiers: .command, action: canvasVM.undo)
        .keyboardShortcut("z", modifiers: [.command, .shift], action: canvasVM.redo)
    }
    
    // MARK: - Subviews
    
    /// Section Header mit Label
    private func sectionHeader(_ title: String, count: Int? = nil, fps: Int? = nil) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            if let count {
                Text("\(count)/\(frameVM.maxFrames)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            
            if let fps {
                Text("\(fps) FPS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.pink)
            }
        }
    }
    
    /// Einzelnes Frame-Thumbnail mit Drag & Drop
    private func frameThumb(index: Int, frame: SpriteFrame) -> some View {
        let isActive = index == frameVM.activeFrameIndex
        
        return VStack(spacing: 2) {
            // Mini-Canvas: 64×64 Punkte
            Canvas { context, size in
                let cellSize = size.width / CGFloat(PixelCanvas.gridSize)
                
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(Color(red: 0.12, green: 0.12, blue: 0.16))
                )
                
                for y in 0..<PixelCanvas.gridSize {
                    for x in 0..<PixelCanvas.gridSize {
                        if let color = frame.canvas.pixel(at: x, y: y) {
                            let rect = CGRect(
                                x: CGFloat(x) * cellSize,
                                y: CGFloat(y) * cellSize,
                                width: cellSize,
                                height: cellSize
                            )
                            context.fill(Path(rect), with: .color(color))
                        }
                    }
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isActive ? .pink : .white.opacity(0.1), lineWidth: isActive ? 2 : 1)
            )
            
            // Frame-Nummer
            Text("\(index + 1)")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(isActive ? .pink : .secondary)
        }
        .onTapGesture {
            frameVM.selectFrame(at: index)
        }
        // MARK: Drag & Drop
        .draggable(frame) {
            // Drag Preview: was du siehst während du ziehst
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.pink.opacity(0.3))
                .frame(width: 64, height: 64)
                .overlay(
                    Text("\(index + 1)")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(.pink)
                )
        }
        .dropDestination(for: SpriteFrame.self) { droppedFrames, _ in
            guard let dropped = droppedFrames.first,
                  let sourceIndex = frameVM.frames.firstIndex(where: { $0.id == dropped.id })
            else { return false }
            
            // Nicht auf sich selbst droppen
            if sourceIndex == index { return false }
            
            withAnimation(.easeInOut(duration: 0.25)) {
                frameVM.moveFrame(from: sourceIndex, to: index)
            }
            return true
        } isTargeted: { isTargeted in
            // Hier könntest du später einen visuellen
            // Drop-Indikator einbauen
        }
    }
    
    /// Einfache animierte Vorschau.
    /// Wechselt per Timer durch alle Frames.
    private var previewCanvas: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / Double(frameVM.project.fps))) { timeline in
            let frameIndex = animationFrameIndex(for: timeline.date)
            let grid = frameVM.project.frame(at: frameIndex)?.canvas ?? PixelCanvas()
            
            Canvas { context, size in
                let cellSize = size.width / CGFloat(PixelCanvas.gridSize)
                
                // Dunkler Hintergrund
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(Color(red: 0.05, green: 0.05, blue: 0.08))
                )
                
                // Pixel
                for y in 0..<PixelCanvas.gridSize {
                    for x in 0..<PixelCanvas.gridSize {
                        if let color = grid.pixel(at: x, y: y) {
                            let rect = CGRect(
                                x: CGFloat(x) * cellSize,
                                y: CGFloat(y) * cellSize,
                                width: cellSize,
                                height: cellSize
                            )
                            context.fill(Path(rect), with: .color(color))
                        }
                    }
                }
            }
            .frame(width: 128, height: 128)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    /// Berechnet welcher Frame gerade angezeigt werden soll.
    /// Basiert auf der aktuellen Zeit und FPS.
    private func animationFrameIndex(for date: Date) -> Int {
        guard frameVM.frameCount > 0 else { return 0 }
        let elapsed = date.timeIntervalSinceReferenceDate
        let fps = Double(frameVM.project.fps)
        let totalFrames = frameVM.frameCount
        return Int(elapsed * fps) % totalFrames
    }
}

// MARK: - Keyboard Shortcut Extension

/// Ermöglicht .keyboardShortcut() direkt mit einer Action-Closure.
/// SwiftUI hat das nicht eingebaut – wir bauen es uns.
extension View {
    func keyboardShortcut(
        _ key: KeyEquivalent,
        modifiers: EventModifiers,
        action: @escaping () -> Void
    ) -> some View {
        self.background(
            Button("", action: action)
                .keyboardShortcut(key, modifiers: modifiers)
                .hidden()
        )
    }
}
