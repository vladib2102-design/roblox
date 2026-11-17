local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local buyRemote = remotes:WaitForChild("BuyBrainrot")
local notifyRemote = remotes:WaitForChild("Notify")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local top = Instance.new("Frame")
top.Size = UDim2.fromOffset(280, 72)
top.Position = UDim2.new(0.5, -140, 0, 20)
top.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
top.BackgroundTransparency = 0.12
top.BorderSizePixel = 0
top.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = top

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.new(0.65, 0, 1, 0)
coinsLabel.BackgroundTransparency = 1
coinsLabel.Text = "$0"
coinsLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
coinsLabel.TextScaled = true
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.Parent = top

local streakLabel = Instance.new("TextLabel")
streakLabel.Position = UDim2.new(0.65, 0, 0, 0)
streakLabel.Size = UDim2.new(0.35, 0, 1, 0)
streakLabel.BackgroundTransparency = 1
streakLabel.Text = "FURAT: 0"
streakLabel.TextColor3 = Color3.fromRGB(255, 100, 170)
streakLabel.TextScaled = true
streakLabel.Font = Enum.Font.GothamBold
streakLabel.Parent = top

local shop = Instance.new("Frame")
shop.Name = "Shop"
shop.Size = UDim2.fromOffset(230, 260)
shop.Position = UDim2.new(1, -250, 0.5, -130)
shop.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
shop.BackgroundTransparency = 0.08
shop.BorderSizePixel = 0
shop.Parent = gui

local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 14)
shopCorner.Parent = shop

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 46)
title.BackgroundTransparency = 1
title.Text = "MAGAZIN BRAINROT"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = shop

for index, brainrot in ipairs(Config.Brainrots) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.86, 0, 0, 54)
    button.Position = UDim2.new(0.07, 0, 0, 50 + (index - 1) * 64)
    button.BackgroundColor3 = brainrot.Color
    button.Text = brainrot.Name .. "\n$" .. brainrot.Cost
    button.TextColor3 = Color3.fromRGB(20, 20, 25)
    button.TextScaled = true
    button.Font = Enum.Font.GothamBold
    button.BorderSizePixel = 0
    button.Parent = shop

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 10)
    buttonCorner.Parent = button

    button.Activated:Connect(function()
        buyRemote:FireServer(brainrot.Id)
    end)
end

local toast = Instance.new("TextLabel")
toast.Size = UDim2.fromOffset(360, 58)
toast.Position = UDim2.new(0.5, -180, 1, -86)
toast.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
toast.BackgroundTransparency = 0.12
toast.Text = ""
toast.TextColor3 = Color3.new(1, 1, 1)
toast.TextScaled = true
toast.Font = Enum.Font.GothamBold
toast.Visible = false
toast.Parent = gui

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 12)
toastCorner.Parent = toast

local function refresh()
    coinsLabel.Text = "$" .. tostring(player:GetAttribute("Coins") or 0)
    streakLabel.Text = "FURAT: " .. tostring(player:GetAttribute("Streak") or 0)
end

player:GetAttributeChangedSignal("Coins"):Connect(refresh)
player:GetAttributeChangedSignal("Streak"):Connect(refresh)
refresh()

notifyRemote.OnClientEvent:Connect(function(message)
    toast.Text = message
    toast.Visible = true
    task.delay(3, function()
        toast.Visible = false
    end)
end)
