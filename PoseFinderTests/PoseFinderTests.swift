//
//  PoseFinderTests.swift
//  PoseFinderTests
//
//  Created by tujing on 2026/03/09.
//  Copyright © 2026 Apple. All rights reserved.
//

import Testing
import Foundation
import Darwin.Mach
@testable import PoseFinder

struct PoseFinderTests {
    @Test func poseScoreLevelBoundary_isClassifiedAsExpected() throws {
        #expect(PoseScoreEvaluation.level(for: 0.90) == .ok)
        #expect(PoseScoreEvaluation.level(for: PoseScoreEvaluation.okThreshold) == .ok)
        #expect(PoseScoreEvaluation.level(for: 0.60) == .caution)
        #expect(PoseScoreEvaluation.level(for: PoseScoreEvaluation.cautionThreshold) == .caution)
        #expect(PoseScoreEvaluation.level(for: 0.10) == .ng)
    }

    @Test func concernJointNames_returnsLowScoreJointsFirst() throws {
        var pose = Pose()

        var rightShoulder = pose[.rightShoulder]
        rightShoulder.isValid = true
        rightShoulder.score = 0.20
        pose[.rightShoulder] = rightShoulder

        var rightElbow = pose[.rightElbow]
        rightElbow.isValid = true
        rightElbow.score = 0.55
        pose[.rightElbow] = rightElbow

        var rightWrist = pose[.rightWrist]
        rightWrist.isValid = true
        rightWrist.score = 0.40
        pose[.rightWrist] = rightWrist

        var leftShoulder = pose[.leftShoulder]
        leftShoulder.isValid = true
        leftShoulder.score = 0.88
        pose[.leftShoulder] = leftShoulder

        let concerns = PoseScoreEvaluation.concernJointNames(in: pose, limit: 2)
        #expect(concerns.count == 2)
        #expect(concerns[0] == .rightShoulder)
        #expect(concerns[1] == .rightWrist)
    }

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

    @Test func poseReplayLoadBenchmark_recordsMedianForThreeRuns() throws {
        let fileURL = try makeSyntheticPoseFile(durationSeconds: 600, fps: 30)
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }

        let repository = RecordingSessionRepository()
        var baselineTimesMs: [Double] = []
        var baselineMemoryMB: [Double] = []
        var improvedTimesMs: [Double] = []
        var improvedMemoryMB: [Double] = []

        for _ in 0..<3 {
            autoreleasepool {
                let baselineBeforeMem = currentMemoryMB()
                let baselineStart = CFAbsoluteTimeGetCurrent()
                let baselineResult = repository.loadAllPoseFrames(from: fileURL)
                let baselineElapsedMs = (CFAbsoluteTimeGetCurrent() - baselineStart) * 1000
                baselineTimesMs.append(baselineElapsedMs)

                switch baselineResult {
                case .success(let frames):
                    #expect(!frames.isEmpty)
                case .failure(let error):
                    Issue.record("baseline load failed: \(error)")
                }
                let baselineAfterMem = currentMemoryMB()
                baselineMemoryMB.append(max(0, baselineAfterMem - baselineBeforeMem))
            }

            autoreleasepool {
                let improvedBeforeMem = currentMemoryMB()
                let improvedStart = CFAbsoluteTimeGetCurrent()
                let indexResult = repository.loadPoseFrameIndex(from: fileURL)
                let improvedElapsedMs = (CFAbsoluteTimeGetCurrent() - improvedStart) * 1000
                improvedTimesMs.append(improvedElapsedMs)

                switch indexResult {
                case .success(let index):
                    let midTimestamp = 300_000
                    if let nearest = index.closestFrameIndex(for: midTimestamp) {
                        let frameResult = repository.loadPoseFrame(from: index, at: nearest)
                        if case .failure(let error) = frameResult {
                            Issue.record("improved frame load failed: \(error)")
                        }
                    } else {
                        Issue.record("improved index returned no nearest frame")
                    }
                case .failure(let error):
                    Issue.record("improved index build failed: \(error)")
                }
                let improvedAfterMem = currentMemoryMB()
                improvedMemoryMB.append(max(0, improvedAfterMem - improvedBeforeMem))
            }
        }

        let baselineTimeMedian = median(baselineTimesMs)
        let improvedTimeMedian = median(improvedTimesMs)
        let baselineMemoryMedian = median(baselineMemoryMB)
        let improvedMemoryMedian = median(improvedMemoryMB)

        let timeImprovementPercent = improvementPercent(baseline: baselineTimeMedian, improved: improvedTimeMedian)
        let memoryImprovementPercent = improvementPercent(baseline: baselineMemoryMedian, improved: improvedMemoryMedian)

        print("[0010-benchmark] baseline time median ms: \(baselineTimeMedian)")
        print("[0010-benchmark] improved time median ms: \(improvedTimeMedian)")
        print("[0010-benchmark] baseline memory delta MB: \(baselineMemoryMedian)")
        print("[0010-benchmark] improved memory delta MB: \(improvedMemoryMedian)")
        print("[0010-benchmark] time improvement %: \(timeImprovementPercent)")
        print("[0010-benchmark] memory improvement %: \(memoryImprovementPercent)")

        let payload: [String: Double] = [
            "baseline_time_median_ms": baselineTimeMedian,
            "improved_time_median_ms": improvedTimeMedian,
            "baseline_memory_median_mb": baselineMemoryMedian,
            "improved_memory_median_mb": improvedMemoryMedian,
            "time_improvement_percent": timeImprovementPercent,
            "memory_improvement_percent": memoryImprovementPercent
        ]
        writeBenchmarkPayload(payload)

        #expect(timeImprovementPercent >= 30)
        #expect(memoryImprovementPercent >= 30)
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

    func makeSyntheticPoseFile(durationSeconds: Int, fps: Int) throws -> URL {
        let frameCount = durationSeconds * fps
        let frameIntervalMs = Int(1000.0 / Double(fps))

        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PoseFinderBenchmark-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let fileURL = directoryURL.appendingPathComponent("pose.ndjson")

        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        let handle = try FileHandle(forWritingTo: fileURL)
        defer { try? handle.close() }

        for i in 0..<frameCount {
            let tMs = i * frameIntervalMs
            let x = 0.30 + (Double(i % 50) * 0.001)
            let y = 0.40 + (Double(i % 40) * 0.001)
            let line = """
            {"t_ms":\(tMs),"img_size":[1280,720],"score":0.95,"joints":{"nose":{"x":\(x),"y":\(y),"c":0.9},"leftShoulder":{"x":0.40,"y":0.52,"c":0.8},"rightShoulder":{"x":0.60,"y":0.52,"c":0.8}}}
            """
            if let data = "\(line)\n".data(using: .utf8) {
                try handle.write(contentsOf: data)
            }
        }

        return fileURL
    }

    func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return 0 }
        if sorted.count % 2 == 1 {
            return sorted[sorted.count / 2]
        }
        let upper = sorted[sorted.count / 2]
        let lower = sorted[(sorted.count / 2) - 1]
        return (lower + upper) / 2
    }

    func improvementPercent(baseline: Double, improved: Double) -> Double {
        guard baseline > 0 else { return 0 }
        return ((baseline - improved) / baseline) * 100.0
    }

    func currentMemoryMB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        return Double(info.resident_size) / (1024.0 * 1024.0)
    }

    func writeBenchmarkPayload(_ payload: [String: Double]) {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("0010-benchmark-latest.json")
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]) else {
            return
        }
        try? data.write(to: fileURL)
    }

}
