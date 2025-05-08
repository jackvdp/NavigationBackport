struct QueueAnalyser {

    enum Result<Path> where Path: MutableCollection & RandomAccessCollection & RangeReplaceableCollection, Path.Element: Hashable {
        case unchanged                      // identical arrays
        case push(pagesToPush: Path)        // `old` is prefix of `new`; push the suffix
        case pop(to: Path.Element)          // `new` is prefix of `old`; pop until *after* this element is visible
        case popToRoot                      // `new` is empty; pop to root
        case wholeNewStackWithPushAnimation // unrelated stack but `new.count` > `old.count` – treat like a push animation
        case wholeNewStackWithPopAnimation  // unrelated stack and shrinking – treat like a pop animation
        case hybridStackWithPushAnimation(queueToKeep: Path, newQueue: Path)   // related stack but `new.count` > `old.count` – treat like a push animation
        case hybridStackWithPopAnimation(queueToKeep: Path, newQueue: Path)   // related stack but `new.count` < `old.count` – treat like a push animation
    }

    /// Decide which action brings `oldQueue` to `newQueue`.
    static func analyse<Path>(
        newQueue: Path,
        oldQueue: Path
    ) -> Result<Path> where Path: MutableCollection & RandomAccessCollection & RangeReplaceableCollection, Path.Element: Hashable {

        if newQueue.elementsEqual(oldQueue) {
            return .unchanged
        }

        if newQueue.isEmpty {
            return .popToRoot
        }

        // Find the longest common prefix
        var commonPrefixLength = 0
        let minLength = min(newQueue.count, oldQueue.count)
        
        while commonPrefixLength < minLength {
            let newIndex = newQueue.index(newQueue.startIndex, offsetBy: commonPrefixLength)
            let oldIndex = oldQueue.index(oldQueue.startIndex, offsetBy: commonPrefixLength)
            if newQueue[newIndex] != oldQueue[oldIndex] {
                break
            }
            commonPrefixLength += 1
        }
        
        // old ⊂ new (push) - old is exactly a prefix of new
        if commonPrefixLength == oldQueue.count && commonPrefixLength < newQueue.count {
            let suffix = Path(newQueue.dropFirst(commonPrefixLength))
            return .push(pagesToPush: suffix)
        }
        
        // new ⊂ old (pop) - new is exactly a prefix of old
        if commonPrefixLength == newQueue.count && commonPrefixLength < oldQueue.count {
            if let last = newQueue.last {
                return .pop(to: last)
            }
        }
        
        // Hybrid case - common prefix but divergence
        if commonPrefixLength > 0 && commonPrefixLength < min(newQueue.count, oldQueue.count) {
            let commonPrefix = Path(newQueue.prefix(commonPrefixLength))
            let newSuffix = Path(newQueue.dropFirst(commonPrefixLength))
            
            if newQueue.count >= oldQueue.count {
                return .hybridStackWithPushAnimation(queueToKeep: commonPrefix, newQueue: newSuffix)
            } else {
                return .hybridStackWithPopAnimation(queueToKeep: commonPrefix, newQueue: newSuffix)
            }
        }
        
        // Completely different stacks - decide push vs pop by length
        return newQueue.count > oldQueue.count ? .wholeNewStackWithPushAnimation : .wholeNewStackWithPopAnimation
    }
}
