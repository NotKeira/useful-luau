-->> Cryptographic Module Demonstrations
-->> Extends CryptoModule
-->> Displays:
--[[
- SHA256 Hashing (one-way hash function for data integrity)
- AES-256-CBC Encryption/Decryption (reversible encryption with passwords)
- Manual AES with custom keys and IVs (full cryptographic control)
- HMAC-SHA256 Authentication (message authenticity verification)
- Utility functions (hex/base64 encoding, key generation)
]]
-->> Built from scratch, no externals.
-->> Author: Keira Hopkins (github.com/NotKeira)
-->> Copyrighted and Licensed under the MIT License

local Crypto = require(script.Parent.CryptoModule)

-->> ========================================
-->> SHA256 DEMONSTRATION
-->> ========================================

print("=== SHA256 Hash Demo ===")
local message = "hello"
local hash = Crypto.sha256Hex(message)
print(`'{message}' SHA256 hash: {hash}`)

-- Note: SHA256 is one-way - you cannot decrypt/reverse a hash
-- Hashes are used for verification, not encryption

-->> ========================================
-->> AES ENCRYPTION/DECRYPTION DEMO
-->> ========================================

print("\n=== AES Encryption Demo ===")

-- Method 1: Simple string encryption with password
local plaintext = "This is a secret message!"
local password = "mySecurePassword123"

local encrypted, err = Crypto.encryptString(plaintext, password)
if err then
	print("Encryption error:", err)
else
	print("Original text:", plaintext)
	print("Encrypted (Base64):", encrypted)

	-- Decrypt it back
	local decrypted, err2 = Crypto.decryptString(encrypted, password)
	if err2 then
		print("Decryption error:", err2)
	else
		print("Decrypted text:", decrypted)
		print("Match original?", decrypted == plaintext)
	end
end

print("\n=== Manual AES with Custom Key Demo ===")

-- Method 2: Manual AES with generated key and IV
local key = Crypto.generateAESKey()
local iv = Crypto.generateIV()

print("Generated AES key (hex):", Crypto.bytesToHex(key))
print("Generated IV (hex):", Crypto.bytesToHex(iv))

local plaintext2 = "Another secret message with custom key!"
local ciphertext, usedIV, err3 = Crypto.aesEncrypt(plaintext2, key, iv)

if err3 then
	print("Manual encryption error:", err3)
else
	print("Original:", plaintext2)
	print("Ciphertext (hex):", Crypto.bytesToHex(ciphertext))

	-- Decrypt using the same key and IV
	local decryptedBytes, err4 = Crypto.aesDecrypt(ciphertext, key, usedIV)
	if err4 then
		print("Manual decryption error:", err4)
	else
		local decryptedText = Crypto.bytesToString(decryptedBytes)
		print("Decrypted:", decryptedText)
		print("Match original?", decryptedText == plaintext2)
	end
end

print("\n=== HMAC Authentication Demo ===")

-- HMAC for message authentication (ensures message hasn't been tampered with)
local secretKey = "authenticationKey"
local messageToAuth = "Important message that must not be tampered with"
local hmac = Crypto.hmacSha256(secretKey, messageToAuth)

print("Message:", messageToAuth)
print("HMAC (hex):", Crypto.bytesToHex(hmac))

-- Verify HMAC (would be done by recipient)
local verifyHmac = Crypto.hmacSha256(secretKey, messageToAuth)
local isValid = Crypto.bytesToHex(hmac) == Crypto.bytesToHex(verifyHmac)
print("HMAC verification:", isValid and "VALID" or "INVALID")
