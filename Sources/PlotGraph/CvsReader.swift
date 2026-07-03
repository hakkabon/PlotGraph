//
//  csvReader.swift
//  Graph
//
//  Created by Ulf Akerstedt-Inoue on 2019/06/11.
//  Copyright © 2019 hakkabon software. All rights reserved.
//
import Foundation

extension String {
    var data: Data { return Data(utf8) }
}

public extension Numeric {
    var data: Data {
        var source = self
        // This will return 1 byte for 8-bit, 2 bytes for 16-bit,
        // 4 bytes for 32-bit and 8 bytes for 64-bit binary integers.
        // For floating point types it will return 4 bytes for single-precision,
        // 8 bytes for double-precision and 16 bytes for extended precision.
        return Data(bytes: &source, count: MemoryLayout<Self>.size)
    }
}

public extension Data {
    var integer: Int { safelyLoaded() }
    var int32: Int32 { safelyLoaded() }
    var float: Float { safelyLoaded() }
    var double: Double { safelyLoaded() }
    var string: String? {
        return String(data: self, encoding: .utf8)
    }
}

private extension Data {
    /// Copies raw bytes into a value of type `T`. Unlike `load(as:)`, this does not
    /// require the underlying buffer to be aligned for `T`, since `Data`'s storage
    /// makes no such alignment guarantee and `load(as:)` traps if it's violated.
    func safelyLoaded<T>() -> T {
        precondition(count >= MemoryLayout<T>.size,
                     "Not enough bytes to load \(T.self): need \(MemoryLayout<T>.size), have \(count).")
        return withUnsafeBytes { rawBuffer -> T in
            let value = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<T>.size, alignment: MemoryLayout<T>.alignment)
            defer { value.deallocate() }
            value.copyMemory(from: rawBuffer.baseAddress!, byteCount: MemoryLayout<T>.size)
            return value.load(as: T.self)
        }
    }
}

public struct Extract {
    var data: [[Data]] = []
    
    public init(data: [[Data]]) {
        self.data = data
    }
    
    public subscript(index: Int) -> [Data] {
        return data.compactMap { $0.dropFirst(index).first }
    }
}

public func readCSV(from fileName: String, extension fileType: String, bundle: Bundle = .main) -> [[Data]] {
    guard
        let filepath = bundle.path(forResource: fileName, ofType: fileType)
    else { return [] }
    
    do {
        let content = try String(contentsOfFile: filepath, encoding: .utf8)
        let data: [[Data]] = content
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .map({
                $0.components(separatedBy: ",")
                    .map({
                        if let double = Double($0) {
                            return double.data
                        }
                        return $0.data
                    })
            })
        return data
        
    } catch {
        print("Read Error occured reading file '\(fileName)' at '\(filepath)'")
    }
    return []
}

