-- React
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

-- Components
local Components = script.Parent.Parent
local DragDropContext = require(Components.DragDrop.DragDropContext)
local InternalDragDropContext = require(Components.DragDrop.InternalDragDropContext)

-- DragDropProvider
local DragDropProvider = React.Component:extend("DragDropProvider")

function DragDropProvider:init()
    local context = InternalDragDropContext.Default
    self.dropContext = context
end

function DragDropProvider:render()
    return React.createElement(DragDropContext.Provider, {
        value = self.dropContext
    }, self.props.children)
end

return DragDropProvider