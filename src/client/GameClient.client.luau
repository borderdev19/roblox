local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("CreatureConfig"))
local action = ReplicatedStorage:WaitForChild("CreatureIslandAction")
local stateEvent = ReplicatedStorage:WaitForChild("CreatureIslandState")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "CreatureIslandUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")
local panel = Instance.new("ScrollingFrame")
panel.Name = "Shop"
panel.AnchorPoint = Vector2.new(1, 0.5)
panel.Position = UDim2.new(1, -12, 0.5, 0)
panel.Size = UDim2.new(0.42, 0, 0.78, 0)
panel.BackgroundColor3 = Color3.fromRGB(21, 40, 47)
panel.BackgroundTransparency = 0.08
panel.ScrollBarThickness = 5
panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
panel.CanvasSize = UDim2.fromOffset(0, 0)
panel.Parent = gui
local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize = Vector2.new(360, 700)
constraint.MinSize = Vector2.new(170, 250)
constraint.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 7)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = panel
local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 12)
pad.PaddingBottom = UDim.new(0, 12)
pad.Parent = panel
local function label(text, height)
    local item = Instance.new("TextLabel")
    item.Size = UDim2.new(0.94, 0, 0, height)
    item.BackgroundTransparency = 1
    item.TextColor3 = Color3.fromRGB(245, 249, 240)
    item.TextScaled = true
    item.Font = Enum.Font.GothamBold
    item.Text = text
    item.Parent = panel
    return item
end
local function button(text, callback)
    local item = Instance.new("TextButton")
    item.Size = UDim2.new(0.94, 0, 0, 47)
    item.BackgroundColor3 = Color3.fromRGB(57, 145, 112)
    item.TextColor3 = Color3.new(1, 1, 1)
    item.TextScaled = true
    item.TextWrapped = true
    item.Font = Enum.Font.GothamBold
    item.Text = text
    item.Parent = panel
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 9)
    corner.Parent = item
    item.Activated:Connect(callback)
    return item
end
label("CREATURE ISLAND", 42)
local stats = label("Cargando...", 70)
local creatureButtons = {}
for i, name in ipairs(Config.CreatureNames) do
    creatureButtons[i] = button(name, function() action:FireServer("BuyCreature", i) end)
end
local upgrade = button("Mejorar producción", function() action:FireServer("Upgrade") end)
local island = button("Ampliar isla", function() action:FireServer("Island") end)
label("Las monedas se generan automáticamente", 35)
stateEvent.OnClientEvent:Connect(function(s)
    stats.Text = string.format("Monedas: %d\nProducción: %d / 2s\nIsla: %d | Criaturas: %d/30", s.coins, math.floor(s.income), s.island, s.total)
    for i, item in ipairs(creatureButtons) do
        local owned = s.creatures[i] or 0
        local cost = math.floor(Config.CreatureCosts[i] * (1.3 ^ owned))
        item.Text = string.format("%s (%d) · %d monedas", Config.CreatureNames[i], owned, cost)
        item.BackgroundColor3 = s.coins >= cost and Color3.fromRGB(57,145,112) or Color3.fromRGB(85,91,97)
    end
    local upgradeCost = math.floor(Config.UpgradeBaseCost * (1.8 ^ s.upgrade))
    upgrade.Text = s.upgrade >= Config.UpgradeMax and "Producción al máximo" or string.format("Mejorar x%d · %d monedas", s.upgrade + 1, upgradeCost)
    local islandCost = Config.IslandLevelCosts[s.island]
    island.Text = islandCost and string.format("Isla nivel %d · %d monedas", s.island + 1, islandCost) or "Isla al máximo"
end)
action:FireServer("Sync")
