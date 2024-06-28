local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Packages.Net)

return Net.CreateDefinitions({
    -- Game state
    GetState = Net.Definitions.ServerAsyncFunction(),
    StateChanged = Net.Definitions.ServerToClientEvent(),

    -- Inventory
    EquipItem = Net.Definitions.ClientToServerEvent(),
    UnequipItem = Net.Definitions.ClientToServerEvent(),
    -- MoveItem = Net.Definitions.ServerAsyncFunction()
})