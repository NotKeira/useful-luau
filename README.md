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

### 🎯 [GuiClickOutside](src/GuiClickOutside/)

A comprehensive GUI interaction library for automatically closing Roblox ScreenGuis when clicking outside their bounds.

**Features:**

- Multiple Close Animations (8 built-in types)
- Custom Handler Support
- Type-Safe API with Full Luau Types
- Automatic Click Detection
- Multi-GUI Support
- Zero Configuration Required
- Performance Optimised

**Quick Example:**

```luau
local GuiClickOutside = require(path.to.GuiClickOutside)
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Register with animation
local storeGui = PlayerGui:WaitForChild("Store")
GuiClickOutside.register(storeGui, "animate_up")

-- Register with fade effect
local notificationGui = PlayerGui:WaitForChild("Notification")
GuiClickOutside.register(notificationGui, "fade_out")

-- Multiple GUIs
local guis = {
    {gui = PlayerGui:WaitForChild("Inventory"), closeType = "slide_right"},
    {gui = PlayerGui:WaitForChild("Map"), closeType = "fade_out"},
}

for _, data in ipairs(guis) do
    GuiClickOutside.register(data.gui, data.closeType)
end
```

📖 **[Full Documentation](src/GuiClickOutside/README.md)**

## 👤 Authors

**Keira Hopkins**

- GitHub: [@NotKeira](https://github.com/NotKeira)

## 🔮 Future Modules

This repository will grow with more useful Luau modules. Potential additions:

- Player data management (profiles, sessions, cross-server data)
- GUI frameworks (responsive layouts, animation systems, themes)
- Game mechanics (inventory systems, questing, achievements)
- Networking utilities (remote events, data validation, rate limiting)
- Economy systems (shops, trading, currency management)
- Chat & social features (filtering, friend systems, guilds)
- Analytics & telemetry (player behaviour tracking, A/B testing)
- Performance monitoring (memory usage, lag detection, optimisation)
- Audio management (music systems, sound pools, 3D audio)
- Anti-cheat & security (exploit detection, data validation)
- World generation (procedural terrain, dungeon generation)
- Save system utilities (DataStore wrappers, backup strategies)
- Localisation & translation systems
- Admin commands & moderation tools
- Monetisation helpers (developer products, game passes)
- And more!

## 🤝 Contributing

This is a collection of useful utilities. Feel free to:

- Report bugs or security issues
- Suggest new modules to add
- Submit improvements or optimisations
- Add more utility functions

## 📜 Licence

This project is licenced under the MIT Licence - see the [LICENCE](LICENCE) file for details.