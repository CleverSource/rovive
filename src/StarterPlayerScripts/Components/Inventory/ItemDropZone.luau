-- React
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

-- Components
local Components = script.Parent.Parent
local DroppableFrame = require(Components.DragDrop.DroppableFrame)

-- Remotes
local Remotes = require(ReplicatedStorage.Remotes).Client
local DropItemRemote = Remotes:Get("DropItem")

local function ItemDropZone(props)
    local ref = React.useRef(nil)

    return React.createElement(DroppableFrame, {
        dropId = "DropZone",
        dropRef = ref,
        onTargetDropped = function(data, gui)
            local icon = gui:FindFirstChild("Icon")
            if icon then
                icon:Destroy()
            end
            DropItemRemote:SendToServer(data)
        end,
        renderProps = {
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1)
        }
    }, {
        React.createElement("Frame", {
            AnchorPoint = props.AnchorPoint,
            BackgroundTransparency = 1,
            Position = props.Position,
            Size = props.Size,
            ref = ref
        })
    })
end

return ItemDropZone