import ObjectiveC
import UIKit

@MainActor private var taskStoreKey: UInt8 = 0

extension UIViewController {
    var existingTaskStore: TaskStore? {
        objc_getAssociatedObject(self, &taskStoreKey) as? TaskStore
    }

    var taskStore: TaskStore {
        if let store = existingTaskStore {
            return store
        }
        let store = TaskStore()
        objc_setAssociatedObject(self, &taskStoreKey, store, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return store
    }
}
