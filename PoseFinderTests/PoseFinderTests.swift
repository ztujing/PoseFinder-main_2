//
//  PoseFinderTests.swift
//  PoseFinderTests
//
//  Created by tujing on 2026/03/09.
//  Copyright © 2026 Apple. All rights reserved.
//

import Testing
import Foundation
@testable import PoseFinder

struct PoseFinderTests {

    @Test func poseFrameIndexBuildsAndFindsClosestFrame() throws {
        let fileURL = try makePoseFile(
            """
            {"t_ms":0,"img_size":[100,200],"score":0.9,"joints":{"nose":{"x":0.50,"y":0.25,"c":0.8}}}
            {"t_ms":100,"img_size":[100,200],"score":0.9,"joints":{"nose":{"x":0.52,"y":0.26,"c":0.8}}}
            {"t_ms":240,"img_size":[100,200],"score":0.9,"joints":{"nose":{"x":0.54,"y":0.27,"c":0.8}}}
            """
        )
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let repository = RecordingSessionRepository()
        let result = repository.loadPoseFrameIndex(from: fileURL)

        guard case .success(let index) = result else {
            Issue.record("pose index build failed: \(result)")
            return
        }

        #expect(index.count == 3)
        #expect(index.closestFrameIndex(for: -10) == 0)
        #expect(index.closestFrameIndex(for: 49) == 0)
        #expect(index.closestFrameIndex(for: 90) == 1)
        #expect(index.closestFrameIndex(for: 181) == 2)
    }

    @Test func poseFrameCanBeLoadedOnDemandFromIndex() throws {
        let fileURL = try makePoseFile(
            """
            {"t_ms":0,"img_size":[200,100],"score":0.9,"joints":{"nose":{"x":0.20,"y":0.40,"c":0.7}}}
            {"t_ms":100,"img_size":[200,100],"score":0.9,"joints":{"nose":{"x":0.30,"y":0.50,"c":0.7}}}
            """
        )
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let repository = RecordingSessionRepository()
        let indexResult = repository.loadPoseFrameIndex(from: fileURL)
        guard case .success(let index) = indexResult else {
            Issue.record("pose index build failed: \(indexResult)")
            return
        }

        let frameResult = repository.loadPoseFrame(from: index, at: 1)
        guard case .success(let frame) = frameResult else {
            Issue.record("pose frame load failed: \(frameResult)")
            return
        }

        #expect(frame.timestampMs == 100)
        #expect(Int(frame.imageSize.width) == 200)
        #expect(Int(frame.imageSize.height) == 100)
    }
}

private extension PoseFinderTests {
    func makePoseFile(_ content: String) throws -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PoseFinderTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let fileURL = directoryURL.appendingPathComponent("pose.ndjson")
        guard let data = content.data(using: .utf8) else {
            throw NSError(domain: "PoseFinderTests", code: 1)
        }
        try data.write(to: fileURL)
        return fileURL
    }

}
