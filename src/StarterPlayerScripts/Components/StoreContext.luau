-- React
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

-- StoreContext
local StoreContext = React.createContext(nil)

return StoreContext