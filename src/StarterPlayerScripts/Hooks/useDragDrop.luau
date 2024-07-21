-- React
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

-- Components
local Components = script.Parent.Parent:WaitForChild("Components")
local DragDropContext = require(Components.DragDrop.DragDropContext)

return function(innerComponent)
    local componentName = (`DragDropConnection{tostring(innerComponent)}`)
    local connection = React.Component:extend(componentName)

    function connection:init(props)
        self.dropContext = props.dropContext

        if self.dropContext == nil then
            error("Cannot initialize useStore connection without being a descendent of StoreProvider!")
        end

        self:setState(self:computeProps())
    end

    function connection:computeProps()
        local computedProps = {
            dropContext = self.dropContext
        }

        local function mergeRenderProps(target, source)
            for key, value in next, source do
                if key ~= "innerProps" and key ~= "children" then
                    target[key] = value
                elseif key == "renderProps" then
                    for renderKey, renderValue in next, value do
                        target.renderProps[renderKey] = renderValue
                    end
                end 
            end
        end

        mergeRenderProps(computedProps, self.props)

        if self.props.innerProps then
            mergeRenderProps(computedProps, self.props.innerProps)
        end

        return computedProps
    end

    function connection:render()
        return React.createElement(innerComponent, self.state, self.props.innerProps.children)
    end

    local connectedComponent = React.Component:extend(componentName)

    function connectedComponent:render()
        return React.createElement(DragDropContext.Consumer, nil, function(dropContext)
            return React.createElement(connection, {
                innerProps = self.props,
                dropContext = dropContext
            })
        end)
    end

    return connectedComponent
end