import Testing
@testable import NavigationBackport

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

@Test func shouldSetPopWhenHasDifferentQueues() async throws {
    let oldQueue = [2,3,4,5]
    let newQueue = [1,2,3]
    
    let result = QueueAnalyser.analyse(
        newQueue: newQueue,
        oldQueue: oldQueue
    )
    
    switch result {
    case .setPop:
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
    case .setPush:
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

