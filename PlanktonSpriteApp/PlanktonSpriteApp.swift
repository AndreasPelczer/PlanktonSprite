//
//  PlanktonSpriteApp.swift
//  PlanktonSpriteApp
//
//  Created by Andreas Pelczer on 27.02.26.
//


import SwiftUI

/// Entry Point der App.
/// Hier werden alle ViewModels erzeugt und miteinander verbunden.
@main
struct PlanktonSpriteApp: App {
    
    // MARK: - ViewModels
    
    /// Die drei ViewModels als @StateObject – sie leben so lange wie die App.
    /// @StateObject bedeutet: SwiftUI erstellt sie EINMAL und behält sie.
    /// Im Gegensatz zu @ObservedObject, das bei jedem View-Rebuild
    /// potenziell neu erstellt werden könnte.
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
                    // ViewModels miteinander verbinden.
                    // Das passiert EINMAL beim App-Start.
                    canvasVM.connect(to: frameVM)
                    exportVM.connect(to: frameVM)
                }
        }
    }
}