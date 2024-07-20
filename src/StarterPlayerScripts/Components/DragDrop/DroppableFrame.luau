-- React
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

-- Hooks
local Hooks = script.Parent.Parent.Parent:WaitForChild("Hooks")
local useDragDrop = require(Hooks.useDragDrop)

-- DroppableFrame
local DroppableFrame = React.Component:extend("DroppableFrame")
function DroppableFrame:init(props)
    local dropContext = props.dropContext
    local dropRef = props.dropRef

    if not dropContext then
        error("A top-level DragDropProvider must be in the hierarchy.")
    end

    if props.dropId == nil then
        error("DroppableFrame requires a dropId prop to be set.")
    end

    self.dropContext = dropContext    
    self.dropRef = dropRef
end

function DroppableFrame:didMount()
    self.dropContext:dispatch({
        type = "AddTarget",
        target = self.dropRef,
        props = self.props
    })
end

function DroppableFrame:willUnmount()
    self.dropContext:dispatch({
        type = "RemoveTarget",
        target = self.dropRef
    })
end

function DroppableFrame:render()
    return React.createElement("Frame", self.props.renderProps, self.props.children)
end

return useDragDrop(DroppableFrame)
