# AGENT MANDATE
- Role: Reader → Synthesizer → Writer (Docs only)
- No code/build changes. No xcodebuild. Markdown outputs only.
- Scan order: docs/** → Sources/** (Swift). Skip: .xcodeproj, DerivedData, .build, Pods, Carthage, .git
- Deliver: spec/*.md (overview, codemap, usecases), plan/*.md (roadmap, backlog, open_questions, risks)
- Process: Inventory → Draft TOC → Write files (with human approval)
- Domain: iOS video pose estimation (pipeline, smoothing, overlay, perf, power, permissions, logging)
