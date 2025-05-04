import Testing
@testable import NavigationBackport

// MARK: - Simple push and pop

@Test func shouldPushOneViewWhenOneAppended() async throws {
    let oldQueue = [1,2,3]
    let newQueue = [1,2,3,4]
    
    let result = QueueAnalyser.analyse(
        newQueue: newQueue,
        oldQueue: oldQueue
    )
    
    switch result {
    case .push(let path):
        #expect(path == [4])
    default:
        Issue.record()
    }
}

@Test func shouldPopOneViewWhenOneAppended() async throws {
    let oldQueue = [1,2,3,4,5]
    let newQueue = [1,2,3,4]
    
    let result = QueueAnalyser.analyse(
        newQueue: newQueue,
        oldQueue: oldQueue
    )
    
    switch result {
    case .pop(let page):
        #expect(page == 4)
    default:
        Issue.record()
    }
}

@Test func shouldPopToRouteWithBlankArray() async throws {
    let oldQueue = [1,2,3,4,5]
    let newQueue: [Int] = []
    
    let result = QueueAnalyser.analyse(
        newQueue: newQueue,
        oldQueue: oldQueue
    )
    
    switch result {
    case .popToRoot:
        #expect(true)
    default:
        Issue.record()
    }
}

@Test func shouldPushOneViewWhenOneAppendedWithDifferentType() async throws {
    let oldQueue = ["one","two","three"]
    let newQueue = ["one","two","three", "four"]
    
    let result = QueueAnalyser.analyse(
        newQueue: newQueue,
        oldQueue: oldQueue
    )
    
    switch result {
    case .push(let path):
        #expect(path == ["four"])
    default:
        Issue.record()
    }
}

// MARK: - Whole new stack

@Test func shouldSetPopWhenHasDifferentQueues() async throws {
    let oldQueue = [2,3,4,5]
    let newQueue = [1,2,3]
    
    let result = QueueAnalyser.analyse(
        newQueue: newQueue,
        oldQueue: oldQueue
    )
    
    switch result {
    case .wholeNewStackWithPopAnimation:
        #expect(true)
    default:
        Issue.record()
    }
}

@Test func shouldSetPushWhenHasDifferentQueues() async throws {
    let oldQueue = [2,3]
    let newQueue = [1,2,3]
    
    let result = QueueAnalyser.analyse(
        newQueue: newQueue,
        oldQueue: oldQueue
    )
    
    switch result {
    case .wholeNewStackWithPushAnimation:
        #expect(true)
    default:
        Issue.record()
    }
}

// MARK: - Hybrid stack

@Test func shouldSetHybridPushWhenHasDifferentButRelatedQueues() async throws {
    let oldQueue = [1,2,3]
    let newQueue = [1,2,4,5]
    
    let result = QueueAnalyser.analyse(
        newQueue: newQueue,
        oldQueue: oldQueue
    )
    
    switch result {
    case .hybridStackWithPushAnimation(let queeueToKeep, let newQueue):
        #expect(queeueToKeep == [1,2])
        #expect(newQueue == [4,5])
    default:
        Issue.record("Got \(result)")
    }
}

@Test func shouldSetHybridPopWhenHasDifferentButRelatedQueues() async throws {
    let oldQueue = [1,2,4,5]
    let newQueue = [1,2,3]
    
    let result = QueueAnalyser.analyse(
        newQueue: newQueue,
        oldQueue: oldQueue
    )
    
    switch result {
    case .hybridStackWithPopAnimation(let queeueToKeep, let newQueue):
        #expect(queeueToKeep == [1,2])
        #expect(newQueue == [3])
    default:
        Issue.record("Got \(result)")
    }
}

@Test func shouldSetHybridPushWhenHasDifferentButRelatedQueuesAndWithDuplicates() async throws {
    let oldQueue = [1,2,3,2]
    let newQueue = [1,2,4,5]
    
    let result = QueueAnalyser.analyse(
        newQueue: newQueue,
        oldQueue: oldQueue
    )
    
    switch result {
    case .hybridStackWithPushAnimation(let queeueToKeep, let newQueue):
        #expect(queeueToKeep == [1,2])
        #expect(newQueue == [4,5])
    default:
        Issue.record("Got \(result)")
    }
}
