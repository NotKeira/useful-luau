-->> Advanced Cryptographic Module
-->> Implements AES-256-CBC encryption/decyption and SHA256 hashing
-->> Built from scratch, no externals.
-->> Author: Keira Hopkins (github.com/NotKeira)
-->> Copyrighted and Licensed under the MIT License

local CryptoModule = {}

-->> ========================================
-->> UTILITY FUNCTIONS
-->> ========================================

-->> Convert string to byte array
local function stringToBytes(str)
	local bytes = {}
	for i = 1, #str do
		bytes[i] = string.byte(str, i)
	end
	return bytes
end

-->> Convert byte array to string
local function bytesToString(bytes)
	local chars = {}
	for i = 1, #bytes do
		chars[i] = string.char(bytes[i])
	end
	return table.concat(chars)
end

-->> Secure byte array comparison (constant time)
local function secureCompare(a, b)
	if #a ~= #b then
		return false
	end

	local result = 0
	for i = 1, #a do
		result = bit32.bor(result, bit32.bxor(a[i], b[i]))
	end

	return result == 0
end

-->> XOR two byte arrays
local function xorBytes(a, b)
	local result = {}
	local len = math.min(#a, #b)
	for i = 1, len do
		result[i] = bit32.bxor(a[i], b[i])
	end
	return result
end

-->> PKCS7 padding
local function addPadding(data, blockSize)
	local padLen = blockSize - (#data % blockSize)
	local padded = { table.unpack(data) }

	for i = 1, padLen do
		table.insert(padded, padLen)
	end

	return padded
end

-->> Remove PKCS7 padding with validation
local function removePadding(data)
	if #data == 0 then
		return nil, "Invalid padding: empty data"
	end

	local padLen = data[#data]

	if padLen < 1 or padLen > 16 then
		return nil, "Invalid padding length"
	end

	if #data < padLen then
		return nil, "Invalid padding: insufficient data"
	end

	-->> Create expected padding for constant-time comparison
	local expectedPadding = {}
	for i = 1, padLen do
		expectedPadding[i] = padLen
	end

	local actualPadding = {}
	for i = #data - padLen + 1, #data do
		table.insert(actualPadding, data[i])
	end

	-->> Use constant-time comparison
	if not secureCompare(expectedPadding, actualPadding) then
		return nil, "Invalid padding: incorrect padding bytes"
	end

	local result = {}
	for i = 1, #data - padLen do
		result[i] = data[i]
	end

	return result, nil
end

-->> Generate cryptographically secure random bytes
local function generateSecureRandom(length)
	local bytes = {}
	local rng = Random.new()

	for i = 1, length do
		bytes[i] = rng:NextInteger(0, 255)
	end

	return bytes
end

-->> ========================================
-->> SHA256 IMPLEMENTATION
-->> ========================================

local SHA256 = {}

-->> SHA256 constants
local SHA256_K = {
	0x428a2f98,
	0x71374491,
	0xb5c0fbcf,
	0xe9b5dba5,
	0x3956c25b,
	0x59f111f1,
	0x923f82a4,
	0xab1c5ed5,
	0xd807aa98,
	0x12835b01,
	0x243185be,
	0x550c7dc3,
	0x72be5d74,
	0x80deb1fe,
	0x9bdc06a7,
	0xc19bf174,
	0xe49b69c1,
	0xefbe4786,
	0x0fc19dc6,
	0x240ca1cc,
	0x2de92c6f,
	0x4a7484aa,
	0x5cb0a9dc,
	0x76f988da,
	0x983e5152,
	0xa831c66d,
	0xb00327c8,
	0xbf597fc7,
	0xc6e00bf3,
	0xd5a79147,
	0x06ca6351,
	0x14292967,
	0x27b70a85,
	0x2e1b2138,
	0x4d2c6dfc,
	0x53380d13,
	0x650a7354,
	0x766a0abb,
	0x81c2c92e,
	0x92722c85,
	0xa2bfe8a1,
	0xa81a664b,
	0xc24b8b70,
	0xc76c51a3,
	0xd192e819,
	0xd6990624,
	0xf40e3585,
	0x106aa070,
	0x19a4c116,
	0x1e376c08,
	0x2748774c,
	0x34b0bcb5,
	0x391c0cb3,
	0x4ed8aa4a,
	0x5b9cca4f,
	0x682e6ff3,
	0x748f82ee,
	0x78a5636f,
	0x84c87814,
	0x8cc70208,
	0x90befffa,
	0xa4506ceb,
	0xbef9a3f7,
	0xc67178f2,
}

-->> SHA256 initial hash values
local SHA256_H0 = {
	0x6a09e667,
	0xbb67ae85,
	0x3c6ef372,
	0xa54ff53a,
	0x510e527f,
	0x9b05688c,
	0x1f83d9ab,
	0x5be0cd19,
}

-->> Right rotate 32-bit
local function rotr32(n, b)
	return bit32.bor(bit32.rshift(n, b), bit32.lshift(n, 32 - b))
end

-->> SHA256 message schedule
local function sha256Schedule(chunk)
	local w = {}

	-->> Copy chunk into first 16 words
	for i = 1, 16 do
		local base = (i - 1) * 4 + 1
		w[i] = bit32.bor(
			bit32.lshift(chunk[base], 24),
			bit32.lshift(chunk[base + 1], 16),
			bit32.lshift(chunk[base + 2], 8),
			chunk[base + 3]
		)
	end

	-->> Extend to 64 words
	for i = 17, 64 do
		local w15 = w[i - 15]
		local w2 = w[i - 2]

		local s0 = bit32.bxor(rotr32(w15, 7), rotr32(w15, 18), bit32.rshift(w15, 3))
		local s1 = bit32.bxor(rotr32(w2, 17), rotr32(w2, 19), bit32.rshift(w2, 10))

		w[i] = (w[i - 16] + s0 + w[i - 7] + s1) % (2 ^ 32)
	end

	return w
end

-->> SHA256 compression function
local function sha256Compress(hashState, w)
	local a, b, c, d, e, f, g, h =
		hashState[1], hashState[2], hashState[3], hashState[4], hashState[5], hashState[6], hashState[7], hashState[8]

	for i = 1, 64 do
		local s1 = bit32.bxor(rotr32(e, 6), rotr32(e, 11), rotr32(e, 25))
		local ch = bit32.bxor(bit32.band(e, f), bit32.band(bit32.bnot(e), g))
		local temp1 = (h + s1 + ch + SHA256_K[i] + w[i]) % (2 ^ 32)

		local s0 = bit32.bxor(rotr32(a, 2), rotr32(a, 13), rotr32(a, 22))
		local maj = bit32.bxor(bit32.band(a, b), bit32.band(a, c), bit32.band(b, c))
		local temp2 = (s0 + maj) % (2 ^ 32)

		h = g
		g = f
		f = e
		e = (d + temp1) % (2 ^ 32)
		d = c
		c = b
		b = a
		a = (temp1 + temp2) % (2 ^ 32)
	end

	return {
		(hashState[1] + a) % (2 ^ 32),
		(hashState[2] + b) % (2 ^ 32),
		(hashState[3] + c) % (2 ^ 32),
		(hashState[4] + d) % (2 ^ 32),
		(hashState[5] + e) % (2 ^ 32),
		(hashState[6] + f) % (2 ^ 32),
		(hashState[7] + g) % (2 ^ 32),
		(hashState[8] + h) % (2 ^ 32),
	}
end

-->> SHA256 main function
function SHA256.hash(data)
	local h = { table.unpack(SHA256_H0) }

	-->> Pre-processing: adding padding
	local paddedData = { table.unpack(data) }
	local originalBitLen = #data * 8

	-->> Append the '1' bit (0x80)
	table.insert(paddedData, 0x80)

	-->> Append zeros until message length ≡ 448 (mod 512)
	while (#paddedData % 64) ~= 56 do
		table.insert(paddedData, 0x00)
	end

	-->> Append original length as 64-bit big-endian
	for i = 7, 0, -1 do
		table.insert(paddedData, bit32.band(bit32.rshift(originalBitLen, i * 8), 0xFF))
	end

	-->> Process message in 512-bit chunks
	for chunkStart = 1, #paddedData, 64 do
		local chunk = {}
		for i = 1, 64 do
			chunk[i] = paddedData[chunkStart + i - 1]
		end

		local w = sha256Schedule(chunk)
		h = sha256Compress(h, w)
	end

	-->> Convert hash to bytes
	local result = {}
	for i = 1, 8 do
		local word = h[i]
		for j = 3, 0, -1 do
			table.insert(result, bit32.band(bit32.rshift(word, j * 8), 0xFF))
		end
	end

	return result
end

-->> ========================================
-->> AES IMPLEMENTATION
-->> ========================================

local AES = {}

-->> AES S-box
local SBOX = {
	0x63,
	0x7c,
	0x77,
	0x7b,
	0xf2,
	0x6b,
	0x6f,
	0xc5,
	0x30,
	0x01,
	0x67,
	0x2b,
	0xfe,
	0xd7,
	0xab,
	0x76,
	0xca,
	0x82,
	0xc9,
	0x7d,
	0xfa,
	0x59,
	0x47,
	0xf0,
	0xad,
	0xd4,
	0xa2,
	0xaf,
	0x9c,
	0xa4,
	0x72,
	0xc0,
	0xb7,
	0xfd,
	0x93,
	0x26,
	0x36,
	0x3f,
	0xf7,
	0xcc,
	0x34,
	0xa5,
	0xe5,
	0xf1,
	0x71,
	0xd8,
	0x31,
	0x15,
	0x04,
	0xc7,
	0x23,
	0xc3,
	0x18,
	0x96,
	0x05,
	0x9a,
	0x07,
	0x12,
	0x80,
	0xe2,
	0xeb,
	0x27,
	0xb2,
	0x75,
	0x09,
	0x83,
	0x2c,
	0x1a,
	0x1b,
	0x6e,
	0x5a,
	0xa0,
	0x52,
	0x3b,
	0xd6,
	0xb3,
	0x29,
	0xe3,
	0x2f,
	0x84,
	0x53,
	0xd1,
	0x00,
	0xed,
	0x20,
	0xfc,
	0xb1,
	0x5b,
	0x6a,
	0xcb,
	0xbe,
	0x39,
	0x4a,
	0x4c,
	0x58,
	0xcf,
	0xd0,
	0xef,
	0xaa,
	0xfb,
	0x43,
	0x4d,
	0x33,
	0x85,
	0x45,
	0xf9,
	0x02,
	0x7f,
	0x50,
	0x3c,
	0x9f,
	0xa8,
	0x51,
	0xa3,
	0x40,
	0x8f,
	0x92,
	0x9d,
	0x38,
	0xf5,
	0xbc,
	0xb6,
	0xda,
	0x21,
	0x10,
	0xff,
	0xf3,
	0xd2,
	0xcd,
	0x0c,
	0x13,
	0xec,
	0x5f,
	0x97,
	0x44,
	0x17,
	0xc4,
	0xa7,
	0x7e,
	0x3d,
	0x64,
	0x5d,
	0x19,
	0x73,
	0x60,
	0x81,
	0x4f,
	0xdc,
	0x22,
	0x2a,
	0x90,
	0x88,
	0x46,
	0xee,
	0xb8,
	0x14,
	0xde,
	0x5e,
	0x0b,
	0xdb,
	0xe0,
	0x32,
	0x3a,
	0x0a,
	0x49,
	0x06,
	0x24,
	0x5c,
	0xc2,
	0xd3,
	0xac,
	0x62,
	0x91,
	0x95,
	0xe4,
	0x79,
	0xe7,
	0xc8,
	0x37,
	0x6d,
	0x8d,
	0xd5,
	0x4e,
	0xa9,
	0x6c,
	0x56,
	0xf4,
	0xea,
	0x65,
	0x7a,
	0xae,
	0x08,
	0xba,
	0x78,
	0x25,
	0x2e,
	0x1c,
	0xa6,
	0xb4,
	0xc6,
	0xe8,
	0xdd,
	0x74,
	0x1f,
	0x4b,
	0xbd,
	0x8b,
	0x8a,
	0x70,
	0x3e,
	0xb5,
	0x66,
	0x48,
	0x03,
	0xf6,
	0x0e,
	0x61,
	0x35,
	0x57,
	0xb9,
	0x86,
	0xc1,
	0x1d,
	0x9e,
	0xe1,
	0xf8,
	0x98,
	0x11,
	0x69,
	0xd9,
	0x8e,
	0x94,
	0x9b,
	0x1e,
	0x87,
	0xe9,
	0xce,
	0x55,
	0x28,
	0xdf,
	0x8c,
	0xa1,
	0x89,
	0x0d,
	0xbf,
	0xe6,
	0x42,
	0x68,
	0x41,
	0x99,
	0x2d,
	0x0f,
	0xb0,
	0x54,
	0xbb,
	0x16,
}

-->> AES Inverse S-box
local INV_SBOX = {
	0x52,
	0x09,
	0x6a,
	0xd5,
	0x30,
	0x36,
	0xa5,
	0x38,
	0xbf,
	0x40,
	0xa3,
	0x9e,
	0x81,
	0xf3,
	0xd7,
	0xfb,
	0x7c,
	0xe3,
	0x39,
	0x82,
	0x9b,
	0x2f,
	0xff,
	0x87,
	0x34,
	0x8e,
	0x43,
	0x44,
	0xc4,
	0xde,
	0xe9,
	0xcb,
	0x54,
	0x7b,
	0x94,
	0x32,
	0xa6,
	0xc2,
	0x23,
	0x3d,
	0xee,
	0x4c,
	0x95,
	0x0b,
	0x42,
	0xfa,
	0xc3,
	0x4e,
	0x08,
	0x2e,
	0xa1,
	0x66,
	0x28,
	0xd9,
	0x24,
	0xb2,
	0x76,
	0x5b,
	0xa2,
	0x49,
	0x6d,
	0x8b,
	0xd1,
	0x25,
	0x72,
	0xf8,
	0xf6,
	0x64,
	0x86,
	0x68,
	0x98,
	0x16,
	0xd4,
	0xa4,
	0x5c,
	0xcc,
	0x5d,
	0x65,
	0xb6,
	0x92,
	0x6c,
	0x70,
	0x48,
	0x50,
	0xfd,
	0xed,
	0xb9,
	0xda,
	0x5e,
	0x15,
	0x46,
	0x57,
	0xa7,
	0x8d,
	0x9d,
	0x84,
	0x90,
	0xd8,
	0xab,
	0x00,
	0x8c,
	0xbc,
	0xd3,
	0x0a,
	0xf7,
	0xe4,
	0x58,
	0x05,
	0xb8,
	0xb3,
	0x45,
	0x06,
	0xd0,
	0x2c,
	0x1e,
	0x8f,
	0xca,
	0x3f,
	0x0f,
	0x02,
	0xc1,
	0xaf,
	0xbd,
	0x03,
	0x01,
	0x13,
	0x8a,
	0x6b,
	0x3a,
	0x91,
	0x11,
	0x41,
	0x4f,
	0x67,
	0xdc,
	0xea,
	0x97,
	0xf2,
	0xcf,
	0xce,
	0xf0,
	0xb4,
	0xe6,
	0x73,
	0x96,
	0xac,
	0x74,
	0x22,
	0xe7,
	0xad,
	0x35,
	0x85,
	0xe2,
	0xf9,
	0x37,
	0xe8,
	0x1c,
	0x75,
	0xdf,
	0x6e,
	0x47,
	0xf1,
	0x1a,
	0x71,
	0x1d,
	0x29,
	0xc5,
	0x89,
	0x6f,
	0xb7,
	0x62,
	0x0e,
	0xaa,
	0x18,
	0xbe,
	0x1b,
	0xfc,
	0x56,
	0x3e,
	0x4b,
	0xc6,
	0xd2,
	0x79,
	0x20,
	0x9a,
	0xdb,
	0xc0,
	0xfe,
	0x78,
	0xcd,
	0x5a,
	0xf4,
	0x1f,
	0xdd,
	0xa8,
	0x33,
	0x88,
	0x07,
	0xc7,
	0x31,
	0xb1,
	0x12,
	0x10,
	0x59,
	0x27,
	0x80,
	0xec,
	0x5f,
	0x60,
	0x51,
	0x7f,
	0xa9,
	0x19,
	0xb5,
	0x4a,
	0x0d,
	0x2d,
	0xe5,
	0x7a,
	0x9f,
	0x93,
	0xc9,
	0x9c,
	0xef,
	0xa0,
	0xe0,
	0x3b,
	0x4d,
	0xae,
	0x2a,
	0xf5,
	0xb0,
	0xc8,
	0xeb,
	0xbb,
	0x3c,
	0x83,
	0x53,
	0x99,
	0x61,
	0x17,
	0x2b,
	0x04,
	0x7e,
	0xba,
	0x77,
	0xd6,
	0x26,
	0xe1,
	0x69,
	0x14,
	0x63,
	0x55,
	0x21,
	0x0c,
	0x7d,
}

-->> Galois field multiplication
local function gmul(a, b)
	local p = 0
	for i = 0, 7 do
		if bit32.band(b, 1) ~= 0 then
			p = bit32.bxor(p, a)
		end
		local hi_bit_set = bit32.band(a, 0x80) ~= 0
		a = bit32.band(bit32.lshift(a, 1), 0xFF)
		if hi_bit_set then
			a = bit32.bxor(a, 0x1B)
		end
		b = bit32.rshift(b, 1)
	end
	return p
end

-->> Key expansion for AES-256
local function expandKey(key)
	local expandedKey = {}
	local nk = 8 --// AES-256 uses 8 32-bit words
	local nr = 14 --// AES-256 uses 14 rounds

	-->> Copy original key
	for i = 1, nk do
		local word = {}
		local base = (i - 1) * 4 + 1
		for j = 1, 4 do
			word[j] = key[base + j - 1]
		end
		expandedKey[i] = word
	end

	-->> Generate remaining words
	for i = nk + 1, (nr + 1) * 4 do
		local temp = { table.unpack(expandedKey[i - 1]) }

		if i % nk == 1 then
			-->> RotWord and SubBytes
			local temp_0 = temp[1]
			temp[1] = SBOX[temp[2] + 1]
			temp[2] = SBOX[temp[3] + 1]
			temp[3] = SBOX[temp[4] + 1]
			temp[4] = SBOX[temp_0 + 1]

			-->> Rcon
			local rcon = 1
			for j = 1, (i - 1) // nk - 1 do
				rcon = gmul(rcon, 2)
			end
			temp[1] = bit32.bxor(temp[1], rcon)
		elseif nk > 6 and i % nk == 5 then
			-->> SubBytes for AES-256
			for j = 1, 4 do
				temp[j] = SBOX[temp[j] + 1]
			end
		end

		local word = {}
		for j = 1, 4 do
			word[j] = bit32.bxor(expandedKey[i - nk][j], temp[j])
		end
		expandedKey[i] = word
	end

	return expandedKey
end

-->> SubBytes transformation
local function subBytes(state, inverse)
	local box = inverse and INV_SBOX or SBOX
	local newState = {}
	for i = 1, 4 do
		newState[i] = {}
		for j = 1, 4 do
			newState[i][j] = box[state[i][j] + 1]
		end
	end
	return newState
end

-->> ShiftRows transformation
local function shiftRows(state, inverse)
	local newState = {
		{ state[1][1], state[1][2], state[1][3], state[1][4] },
		{ state[2][1], state[2][2], state[2][3], state[2][4] },
		{ state[3][1], state[3][2], state[3][3], state[3][4] },
		{ state[4][1], state[4][2], state[4][3], state[4][4] },
	}

	if inverse then
		-->> Inverse shift rows (right)
		newState[2] = { state[2][4], state[2][1], state[2][2], state[2][3] }
		newState[3] = { state[3][3], state[3][4], state[3][1], state[3][2] }
		newState[4] = { state[4][2], state[4][3], state[4][4], state[4][1] }
	else
		-->> Normal shift rows (left)
		newState[2] = { state[2][2], state[2][3], state[2][4], state[2][1] }
		newState[3] = { state[3][3], state[3][4], state[3][1], state[3][2] }
		newState[4] = { state[4][4], state[4][1], state[4][2], state[4][3] }
	end

	return newState
end

-->> MixColumns transformation
local function mixColumns(state, inverse)
	local newState = { {}, {}, {}, {} }

	for c = 1, 4 do
		if inverse then
			newState[1][c] =
				bit32.bxor(gmul(state[1][c], 14), gmul(state[2][c], 11), gmul(state[3][c], 13), gmul(state[4][c], 9))
			newState[2][c] =
				bit32.bxor(gmul(state[1][c], 9), gmul(state[2][c], 14), gmul(state[3][c], 11), gmul(state[4][c], 13))
			newState[3][c] =
				bit32.bxor(gmul(state[1][c], 13), gmul(state[2][c], 9), gmul(state[3][c], 14), gmul(state[4][c], 11))
			newState[4][c] =
				bit32.bxor(gmul(state[1][c], 11), gmul(state[2][c], 13), gmul(state[3][c], 9), gmul(state[4][c], 14))
		else
			newState[1][c] = bit32.bxor(gmul(state[1][c], 2), gmul(state[2][c], 3), state[3][c], state[4][c])
			newState[2][c] = bit32.bxor(state[1][c], gmul(state[2][c], 2), gmul(state[3][c], 3), state[4][c])
			newState[3][c] = bit32.bxor(state[1][c], state[2][c], gmul(state[3][c], 2), gmul(state[4][c], 3))
			newState[4][c] = bit32.bxor(gmul(state[1][c], 3), state[2][c], state[3][c], gmul(state[4][c], 2))
		end
	end

	return newState
end

-->> AddRoundKey transformation
local function addRoundKey(state, roundKey)
	local newState = {}
	for i = 1, 4 do
		newState[i] = {}
		for j = 1, 4 do
			newState[i][j] = bit32.bxor(state[i][j], roundKey[i][j])
		end
	end
	return newState
end

-->> Convert bytes to state matrix
local function bytesToState(bytes)
	local state = { {}, {}, {}, {} }
	for i = 1, 4 do
		for j = 1, 4 do
			state[j][i] = bytes[(i - 1) * 4 + j]
		end
	end
	return state
end

-->> Convert state matrix to bytes
local function stateToBytes(state)
	local bytes = {}
	for i = 1, 4 do
		for j = 1, 4 do
			bytes[(i - 1) * 4 + j] = state[j][i]
		end
	end
	return bytes
end

-->> Extract round key from expanded key
local function getRoundKey(expandedKey, round)
	local roundKey = { {}, {}, {}, {} }
	local start = round * 4 + 1

	for i = 1, 4 do
		for j = 1, 4 do
			roundKey[j][i] = expandedKey[start + i - 1][j]
		end
	end

	return roundKey
end

-->> AES block encryption
local function encryptBlock(block, expandedKey)
	local state = bytesToState(block)

	-->> Initial round
	state = addRoundKey(state, getRoundKey(expandedKey, 0))

	-->> Main rounds
	for round = 1, 13 do
		state = subBytes(state)
		state = shiftRows(state)
		state = mixColumns(state)
		state = addRoundKey(state, getRoundKey(expandedKey, round))
	end

	-->> Final round (no MixColumns)
	state = subBytes(state)
	state = shiftRows(state)
	state = addRoundKey(state, getRoundKey(expandedKey, 14))

	return stateToBytes(state)
end

-->> AES block decryption
local function decryptBlock(block, expandedKey)
	local state = bytesToState(block)

	-->> Initial round
	state = addRoundKey(state, getRoundKey(expandedKey, 14))

	-->> Main rounds (reverse order)
	for round = 13, 1, -1 do
		state = shiftRows(state, true)
		state = subBytes(state, true)
		state = addRoundKey(state, getRoundKey(expandedKey, round))
		state = mixColumns(state, true)
	end

	-->> Final round (no MixColumns)
	state = shiftRows(state, true)
	state = subBytes(state, true)
	state = addRoundKey(state, getRoundKey(expandedKey, 0))

	return stateToBytes(state)
end

-->> AES-256-CBC encryption
function AES.encrypt(plaintext, key, iv)
	if #key ~= 32 then
		return nil, "Key must be exactly 32 bytes for AES-256"
	end

	if #iv ~= 16 then
		return nil, "IV must be exactly 16 bytes"
	end

	local plaintextBytes = type(plaintext) == "string" and stringToBytes(plaintext) or plaintext
	local paddedData = addPadding(plaintextBytes, 16)
	local expandedKey = expandKey(key)
	local ciphertext = {}
	local prevBlock = iv

	-->> Process each block
	for i = 1, #paddedData, 16 do
		local block = {}
		for j = 1, 16 do
			block[j] = paddedData[i + j - 1]
		end

		-->> XOR with previous ciphertext block (CBC mode)
		block = xorBytes(block, prevBlock)

		-->> Encrypt block
		local encryptedBlock = encryptBlock(block, expandedKey)

		-->> Add to ciphertext
		for j = 1, 16 do
			table.insert(ciphertext, encryptedBlock[j])
		end

		prevBlock = encryptedBlock
	end

	return ciphertext, nil
end

-->> AES-256-CBC decryption
function AES.decrypt(ciphertext, key, iv)
	if #key ~= 32 then
		return nil, "Key must be exactly 32 bytes for AES-256"
	end

	if #iv ~= 16 then
		return nil, "IV must be exactly 16 bytes"
	end

	if #ciphertext % 16 ~= 0 then
		return nil, "Ciphertext length must be multiple of 16 bytes"
	end

	local ciphertextBytes = type(ciphertext) == "string" and stringToBytes(ciphertext) or ciphertext
	local expandedKey = expandKey(key)
	local plaintext = {}
	local prevBlock = iv

	-->> Process each block
	for i = 1, #ciphertextBytes, 16 do
		local block = {}
		for j = 1, 16 do
			block[j] = ciphertextBytes[i + j - 1]
		end

		-->> Decrypt block
		local decryptedBlock = decryptBlock(block, expandedKey)

		-->> XOR with previous ciphertext block (CBC mode)
		decryptedBlock = xorBytes(decryptedBlock, prevBlock)

		-->> Add to plaintext
		for j = 1, 16 do
			table.insert(plaintext, decryptedBlock[j])
		end

		prevBlock = block
	end

	-->> Remove padding
	local unpaddedData, paddingError = removePadding(plaintext)
	if paddingError then
		return nil, paddingError
	end

	return unpaddedData, nil
end

-->> ========================================
-->> PUBLIC API
-->> ========================================

-->> Generate a secure random key for AES-256
function CryptoModule.generateAESKey()
	return generateSecureRandom(32)
end

-->> Generate a secure random IV for AES
function CryptoModule.generateIV()
	return generateSecureRandom(16)
end

-->> SHA256 hash function
function CryptoModule.sha256(data)
	local inputBytes = type(data) == "string" and stringToBytes(data) or data
	return SHA256.hash(inputBytes)
end

-->> SHA256 hash function returning hex string
function CryptoModule.sha256Hex(data)
	local hash = CryptoModule.sha256(data)
	local hexChars = {}
	for i = 1, #hash do
		hexChars[i] = string.format("%02x", hash[i])
	end
	return table.concat(hexChars)
end

-->> AES-256-CBC encryption with auto-generated IV
function CryptoModule.aesEncrypt(plaintext, key, iv)
	local keyBytes = type(key) == "string" and stringToBytes(key) or key
	local ivBytes = iv and (type(iv) == "string" and stringToBytes(iv) or iv) or CryptoModule.generateIV()

	local ciphertext, err = AES.encrypt(plaintext, keyBytes, ivBytes)
	if err then
		return nil, nil, err
	end

	return ciphertext, ivBytes, nil
end

-->> AES-256-CBC decryption
function CryptoModule.aesDecrypt(ciphertext, key, iv)
	local keyBytes = type(key) == "string" and stringToBytes(key) or key
	local ivBytes = type(iv) == "string" and stringToBytes(iv) or iv

	return AES.decrypt(ciphertext, keyBytes, ivBytes)
end

-->> Convert byte array to hex string
function CryptoModule.bytesToHex(bytes)
	local hexChars = {}
	for i = 1, #bytes do
		hexChars[i] = string.format("%02x", bytes[i])
	end
	return table.concat(hexChars)
end

-->> Convert hex string to byte array
function CryptoModule.hexToBytes(hex)
	if #hex % 2 ~= 0 then
		return nil, "Hex string must have even length"
	end

	local bytes = {}
	for i = 1, #hex, 2 do
		local byte = tonumber(hex:sub(i, i + 1), 16)
		if not byte then
			return nil, "Invalid hex character"
		end
		table.insert(bytes, byte)
	end
	return bytes, nil
end

-->> Convert byte array to Base64 string
function CryptoModule.bytesToBase64(bytes)
	local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local result = {}

	for i = 1, #bytes, 3 do
		local b1, b2, b3 = bytes[i], bytes[i + 1] or 0, bytes[i + 2] or 0
		local bitmap = bit32.bor(bit32.lshift(b1, 16), bit32.lshift(b2, 8), b3)

		for j = 1, 4 do
			local idx = bit32.band(bit32.rshift(bitmap, 18 - (j - 1) * 6), 0x3F) + 1
			table.insert(result, b64chars:sub(idx, idx))
		end
	end

	-->> Add padding
	local padding = #bytes % 3
	if padding == 1 then
		result[#result] = "="
		result[#result - 1] = "="
	elseif padding == 2 then
		result[#result] = "="
	end

	return table.concat(result)
end

-->> Convert Base64 string to byte array
function CryptoModule.base64ToBytes(b64)
	local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local decode = {}
	for i = 1, #b64chars do
		decode[b64chars:sub(i, i)] = i - 1
	end

	local result = {}
	local padding = 0

	-->> Remove padding and count it
	b64 = b64:gsub("=", function()
		padding = padding + 1
		return ""
	end)

	for i = 1, #b64, 4 do
		local c1 = decode[b64:sub(i, i)] or 0
		local c2 = decode[b64:sub(i + 1, i + 1)] or 0
		local c3 = decode[b64:sub(i + 2, i + 2)] or 0
		local c4 = decode[b64:sub(i + 3, i + 3)] or 0

		local bitmap = bit32.bor(bit32.lshift(c1, 18), bit32.lshift(c2, 12), bit32.lshift(c3, 6), c4)

		table.insert(result, bit32.band(bit32.rshift(bitmap, 16), 0xFF))
		if i + 2 <= #b64 then
			table.insert(result, bit32.band(bit32.rshift(bitmap, 8), 0xFF))
		end
		if i + 3 <= #b64 then
			table.insert(result, bit32.band(bitmap, 0xFF))
		end
	end

	-->> Remove bytes added by padding
	for i = 1, padding do
		table.remove(result)
	end

	return result
end

-->> Utility functions for string conversion
CryptoModule.stringToBytes = stringToBytes
CryptoModule.bytesToString = bytesToString

-->> High-level encryption function with all parameters handled
function CryptoModule.encryptString(plaintext, password)
	-->> Derive key from password using SHA256
	local key = CryptoModule.sha256(password)

	-->> Encrypt with auto-generated IV
	local ciphertext, iv, err = CryptoModule.aesEncrypt(plaintext, key)
	if err then
		return nil, err
	end

	-->> Combine IV and ciphertext
	local combined = {}
	for i = 1, #iv do
		table.insert(combined, iv[i])
	end
	for i = 1, #ciphertext do
		table.insert(combined, ciphertext[i])
	end

	-->> Return as Base64
	return CryptoModule.bytesToBase64(combined), nil
end

-->> High-level decryption function
function CryptoModule.decryptString(encryptedData, password)
	-->> Decode from Base64
	local combined = CryptoModule.base64ToBytes(encryptedData)

	-->> Extract IV and ciphertext
	local iv = {}
	local ciphertext = {}

	for i = 1, 16 do
		iv[i] = combined[i]
	end
	for i = 17, #combined do
		table.insert(ciphertext, combined[i])
	end

	-->> Derive key from password
	local key = CryptoModule.sha256(password)

	-->> Decrypt
	local plaintext, err = CryptoModule.aesDecrypt(ciphertext, key, iv)
	if err then
		return nil, err
	end

	return CryptoModule.bytesToString(plaintext), nil
end

-->> HMAC-SHA256 for message authentication
function CryptoModule.hmacSha256(key, message)
	local keyBytes = type(key) == "string" and stringToBytes(key) or key
	local messageBytes = type(message) == "string" and stringToBytes(message) or message

	-->> Adjust key length
	if #keyBytes > 64 then
		keyBytes = CryptoModule.sha256(keyBytes)
	end
	while #keyBytes < 64 do
		table.insert(keyBytes, 0)
	end

	-->> Create inner and outer padding
	local innerPad = {}
	local outerPad = {}
	for i = 1, 64 do
		innerPad[i] = bit32.bxor(keyBytes[i], 0x36)
		outerPad[i] = bit32.bxor(keyBytes[i], 0x5C)
	end

	-->> Inner hash
	local innerData = {}
	for i = 1, #innerPad do
		table.insert(innerData, innerPad[i])
	end
	for i = 1, #messageBytes do
		table.insert(innerData, messageBytes[i])
	end
	local innerHash = CryptoModule.sha256(innerData)

	-->> Outer hash
	local outerData = {}
	for i = 1, #outerPad do
		table.insert(outerData, outerPad[i])
	end
	for i = 1, #innerHash do
		table.insert(outerData, innerHash[i])
	end

	return CryptoModule.sha256(outerData)
end

return CryptoModule
