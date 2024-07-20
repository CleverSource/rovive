local HttpService = game:GetService("HttpService")

local InternalDragDropContext = {}
InternalDragDropContext.__index = InternalDragDropContext

function InternalDragDropContext.new()
    return setmetatable({
        DragSources = {},
        DropTargets = {}
    }, InternalDragDropContext)
end

local function addSource(self, binding, props)
    local dropId = props.dropId
    local data = props.targetData
    local dragEnd = props.dragEnd
    local dragBegin = props.dragBegin
    local onDragging = props.onDragging

    self.DragSources[binding] = {
        dropId = dropId,
        data = data,
        dragBegin = dragBegin,
        target = {},
        Identifier = HttpService:GenerateGUID(false),
        dragEnd = dragEnd,
        onDragging = onDragging
    }
end

local function removeSource(self, binding)
    self.DragSources[binding] = nil
end

local function addTarget(self, binding, props)
    local dropIds, onDrop, dropBinding, dropData = props.dropId, props.onTargetDropped, props.dropRef, props.dropData
    self.DropTargets[binding] = {
        dropIds = type(dropIds) == "table" and dropIds or { dropIds },
        onDrop = onDrop,
        dropBinding = dropBinding,
        dropData = dropData,
        Identifier = HttpService:GenerateGUID(false)
    }
end

local function removeTarget(self, binding)
    self.DropTargets[binding] = nil
end

function InternalDragDropContext:GetTargetsByDropId(dropId)
    local targets = {}

    for binding, target in next, self.DropTargets do
        for _, id in next, target.dropIds do
            if id == dropId then
                table.insert(targets, {
                    Binding = binding,
                    Target = target,
                    OnDrop = target.onDrop,
                    DropBinding = target.dropBinding,
                    DropData = target.dropData 
                })
            end
        end
    end

    return targets
end

function InternalDragDropContext:dispatch(action)
    if type(action) ~= "table" then
        error("Invalid dispatch params")
    end

    if type(action.type) ~= "string" then
        error("action.type must be a string!")
    end

    local dragSources = self.DragSources
    local dropTargets = self.DropTargets

    if action.type == "AddSource" then
        addSource(self, action.source, action.props)
    elseif action.type == "AddTarget" then
        addTarget(self, action.target, action.props)
    elseif action.type == "Dragging" then
        local source = dragSources[action.source]
        if type(source.onDragging) == "function" then
            source.onDragging()
        end
    elseif action.type == "DragBegin" then
        local source = dragSources[action.source]
        if type(source.dragBegin) == "function" then
            source.dragBegin()
        end
    elseif action.type == "DragEnd" then
        local dropped = action.dropped
        local source = dragSources[action.source]

        if type(source.dragEnd) == "function" then
            source.dragEnd(dropped)
        end
    elseif action.type == "DropTarget" then
        local target = dropTargets[action.target]
        local canDrop = true

        if canDrop then
            local gui = action.source:getValue()
            target.onDrop(action.data, gui)
        end
    elseif action.type == "RemoveSource" then
        removeSource(self, action.source)
    elseif action.type == "RemoveTarget" then
        removeTarget(self, action.target)
    end
end

InternalDragDropContext.Default = InternalDragDropContext.new()

return InternalDragDropContext