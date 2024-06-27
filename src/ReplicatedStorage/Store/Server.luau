-- Singleton Store
-- This is the SINGLE source of truth for game state
local _onStateChanged = Instance.new("BindableEvent")
local Store = {
    _state = nil,
    OnStateChanged = _onStateChanged.Event
}
Store.__index = Store

function Store.new()
    if Store._instance then
        return Store._instance
    end

    local store = setmetatable({}, Store)
    
    Store._instance = store

    -- Initial game state
    store:SetState({
        GlobalInventory = {}
    })

    return store
end

function Store:GetState()
    return self._state
end

function Store:SetState(state)
    self._state = state
    _onStateChanged:Fire(state)
end

return Store