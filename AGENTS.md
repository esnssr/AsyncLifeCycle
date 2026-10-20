# Repository Guidelines

## Project Structure & Module Organization

This is a Swift Package Manager library that gives UIKit screens SwiftUI-style `task { }` calls.

- `Package.swift` defines the `AsyncLifeCycle` library product and `AsyncLifeCycleTests`.
- `Sources/AsyncLifeCycle/` holds the public API (`UIViewController+Task.swift`, `TaskLifetime.swift`),
  the per-screen `TaskStore`, and `LifeCycleSwizzler`, which hooks `viewWillDisappear(_:)`,
  `viewDidDisappear(_:)` and `didMove(toParent:)`.
- `Tests/AsyncLifeCycleTests/` runs real screens in a window on the iOS simulator.

## Build, Test, and Development Commands

The package is iOS only, so SwiftPM's `swift build` and `swift test` (macOS) don't apply. CI runs:

- `xcodebuild test -scheme AsyncLifeCycle -destination 'platform=iOS Simulator,name=<iPhone>'`

Automated agent sessions should prefer XcodeBuildMCP or an equivalent MCP build tool for build, test, and run workflows. At the start of a new session, confirm or set the package scheme and simulator/session defaults before building.

Package tests have no host app, so presented screens and tab switches get no appearance callbacks
there. Check those cases in an app on the simulator.

## Coding Style & Naming Conventions

Use Swift 6.2 style with 4-space indentation. Keep source files focused on one type or one public extension.

Use `UpperCamelCase` for types, `lowerCamelCase` for functions and properties, and descriptive test names that state the behavior being verified. Prefer explicit concurrency behavior and avoid broad visibility; keep declarations internal unless they are part of the package API.

## Testing Guidelines

Tests use Swift Testing. Add or update tests when changing when tasks are cancelled or how they're stored. Keep the suite serialized: tests share the main run loop and the swizzle.

## Commit & Pull Request Guidelines

Recent commits use short imperative subjects, for example `Add release workflow for versioned tags` and `Update checkout action`. Follow that pattern: concise, present-tense, and focused on one change.

Pull requests should include a brief summary, test evidence, and any behavior or API changes. Link related issues when applicable. Include screenshots only when documentation or rendered output changes.

## Agent-Specific Instructions

When creating files with author metadata, use `Eslam Nasser assisted by <agent>`, with `Codex` or `Claude` as the agent. When addressing PR comments, resolve only comments that were actually fixed and pushed. Never force push unless explicitly required.
