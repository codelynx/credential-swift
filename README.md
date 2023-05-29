# Credential Swift

This package is for providing sensitive credential information for app to use.
You may use `credential-swift` as a command line tool to encrypt credential data into encrypted binary as a file.


## Disclaimer 

This solution is not intended for security professionals, the goal of this solution is to provide a way to relatively secure to deal with sensitive credential information such as API key, shared secret, password and some others from causal hackers.

## Encrypt to file

Encrypt file into encrypted binary file, you may sepcify 32 byte length binary key as an encryption key, but if you don't provide the key file, it will generate random 32 bytes key and save it for you.
Whichever it is, you must specify key file to read or to create.
 
The encrypted file can be decoded by AES256CBC.swift or AES256CBC.kt provided by this package.  Encrypted file can be embed to app, or placed on server side, and can be used upon download.

```.console
$ credential-swift encrypt -in credentials.plist -out credentials.bin -key credentials.key32 --identifier CREDENTIALS_KEY
```
When you specify `--identifier` with identifier name, it will generate swift and kotlin source code of the encryption key. The identifier will be the constant name identifier for the source code as well as its source file name. 
In this example it creates CREDENTIALS_KEY.swift and CREDENTIALS_KEY.kt.  By adding this source file into your project, you don't have to provide key file as a resource to your project. 

```CREDENTIALS_KEY.swift
let CREDENTIALS_KEY = Data([0x9c,0x0e,0xc3,0xea,0x81,0xb8,0xed,0xf4,0x72,0x10,0x57,0x75,0x7a,0xec,0xde,0x2a,0xe6,0x9c,0x7a,0x58,0xf4,0x60,0xad,0xab,0xfc,0xda,0x4e,0x18,0x2d,0xaa,0x22,0xff])
```

```CREDENTIALS_KEY.kt
val CREDENTIALS_KEY = byteArrayOf(0x9c,0x0e,0xc3,0xea,0x81,0xb8,0xed,0xf4,0x72,0x10,0x57,0x75,0x7a,0xec,0xde,0x2a,0xe6,0x9c,0x7a,0x58,0xf4,0x60,0xad,0xab,0xfc,0xda,0x4e,0x18,0x2d,0xaa,0x22,0xff)
```

## Decrypt encrypted file on you app


This package provides AES256CBC for swift and kotlin.  Here is the example of how to decrypt you encrypted credential data.

```swift
try {
	let encryptionKey: Data = ...
	let encryptedCredentialData: Data = ...
	let decyptedData = try decrypt_AES256CBC(encryptedData: encryptedCredentialData, keyData: encryptionKey)
}
catch {
}
```

```kt
try {
	val encryptedData: ByteArray = ...
	val val keyData: ByteArray ...
	val decyptedData = decryptAES256CBC(encryptedData, keyData)
}
catch (e: Exception) {
}
```

## Decrypt from file

You can decrypt encrypted file from command line as well.  You must specify proper encryption key to decrypt from file.  You must specify valid 32 byte encryption key as a file to specify. 

```
$ credential-swift decrypt -in credentials.bin -out credentials.plist -key credentials.key32
```


## Note

Due to compatibility issues, I down graded from AES-GCM to AES-CBC.

## Status

I think it is not ready for productions, but should be ready for testing.

## Thanks

Thanks to Chat GPT and GPT 4 for giving me some advices.

