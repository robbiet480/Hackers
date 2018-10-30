//
//  ArrayExtensions.swift
//  Night Mode
//
//  Created by Michael on 01/04/2018.
//  Copyright © 2018 Late Night Swift. All rights reserved.
//

import Foundation

extension Array {
	/// Move the last element of the array to the beginning
	///  - Returns: The element that was moved
	mutating func rotate() -> Element? {
		guard let lastElement = popLast() else {
			return nil
		}
		insert(lastElement, at: 0)
		return lastElement
	}
}

protocol AnyArray{}/*<--Neat trick to assert if a value is an Array, use-full in reflection and when the value is Any but really an array*/
extension Array:AnyArray{}//Maybe rename to ArrayType
func recFlatMap<T>(_ arr:[AnyObject]) -> [T]{
    var result:[T] = []
    Swift.print("arr.count: " + "\(arr.count)")
    arr.forEach{
        if($0 is AnyArray){
            let a:[AnyObject] = $0 as! [AnyObject]
            result += recFlatMap(a)
        }else{
            result.append($0 as! T)
        }
    }
    return result
}
