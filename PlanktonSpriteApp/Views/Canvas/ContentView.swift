//
//  ContentView.swift
//  PlanktonSpriteApp
//
//  Created by Andreas Pelczer on 27.02.26.
//

import SwiftUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

/// Root View der App.
/// Oben: Frame-Leiste mit Neu/Kopieren/Löschen.
/// Unten: Links Canvas mit Tools, Rechts Preview.
struct ContentView: View {

    @EnvironmentObject var frameVM: FrameViewModel
    @EnvironmentObject var canvasVM: CanvasViewModel
    @EnvironmentObject var exportVM: ExportViewModel

    /// Steuert ob der "Speichern unter"-Dialog angezeigt wird (iPad)
    @State private var showSaveDialog = false
    /// Steuert ob der "Öffnen"-Dialog angezeigt wird (iPad)
    @State private var showOpenDialog = false
    /// Das Dokument das gespeichert werden soll
    @State private var documentToSave: PlanktonDocument?

    var body: some View {
        mainContent
        #if os(macOS)
        .frame(minWidth: 750, minHeight: 580)
        #endif
        .background(Color(red: 0.1, green: 0.1, blue: 0.14))
        .preferredColorScheme(.dark)
        // Keyboard Shortcuts
        .keyboardShortcut("z", modifiers: .command, action: canvasVM.undo)
        .keyboardShortcut("z", modifiers: [.command, .shift], action: canvasVM.redo)
        // MARK: - Share Sheet (Export)
        .sheet(isPresented: $exportVM.showShareSheet) {
            exportVM.cleanup()
        } content: {
            if let url = exportVM.exportedFileURL {
                #if os(iOS)
                ShareSheetView(activityItems: [url])
                #else
                VStack(spacing: 16) {
                    Text("Exportiert!")
                        .font(.headline)
                    Text(url.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("OK") { exportVM.cleanup() }
                        .buttonStyle(.borderedProminent)
                }
                .padding(40)
                #endif
            }
        }
    }

    /// Der Hauptinhalt – wird auf iPad in NavigationStack gewrappt
    @ViewBuilder
    private var mainContent: some View {
        #if os(iOS)
        NavigationStack {
            innerContent
                .toolbar {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        Button {
                            frameVM.newProject()
                            canvasVM.resetUndoHistory()
                        } label: {
                            Label("Neu", systemImage: "doc.badge.plus")
                        }

                        Button {
                            showOpenDialog = true
                        } label: {
                            Label("Öffnen", systemImage: "folder")
                        }

                        Button {
                            saveFile()
                        } label: {
                            Label("Speichern", systemImage: "square.and.arrow.down")
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .fileExporter(
                    isPresented: $showSaveDialog,
                    document: documentToSave,
                    contentType: UTType(filenameExtension: "plankton") ?? .json,
                    defaultFilename: "\(frameVM.project.name).plankton"
                ) { result in
                    if case .success(let url) = result {
                        frameVM.currentFileURL = url
                        frameVM.project.name = url.deletingPathExtension().lastPathComponent
                    }
                }
                .fileImporter(
                    isPresented: $showOpenDialog,
                    allowedContentTypes: [UTType(filenameExtension: "plankton") ?? .json],
                    allowsMultipleSelection: false
                ) { result in
                    if case .success(let urls) = result, let url = urls.first {
                        try? frameVM.loadProject(from: url)
                        canvasVM.resetUndoHistory()
                    }
                }
        }
        #else
        innerContent
        #endif
    }

    private var innerContent: some View {
        VStack(spacing: 0) {

            // MARK: - Oben: Frame-Leiste

            VStack(spacing: 8) {
                HStack {
                    sectionHeader("FRAMES", count: frameVM.frameCount)

                    Spacer()

                    HStack(spacing: 6) {
                        Button {
                            frameVM.addFrame()
                        } label: {
                            Label("Neu", systemImage: "plus")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(!frameVM.canAddFrame)

                        Button {
                            frameVM.duplicateActiveFrame()
                        } label: {
                            Label("Kopieren", systemImage: "doc.on.doc")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(!frameVM.canAddFrame)

                        Button {
                            frameVM.deleteActiveFrame()
                        } label: {
                            Label("Löschen", systemImage: "trash")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.red)
                        .disabled(frameVM.frameCount <= 1)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(frameVM.frames.enumerated()), id: \.element.id) { index, frame in
                            frameThumb(index: index, frame: frame)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.background.opacity(0.5))

            // Trennlinie
            Rectangle()
                .fill(.quaternary)
                .frame(height: 1)

            // MARK: - Unten: Canvas + Preview

            HStack(spacing: 0) {

                // Linke Seite: Canvas-Bereich
                VStack(spacing: 12) {
                    ToolBarView()
                    PixelCanvasView()
                    ColorPaletteView()
                }
                .padding(16)

                // Trennlinie
                Rectangle()
                    .fill(.quaternary)
                    .frame(width: 1)

                // Rechte Seite: Vorschau + Export
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        // MARK: - Canvas-Größe
                        sectionHeader("CANVAS", count: nil, fps: nil)

                        HStack(spacing: 4) {
                            ForEach(PixelCanvas.PresetSize.allCases) { preset in
                                Button {
                                    frameVM.newProject(gridSize: preset.rawValue)
                                    canvasVM.resetUndoHistory()
                                } label: {
                                    Text(preset.label)
                                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                                .tint(frameVM.project.gridSize == preset.rawValue ? .pink : nil)
                            }
                        }

                        Divider()

                        // MARK: - Vorschau
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

                        // Loop Toggle
                        Toggle(isOn: $frameVM.project.loopAnimation) {
                            Label("Loop", systemImage: "repeat")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .toggleStyle(.switch)
                        .controlSize(.mini)

                        // Preview-Fläche
                        previewCanvas

                        Divider()

                        // MARK: - Onion Skin
                        if canvasVM.onionSkinEnabled {
                            sectionHeader("ONION SKIN", count: nil, fps: nil)

                            Toggle("Vorheriger Frame", isOn: $canvasVM.onionSkinPrevious)
                                .font(.system(size: 10))
                                .toggleStyle(.switch)
                                .controlSize(.mini)

                            Toggle("Nächster Frame", isOn: $canvasVM.onionSkinNext)
                                .font(.system(size: 10))
                                .toggleStyle(.switch)
                                .controlSize(.mini)

                            HStack {
                                Text("Opacity")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(.tertiary)
                                Slider(value: $canvasVM.onionSkinOpacity, in: 0.05...0.8)
                                    .controlSize(.small)
                            }

                            Divider()
                        }

                        // MARK: - Export
                        sectionHeader("EXPORT", count: nil, fps: nil)

                        // Transparent BG
                        Toggle("Transparenter Hintergrund", isOn: $exportVM.transparentBackground)
                            .font(.system(size: 10))
                            .toggleStyle(.switch)
                            .controlSize(.mini)

                        // Spritesheet Layout
                        Picker("Layout", selection: $exportVM.spritesheetLayout) {
                            ForEach(ExportViewModel.SpritesheetLayout.allCases) { layout in
                                Text(layout.rawValue).tag(layout)
                            }
                        }
                        .pickerStyle(.segmented)
                        .controlSize(.mini)

                        // Engine Preset
                        Picker("Preset", selection: $exportVM.enginePreset) {
                            ForEach(ExportViewModel.EnginePreset.allCases) { preset in
                                Text(preset.rawValue).tag(preset)
                            }
                        }
                        .pickerStyle(.menu)
                        .controlSize(.small)

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
                                Label("PNG+JSON", systemImage: "rectangle.split.3x1")
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
        }
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
        let gs = frameVM.project.gridSize

        return VStack(spacing: 2) {
            // Mini-Canvas: 64×64 Punkte
            Canvas { context, size in
                let cellSize = size.width / CGFloat(gs)

                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(Color(red: 0.12, green: 0.12, blue: 0.16))
                )

                for y in 0..<gs {
                    for x in 0..<gs {
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

            // Frame-Nummer + optionale Duration
            VStack(spacing: 0) {
                Text("\(index + 1)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(isActive ? .pink : .secondary)
                if let ms = frame.durationMs {
                    Text("\(ms)ms")
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .onTapGesture {
            frameVM.selectFrame(at: index)
            #if canImport(UIKit)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            #endif
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
    private var previewCanvas: some View {
        let gs = frameVM.project.gridSize
        return TimelineView(.periodic(from: .now, by: 1.0 / Double(frameVM.project.fps))) { timeline in
            let frameIndex = animationFrameIndex(for: timeline.date)
            let grid = frameVM.project.frame(at: frameIndex)?.canvas ?? PixelCanvas(gridSize: gs)

            Canvas { context, size in
                let cellSize = size.width / CGFloat(gs)

                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(Color(red: 0.05, green: 0.05, blue: 0.08))
                )

                for y in 0..<gs {
                    for x in 0..<gs {
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
    private func animationFrameIndex(for date: Date) -> Int {
        guard frameVM.frameCount > 0 else { return 0 }
        let elapsed = date.timeIntervalSinceReferenceDate
        let fps = Double(frameVM.project.fps)
        let totalFrames = frameVM.frameCount
        if frameVM.project.loopAnimation {
            return Int(elapsed * fps) % totalFrames
        } else {
            return min(Int(elapsed * fps) % totalFrames, totalFrames - 1)
        }
    }

    // MARK: - iPad Save

    #if os(iOS)
    /// Speichern: wenn schon ein Pfad bekannt ist, direkt überschreiben.
    /// Sonst "Speichern unter" aufrufen.
    private func saveFile() {
        if let url = frameVM.currentFileURL {
            do {
                try frameVM.saveProject(to: url)
            } catch {
                saveFileAs()
            }
        } else {
            saveFileAs()
        }
    }

    private func saveFileAs() {
        let file = ProjectFile(from: frameVM.project)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(file) else { return }
        documentToSave = PlanktonDocument(data: data)
        showSaveDialog = true
    }
    #endif
}

// MARK: - Share Sheet (iOS)

#if os(iOS)
/// Wrapper für UIActivityViewController – das Standard-Teilen-Menü auf iOS/iPad.
struct ShareSheetView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

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
