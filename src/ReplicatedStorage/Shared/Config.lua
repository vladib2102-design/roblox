local Config = {}

Config.StartingCoins = 100
Config.StartingStreak = 0
Config.StealCooldown = 30
Config.IncomeInterval = 5
Config.MaxPlayersPerServer = 6

Config.Brainrots = {
    {
        Id = "wooden",
        Name = "Pinguino",
        Cost = 100,
        Income = 8,
        Color = Color3.fromRGB(180, 220, 255),
        ModelScale = 1,
    },
    {
        Id = "neon",
        Name = "Cappuccino",
        Cost = 500,
        Income = 35,
        Color = Color3.fromRGB(255, 80, 210),
        ModelScale = 1.15,
    },
    {
        Id = "legendary",
        Name = "Sigma Crocodilo",
        Cost = 2500,
        Income = 180,
        Color = Color3.fromRGB(255, 220, 60),
        ModelScale = 1.3,
    },
}

return Config
