-- Services
local ServerStorage = game:GetService("ServerStorage")

-- Server Animations
local ServerAnimations = ServerStorage:WaitForChild("ServerAnimations")

-- ServerAnimator
local ServerAnimator = {}

function ServerAnimator:PlayAnimation(player, itemData)
    local character = player.Character
    local humanoid: Humanoid = character:FindFirstChild("Humanoid")
    local animator: Animator = humanoid:FindFirstChildOfClass("Animator")

    if character and humanoid then
        self:StopAnimations(player)
        
        local serverAnimation = ServerAnimations:FindFirstChild(self:FetchAnimationHoldType(itemData))
        if serverAnimation then
            local animation = animator:LoadAnimation(serverAnimation)
            animation:Play()
        else
            warn(`Can't find server animation for {itemData.Name}`)
        end
    end
end

function ServerAnimator:StopAnimations(player)
    local character = player.Character
    local humanoid: Humanoid = character:FindFirstChild("Humanoid")
    local animator: Animator = humanoid:FindFirstChildOfClass("Animator")

    for _, animation in pairs(animator:GetPlayingAnimationTracks()) do
        for _, serverAnimation in pairs(ServerAnimations:GetChildren()) do
            if animation.Name == serverAnimation.Name then
                animation:Stop()
                break
            end
        end
    end
end

function ServerAnimator:FetchAnimationHoldType(itemData)
    local staticData = itemData.StaticData
    if staticData and staticData.ServerHoldType then
        return staticData.ServerHoldType
    else
        warn("No ServerHoldType found for itemData", itemData)
    end
end

return ServerAnimator