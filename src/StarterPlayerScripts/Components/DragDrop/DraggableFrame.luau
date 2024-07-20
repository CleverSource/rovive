-- Services
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- React
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

-- Hooks
local Hooks = script.Parent.Parent.Parent:WaitForChild("Hooks")
local useDragDrop = require(Hooks.useDragDrop)

-- Systems
local Systems = ReplicatedStorage.Systems
local InventorySystem = require(Systems.InventorySystem)

-- Modules
local Modules = ReplicatedStorage.Modules
local CountTable = require(Modules.CountTable)

-- Variables
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- DraggableFrame
local DraggableFrame = React.Component:extend("DraggableFrame")

function DraggableFrame:init(props)
    local dropContext = props.dropContext
    local targetRef = props.targetRef

    if not dropContext then
        error("A top-level DragDropProvider must be in the hierarchy.")
    end

    if props.dropId == nil then
        error("DraggableFrame requires a dropId prop to be set.")
    end

    self.dropContext = dropContext
    self.targetRef = targetRef
    self._alive = true
    self:setState(self:computeProps())
end

function DraggableFrame:setDraggable(dragGui)
    local dropContext = self.props.dropContext

    if self._inputBegan then
        self._inputBegan:Disconnect()
        self._inputBegan = nil
    end

    if self._inputChanged then
        self._inputChanged:Disconnect()
        self._inputChanged = nil
    end

    if self._globalInputChanged then
        self._globalInputChanged:Disconnect()
        self._globalInputChanged = nil
    end

    local mouseDown = false
    local reachedDraggingThreshold = false

    if not dragGui then
        warn("Ref not set for " .. tostring(dragGui))
        
    end

    local dragInput

    local function update(input, targetGui)
        local startPos = self.startPos - UDim2.fromOffset(targetGui.AbsoluteSize.X * targetGui.AnchorPoint.X, targetGui.AbsoluteSize.Y * targetGui.AnchorPoint.Y)
        local delta = input.Position - self.dragStart

        if mouseDown and self.dragging then
            dropContext:dispatch({
                type = "Dragging",
                source = self.targetRef
            })
        end

        if mouseDown and delta.Magnitude >= 5 and not self.dragging then
            self.dragging = true
            dropContext:dispatch({
                type = "DragBegin",
                source = self.targetRef
            })
            reachedDraggingThreshold = true
        end

        self.position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X + targetGui.AbsoluteSize.X * targetGui.AnchorPoint.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y + targetGui.AbsoluteSize.Y * targetGui.AnchorPoint.Y
        )
        self:setState(self:computeProps())
    end

    self._inputBegan = dragGui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            mouseDown = true
            self.dragStart = input.Position
            self.startPos = dragGui.Position
            self.dropTargets = dropContext:GetTargetsByDropId(self.props.dropId)
            
            self._dragEvent = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    if reachedDraggingThreshold then
                        local dropped = false
                        local dropBinding = nil

                        local mousePos = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
                        local hoveredGui = PlayerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
                        for _, target in self.dropTargets do
                            local targetGui = target.Binding.current
                            if targetGui and not dropped then
                                for _, gui in hoveredGui do
                                    if gui == targetGui then
                                        dropContext:dispatch({
                                            type = "DropTarget",
                                            data = self.props.targetData,
                                            dropId = self.props.dropId,
                                            source = self.targetRef,
                                            target = target.Binding
                                        })
                                        dropBinding = target.DropData
                                        dropped = true
                                        break
                                    end
                                end
                            end
                        end

                        if self._alive then
                            if dropBinding ~= nil and dropped == true then
                                local playerData = InventorySystem:GetInventoryFromObject(Player)
                                local targetData = self.props.targetData
                                local dropData = dropBinding
                                local occupied = CountTable(playerData.RawData[dropData]) > 0

                                if occupied then
                                    -- TODO
                                    self.position = React.None
                                    self.dragging = false
                                    self:setState(self:computeProps())
                                else
                                    self.dragging = false
                                end
                            else
                                self.position = React.None
                                self.dragging = false
                                self:setState(self:computeProps())
                            end
                            mouseDown = false

                            dropContext:dispatch({
                                type = "DragEnd",
                                source = self.targetRef,
                                dropped = dropped
                            })
                            self._dragEvent:Disconnect()
                        end
                        reachedDraggingThreshold = false
                    else
                        mouseDown = false
                    end
                end
            end)
        end
    end)

    self._inputChanged = dragGui.InputChanged:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    self._globalInputChanged = UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and mouseDown then
            update(input, dragGui)
        end
    end)
end

function DraggableFrame:didMount()
    local gui = self.targetRef.current
    self.dropContext:dispatch({
        type = "AddSource",
        source = self.targetRef,
        props = self.props
    })
    self:setDraggable(gui)
end

function DraggableFrame:willUnmount()
    self._alive = false

    if self._inputBegan then
        self._inputBegan:Disconnect()
        self._inputBegan = nil
    end

    if self._inputChanged then
        self._inputChanged:Disconnect()
        self._inputChanged = nil
    end

    if self._globalInputChanged then
        self._globalInputChanged:Disconnect()
        self._globalInputChanged = nil
    end

    if self._dragEvent then
        self._dragEvent:Disconnect()
        self._dragEvent = nil
    end

    self.dropContext:dispatch({
        type = "RemoveSource",
        source = self.targetRef
    })
end

function DraggableFrame:computeProps()
    local computedProps = {
        Position = self.position
    }
    for key, value in next, self.props.renderProps do
        if key ~= "innerProps" and key ~= "children" then
            computedProps[key] = value
        end
    end
    return computedProps
end

function DraggableFrame:render()
    return React.createElement("Frame", self.state, self.props.children)
end

return useDragDrop(DraggableFrame)
