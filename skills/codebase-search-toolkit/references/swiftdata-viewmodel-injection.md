# SwiftData ModelContext injection in Observable ViewModels

## Problem
SwiftUI `@Observable` view models need to query/save SwiftData models, but `@Query` and `@ModelContext` are SwiftUI property wrappers — they only work inside `View` structs, not in plain observable classes.

## Solution: manual context injection

1. **Declare** `private(set) var modelContext: ModelContext?` in the ViewModel
2. **Inject** via a `setModelContext(_:)` method called from the app's init
3. **Query** with `FetchDescriptor` when needed

### AuthViewModel pattern (from FemControl)

```swift
import SwiftData

@MainActor @Observable
final class AuthViewModel {
    private(set) var modelContext: ModelContext?

    /// Computed property — reads singleton from SwiftData
    var userHealthProfile: UserHealthProfile? {
        guard let ctx = modelContext else { return nil }
        let descriptor = FetchDescriptor<UserHealthProfile>(
            predicate: #Predicate { $0.id == "singleton" }
        )
        return try? ctx.fetch(descriptor).first
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func saveUserHealthProfile(_ profile: UserHealthProfile) {
        guard let ctx = modelContext else { return }
        ctx.insert(profile)
        try? ctx.save()
    }
}
```

### App wiring (in @main App struct)

```swift
let container: ModelContainer

init() {
    let schema = Schema(AppSchemaCurrent.models)
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    container = try! ModelContainer(for: schema, migrationPlan: ..., configurations: [config])
    let context = container.mainContext

    let authVM = AuthViewModel(...)
    authVM.setModelContext(context)  // ✅ inject here
}
```

## Alternatives considered

| Approach | Verdict |
|----------|---------|
| Pass ModelContext in init params | Works but clutters init signatures with optional |
| Use `@Environment(\.modelContext)` in each View + pass down | Works for Views but not for shared VMs |
| Singleton ModelContext | Violates DI, hard to test |
| **Manual injection (chosen)** | Clean, testable, single source of truth |

## When to apply this

- The ViewModel is `@Observable` (not `@ObservableObject` with `@Published`)
- The class is NOT a SwiftUI View (so `@Query` doesn't work)
- You need to read/write SwiftData models from a shared service or ViewModel
- Also applies to service classes that receive `ModelContext` via init (e.g. `LocalSettingsService`)

## Pitfalls

- **Call `setModelContext` BEFORE any method that queries.** In FemControl this is done right after `AuthViewModel()` init.
- **`private(set)`** — other objects can read but not write the context.
- **The context is optional** — always `guard` or `if let` before using.
- **Don't mirror the context in multiple places** — inject once per ViewModel, not per method call.
- **The `@Observable` macro means SwiftUI views react to property changes automatically** — no need for `@Published` or `objectWillChange` when query results change.
