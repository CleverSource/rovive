-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Game Data
local GameDefaultKeybinds = require(ReplicatedStorage.GameDefaultKeybinds)

local _onStateChanged = Instance.new("BindableEvent")
local InputSystem = {
    Keybinds = {},
    States = {},
    OnStateChanged = _onStateChanged.Event
}

-- TODO: input system will need a rework soon.. likely

local ImportantStateOrder = {
    "Aim",
    "Sprint"
}

local NonImportantStates = {
    ["Crouch"] = true,
    ["Reload"] = true,
    ["Fire"] = true,
}

function InputSystem:MapKeybinds()
    for name, keybind in GameDefaultKeybinds do
        self.States[name] = false
        if type(keybind) == "table" then
            for _, key in keybind do
                self.Keybinds[key] = name
            end
        end
    end

    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if not gameProcessedEvent then
            local keybind = self.Keybinds[input.KeyCode] or self.Keybinds[input.UserInputType]
            if keybind then
                self.States[keybind] = true
                _onStateChanged:Fire(keybind, true)
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
        if not gameProcessedEvent then
            local keybind = self.Keybinds[input.KeyCode] or self.Keybinds[input.UserInputType]
            if keybind then
                self.States[keybind] = false
                _onStateChanged:Fire(keybind, false)
            end
        end
    end)
end

function InputSystem:IsStateActive(state)
    if not self.States[state] then
        return false
    end
    return self.States[state]
end

function InputSystem:ForceStopAction(state)
    self.States[state] = false
end

function InputSystem:GetImportantState()
    local mostImportantState = nil
    for state, active in self.States do
        if active and NonImportantStates[state] == nil then
            local lastIndex = 1
            for index, _ in ImportantStateOrder do
                if index > lastIndex then
                    mostImportantState = state
                    lastIndex = index
                end
            end
        end
    end
    return mostImportantState
end

return InputSystem