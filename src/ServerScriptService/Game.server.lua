local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local remotes = Instance.new("Folder")
remotes.Name = "BrainrotRemotes"
remotes.Parent = ReplicatedStorage

local buyRemote = Instance.new("RemoteEvent")
buyRemote.Name = "BuyBrainrot"
buyRemote.Parent = remotes

local notifyRemote = Instance.new("RemoteEvent")
notifyRemote.Name = "Notify"
notifyRemote.Parent = remotes

local playerDataStore = DataStoreService:GetDataStore("BrainrotTycoonData_v1")
local playerData = {}
local playerPlots = {}
local brainrotModels = {}

local world = Workspace:FindFirstChild("BrainrotWorld") or Instance.new("Folder")
world.Name = "BrainrotWorld"
world.Parent = Workspace

local function findBrainrot(id)
    for _, brainrot in ipairs(Config.Brainrots) do
        if brainrot.Id == id then
            return brainrot
        end
    end
    return nil
end

local function createBasePart(parent, size, position, color)
    local part = Instance.new("Part")
    part.Name = "PlotPart"
    part.Size = size
    part.Position = position
    part.Color = color
    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function createPlot(index)
    local plot = Instance.new("Folder")
    plot.Name = "Plot" .. index
    plot.Parent = world

    local angle = ((index - 1) / Config.MaxPlayersPerServer) * math.pi * 2
    local radius = 74
    local center = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)

    createBasePart(plot, Vector3.new(36, 1, 36), center, Color3.fromRGB(85, 170, 110))

    local basePad = createBasePart(plot, Vector3.new(10, 1.2, 10), center + Vector3.new(0, 1, 0), Color3.fromRGB(230, 230, 230))
    basePad.Name = "BrainrotPad"
    basePad.CanCollide = false

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "PlayerSpawn"
    spawn.Size = Vector3.new(6, 1, 6)
    spawn.Position = center + Vector3.new(-10, 1.5, 0)
    spawn.Anchored = true
    spawn.Neutral = false
    spawn.Transparency = 0.2
    spawn.Parent = plot

    local sign = Instance.new("Part")
    sign.Name = "PlotSign"
    sign.Size = Vector3.new(14, 4, 1)
    sign.Position = center + Vector3.new(0, 3, -18)
    sign.Anchored = true
    sign.Color = Color3.fromRGB(35, 35, 45)
    sign.Parent = plot

    local surface = Instance.new("SurfaceGui")
    surface.Face = Enum.NormalId.Back
    surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surface.Parent = sign

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = "EMPTY BASE"
    label.TextScaled = true
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.GothamBold
    label.Parent = surface
    plot:SetAttribute("OwnerName", "")

    return plot
end

for i = 1, Config.MaxPlayersPerServer do
    createPlot(i)
end

local function claimPlot(player)
    for _, plot in ipairs(world:GetChildren()) do
        if plot:IsA("Folder") and plot.Name:match("^Plot") and plot:GetAttribute("OwnerUserId") == nil then
            plot:SetAttribute("OwnerUserId", player.UserId)
            plot:SetAttribute("OwnerName", player.Name)

            local sign = plot:FindFirstChild("PlotSign")
            local label = sign and sign:FindFirstChildOfClass("SurfaceGui") and sign:FindFirstChildOfClass("SurfaceGui"):FindFirstChildOfClass("TextLabel")
            if label then
                label.Text = player.Name .. "'s BASE"
            end

            local spawn = plot:FindFirstChild("PlayerSpawn")
            if spawn then
                player.RespawnLocation = spawn
            end
            playerPlots[player] = plot
            return plot
        end
    end
    return nil
end

local function loadData(player)
    local success, result = pcall(function()
        return playerDataStore:GetAsync("user_" .. player.UserId)
    end)
    if success and type(result) == "table" then
        return {
            Coins = tonumber(result.Coins) or Config.StartingCoins,
            Streak = tonumber(result.Streak) or Config.StartingStreak,
            OwnedBrainrots = type(result.OwnedBrainrots) == "table" and result.OwnedBrainrots or {},
        }
    end
    return {
        Coins = Config.StartingCoins,
        Streak = Config.StartingStreak,
        OwnedBrainrots = {},
    }
end

local function saveData(player)
    local data = playerData[player]
    if not data then
        return
    end
    pcall(function()
        playerDataStore:SetAsync("user_" .. player.UserId, data)
    end)
end

local function createBrainrotModel(brainrot, owner, position)
    local model = Instance.new("Model")
    model.Name = brainrot.Name
    model:SetAttribute("BrainrotId", brainrot.Id)
    model:SetAttribute("OwnerUserId", owner.UserId)
    model:SetAttribute("OwnerName", owner.Name)
    model:SetAttribute("Income", brainrot.Income)

    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(4, 4, 4) * brainrot.ModelScale
    body.Color = brainrot.Color
    body.Shape = Enum.PartType.Ball
    body.Material = Enum.Material.SmoothPlastic
    body.Anchored = false
    body.CanCollide = false
    body.Position = position
    body.Parent = model

    local face = Instance.new("BillboardGui")
    face.Name = "NameTag"
    face.Size = UDim2.fromOffset(180, 48)
    face.StudsOffset = Vector3.new(0, 3.5 * brainrot.ModelScale, 0)
    face.AlwaysOnTop = true
    face.Parent = body

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    label.BackgroundTransparency = 0.25
    label.Text = brainrot.Name
    label.TextColor3 = brainrot.Color
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = face

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "StealPrompt"
    prompt.ActionText = "Steal"
    prompt.ObjectText = brainrot.Name
    prompt.HoldDuration = 1.5
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt.Parent = body

    model.PrimaryPart = body
    model.Parent = world
    table.insert(brainrotModels, model)

    prompt.Triggered:Connect(function(player)
        if player == owner then
            notifyRemote:FireClient(player, "Acesta este brainrot-ul tau!")
            return
        end

        local now = os.time()
        local lastSteal = model:GetAttribute("LastStealTime") or 0
        if now - lastSteal < Config.StealCooldown then
            notifyRemote:FireClient(player, "Brainrot-ul este protejat!")
            return
        end

        model:SetAttribute("LastStealTime", now)
        model:SetAttribute("OwnerUserId", player.UserId)
        model:SetAttribute("OwnerName", player.Name)

        local targetPlot = playerPlots[player]
        if targetPlot then
            local pad = targetPlot:FindFirstChild("BrainrotPad")
            if pad then
                body.Anchored = true
                body.CFrame = pad.CFrame + Vector3.new(0, 4, 0)
                body.Anchored = false
            end
        end

        local thiefData = playerData[player]
        if thiefData then
            thiefData.Streak = thiefData.Streak + 1
            player:SetAttribute("Streak", thiefData.Streak)
            local leaderstats = player:FindFirstChild("leaderstats")
            local streak = leaderstats and leaderstats:FindFirstChild("StealStreak")
            if streak then
                streak.Value = thiefData.Streak
            end
        end

        notifyRemote:FireClient(player, "Ai furat " .. brainrot.Name .. "!")
    end)

    return model
end

local function updateIncome(player)
    local data = playerData[player]
    if not data then
        return
    end
    local plot = playerPlots[player]
    if not plot then
        return
    end

    local coinsEarned = 0
    for _, model in ipairs(brainrotModels) do
        if model.Parent and model:GetAttribute("OwnerUserId") == player.UserId then
            coinsEarned = coinsEarned + (model:GetAttribute("Income") or 0)
        end
    end
    data.Coins = data.Coins + coinsEarned
    player:SetAttribute("Coins", data.Coins)
    player:SetAttribute("Streak", data.Streak)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local coins = leaderstats:FindFirstChild("Coins")
        local streak = leaderstats:FindFirstChild("StealStreak")
        if coins then
            coins.Value = data.Coins
        end
        if streak then
            streak.Value = data.Streak
        end
    end
end

local function createShop(player)
    local plot = playerPlots[player]
    if not plot then
        return
    end

    for _, brainrot in ipairs(Config.Brainrots) do
        local key = "Shop_" .. brainrot.Id
        local old = plot:FindFirstChild(key)
        if old then
            old:Destroy()
        end

        local index = table.find(Config.Brainrots, brainrot)
        local pad = createBasePart(plot, Vector3.new(7, 1, 7),
            plot:FindFirstChild("PlotPart").Position + Vector3.new((index - 2) * 10, 1.5, 12),
            brainrot.Color)
        pad.Name = key
        pad:SetAttribute("BrainrotId", brainrot.Id)

        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = "BuyPrompt"
        prompt.ActionText = "Cumpara"
        prompt.ObjectText = brainrot.Name .. " - $" .. brainrot.Cost
        prompt.HoldDuration = 0.5
        prompt.RequiresLineOfSight = false
        prompt.Parent = pad

        prompt.Triggered:Connect(function(triggerPlayer)
            if triggerPlayer ~= player then
                return
            end
            buyRemote:FireClient(triggerPlayer, brainrot.Id)
        end)
    end
end

buyRemote.OnServerEvent:Connect(function(player, brainrotId)
    local brainrot = findBrainrot(brainrotId)
    local data = playerData[player]
    if not brainrot or not data then
        return
    end
    if data.Coins < brainrot.Cost then
        notifyRemote:FireClient(player, "Nu ai destui bani!")
        return
    end

    local plot = playerPlots[player]
    if not plot then
        return
    end

    data.Coins = data.Coins - brainrot.Cost
    player:SetAttribute("Coins", data.Coins)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local coins = leaderstats:FindFirstChild("Coins")
        if coins then
            coins.Value = data.Coins
        end
    end

    local pad = plot:FindFirstChild("BrainrotPad")
    local position = pad and (pad.Position + Vector3.new(math.random(-3, 3), 5, math.random(-3, 3)))
        or plot:FindFirstChild("PlotPart").Position + Vector3.new(0, 5, 0)
    createBrainrotModel(brainrot, player, position)

    notifyRemote:FireClient(player, "Ai cumparat " .. brainrot.Name .. "!")
end)

Players.PlayerAdded:Connect(function(player)
    local data = loadData(player)
    playerData[player] = data

    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = data.Coins
    coins.Parent = leaderstats

    local streak = Instance.new("IntValue")
    streak.Name = "StealStreak"
    streak.Value = data.Streak
    streak.Parent = leaderstats

    player:SetAttribute("Coins", data.Coins)
    player:SetAttribute("Streak", data.Streak)

    task.defer(function()
        local plot = claimPlot(player)
        if plot then
            createShop(player)
            player:LoadCharacter()
        else
            notifyRemote:FireClient(player, "Serverul este plin!")
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    saveData(player)
    playerData[player] = nil

    local plot = playerPlots[player]
    if plot then
        plot:SetAttribute("OwnerUserId", nil)
        plot:SetAttribute("OwnerName", "")
        local sign = plot:FindFirstChild("PlotSign")
        local label = sign and sign:FindFirstChildOfClass("SurfaceGui") and sign:FindFirstChildOfClass("SurfaceGui"):FindFirstChildOfClass("TextLabel")
        if label then
            label.Text = "EMPTY BASE"
        end

        for _, model in ipairs(brainrotModels) do
            if model.Parent and model:GetAttribute("OwnerUserId") == player.UserId then
                model:Destroy()
            end
        end
        for _, child in ipairs(plot:GetChildren()) do
            if child.Name:match("^Shop_") then
                child:Destroy()
            end
        end
    end
    playerPlots[player] = nil
end)

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        saveData(player)
    end
end)

task.spawn(function()
    while true do
        task.wait(Config.IncomeInterval)
        for _, player in ipairs(Players:GetPlayers()) do
            updateIncome(player)
        end
    end
end)
