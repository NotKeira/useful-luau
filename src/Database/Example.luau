-->> Database Module Demonstrations
-->> Extends DatabaseModule
-->> Displays:
--[[
- Database Creation (in-memory and DataStore persistence)
- Schema Validation (type checking, constraints, required fields)
- CRUD Operations (Create, Read, Update, Delete with advanced querying)
- Indexing (fast lookups and performance optimization)
- Transactions (atomic operations with rollback support)
- Aggregation (count, sum, average, min/max operations)
- DataStore Integration (automatic persistence with retry logic)
]]
-->> Built from scratch, no externals.
-->> Author: Keira Hopkins (github.com/NotKeira)
-->> Copyrighted and Licensed under the MIT License

local DB = require(script.Parent.DatabaseModule)
local Schema = DB.Schema()

-->> ========================================
-->> DATABASE CREATION DEMONSTRATION
-->> ========================================

print("=== Database Creation Demo ===")

-- Create in-memory database
local memoryDB = DB.createDatabase("MemoryExample")
print("Created in-memory database:", memoryDB.name)

-- Create database with DataStore persistence (server only)
local gameDB = DB.createDatabase("GameData", {
	useDataStore = true,
	storeName = "PlayerData_v1",
	autoSave = true,
	saveInterval = 30,
	loadOnStart = true,
})
print("Created persistent database:", gameDB.name)
print("DataStore enabled:", gameDB.dataStore ~= nil)

-->> ========================================
-->> SCHEMA VALIDATION DEMONSTRATION
-->> ========================================

print("\n=== Schema Validation Demo ===")

-- Define player schema with constraints
local playerSchema = {
	username = Schema.string({ required = true, maxLength = 20 }),
	level = Schema.number({ required = true, min = 1, max = 100 }),
	coins = Schema.number({ min = 0 }),
	class = Schema.string({ enum = { "warrior", "mage", "archer" } }),
	isVIP = Schema.boolean(),
	inventory = Schema.table(),
}

-- Create table with schema
local success, err = gameDB:createTable("players", playerSchema)
if success then
	print("Created 'players' table with schema validation")
else
	print("Error creating table:", err)
end

local players = gameDB:getTable("players")

-- Test schema validation
print("\n--- Testing Schema Validation ---")

-- Valid player
local validPlayer = {
	username = "TestPlayer",
	level = 5,
	coins = 1000,
	class = "warrior",
	isVIP = false,
	inventory = { "sword", "potion" },
}

local player, insertErr = players:insert(validPlayer)
if insertErr then
	print("Failed to insert valid player:", insertErr)
else
	print("Successfully inserted player:", player.username)
	print("Player ID:", player.id)
	print("Created at:", os.date("%c", player._createdAt))
end

-- Invalid player (violates constraints)
local invalidPlayer = {
	username = "ThisUsernameIsTooLongToBeValid",
	level = 150, -- Exceeds max
	class = "ninja", -- Not in enum
	coins = -100, -- Below minimum
}

local _, invalidErr = players:insert(invalidPlayer)
print("Expected validation error:", invalidErr)

-->> ========================================
-->> INDEXING DEMONSTRATION
-->> ========================================

print("\n=== Indexing Demo ===")

-- Create indices for fast lookups
players:createIndex("username")
players:createIndex("level")
players:createIndex("class")
print("Created indices on username, level, and class")

-- Insert more test data
local testPlayers = {
	{ username = "Warrior1", level = 10, coins = 500, class = "warrior", isVIP = false },
	{ username = "Mage1", level = 15, coins = 1200, class = "mage", isVIP = true },
	{ username = "Archer1", level = 8, coins = 300, class = "archer", isVIP = false },
	{ username = "Warrior2", level = 25, coins = 2500, class = "warrior", isVIP = true },
}

for _, playerData in ipairs(testPlayers) do
	players:insert(playerData)
end

print("Inserted", #testPlayers + 1, "total players")

-->> ========================================
-->> CRUD OPERATIONS DEMONSTRATION
-->> ========================================

print("\n=== CRUD Operations Demo ===")

-- READ: Basic queries
print("\n--- Basic Queries ---")
local allPlayers = players:find()
print("Total players:", #allPlayers)

-- Find by exact match
local warriors = players:find({ class = "warrior" })
print("Warriors found:", #warriors)

-- Find with advanced operators
local highLevelPlayers = players:find({
	level = { ["$gte"] = 10 },
	coins = { ["$gt"] = 500 },
})
print("High level players with >500 coins:", #highLevelPlayers)

-- Find with regex (username contains "Warrior")
local warriorUsers = players:find({
	username = { ["$regex"] = "Warrior" },
})
print("Users with 'Warrior' in name:", #warriorUsers)

-- Find with multiple conditions and sorting
local sortedVIPs = players:find({ isVIP = true }, {
	sort = { field = "level", order = "desc" },
	limit = 2,
})
print("Top 2 VIP players by level:")
for _, player in ipairs(sortedVIPs) do
	print(`  {player.username}: Level {player.level}`)
end

-- UPDATE: Modify existing records
print("\n--- Update Operations ---")
local updateCount = players:update({ class = "warrior" }, { coins = 1500, isVIP = true })
print("Updated", updateCount, "warrior players")

-- UPDATE: Targeted update
players:update({ username = "TestPlayer" }, { level = 10, coins = 2000 })
print("Leveled up TestPlayer")

-- DELETE: Remove records
print("\n--- Delete Operations ---")
local deleteCount = players:delete({ level = { ["$lt"] = 10 } })
print("Deleted", deleteCount, "low level players")

-->> ========================================
-->> TRANSACTION DEMONSTRATION
-->> ========================================

print("\n=== Transaction Demo ===")

-- Start transaction for atomic operations
local tx = gameDB:beginTransaction()

print("Starting transaction...")
-- Transfer coins between players
local success1 = tx:update("players", { username = "Mage1" }, { coins = 1000 }) -- Remove 200 coins
local success2 = tx:update("players", { username = "Warrior2" }, { coins = 2700 }) -- Add 200 coins

if success1 and success2 then
	local commitSuccess = tx:commit()
	if commitSuccess then
		print("Transaction committed: Transferred 200 coins from Mage1 to Warrior2")
	else
		print("Failed to commit transaction")
	end
else
	tx:rollback()
	print("Transaction rolled back due to error")
end

-- Demonstrate rollback
print("\n--- Rollback Demo ---")
local tx2 = gameDB:beginTransaction()
tx2:update("players", { class = "mage" }, { level = 50 })
tx2:insert("players", { username = "TempPlayer", level = 1, class = "warrior" })
print("Made changes in transaction...")

tx2:rollback()
print("Transaction rolled back - changes undone")

-->> ========================================
-->> AGGREGATION DEMONSTRATION
-->> ========================================

print("\n=== Aggregation Demo ===")

-- Perform aggregation operations
local stats = players:aggregate({
	count = {},
	sum = { field = "coins" },
	avg = { field = "level" },
	min = { field = "level" },
	max = { field = "coins" },
})

print("Player Statistics:")
print("  Total players:", stats.count)
print("  Total coins:", stats.sum)
print("  Average level:", math.floor(stats.avg * 100) / 100)
print("  Minimum level:", stats.min)
print("  Maximum coins:", stats.max)

-- Count by class
local classCounts = {}
for _, class in ipairs({ "warrior", "mage", "archer" }) do
	classCounts[class] = players:count({ class = class })
end

print("\nPlayers by class:")
for class, count in pairs(classCounts) do
	print(`  {class}: {count}`)
end

-->> ========================================
-->> DATASTORE INTEGRATION DEMONSTRATION
-->> ========================================

print("\n=== DataStore Integration Demo ===")

-- Note: DataStore operations only work on the server
if game:GetService("RunService"):IsServer() then
	print("Running on server - DataStore operations available")

	-- Force save to DataStore
	local saveSuccess, saveErr = gameDB:forceSync()
	if saveSuccess then
		print("Successfully saved database to DataStore")
	else
		print("Failed to save to DataStore:", saveErr)
	end

	-- Save individual table
	local tableSaveSuccess, tableSaveErr = gameDB:saveTable("players")
	if tableSaveSuccess then
		print("Successfully saved players table to DataStore")
	else
		print("Failed to save players table:", tableSaveErr)
	end

	print("Auto-save is enabled - database will automatically persist changes")
else
	print("Running on client - DataStore operations not available")
	print("Database exists in memory only")
end

-->> ========================================
-->> PERFORMANCE DEMONSTRATION
-->> ========================================

print("\n=== Performance Demo ===")

-- Measure query performance with and without indices
local startTime = tick()

-- Query using index (fast)
local indexedResults = players:find({ username = "Mage1" })
local indexTime = tick() - startTime

print(`Indexed query (username): {#indexedResults} results in {math.floor(indexTime * 1000000)} microseconds`)

-- Query without index (slower for large datasets)
startTime = tick()
local nonIndexedResults = players:find({ coins = { ["$gte"] = 1000 } })
local nonIndexTime = tick() - startTime

print(`Non-indexed query (coins): {#nonIndexedResults} results in {math.floor(nonIndexTime * 1000000)} microseconds`)

-->> ========================================
-->> BACKUP/RESTORE DEMONSTRATION
-->> ========================================

print("\n=== Backup/Restore Demo ===")

-- Create backup
local backup = gameDB:backup()
print("Created database backup")
print("Backup contains", #gameDB:listTables(), "tables")

-- Simulate data loss and restore
local originalPlayerCount = players:count()
players:delete({}) -- Delete all players
print("Deleted all players. Count:", players:count())

-- Restore from backup
if gameDB.restore then
	local restoreSuccess, restoreErr = gameDB:restore(backup)
	if restoreSuccess then
		print("Successfully restored database from backup")
		-- Get the restored players table
		players = gameDB:getTable("players")
		print("Restored player count:", players:count())
		print("Data integrity verified:", players:count() == originalPlayerCount)
	else
		print("Failed to restore:", restoreErr)
	end
else
	print("Restore method not available on this database instance")
end

print("\n=== Database Demo Complete ===")
print("All features demonstrated successfully!")
