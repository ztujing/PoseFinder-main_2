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
        seedUITestSessionIfNeeded()
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

    private func seedUITestSessionIfNeeded() {
        guard UITestSupport.shouldSeedSession else { return }

        let fileManager = FileManager.default
        guard let directoryURL = UITestSupport.seededSessionDirectoryURL(fileManager: fileManager) else {
            return
        }

        do {
            try createUITestSession(at: directoryURL, fileManager: fileManager)
        } catch {
            print("[AppDelegate] Failed to seed UI test session: \(error)")
        }
    }

    private func createUITestSession(at directoryURL: URL, fileManager: FileManager) throws {
        let sessionsDirectory = directoryURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: sessionsDirectory.path) {
            try fileManager.createDirectory(at: sessionsDirectory, withIntermediateDirectories: true, attributes: nil)
        }

        if fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.removeItem(at: directoryURL)
        }

        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)

        let metadataURL = directoryURL.appendingPathComponent("session.json")
        let videoURL = directoryURL.appendingPathComponent("video.mp4")
        let poseURL = directoryURL.appendingPathComponent("pose.ndjson")

        let metadataJSON = """
        {
          "schemaVersion": 1,
          "sessionId": "\(UITestSupport.seededSessionID)",
          "createdAt": "2026-03-09T00:00:00.000Z",
          "device": { "model": "iPhone", "os": "iOS" },
          "camera": { "position": "front", "preset": "hd1280x720" },
          "video": { "file": "video.mp4", "codec": "h264", "size": [1280, 720], "fps": 30.0 },
          "pose": { "file": "pose.ndjson", "jointSet": "coco17", "coords": "normalized" }
        }
        """

        let poseNDJSON = """
        {"t_ms":0,"img_size":[1280,720],"score":0.98,"joints":{"nose":{"x":0.50,"y":0.30,"c":0.98},"leftShoulder":{"x":0.43,"y":0.42,"c":0.95},"rightShoulder":{"x":0.57,"y":0.42,"c":0.96},"leftHip":{"x":0.46,"y":0.58,"c":0.92},"rightHip":{"x":0.54,"y":0.58,"c":0.93}}}
        """

        guard let metadataData = metadataJSON.data(using: .utf8),
              let poseData = poseNDJSON.data(using: .utf8) else {
            throw NSError(domain: "PoseFinder.UITest", code: -1, userInfo: nil)
        }

        try metadataData.write(to: metadataURL)
        try poseData.write(to: poseURL)

        if !fileManager.fileExists(atPath: videoURL.path) {
            _ = fileManager.createFile(atPath: videoURL.path, contents: Data(), attributes: nil)
        }
    }
}
