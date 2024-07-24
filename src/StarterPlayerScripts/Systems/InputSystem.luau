--[[
    Requirements:
    - ImportantState which is a list of states that are most important
        this is essentially for animations
        e.g. aiming is more important than sprinting
    - NonImportantState which is a list of non-important states, these are that are not important for animation
        but these states should still be checked for certain things
        such as, firing, for example
    - Blocked states, for example, you can't fire while reloading or aim while reloading
        and can not sprint while crouching

    Current states:
    Fire = { Enum.UserInputType.MouseButton1 },
    Reload = { Enum.KeyCode.R },
    Sprint = { Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift },
    Crouch = { Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl },
    Aim = { Enum.KeyCode.Q, Enum.UserInputType.MouseButton2 }
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Game Data
local GameDefaultKeybinds = require(ReplicatedStorage.GameDefaultKeybinds)

-- For animation
local ImportantStates = {
    "Aim",
    "Sprint"
}

-- If these states are active, then block those other states from happening.
local BlockedStates = {
    ["Reload"] = { "Fire", "Aim" }
}

-- If this state is happening, it can be stopped by another state
local OneOrOtherStates = {
    ["Sprint"] = { "Crouch" },
    ["Crouch"] = { "Sprint" },
    -- TODO: weird bug w/ aiming while meleeing
    ["Aim"] = { "Fire" }
}

-- States that must be manually stopped via code
local ManualStates = {
    -- "Fire",
    "Reload"
}

local _onStateChanged = Instance.new("BindableEvent")
local _bindToKey = Instance.new("BindableEvent")
local InputSystem = {
    Keybinds = {},
    States = {},
    Blocked = {},
    OnStateChanged = _onStateChanged.Event,
    BindTokey = _bindToKey.Event
}

-- For listening to player events
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
            if keybind and not self.Blocked[keybind] and self.States[keybind] == false then
                if BlockedStates[keybind] then
                    for _, state in BlockedStates[keybind] do
                        self:ToggleBlock(state)
                    end
                end

                if OneOrOtherStates[keybind] then
                    for _, state in OneOrOtherStates[keybind] do
                        self:ForceStopAction(state)
                    end
                end

                self.States[keybind] = true
                _onStateChanged:Fire(keybind, true, input)
            end
            _bindToKey:fire(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
        if not gameProcessedEvent then
            local keybind = self.Keybinds[input.KeyCode] or self.Keybinds[input.UserInputType]
            if keybind then
                if not table.find(ManualStates, keybind) then
                    self.States[keybind] = false
                    _onStateChanged:Fire(keybind, false, input)
                end
            end
            _bindToKey:fire(input)
        end
    end)
end

function InputSystem:ToggleBlock(state: string)
    self.Blocked[state] = not self.Blocked[state]
end

function InputSystem:IsStateActive(state: string)
    if not self.States[state] then
        return false
    end
    return true
end

function InputSystem:ForceStopAction(state: string)
    self.States[state] = false
    _onStateChanged:Fire(state, false, nil)

    if BlockedStates[state] then
        for _, blockedState in BlockedStates[state] do
            self.Blocked[blockedState] = false
        end
    end
end

function InputSystem:ForceStopActions(actions: table)
    for _, action in actions do
        self:ForceStopAction(action)
    end
end

function InputSystem:GetImportantState()
    local mostImportantState = nil
    for state, active in self.States do
        if active and table.find(ImportantStates, state) then
            local lastIndex = 1
            for index, _ in ImportantStates do
                if index > lastIndex then
                    mostImportantState = state
                    lastIndex = index
                end
            end
        end
    end
    return mostImportantState
end

function InputSystem:IsKeyActive(key)
    if type(key) == "userdata" then
        return UserInputService:IsKeyDown(key)
    elseif type(key) == "table" then
        for _, k in key do
            if UserInputService:IsKeyDown(k) then
                return true
            end
        end
    end
end

return InputSystem