//
//  MainThread.swift
//  Finance App
//
//  Created by Jas  on 9/8/25.
//

import Foundation

@inline(__always)
func onMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async(execute: block)
    }
}

