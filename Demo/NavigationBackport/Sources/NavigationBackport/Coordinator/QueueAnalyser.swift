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

        // old ⊂ new  (push)
        if oldQueue.count < newQueue.count, newQueue.starts(with: oldQueue) {
            let suffix = Path(newQueue.dropFirst(oldQueue.count))
            return .push(pagesToPush: suffix)
        }

        // new ⊂ old  (pop)
        if newQueue.count < oldQueue.count, oldQueue.starts(with: newQueue) {
            if let last = newQueue.last {
                return .pop(to: last)
            }
        }

        // diverged – decide push–vs–pop by length
        return newQueue.count > oldQueue.count ? .wholeNewStackWithPushAnimation : .wholeNewStackWithPopAnimation
    }
}
