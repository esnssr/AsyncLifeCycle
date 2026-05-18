# Architecture

AsyncLifeCycle is split into a small public runtime target and a compiler plugin target.

## Public Runtime

`Sources/AsyncLifeCycle/` exposes the `@Async` macro declaration, runtime configuration, logging, and `_AsyncLifeCycleTaskBag`. Generated code creates one task bag per annotated type. Each generated override calls UIKit `super` synchronously, then starts the matching async hook in a tracked main-actor task. The task bag cancels active work when the component profile says cancellation should happen.

## Macro Plugin

`Sources/AsyncLifeCyclePlugin/AsyncMacro.swift` is orchestration only:

1. Validate the annotated declaration is a supported UIKit class.
2. Resolve an `AsyncComponentProfile` from the direct base type.
3. Diagnose unsupported usage, sync override conflicts, and `super` calls inside async hooks.
4. Generate storage, helper methods, overrides, and cancellation-only overrides.

Reusable plugin foundations live under `Sources/AsyncLifeCyclePlugin/Foundation/`:

- `AsyncComponentProfile` describes one supported UIKit component.
- `AsyncComponentRegistry` lists available profiles.
- `AsyncHook` describes generated override behavior.
- `AsyncHookSignature` matches user-written async methods by name, labels, and accepted type spellings.
- `AsyncMemberGenerator` creates shared task storage and enabled hook overrides.

Diagnostics live under `Sources/AsyncLifeCyclePlugin/Diagnostics/`. Concrete UIKit support lives under `Sources/AsyncLifeCyclePlugin/Components/UIKit/`, with one folder per supported component.

## Adding Type Support

To add a UIKit component:

1. Add a folder under `Components/UIKit/<ComponentName>/`.
2. Define the component hooks as `AsyncHook` values with exact signatures and generated call arguments.
3. Define an `AsyncComponentProfile` with supported direct base type spellings, hooks, and cancellation hook.
4. Register the profile in `AsyncComponentRegistry.profiles`.
5. Add macro expansion and diagnostic tests for the new component.
6. Add or update registry invariant tests so duplicate hooks, missing cancellation hooks, and generated override shape are caught.

Keep support explicit. The macro cannot safely infer custom base-class inheritance, so profiles should list only direct UIKit base types the macro can see syntactically.
