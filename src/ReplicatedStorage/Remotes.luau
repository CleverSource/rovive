local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Packages.Net)

return Net.CreateDefinitions({
    -- Game state
    GetState = Net.Definitions.ServerAsyncFunction(),
    StateChanged = Net.Definitions.ServerToClientEvent(),

    -- Inventory
    -- MoveItem = Net.Definitions.ServerAsyncFunction()
})