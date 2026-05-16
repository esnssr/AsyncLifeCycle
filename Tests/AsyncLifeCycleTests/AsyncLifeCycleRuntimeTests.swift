import AsyncLifeCycle
import XCTest

final class AsyncLifeCycleRuntimeTests: XCTestCase {
    func testConfigurationCanBeUpdatedAndRestored() {
        let originalConfiguration = AsyncLifeCycleConfiguration.current
        defer {
            AsyncLifeCycleConfiguration.current = originalConfiguration
        }

        AsyncLifeCycleConfiguration.current = AsyncLifeCycleConfiguration(isLoggingEnabled: true)
        XCTAssertTrue(AsyncLifeCycleConfiguration.current.isLoggingEnabled)

        AsyncLifeCycleConfiguration.current = AsyncLifeCycleConfiguration(isLoggingEnabled: false)
        XCTAssertFalse(AsyncLifeCycleConfiguration.current.isLoggingEnabled)
    }

    @MainActor
    func testTaskBagCancelsRunningTasks() async {
        let taskBag = _AsyncLifeCycleTaskBag(ownerType: "TestViewController")
        let cancellationExpectation = expectation(description: "Task was canceled")

        taskBag.start(methodName: "viewDidAppear") {
            await withTaskCancellationHandler {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(10))
                }
            } onCancel: {
                cancellationExpectation.fulfill()
            }
        }

        await Task.yield()
        taskBag.cancelAll()

        await fulfillment(of: [cancellationExpectation], timeout: 1)
    }
}
