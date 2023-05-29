//
//	AES256CBC.swift
//	credential-swift
//
//	Created by Kaz Yoshikawa on 5/12/23.
//
//	MIT License
//

import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec
import java.security.SecureRandom

fun encrypt_AES256CBC(content: ByteArray, key: ByteArray): ByteArray {
	val random = SecureRandom()
	val iv = ByteArray(16)
	random.nextBytes(iv)
	
	val cipher = Cipher.getInstance("AES/CBC/PKCS5Padding")
	val secretKey = SecretKeySpec(key, "AES")
	val ivParameterSpec = IvParameterSpec(iv)
	
	cipher.init(Cipher.ENCRYPT_MODE, secretKey, ivParameterSpec)
	val encryptedContent = cipher.doFinal(content)
	return iv + encryptedContent
}

fun decrypt_AES256CBC(encrypted: ByteArray, key: ByteArray): ByteArray {
	val iv = encrypted.take(16).toByteArray()
	val encryptedContent = encrypted.drop(16).toByteArray()
	val cipher = Cipher.getInstance("AES/CBC/PKCS5Padding")
	val secretKey = SecretKeySpec(key, "AES")
	val ivParameterSpec = IvParameterSpec(iv)
	
	cipher.init(Cipher.DECRYPT_MODE, secretKey, ivParameterSpec)
	return cipher.doFinal(encryptedContent)
}

