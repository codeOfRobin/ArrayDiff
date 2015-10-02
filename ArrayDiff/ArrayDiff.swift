
import Foundation

public struct ArrayDiff {
	/// The indexes in the old array of the items that were kept
	public let commonIndexes: NSIndexSet
	/// The indexes in the old array of the items that were removed
	public let removedIndexes: NSIndexSet
	/// The indexes in the new array of the items that were inserted
	public let insertedIndexes: NSIndexSet
	
	/// Returns nil if the item was inserted
	public func oldIndexForNewIndex(index: Int) -> Int? {
		if insertedIndexes.containsIndex(index) { return nil }
		
		var result = index
		result -= insertedIndexes.countOfIndexesInRange(NSMakeRange(0, index))
		result += removedIndexes.countOfIndexesInRange(NSMakeRange(0, result + 1))
		return result
	}
	
	/// Returns nil if the item was deleted
	public func newIndexForOldIndex(index: Int) -> Int? {
		if removedIndexes.containsIndex(index) { return nil }
		
		var result = index
		result -= removedIndexes.countOfIndexesInRange(NSMakeRange(0, index))
		result += insertedIndexes.countOfIndexesInRange(NSMakeRange(0, result + 1))
		return result
	}
}

public extension Array {
	public func diff(other: Array<Element>, elementsAreEqual: ((Element, Element) -> Bool)) -> ArrayDiff {
		var lengths: [[Int]] = Array<Array<Int>>(
			count: count + 1,
			repeatedValue: Array<Int>(
				count: other.count + 1,
				repeatedValue: 0)
		)
		
		for var i = count; i >= 0; i-- {
			for var j = other.count; j >= 0; j-- {
				if i == count || j == other.count {
					lengths[i][j] = 0
				} else if elementsAreEqual(self[i], other[j]) {
					lengths[i][j] = 1 + lengths[i+1][j+1]
				} else {
					lengths[i][j] = max(lengths[i+1][j], lengths[i][j+1])
				}
			}
		}
		let commonIndexes = NSMutableIndexSet()
		
		for var i = 0, j = 0; i < count && j < other.count; {
			if elementsAreEqual(self[i], other[j]) {
				commonIndexes.addIndex(i)
				i++
				j++
			} else if lengths[i+1][j] >= lengths[i][j+1] {
				i++
			} else {
				j++
			}
		}
		
		let removedIndexes = NSMutableIndexSet()
		for i in 0..<count {
			if !commonIndexes.containsIndex(i) {
				removedIndexes.addIndex(i)
			}
		}
		
		let commonObjects = self[commonIndexes]
		let addedIndexes = NSMutableIndexSet()
		for var i = 0, j = 0; i < commonObjects.count || j < other.count; {
			if i < commonObjects.count && j < other.count && elementsAreEqual (commonObjects[i], other[j]) {
				i++
				j++
			} else {
				addedIndexes.addIndex(j)
				j++
			}
		}
		
		return ArrayDiff(commonIndexes: commonIndexes, removedIndexes: removedIndexes, insertedIndexes: addedIndexes)
	}
}

public extension Array where Element: Equatable {
	public func diff(other: Array<Element>) -> ArrayDiff {
		return self.diff(other, elementsAreEqual: { $0 == $1 })
	}
}
