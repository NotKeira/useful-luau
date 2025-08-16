-->> Advanced Database System
-->> Provides in-memory database with persistence, indexing, and querying
-->> Features: CRUD operations, indexing, transactions, data validation, backup/restore
-->> Built from scratch with no external dependencies
-->> Author: Keira Hopkins (github.com/NotKeira)
-->> Copyrighted and Licensed under the MIT License

local DatabaseModule = {}

-->> ========================================
-->> CORE DATABASE STRUCTURES
-->> ========================================

local Database = {}
Database.__index = Database

-->> Table structure
local Table = {}
Table.__index = Table

-->> Index structure for fast lookups
local Index = {}
Index.__index = Index

-->> Transaction structure for atomic operations
local Transaction = {}
Transaction.__index = Transaction

-->> ========================================
-->> UTILITY FUNCTIONS
-->> ========================================

-->> Deep copy function for data isolation
local function deepCopy(original)
	if type(original) ~= "table" then
		return original
	end

	local copy = {}
	for key, value in pairs(original) do
		copy[key] = deepCopy(value)
	end

	return copy
end

-->> Generate unique ID
local function generateId()
	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	local id = ""
	local rng = Random.new()

	for i = 1, 16 do
		local randomIndex = rng:NextInteger(1, #chars)
		id = id .. chars:sub(randomIndex, randomIndex)
	end

	return id .. "_" .. tostring(tick())
end

-->> Validate data against schema
local function validateData(data, schema)
	if not schema then
		return true, nil
	end

	for field, fieldSchema in pairs(schema) do
		local value = data[field]

		-->> Check required fields
		if fieldSchema.required and value == nil then
			return false, `Field '{field}' is required`
		end

		-->> Check data type
		if value ~= nil and fieldSchema.type then
			local valueType = type(value)
			if valueType ~= fieldSchema.type then
				return false, `Field '{field}' must be of type {fieldSchema.type}, got {valueType}`
			end
		end

		-->> Check string length
		if value and fieldSchema.maxLength and type(value) == "string" then
			if #value > fieldSchema.maxLength then
				return false, `Field '{field}' exceeds maximum length of {fieldSchema.maxLength}`
			end
		end

		-->> Check number range
		if value and fieldSchema.min and type(value) == "number" then
			if value < fieldSchema.min then
				return false, `Field '{field}' must be at least {fieldSchema.min}`
			end
		end

		if value and fieldSchema.max and type(value) == "number" then
			if value > fieldSchema.max then
				return false, `Field '{field}' must be at most {fieldSchema.max}`
			end
		end

		-->> Check enum values
		if value and fieldSchema.enum then
			local found = false
			for _, enumValue in ipairs(fieldSchema.enum) do
				if value == enumValue then
					found = true
					break
				end
			end
			if not found then
				return false, `Field '{field}' must be one of: {table.concat(fieldSchema.enum, ", ")}`
			end
		end
	end

	return true, nil
end

-->> Match query conditions
local function matchesQuery(record, query)
	if not query then
		return true
	end

	for field, condition in pairs(query) do
		local value = record[field]

		if type(condition) == "table" then
			-->> Advanced query operators
			if condition["$eq"] and value ~= condition["$eq"] then
				return false
			end
			if condition["$ne"] and value == condition["$ne"] then
				return false
			end
			if condition["$gt"] and (not value or value <= condition["$gt"]) then
				return false
			end
			if condition["$gte"] and (not value or value < condition["$gte"]) then
				return false
			end
			if condition["$lt"] and (not value or value >= condition["$lt"]) then
				return false
			end
			if condition["$lte"] and (not value or value > condition["$lte"]) then
				return false
			end
			if condition["$in"] then
				local found = false
				for _, v in ipairs(condition["$in"]) do
					if value == v then
						found = true
						break
					end
				end
				if not found then
					return false
				end
			end
			if condition["$nin"] then
				for _, v in ipairs(condition["$nin"]) do
					if value == v then
						return false
					end
				end
			end
			if condition["$regex"] and type(value) == "string" then
				if not string.match(value, condition["$regex"]) then
					return false
				end
			end
		else
			-->> Simple equality check
			if value ~= condition then
				return false
			end
		end
	end

	return true
end

-->> ========================================
-->> INDEX IMPLEMENTATION
-->> ========================================

function Index.new(field)
	local self = setmetatable({}, Index)
	self.field = field
	self.values = {} --// value -> {record_id1, record_id2, ...}
	return self
end

function Index:add(recordId, value)
	if value == nil then
		return
	end

	if not self.values[value] then
		self.values[value] = {}
	end

	table.insert(self.values[value], recordId)
end

function Index:remove(recordId, value)
	if not self.values[value] then
		return
	end

	for i, id in ipairs(self.values[value]) do
		if id == recordId then
			table.remove(self.values[value], i)
			break
		end
	end

	-->> Clean up empty arrays
	if #self.values[value] == 0 then
		self.values[value] = nil
	end
end

function Index:find(value)
	return self.values[value] or {}
end

-->> ========================================
-->> TABLE IMPLEMENTATION
-->> ========================================

function Table.new(name, schema, database)
	local self = setmetatable({}, Table)
	self.name = name
	self.schema = schema
	self.database = database --// Reference to parent database
	self.records = {} --// id -> record (ensure this is always initialized)
	self.indices = {} --// field -> Index (ensure this is always initialized)
	self.primaryKey = "id"
	self.autoIncrement = 0
	return self
end

function Table:createIndex(field)
	-->> Ensure indices table exists
	if not self.indices then
		self.indices = {}
	end

	if self.indices[field] then
		return false, `Index on field '{field}' already exists`
	end

	local index = Index.new(field)

	-->> Build index from existing records
	if self.records then
		for id, record in pairs(self.records) do
			index:add(id, record[field])
		end
	end

	self.indices[field] = index
	return true, nil
end

function Table:insert(data)
	-->> Ensure records and indices tables exist
	if not self.records then
		self.records = {}
	end
	if not self.indices then
		self.indices = {}
	end

	-->> Validate data
	local valid, err = validateData(data, self.schema)
	if not valid then
		return nil, err
	end

	-->> Create record with ID
	local record = deepCopy(data)
	local id = data.id or generateId()
	record.id = id
	record._createdAt = os.time()
	record._updatedAt = os.time()

	-->> Check for duplicate primary key
	if self.records[id] then
		return nil, `Record with id '{id}' already exists`
	end

	-->> Store record
	self.records[id] = record

	-->> Update indices
	for field, index in pairs(self.indices) do
		index:add(id, record[field])
	end

	-->> Mark database as dirty for DataStore
	if self.database and self.database.dataStore then
		self.database.dataStore:markDirty()
	end

	return deepCopy(record), nil
end

function Table:findById(id)
	local record = self.records[id]
	return record and deepCopy(record) or nil
end

function Table:find(query, options)
	-->> Ensure records and indices tables exist
	if not self.records then
		self.records = {}
		return {}
	end
	if not self.indices then
		self.indices = {}
	end

	options = options or {}
	local results = {}

	-->> Try to use index for faster lookup
	local indexField = nil
	local indexValue = nil

	if query then
		for field, value in pairs(query) do
			if self.indices[field] and type(value) ~= "table" then
				indexField = field
				indexValue = value
				break
			end
		end
	end

	if indexField then
		-->> Use index for fast lookup
		local recordIds = self.indices[indexField]:find(indexValue)
		for _, id in ipairs(recordIds) do
			local record = self.records[id]
			if record and matchesQuery(record, query) then
				table.insert(results, deepCopy(record))
			end
		end
	else
		-->> Full table scan
		for _, record in pairs(self.records) do
			if matchesQuery(record, query) then
				table.insert(results, deepCopy(record))
			end
		end
	end

	-->> Apply sorting
	if options.sort then
		table.sort(results, function(a, b)
			local field = options.sort.field
			local order = options.sort.order or "asc"

			if order == "asc" then
				return (a[field] or 0) < (b[field] or 0)
			else
				return (a[field] or 0) > (b[field] or 0)
			end
		end)
	end

	-->> Apply pagination
	if options.limit then
		local start = (options.offset or 0) + 1
		local finish = start + options.limit - 1
		local pagedResults = {}

		for i = start, math.min(finish, #results) do
			table.insert(pagedResults, results[i])
		end

		return pagedResults
	end

	return results
end

function Table:update(query, updateData)
	-->> Ensure indices table exists
	if not self.indices then
		self.indices = {}
	end

	local records = self:find(query)
	local updatedCount = 0

	for _, record in ipairs(records) do
		local id = record.id
		local currentRecord = self.records[id]

		if currentRecord then
			-->> Remove from indices before update
			for field, index in pairs(self.indices) do
				index:remove(id, currentRecord[field])
			end

			-->> Apply updates
			for field, value in pairs(updateData) do
				if field ~= "id" and field ~= "_createdAt" then
					currentRecord[field] = value
				end
			end
			currentRecord._updatedAt = os.time()

			-->> Validate updated record
			local valid, err = validateData(currentRecord, self.schema)
			if not valid then
				return 0, err
			end

			-->> Re-add to indices
			for field, index in pairs(self.indices) do
				index:add(id, currentRecord[field])
			end

			updatedCount = updatedCount + 1
		end
	end

	-->> Mark database as dirty for DataStore
	if updatedCount > 0 and self.database and self.database.dataStore then
		self.database.dataStore:markDirty()
	end

	return updatedCount, nil
end

function Table:delete(query)
	-->> Ensure indices table exists
	if not self.indices then
		self.indices = {}
	end

	local records = self:find(query)
	local deletedCount = 0

	for _, record in ipairs(records) do
		local id = record.id
		local currentRecord = self.records[id]

		if currentRecord then
			-->> Remove from indices
			for field, index in pairs(self.indices) do
				index:remove(id, currentRecord[field])
			end

			-->> Remove record
			self.records[id] = nil
			deletedCount = deletedCount + 1
		end
	end

	-->> Mark database as dirty for DataStore
	if deletedCount > 0 and self.database and self.database.dataStore then
		self.database.dataStore:markDirty()
	end

	return deletedCount, nil
end

function Table:count(query)
	if not query then
		local count = 0
		for _ in pairs(self.records) do
			count = count + 1
		end
		return count
	end

	return #self:find(query)
end

function Table:aggregate(operations)
	local records = self:find()
	local results = {}

	for operation, config in pairs(operations) do
		if operation == "count" then
			results.count = #records
		elseif operation == "sum" then
			local total = 0
			for _, record in ipairs(records) do
				total = total + (record[config.field] or 0)
			end
			results.sum = total
		elseif operation == "avg" then
			local total = 0
			local count = 0
			for _, record in ipairs(records) do
				if record[config.field] then
					total = total + record[config.field]
					count = count + 1
				end
			end
			results.avg = count > 0 and total / count or 0
		elseif operation == "min" then
			local min = nil
			for _, record in ipairs(records) do
				local value = record[config.field]
				if value and (not min or value < min) then
					min = value
				end
			end
			results.min = min
		elseif operation == "max" then
			local max = nil
			for _, record in ipairs(records) do
				local value = record[config.field]
				if value and (not max or value > max) then
					max = value
				end
			end
			results.max = max
		end
	end

	return results
end

-->> ========================================
-->> TRANSACTION IMPLEMENTATION
-->> ========================================

function Transaction.new(database)
	local self = setmetatable({}, Transaction)
	self.database = database
	self.operations = {}
	self.backup = {}
	self.committed = false
	self.rolledBack = false
	return self
end

function Transaction:createBackup()
	for tableName, table in pairs(self.database.tables) do
		self.backup[tableName] = {
			records = deepCopy(table.records),
			indices = {},
		}

		-->> Backup indices
		for field, index in pairs(table.indices) do
			self.backup[tableName].indices[field] = deepCopy(index.values)
		end
	end
end

function Transaction:insert(tableName, data)
	if self.committed or self.rolledBack then
		return nil, "Transaction already completed"
	end

	local table = self.database.tables[tableName]
	if not table then
		return nil, `Table '{tableName}' does not exist`
	end

	if #self.operations == 0 then
		self:createBackup()
	end

	local record, err = table:insert(data)
	if err then
		return nil, err
	end

	table.insert(self.operations, {
		type = "insert",
		table = tableName,
		id = record.id,
	})

	return record, nil
end

function Transaction:update(tableName, query, updateData)
	if self.committed or self.rolledBack then
		return 0, "Transaction already completed"
	end

	local table = self.database.tables[tableName]
	if not table then
		return 0, `Table '{tableName}' does not exist`
	end

	if #self.operations == 0 then
		self:createBackup()
	end

	local count, err = table:update(query, updateData)
	if err then
		return 0, err
	end

	table.insert(self.operations, {
		type = "update",
		table = tableName,
		query = query,
		count = count,
	})

	return count, nil
end

function Transaction:delete(tableName, query)
	if self.committed or self.rolledBack then
		return 0, "Transaction already completed"
	end

	local table = self.database.tables[tableName]
	if not table then
		return 0, `Table '{tableName}' does not exist`
	end

	if #self.operations == 0 then
		self:createBackup()
	end

	local count, err = table:delete(query)
	if err then
		return 0, err
	end

	table.insert(self.operations, {
		type = "delete",
		table = tableName,
		query = query,
		count = count,
	})

	return count, nil
end

function Transaction:commit()
	if self.committed or self.rolledBack then
		return false, "Transaction already completed"
	end

	self.committed = true
	self.backup = {} --// Clear backup
	return true, nil
end

function Transaction:rollback()
	if self.committed or self.rolledBack then
		return false, "Transaction already completed"
	end

	-->> Restore from backup
	for tableName, backupData in pairs(self.backup) do
		local table = self.database.tables[tableName]
		if table then
			table.records = backupData.records

			-->> Restore indices
			for field, indexData in pairs(backupData.indices) do
				if table.indices[field] then
					table.indices[field].values = indexData
				end
			end
		end
	end

	self.rolledBack = true
	return true, nil
end

-->> ========================================
-->> DATASTORE INTEGRATION
-->> ========================================

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local DataStoreAdapter = {}
DataStoreAdapter.__index = DataStoreAdapter

function DataStoreAdapter.new(database, options)
	local self = setmetatable({}, DataStoreAdapter)
	self.database = database
	self.dataStore = DataStoreService:GetDataStore(options.storeName or database.name)
	self.autoSave = options.autoSave ~= false --// Default true
	self.saveInterval = options.saveInterval or 30 --// Seconds
	self.lastSave = 0
	self.isDirty = false
	self.retryAttempts = options.retryAttempts or 3
	self.retryDelay = options.retryDelay or 2

	if self.autoSave then
		self:startAutoSave()
	end

	return self
end

function DataStoreAdapter:startAutoSave()
	if RunService:IsServer() then
		spawn(function()
			while self.autoSave do
				wait(self.saveInterval)
				if self.isDirty and tick() - self.lastSave >= self.saveInterval then
					local success, err = self:save()
					if success then
						self.isDirty = false
					else
						warn(`DataStore auto-save failed: {err}`)
					end
				end
			end
		end)
	end
end

function DataStoreAdapter:markDirty()
	self.isDirty = true
end

function DataStoreAdapter:save(key)
	if not RunService:IsServer() then
		return false, "DataStore operations can only be performed on the server"
	end

	key = key or "database_" .. self.database.name

	local function attemptSave(attempt)
		local success, result = pcall(function()
			local data = self.database:backup()
			return self.dataStore:SetAsync(key, data)
		end)

		if success then
			self.lastSave = tick()
			return true, nil
		else
			if attempt < self.retryAttempts then
				wait(self.retryDelay * attempt)
				return attemptSave(attempt + 1)
			else
				return false, result
			end
		end
	end

	return attemptSave(1)
end

function DataStoreAdapter:load(key)
	if not RunService:IsServer() then
		return false, "DataStore operations can only be performed on the server"
	end

	key = key or "database_" .. self.database.name

	local function attemptLoad(attempt)
		local success, result = pcall(function()
			return self.dataStore:GetAsync(key)
		end)

		if success then
			if result then
				-->> Check if restore method exists
				if self.database.restore then
					local restoreSuccess, restoreErr = self.database:restore(result)
					if restoreSuccess then
						return true, nil
					else
						return false, restoreErr
					end
				else
					-->> Manual restore if method is missing
					self.database.tables = {}
					for tableName, tableData in pairs(result.tables or {}) do
						local table = Table.new(tableData.name, tableData.schema, self.database)
						table.records = tableData.records or {}
						table.indices = {}
						table.primaryKey = tableData.primaryKey or "id"
						table.autoIncrement = tableData.autoIncrement or 0
						self.database.tables[tableName] = table
					end
					return true, nil
				end
			else
				return true, nil --// No data found, that's okay
			end
		else
			if attempt < self.retryAttempts then
				wait(self.retryDelay * attempt)
				return attemptLoad(attempt + 1)
			else
				return false, result
			end
		end
	end

	return attemptLoad(1)
end

function DataStoreAdapter:saveTable(tableName, key)
	if not RunService:IsServer() then
		return false, "DataStore operations can only be performed on the server"
	end

	local table = self.database:getTable(tableName)
	if not table then
		return false, `Table '{tableName}' does not exist`
	end

	key = key or `table_{tableName}`

	local function attemptSave(attempt)
		local success, result = pcall(function()
			local tableData = {
				name = table.name,
				schema = table.schema,
				records = table.records,
				primaryKey = table.primaryKey,
				autoIncrement = table.autoIncrement,
				savedAt = os.time(),
			}
			return self.dataStore:SetAsync(key, tableData)
		end)

		if success then
			return true, nil
		else
			if attempt < self.retryAttempts then
				wait(self.retryDelay * attempt)
				return attemptSave(attempt + 1)
			else
				return false, result
			end
		end
	end

	return attemptSave(1)
end

function DataStoreAdapter:loadTable(tableName, key)
	if not RunService:IsServer() then
		return false, "DataStore operations can only be performed on the server"
	end

	key = key or `table_{tableName}`

	local function attemptLoad(attempt)
		local success, result = pcall(function()
			return self.dataStore:GetAsync(key)
		end)

		if success then
			if result then
				--// Create or update table
				local table = Table.new(result.name, result.schema)
				table.records = result.records or {}
				table.primaryKey = result.primaryKey or "id"
				table.autoIncrement = result.autoIncrement or 0

				self.database.tables[tableName] = table
				return true, nil
			else
				return true, nil --// No data found
			end
		else
			if attempt < self.retryAttempts then
				wait(self.retryDelay * attempt)
				return attemptLoad(attempt + 1)
			else
				return false, result
			end
		end
	end

	return attemptLoad(1)
end

function DataStoreAdapter:deleteData(key)
	if not RunService:IsServer() then
		return false, "DataStore operations can only be performed on the server"
	end

	key = key or "database_" .. self.database.name

	local function attemptDelete(attempt)
		local success, result = pcall(function()
			return self.dataStore:RemoveAsync(key)
		end)

		if success then
			return true, result
		else
			if attempt < self.retryAttempts then
				wait(self.retryDelay * attempt)
				return attemptDelete(attempt + 1)
			else
				return false, result
			end
		end
	end

	return attemptDelete(1)
end

function DataStoreAdapter:stop()
	self.autoSave = false
end

-->> ========================================
-->> DATABASE IMPLEMENTATION
-->> ========================================

function Database.new(name, options)
	local self = setmetatable({}, Database)
	self.name = name
	self.tables = {}
	self.created = os.time()
	self.dataStore = nil

	-->> Initialize DataStore if requested
	if options and options.useDataStore then
		local dsOptions = {
			storeName = options.storeName,
			autoSave = options.autoSave,
			saveInterval = options.saveInterval,
			retryAttempts = options.retryAttempts,
			retryDelay = options.retryDelay,
		}
		self.dataStore = DataStoreAdapter.new(self, dsOptions)

		--// Attempt to load existing data
		if options.loadOnStart ~= false then
			spawn(function()
				local success, err = self.dataStore:load()
				if not success then
					warn(`Failed to load database from DataStore: {err}`)
				end
			end)
		end
	end

	return self
end

function Database:createTable(name, schema)
	if self.tables[name] then
		return false, `Table '{name}' already exists`
	end

	self.tables[name] = Table.new(name, schema, self)
	return true, nil
end

function Database:dropTable(name)
	if not self.tables[name] then
		return false, `Table '{name}' does not exist`
	end

	self.tables[name] = nil
	return true, nil
end

function Database:getTable(name)
	return self.tables[name]
end

function Database:listTables()
	local tables = {}
	for name in pairs(self.tables) do
		table.insert(tables, name)
	end
	return tables
end

function Database:beginTransaction()
	return Transaction.new(self)
end

function Database:backup()
	local backup = {
		name = self.name,
		created = self.created,
		backupTime = os.time(),
		tables = {},
	}

	for tableName, table in pairs(self.tables) do
		backup.tables[tableName] = {
			name = table.name,
			schema = table.schema,
			records = deepCopy(table.records),
			primaryKey = table.primaryKey,
			autoIncrement = table.autoIncrement,
		}
	end

	return backup
end

function Database:save(key)
	if self.dataStore then
		return self.dataStore:save(key)
	else
		return false, "DataStore not enabled for this database"
	end
end

function Database:load(key)
	if self.dataStore then
		return self.dataStore:load(key)
	else
		return false, "DataStore not enabled for this database"
	end
end

function Database:saveTable(tableName, key)
	if self.dataStore then
		return self.dataStore:saveTable(tableName, key)
	else
		return false, "DataStore not enabled for this database"
	end
end

function Database:loadTable(tableName, key)
	if self.dataStore then
		return self.dataStore:loadTable(tableName, key)
	else
		return false, "DataStore not enabled for this database"
	end
end

function Database:enableAutoSave(enabled)
	if self.dataStore then
		self.dataStore.autoSave = enabled ~= false
		if enabled then
			self.dataStore:startAutoSave()
		end
		return true
	else
		return false, "DataStore not enabled for this database"
	end
end

function Database:forceSync()
	if self.dataStore then
		self.dataStore.isDirty = true
		return self.dataStore:save()
	else
		return false, "DataStore not enabled for this database"
	end
end

-->> ========================================
-->> PUBLIC API
-->> ========================================

-->> Create new database
function DatabaseModule.createDatabase(name, options)
	return Database.new(name, options)
end

-->> Schema helper functions
function DatabaseModule.Schema()
	return {
		string = function(options)
			options = options or {}
			return {
				type = "string",
				required = options.required,
				maxLength = options.maxLength,
				enum = options.enum,
			}
		end,

		number = function(options)
			options = options or {}
			return {
				type = "number",
				required = options.required,
				min = options.min,
				max = options.max,
			}
		end,

		boolean = function(options)
			options = options or {}
			return {
				type = "boolean",
				required = options.required,
			}
		end,

		table = function(options)
			options = options or {}
			return {
				type = "table",
				required = options.required,
			}
		end,
	}
end

-->> Export classes for advanced usage
DatabaseModule.Database = Database
DatabaseModule.Table = Table
DatabaseModule.Index = Index
DatabaseModule.Transaction = Transaction

return DatabaseModule
