/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Delegate class for the application.
*/

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        copyBundleTrainingResourcesToDocumentsIfNeeded()
        return true
    }

    private func copyBundleTrainingResourcesToDocumentsIfNeeded() {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        let targetDir = documentsURL.appendingPathComponent("PoseFinderTrainingMenus", isDirectory: true)
        let targetVideosDir = targetDir.appendingPathComponent("videos", isDirectory: true)

        do {
            if !fileManager.fileExists(atPath: targetDir.path) {
                try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true, attributes: nil)
            }
            if !fileManager.fileExists(atPath: targetVideosDir.path) {
                try fileManager.createDirectory(at: targetVideosDir, withIntermediateDirectories: true, attributes: nil)
            }

            if let bundleJSON = Bundle.main.url(forResource: "training-menus", withExtension: "json") {
                let dest = targetDir.appendingPathComponent("training-menus.json")
                try replaceItemIfNeeded(at: dest, with: bundleJSON, fileManager: fileManager)
            }

            let rootVideoURLs = Bundle.main.urls(forResourcesWithExtension: "mp4", subdirectory: nil) ?? []
            let videosDirectoryURLs = Bundle.main.urls(forResourcesWithExtension: "mp4", subdirectory: "videos") ?? []

            for videoURL in (rootVideoURLs + videosDirectoryURLs) {
                let dest = targetVideosDir.appendingPathComponent(videoURL.lastPathComponent)
                try replaceItemIfNeeded(at: dest, with: videoURL, fileManager: fileManager)
            }
        } catch {
            print("[AppDelegate] Failed to copy training resources: \(error)")
        }
    }

    private func replaceItemIfNeeded(at destinationURL: URL, with sourceURL: URL, fileManager: FileManager) throws {
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }
}
