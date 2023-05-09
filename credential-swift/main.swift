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
	static let version = "0.5"

	static let configuration = CommandConfiguration(
		commandName: "credential-swift",
		abstract: "Encrypt or decrypt a file with a hexadecimal key",
		version: Self.version
	)
	
	@Argument(help: "`encrypt` or `decrypt` for the input file")
	var mode: CryptoMode

	@Option(name: .shortAndLong, help: "Input file path")
	var `in`: String
	
	@Option(name: .shortAndLong, help: "Output file path")
	var `out`: String?
	
	@Option(name: .shortAndLong, help: "Hexadecimal key")
	var key: String?
	
	@Option(name: .shortAndLong, help: "Source file path to generate swift code")
	var source: String?
	
	func run() throws {
		let inputData = try Data(contentsOf: URL(fileURLWithPath: `in`))
		let outputData: Data
		switch mode {
		case .encrypt:
			guard source != nil || `out` != nil else { throw "must specify either `out` or `source` for encryption." }
			if `out` != nil && key == nil { throw "you must specify `key` with `out` option for encryption." }
			let keyData = try key.flatMap { try Data(hexadecimalString: $0) } ?? self.makeEncryptionKey()
			outputData = try inputData.encrypt_AES256GCM(with: keyData)
			if let source = source {
				try codegen(sourcePath: source, outputData: outputData, keyData: keyData)
			}
		case .decrypt:
			guard `out` != nil else { throw "you must specify `out` for decryption." }
			guard let key = key else { throw "you must specify `key` for decryption." }
			let keyData = try Data(hexadecimalString: key)
			guard keyData.count == 32 else { throw "`key` must be 32 byte length."  }
			outputData = try inputData.decrypt_AES256GCM(with: keyData)
		}
		if let `out` = `out` {
			try outputData.write(to: URL(fileURLWithPath: `out`))
		}
	}
	func makeEncryptionKey() -> Data {
		let key = SymmetricKey(size: .bits256)
		return key.withUnsafeBytes { Data($0) }
	}
	
	func codegen(sourcePath: String, outputData: Data, keyData: Data) throws {
		guard sourcePath.pathExtension == "swift" else { throw "must specify .swift for source" }
		let identifer = sourcePath.lastPathComponent.deletingPathExtension
		guard self.isValidIdentifier(identifer) else { throw "identifier contains some unexpected characters" }
		let keyString = keyData.map { String(format: "0x%02x", $0) }.joined(separator: ",")
		let bytesString =
				stride(from: 0, to: outputData.count, by: 16).map {
					"\t\t\t" + ($0 ..< min($0 + 16, outputData.count)).map { String(format: "0x%02x", outputData[$0]) }.joined(separator: ",")
				}.joined(separator: ",\r\n")
		let code = """
		import Foundation
		import CryptoKit
		fileprivate extension Data {
			func encrypt_AES256GCM(with key: Data) throws -> Data {
				let nonce = AES.GCM.Nonce()
				let sealedBox = try AES.GCM.seal(self, using: SymmetricKey(data: key), nonce: nonce)
				return sealedBox.combined!
			}
			
			func decrypt_AES256GCM(with key: Data) throws -> Data {
				let sealedBox = try AES.GCM.SealedBox(combined: self)
				let decryptedData = try AES.GCM.open(sealedBox, using: SymmetricKey(data: key))
				return decryptedData
			}
		}
		extension Data {
			static var catalog: Data? = {
				let key = Data([\(keyString)])
				return try? Data([
		\(bytesString)
				]).decrypt_AES256GCM(with: key)
			}()
		}
		"""
		print(code)
		try code.write(toFile: sourcePath, atomically: true, encoding: .utf8)
	}
	
	func isValidIdentifier(_ string: String) -> Bool {
		let firstCharSet = CharacterSet(charactersIn: "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
		let restCharSet = firstCharSet.union(CharacterSet(charactersIn: "123456789"))
		var charSet = firstCharSet
		for ch in string {
			guard charSet.contains(ch.unicodeScalars.first!) else { return false }
			charSet = restCharSet
		}
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

