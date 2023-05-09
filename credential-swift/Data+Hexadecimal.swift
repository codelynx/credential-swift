//
//	Data+Hexadecimal.swift
//
//	The MIT License (MIT)
//
//	Copyright (c) 2023 Electricwoods LLC, Kaz Yoshikawa.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.
//
//	Usage:
//	    do {
//	        let string = "0x48656c6c6f20576f726C64"
//	        let data = try Data(hexadecimalString: string)
//	        print(data.hexadecimalString(prefix: "0x"))
//	    }
//	    catch {
//	        print("\(error)")
//	    }

import Foundation

extension Data {
    enum HexadecimalConversionError: String, Error, CustomStringConvertible {
        case incomplete_hexadecimal_string
        case none_hexadecimal_charactor
        var description: String {
            return self.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    init(hexadecimalString string: String) throws {
        let hexadecimalString = (string.hasPrefix("0x") || string.hasPrefix("0X")) ? String(string.dropFirst(2)) : string
        let characters = Array(hexadecimalString)
        guard characters.count % 2 == 0 else { throw HexadecimalConversionError.incomplete_hexadecimal_string }
        let indices = stride(from: 0, to: characters.count, by: 2)
        let bytes = indices.map { String([characters[$0], characters[$0 + 1]]) }.map { UInt8($0, radix: 16) }
        guard bytes.filter({ $0 == nil }).count == 0 else { throw HexadecimalConversionError.none_hexadecimal_charactor }
        self = Data(bytes.compactMap { $0 })
    }
    func hexadecimalString(prefix: String? = nil) -> String {
        let hexadecimalString = self.map { String(format: "%02hhx", $0) }.joined()
        return (prefix ?? "") + hexadecimalString
    }
    var hexadecimalString: String {
        return hexadecimalString()
    }
}
