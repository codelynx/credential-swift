//
//	AES256CBC.swift
//	credential-swift
//
//	Created by Kaz Yoshikawa on 5/12/23.
//
//	MIT License
//

import Foundation
import CommonCrypto


fileprivate enum AES256CBC_error: String, Error, CustomStringConvertible {
	case encryption_failed
	case decryption_failed
	var description: String {
		return self.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
	}
}

fileprivate extension Data {
	static func randomData(count: Int) -> Data {
		let randomData = NSMutableData(length: count)!
		let result = SecRandomCopyBytes(kSecRandomDefault, count, randomData.mutableBytes)
		precondition(result == errSecSuccess)
		return randomData as Data
	}
}

func encrypt_AES256CBC(contentData: Data, keyData: Data) throws -> Data {
	let keyLength = kCCKeySizeAES256
	let blockSize = kCCBlockSizeAES128
	
	let contentData = contentData as NSData
	let keyData = keyData as NSData
	let encryptedContentData = NSMutableData(length: contentData.count + blockSize)!
	let ivData = Data.randomData(count: 16) as NSData
	precondition(ivData.count == 16)
	
	let keyPtr = keyData.bytes
	let ivPtr = ivData.bytes
	let contentPtr = contentData.bytes
	let encryptedPtr = encryptedContentData.mutableBytes
	
	var encryptedContentDataLength: size_t = 0
	let status = CCCrypt(
		CCOperation(kCCEncrypt),
		CCAlgorithm(kCCAlgorithmAES),
		CCOptions(kCCOptionPKCS7Padding),
		keyPtr, keyLength,
		ivPtr,
		contentPtr, contentData.count,
		encryptedPtr, encryptedContentData.count,
		&encryptedContentDataLength
	)
	
	if status != kCCSuccess {
		throw AES256CBC_error.encryption_failed
	}
	
	encryptedContentData.length = encryptedContentDataLength
	
	return ivData + (encryptedContentData as Data)
}

func decrypt_AES256CBC(encryptedData: Data, keyData: Data) throws -> Data {
	let keyLength = kCCKeySizeAES256
	let blockSize = kCCBlockSizeAES128
	precondition(blockSize == 16)
	
	let encryptedData = encryptedData as NSData
	let keyData = keyData as NSData
	let ivData = Data(encryptedData.prefix(16)) as NSData // first 16 bytes is IV
	precondition(ivData.count == 16)
	let encryptedContentData = Data(encryptedData.suffix(from: 16)) as NSData // rest of bytes are body contents
	
	let decryptedData = NSMutableData(length: encryptedContentData.count)!
	
	let keyPtr = keyData.bytes
	let ivPtr = ivData.bytes
	let encryptedPtr = encryptedContentData.bytes
	let decryptedPtr = decryptedData.mutableBytes
	
	var decryptedDataLength: size_t = 0
	let status = CCCrypt(
		CCOperation(kCCDecrypt),
		CCAlgorithm(kCCAlgorithmAES),
		CCOptions(kCCOptionPKCS7Padding),
		keyPtr, keyLength,
		ivPtr,
		encryptedPtr, encryptedContentData.count,
		decryptedPtr, decryptedData.count,
		&decryptedDataLength
	)
	
	if status != kCCSuccess {
		throw AES256CBC_error.decryption_failed
	}
	
	decryptedData.length = decryptedDataLength
	
	return decryptedData as Data
}
