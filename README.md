# Useful Luau
A collection of useful luau modules and files for your projects. This repository contains well-documented, from-scratch implementations of commonly needed functionality.

## 📋 Modules

### 🔐 [Cryptographic](src/Cryptographic/)
A comprehensive cryptographic library implementing enterprise-grade encryption and hashing algorithms built entirely from scratch in Luau.

**Features:**
- AES-256-CBC Encryption/Decryption
- SHA256 Hashing
- HMAC-SHA256 Message Authentication
- Secure Random Generation
- High-level and Low-level APIs
- Utility Functions (Hex/Base64 encoding)

**Quick Example:**
```luau
local Crypto = require(path.to.Cryptographic)

-- Simple encryption
local encrypted, err = Crypto.encryptString("Hello, World!", "password123")
local decrypted, err2 = Crypto.decryptString(encrypted, "password123")

-- SHA256 hashing
local hash = Crypto.sha256Hex("hello world")
```
📖 **[Full Documentation](src/Cryptographic/README.md)**


## 👤 Authors
**Keira Hopkins**
- GitHub: [@NotKeira](https://github.com/NotKeira)

## 🔮 Future Modules
This repository will grow with more useful Luau modules. Potential additions:
- Data structures (trees, graphs, queues)
- Utility libraries (string manipulation, math helpers)
- Network utilities
- File system helpers
- And more!

## 🤝 Contributing
This is a collection of useful utilities. Feel free to:
- Report bugs or security issues
- Suggest new modules to add
- Submit improvements or optimisations
- Add more utility functions

## 📜 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
