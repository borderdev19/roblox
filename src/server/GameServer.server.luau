local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Config = require(ReplicatedStorage:WaitForChild("CreatureConfig"))
local store = DataStoreService:GetDataStore("CreatureIsland_MVP_v1")

local remote = Instance.new("RemoteEvent")
remote.Name = "CreatureIslandAction"
remote.Parent = ReplicatedStorage
local stateEvent = Instance.new("RemoteEvent")
stateEvent.Name = "CreatureIslandState"
stateEvent.Parent = ReplicatedStorage

local states = {}
local lastAction = {}
local function fresh()
    return {coins = Config.StartingCoins, creatures = {}, upgrade = 0, island = 1}
end
local function sanitize(raw)
    local s = fresh()
    if type(raw) ~= "table" then return s end
    s.coins = math.clamp(math.floor(tonumber(raw.coins) or s.coins), 0, 1000000000)
    s.upgrade = math.clamp(math.floor(tonumber(raw.upgrade) or 0), 0, Config.UpgradeMax)
    s.island = math.clamp(math.floor(tonumber(raw.island) or 1), 1, 3)
    if type(raw.creatures) == "table" then
        for i = 1, #Config.CreatureNames do
            s.creatures[i] = math.clamp(math.floor(tonumber(raw.creatures[i]) or 0), 0, Config.MaxCreatures)
        end
    end
    return s
end
local function count(s)
    local n = 0
    for i = 1, #Config.CreatureNames do n += (s.creatures[i] or 0) end
    return n
end
local function income(s)
    local amount = Config.BaseIncome
    for i, value in ipairs(Config.CreatureIncome) do
        amount += (s.creatures[i] or 0) * value
    end
    return amount * (1 + s.upgrade * 0.25)
end
local function sync(player)
    local s = states[player]
    if s then
        stateEvent:FireClient(player, {
            coins = s.coins, creatures = s.creatures, upgrade = s.upgrade,
            island = s.island, income = income(s), total = count(s),
        })
    end
end
local function save(player)
    local s = states[player]
    if not s then return end
    local ok, err = pcall(function()
        store:UpdateAsync("p_" .. player.UserId, function() return s end)
    end)
    if not ok then warn("Creature Island save failed:", player.UserId, err) end
end
Players.PlayerAdded:Connect(function(player)
    local ok, data = pcall(function() return store:GetAsync("p_" .. player.UserId) end)
    if not ok then warn("Creature Island load failed:", player.UserId) end
    states[player] = sanitize(ok and data or nil)
    sync(player)
end)
Players.PlayerRemoving:Connect(function(player)
    save(player)
    states[player] = nil
    lastAction[player] = nil
end)
remote.OnServerEvent:Connect(function(player, action, index)
    local s = states[player]
    if not s or type(action) ~= "string" then return end
    local now = os.clock()
    if now - (lastAction[player] or 0) < 0.15 then return end
    lastAction[player] = now
    if action == "BuyCreature" then
        if type(index) ~= "number" or index % 1 ~= 0 then return end
        if index < 1 or index > #Config.CreatureNames or count(s) >= Config.MaxCreatures then return end
        local owned = s.creatures[index] or 0
        local cost = math.floor(Config.CreatureCosts[index] * (1.3 ^ owned))
        if s.coins >= cost then
            s.coins -= cost
            s.creatures[index] = owned + 1
        end
    elseif action == "Upgrade" then
        if s.upgrade >= Config.UpgradeMax then return end
        local cost = math.floor(Config.UpgradeBaseCost * (1.8 ^ s.upgrade))
        if s.coins >= cost then s.coins -= cost; s.upgrade += 1 end
    elseif action == "Island" then
        local cost = Config.IslandLevelCosts[s.island]
        if cost and s.coins >= cost then s.coins -= cost; s.island += 1 end
    elseif action ~= "Sync" then
        return
    end
    sync(player)
end)
task.spawn(function()
    while true do
        task.wait(Config.TickSeconds)
        for player, s in pairs(states) do
            s.coins = math.min(1000000000, s.coins + math.floor(income(s)))
            sync(player)
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(60)
        for player in pairs(states) do save(player) end
    end
end)
game:BindToClose(function()
    for player in pairs(states) do save(player) end
end)

-- Build a simple shared island at runtime; no external assets required.
local island = Instance.new("Part")
island.Name = "CreatureIsland"
island.Anchored = true
island.Size = Vector3.new(140, 4, 140)
island.Position = Vector3.new(0, -2, 0)
island.Color = Color3.fromRGB(75, 172, 91)
island.Material = Enum.Material.Grass
island.Parent = workspace
local spawn = Instance.new("SpawnLocation")
spawn.Name = "IslandSpawn"
spawn.Anchored = true
spawn.Neutral = true
spawn.Size = Vector3.new(12, 1, 12)
spawn.Position = Vector3.new(0, 1, 0)
spawn.Parent = workspace
for i = 1, 14 do
    local tree = Instance.new("Part")
    tree.Name = "DecorRock"
    tree.Anchored = true
    tree.Shape = Enum.PartType.Ball
    tree.Size = Vector3.new(3 + i % 4, 2 + i % 3, 3 + i % 4)
    tree.Position = Vector3.new(math.cos(i * 2.4) * 55, 0.8, math.sin(i * 2.4) * 55)
    tree.Color = Color3.fromRGB(115, 125, 130)
    tree.Parent = workspace
end
