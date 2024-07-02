local Workspace = game:GetService("Workspace")

return function (toolObj)
    task.spawn(function()
        local anchorConn
        anchorConn = toolObj.Touched:Connect(function(hit)
            anchorConn:Disconnect()
            task.wait(1)
            if hit == Workspace.Terrain or hit:IsDescendantOf(Workspace.PlayerBuildings) then
                toolObj.Anchored = true
                toolObj.CanCollide = false
            end
        end)
    end)
end