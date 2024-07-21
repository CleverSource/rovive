local HttpService = game:GetService("HttpService")

local InternalDragDropContext = {}
InternalDragDropContext.__index = InternalDragDropContext

function InternalDragDropContext.new()
    return setmetatable({
        DragSources = {},
        DropTargets = {}
    }, InternalDragDropContext)
end

local function addSource(self, ref, props)
    local dropId = props.dropId
    local data = props.targetData
    local dragEnd = props.dragEnd
    local dragBegin = props.dragBegin
    local onDragging = props.onDragging

    self.DragSources[ref] = {
        dropId = dropId,
        data = data,
        dragBegin = dragBegin,
        target = {},
        Identifier = HttpService:GenerateGUID(false),
        dragEnd = dragEnd,
        onDragging = onDragging
    }
end

local function removeSource(self, ref)
    self.DragSources[ref] = nil
end

local function addTarget(self, ref, props)
    local dropIds, onDrop, dropRef, dropData = props.dropId, props.onTargetDropped, props.dropRef, props.dropData
    self.DropTargets[ref] = {
        dropIds = type(dropIds) == "table" and dropIds or { dropIds },
        onDrop = onDrop,
        dropRef = dropRef,
        dropData = dropData,
        Identifier = HttpService:GenerateGUID(false)
    }
end

local function removeTarget(self, ref)
    self.DropTargets[ref] = nil
end

function InternalDragDropContext:GetTargetsByDropId(dropId)
    local targets = {}

    for ref, target in next, self.DropTargets do
        for _, id in next, target.dropIds do
            if table.find(dropId, id) then
                table.insert(targets, {
                    Ref = ref,
                    Target = target,
                    OnDrop = target.onDrop,
                    DropRef = target.dropRef,
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