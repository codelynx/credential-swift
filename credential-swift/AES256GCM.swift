//
//	AES256GCM.swift
//	credential swift
//
//	Created by Kaz Yoshikawa on 5/9/23.
//

import Foundation
import CryptoKit

extension Data {
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
