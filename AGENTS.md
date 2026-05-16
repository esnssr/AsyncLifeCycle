# Repository Guidelines

## Project Structure & Module Organization

This is a Swift Package Manager library for UIKit async lifecycle macros.

- `Package.swift` defines the `AsyncLifeCycle` library product, the `AsyncLifeCyclePlugin` macro target, and `AsyncLifeCycleTests`.
- `Sources/AsyncLifeCycle/` contains public API and runtime support:
  - `Macros/` exposes macro declarations.
  - `Runtime/` contains task tracking and logging.
  - `Configuration/` contains package configuration.
- `Sources/AsyncLifeCyclePlugin/` contains the compiler macro implementation.
- `Tests/AsyncLifeCycleTests/` contains macro expansion, diagnostics, and runtime tests.

## Build, Test, and Development Commands

CI validates the package with SwiftPM on `macos-26`. Match those commands when verifying contributor changes locally:

- `swift build` builds the package and macro plugin.
- `swift test` runs the `AsyncLifeCycleTests` suite.
- `xcodebuild test -scheme AsyncLifeCycle -destination 'platform=macOS'` is a useful Xcode fallback when testing the generated scheme.

Automated agent sessions should prefer XcodeBuildMCP or an equivalent MCP build tool for build, test, and run workflows. At the start of a new session, confirm or set the package scheme and simulator/session defaults before building.

## Coding Style & Naming Conventions

Use Swift 6.2 style with 4-space indentation. Keep source files focused by target responsibility: public macro declarations in `Sources/AsyncLifeCycle/Macros`, runtime types in `Runtime`, and compiler implementation details in `AsyncLifeCyclePlugin`.

Use `UpperCamelCase` for types, `lowerCamelCase` for functions and properties, and descriptive test names that state the behavior being verified. Prefer explicit concurrency behavior and avoid broad visibility; keep declarations internal unless they are part of the package API.

## Testing Guidelines

Tests use Swift Testing and SwiftSyntax macro test support. Add or update tests when changing macro output, diagnostics, runtime task cancellation, or logging behavior.

Place macro expansion tests in `AsyncMacroExpansionTests.swift`, diagnostic checks in `AsyncMacroDiagnosticTests.swift`, and runtime behavior tests in `AsyncLifeCycleRuntimeTests.swift`. Keep fixtures minimal and assert generated source or diagnostics precisely.

## Commit & Pull Request Guidelines

Recent commits use short imperative subjects, for example `Add release workflow for versioned tags` and `Update checkout action`. Follow that pattern: concise, present-tense, and focused on one change.

Pull requests should include a brief summary, test evidence, and any behavior or API changes. Link related issues when applicable. Include screenshots only when documentation or rendered output changes.

## Agent-Specific Instructions

When creating files with author metadata, use `Eslam Nasser assisted by Codex` rather than generic tool or agent names. When addressing PR comments, resolve only comments that were actually fixed and pushed. Never force push unless explicitly required.
