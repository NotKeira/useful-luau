# Useful Luau

A collection of useful luau modules and files for your projects. This repository contains well-documented, from-scratch implementations of commonly needed functionality.

## 📋 Modules

### 🔐 [Cryptographic](src/Cryptographic/)

A comprehensive cryptographic library implementing enterprise-grade encryption and hashing algorithms.

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

### 🗄️ [Database](src/Database/)
A comprehensive in-memory & DataStoreService database system with persistence, indexing, and advanced querying capabilities.

**Features:**
- CRUD Operations with Advanced Querying
- Schema Validation & Type Checking
- Indexing System for Performance
- Transaction Support with Rollback
- DataStore Integration (Roblox)
- Aggregation Functions
- MongoDB-style Query Operators
- Backup/Restore Capabilities

**Quick Example:**
```luau
local DB = require(path.to.Database)

-- Create database with persistence
local database = DB.createDatabase("GameData", {
    useDataStore = true,
    autoSave = true
})

-- Define schema and create table
local Schema = DB.Schema()
local userSchema = {
    username = Schema.string({ required = true, maxLength = 20 }),
    level = Schema.number({ min = 1, max = 100 }),
    coins = Schema.number({ min = 0 })
}

database:createTable("users", userSchema)
local users = database:getTable("users")

-- CRUD operations
local user = users:insert({ username = "Player1", level = 5, coins = 1000 })
local highLevel = users:find({ level = { ["$gte"] = 10 } })
users:update({ username = "Player1" }, { coins = 1500 })
```

📖 **[Full Documentation](src/Database/README.md)**

## 👤 Authors
**Keira Hopkins**
- GitHub: [@NotKeira](https://github.com/NotKeira)

## 🔮 Future Modules
This repository will grow with more useful Luau modules. Potential additions:

- Data structures (trees, graphs, queues)
- Utility libraries (string manipulation, math helpers)
- Network utilities
- File system helpers
- Authentication systems
- Configuration management
- Logging frameworks
- And more!

## 🤝 Contributing
This is a collection of useful utilities. Feel free to:

- Report bugs or security issues
- Suggest new modules to add
- Submit improvements or optimisations
- Add more utility functions

## 📜 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
