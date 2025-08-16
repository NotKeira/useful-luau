# Database Module

A comprehensive in-memory & DataStoreService database system with persistence, indexing, and advanced querying capabilities.

## 🗄️ Features

- **CRUD Operations** - Create, Read, Update, Delete with advanced querying
- **Schema Validation** - Type checking, constraints, and required fields
- **Indexing System** - Fast lookups and performance optimisation
- **Transaction Support** - Atomic operations with rollback capability
- **DataStore Integration** - Automatic persistence with retry logic
- **Aggregation Functions** - Count, sum, average, min/max operations
- **Query Operators** - Advanced filtering with MongoDB-style operators
- **Backup/Restore** - Data integrity and recovery features

## 🚀 Quick Start

### Basic Database Creation

```luau
local DB = require(script.DatabaseModule)

-- Create in-memory database
local database = DB.createDatabase("MyApp")

-- Create database with DataStore persistence (server only)
local persistentDB = DB.createDatabase("GameData", {
    useDataStore = true,
    storeName = "PlayerData_v1",
    autoSave = true,
    saveInterval = 30
})
```

### Schema Definition and Table Creation

```luau
local Schema = DB.Schema()

-- Define schema with validation rules
local userSchema = {
    username = Schema.string({ required = true, maxLength = 20 }),
    level = Schema.number({ required = true, min = 1, max = 100 }),
    coins = Schema.number({ min = 0 }),
    class = Schema.string({ enum = { "warrior", "mage", "archer" } }),
    isVIP = Schema.boolean(),
    inventory = Schema.table()
}

-- Create table with schema
database:createTable("users", userSchema)
local users = database:getTable("users")
```

### Basic CRUD Operations

```luau
-- CREATE: Insert new record
local user, err = users:insert({
    username = "Player1",
    level = 5,
    coins = 1000,
    class = "warrior",
    isVIP = false,
    inventory = { "sword", "potion" }
})

-- READ: Find records
local allUsers = users:find()
local warriors = users:find({ class = "warrior" })
local highLevel = users:find({ level = { ["$gte"] = 10 } })

-- UPDATE: Modify records
local updateCount = users:update({ class = "warrior" }, { coins = 1500 })

-- DELETE: Remove records
local deleteCount = users:delete({ level = { ["$lt"] = 5 } })
```

## 📖 API Reference

### Database Operations

#### `createDatabase(name: string, options?: table) -> Database`

Creates a new database instance.

**Parameters:**

- `name` - Database name
- `options` - Configuration options
  - `useDataStore` - Enable DataStore persistence (server only)
  - `storeName` - DataStore name (default: database name)
  - `autoSave` - Enable automatic saving (default: true)
  - `saveInterval` - Auto-save interval in seconds (default: 30)
  - `loadOnStart` - Load existing data on creation (default: true)
  - `retryAttempts` - DataStore retry attempts (default: 3)
  - `retryDelay` - Delay between retries (default: 2)

#### `database:createTable(name: string, schema?: table) -> (boolean, string?)`

Creates a new table with optional schema validation.

#### `database:getTable(name: string) -> Table?`

Retrieves a table by name.

#### `database:listTables() -> {string}`

Returns list of all table names.

#### `database:beginTransaction() -> Transaction`

Starts a new transaction for atomic operations.

### Table Operations

#### `table:insert(data: table) -> (table?, string?)`

Inserts a new record into the table.

**Returns:**

- `record` - Inserted record with generated ID and timestamps
- `error` - Error message if validation failed

#### `table:find(query?: table, options?: table) -> {table}`

Finds records matching the query.

**Query Operators:**

- `$eq` - Equal to
- `$ne` - Not equal to
- `$gt` - Greater than
- `$gte` - Greater than or equal
- `$lt` - Less than
- `$lte` - Less than or equal
- `$in` - Value in array
- `$nin` - Value not in array
- `$regex` - Regular expression match

**Options:**

- `sort` - `{ field = "fieldName", order = "asc|desc" }`
- `limit` - Maximum number of results
- `offset` - Skip number of results

#### `table:findById(id: string) -> table?`

Finds a record by its unique ID.

#### `table:update(query: table, updateData: table) -> (number, string?)`

Updates records matching the query.

**Returns:**

- `count` - Number of updated records
- `error` - Error message if update failed

#### `table:delete(query: table) -> (number, string?)`

Deletes records matching the query.

**Returns:**

- `count` - Number of deleted records
- `error` - Error message if deletion failed

#### `table:count(query?: table) -> number`

Counts records matching the query.

#### `table:aggregate(operations: table) -> table`

Performs aggregation operations.

**Operations:**

- `count` - Count records
- `sum` - Sum values: `{ field = "fieldName" }`
- `avg` - Average values: `{ field = "fieldName" }`
- `min` - Minimum value: `{ field = "fieldName" }`
- `max` - Maximum value: `{ field = "fieldName" }`

### Indexing

#### `table:createIndex(field: string) -> (boolean, string?)`

Creates an index on the specified field for faster queries.

### Schema Validation

#### `Schema.string(options?) -> table`

Defines string field validation.

**Options:**

- `required` - Field is required
- `maxLength` - Maximum string length
- `enum` - Array of allowed values

#### `Schema.number(options?) -> table`

Defines number field validation.

**Options:**

- `required` - Field is required
- `min` - Minimum value
- `max` - Maximum value

#### `Schema.boolean(options?) -> table`

Defines boolean field validation.

#### `Schema.table(options?) -> table`

Defines table field validation.

### Transactions

#### `transaction:insert(tableName: string, data: table) -> (table?, string?)`

Inserts record within transaction.

#### `transaction:update(tableName: string, query: table, updateData: table) -> (number, string?)`

Updates records within transaction.

#### `transaction:delete(tableName: string, query: table) -> (number, string?)`

Deletes records within transaction.

#### `transaction:commit() -> (boolean, string?)`

Commits all transaction operations.

#### `transaction:rollback() -> (boolean, string?)`

Rolls back all transaction operations.

### DataStore Operations (Server Only)

#### `database:save(key?: string) -> (boolean, string?)`

Manually saves database to DataStore.

#### `database:load(key?: string) -> (boolean, string?)`

Loads database from DataStore.

#### `database:saveTable(tableName: string, key?: string) -> (boolean, string?)`

Saves individual table to DataStore.

#### `database:loadTable(tableName: string, key?: string) -> (boolean, string?)`

Loads individual table from DataStore.

#### `database:forceSync() -> (boolean, string?)`

Forces immediate synchronisation with DataStore.

#### `database:enableAutoSave(enabled: boolean) -> boolean`

Enables or disables automatic saving.

### Backup Operations

#### `database:backup() -> table`

Creates a complete backup of the database.

## 🔧 Advanced Features

### Query Examples

```luau
-- Find users with level between 10 and 50
local midLevelUsers = users:find({
    level = { ["$gte"] = 10, ["$lte"] = 50 }
})

-- Find warriors or mages with more than 1000 coins
local richFighters = users:find({
    class = { ["$in"] = { "warrior", "mage" } },
    coins = { ["$gt"] = 1000 }
})

-- Find users with usernames containing "Pro"
local proUsers = users:find({
    username = { ["$regex"] = "Pro" }
})

-- Sorted and paginated results
local topPlayers = users:find({}, {
    sort = { field = "level", order = "desc" },
    limit = 10,
    offset = 0
})
```

### Transaction Example

```luau
local tx = database:beginTransaction()

-- Transfer coins between users
tx:update("users", { username = "Player1" }, { coins = 500 })
tx:update("users", { username = "Player2" }, { coins = 1500 })

-- Commit if both operations succeeded
local success, err = tx:commit()
if not success then
    print("Transaction failed:", err)
    tx:rollback()
end
```

### Aggregation Example

```luau
local stats = users:aggregate({
    count = {},
    sum = { field = "coins" },
    avg = { field = "level" },
    min = { field = "level" },
    max = { field = "coins" }
})

print("Total users:", stats.count)
print("Total wealth:", stats.sum)
print("Average level:", stats.avg)
```

## ⚡ Performance Optimisation

### Indexing Best Practices

```luau
-- Create indices on frequently queried fields
users:createIndex("username")  -- For username lookups
users:createIndex("level")     -- For level-based queries
users:createIndex("class")     -- For class filtering

-- Indexed queries are much faster
local player = users:find({ username = "Player1" })  -- Uses index
```

### Query Optimisation

- **Use indices** for frequently queried fields
- **Limit results** when possible with `limit` option
- **Use specific queries** instead of scanning all records
- **Combine conditions** efficiently

## 🔒 Data Persistence

### DataStore Integration

```luau
-- Enable persistence on database creation
local database = DB.createDatabase("GameData", {
    useDataStore = true,
    storeName = "PlayerData_v1",
    autoSave = true,        -- Automatically save changes
    saveInterval = 30,      -- Save every 30 seconds
    retryAttempts = 3,      -- Retry failed operations
    retryDelay = 2          -- Wait 2 seconds between retries
})

-- Manual operations
database:save()                    -- Save entire database
database:saveTable("users")       -- Save specific table
database:load()                    -- Load from DataStore
database:forceSync()               -- Force immediate save
```

### Backup and Recovery

```luau
-- Create backup
local backup = database:backup()

-- Restore from backup (if restore method exists)
if database.restore then
    database:restore(backup)
end
```

## ⚠️ Important Considerations

### DataStore Limitations

- **Server only** - DataStore operations only work on the server
- **Rate limits** - Roblox imposes DataStore request limits
- **Data size** - Individual DataStore entries have size limits
- **Retry logic** - Built-in retry mechanism handles temporary failures

### Memory Management

- **In-memory storage** - All data stored in RAM during runtime
- **Large datasets** - Consider data archiving for very large tables
- **Index overhead** - Indices improve query speed but use additional memory

### Schema Validation

- **Runtime validation** - Schema is enforced on insert/update operations
- **Migration** - Changing schema requires manual data migration
- **Performance** - Validation adds slight overhead to write operations

## 🧪 Examples

See `Example.luau` for comprehensive usage examples including:

- Database and table creation
- Schema validation demonstrations
- Advanced querying techniques
- Transaction usage patterns
- DataStore integration
- Performance comparisons
- Backup and restore operations

## 📜 License

Licensed under the MIT License - see the main repository LICENSE file for details.

## 👤 Author

**Keira Hopkins**

- GitHub: [@NotKeira](https://github.com/NotKeira)

---

_Built from scratch for high-performance in-memory database operations_ 🗄️
