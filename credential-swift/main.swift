// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import ArgumentParser
import CryptoKit


extension String: Error {
}

enum CryptoMode: String, CaseIterable, ExpressibleByArgument {
	case encrypt, decrypt
}

struct credential_swift: ParsableCommand {
	static let version = "0.8"
	
	static let configuration = CommandConfiguration(
		commandName: "credential-swift",
		abstract: "Encrypt or decrypt a file",
		version: Self.version
	)
	
	@Argument(help: "`encrypt` or `decrypt` for the input file")
	var mode: CryptoMode
	
	@Option(name: .shortAndLong, help: "Input file path")
	var `in`: String
	
	@Option(name: .shortAndLong, help: "Output file path")
	var `out`: String
	
	@Option(name: .shortAndLong, help: "Encryption or decryption key file path")
	var key: String
	
	@Option(name: .long, help: "source and identifier of the key")
	var identifier: String?
	
	func run() throws {
		
		let keyLength = 32
		switch mode {
		case .encrypt:
			let inputData = try Data(contentsOf: URL(fileURLWithPath: `in`))
			let keyData: Data
			if FileManager.default.fileExists(atPath: key) {
				keyData = try Data(contentsOf: URL(fileURLWithPath: key))
				guard keyData.count == keyLength else { throw "`key` must be \(keyLength) byte length."  }
			}
			else {
				var buffer = Data(count: keyLength)
				let result = buffer.withUnsafeMutableBytes { mutableBytes in
					SecRandomCopyBytes(kSecRandomDefault, keyLength, mutableBytes.baseAddress!)
				}
				guard result == errSecSuccess else { throw "Failed to generate random key: \(result)" }
				try buffer.write(to: URL(fileURLWithPath: key))
				keyData = buffer
			}
			guard keyData.count == keyLength else { throw "`key` must be 32 byte length."  }
			let outputData = try encrypt_AES256CBC(contentData: inputData, keyData: keyData)
			try outputData.write(to: URL(fileURLWithPath: `out`))
			if let identifier = self.identifier {
				guard isValidIdentifier(identifier) else { throw "not suitable for identifier." }
				let hexadecimalString = keyData.map { String(format: "0x%02hhx", $0) }.joined(separator: ",")
				let swiftsource = "let \(identifier) = Data([\(hexadecimalString)])"
				let swiftfilepath = FileManager.default.currentDirectoryPath.appendingPathComponent(identifier.appendingPathExtension("swift")!)
				try swiftsource.data(using: .utf8)!.write(to: URL(filePath: swiftfilepath))
				
				let kotlinsource = "val \(identifier) = byteArrayOf(\(hexadecimalString))"
				let kotlinfilepath = FileManager.default.currentDirectoryPath.appendingPathComponent(identifier.appendingPathExtension("kt")!)
				try kotlinsource.data(using: .utf8)!.write(to: URL(filePath: kotlinfilepath))
			}
		case .decrypt:
			guard FileManager.default.fileExists(atPath: key) else { throw "decryption key file not found" }
			let keyData = try Data(contentsOf: URL(fileURLWithPath: key))
			guard keyData.count == keyLength else { throw "`key` must be \(keyLength) byte length."  }
			let inputData = try Data(contentsOf: URL(fileURLWithPath: `in`))
			let outputData = try decrypt_AES256CBC(encryptedData: inputData, keyData: keyData)
			try outputData.write(to: URL(fileURLWithPath: `out`))
		}
	}
	
	func isValidIdentifier(_ string: String) -> Bool {
		guard let first = string.first, first.isLetter else { return false }
		let characterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")
		let remainingCharacters = string.dropFirst()
		guard characterSet.isSuperset(of: CharacterSet(charactersIn: String(remainingCharacters))) else { return false }
		return true
	}
}

credential_swift.main()

extension String {
	func appendingPathExtension(_ str: String) -> String? {
		return (self as NSString).appendingPathExtension(str)
	}
	func appendingPathComponent(_ str: String) -> String {
		return (self as NSString).appendingPathComponent(str)
	}
	var deletingPathExtension: String {
		return (self as NSString).deletingPathExtension
	}
	var deletingLastPathComponent: String {
		return (self as NSString).deletingLastPathComponent
	}
	var abbreviatingWithTildeInPath: String {
		return (self as NSString).abbreviatingWithTildeInPath;
	}
	var expandingTildeInPath: String {
		return (self as NSString).expandingTildeInPath;
	}
	var fileSystemRepresentation: UnsafePointer<Int8> {
		return (self as NSString).fileSystemRepresentation
	}
	var lastPathComponent: String {
		return (self as NSString).lastPathComponent
	}
	var pathExtension: String {
		return (self as NSString).pathExtension
	}
}

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

extension NSData {
	func hexadecimalString(prefix: String? = nil) -> String {
		return (self as Data).hexadecimalString(prefix: prefix)
	}
	var hexadecimalString: String { return (self as Data).hexadecimalString }
}
