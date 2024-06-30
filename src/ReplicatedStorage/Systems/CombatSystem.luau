-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Modules
local GetStaticData = require(ReplicatedStorage.Modules.GetStaticData)
local VerticalPositionAtTime = require(ReplicatedStorage.Modules.VerticalPositionAtTime)
local RandomNum = require(ReplicatedStorage.Modules.RandomNum)

-- Variables
local CurrentCamera = Workspace.CurrentCamera

-- Functions
local function MetersToStuds(meters)
    return meters / 0.05
end

-- Combat System
local CombatSystem = {}

function CombatSystem:CanPierceObject()
    return false    
end

function CombatSystem:CalculateRaycast(weapon, origin)
    local timeOffset = 20
    local staticData = GetStaticData(weapon.Name)
    local bulletSpeed = staticData.BulletSpeed or 100

    local spread = Vector3.new()
    if staticData.BulletPattern == "Spread" then
        local spreadAmount = staticData.BulletSpread * 100
        spread = Vector3.new(RandomNum(-spreadAmount, spreadAmount) / 100, RandomNum(-spreadAmount, spreadAmount) / 100, RandomNum(-spreadAmount, spreadAmount) / 100)
    end

    local shootingAngle = math.rad(origin.LookVector.Y * 90)
    shootingAngle = shootingAngle < 0 and 0 or shootingAngle

    local xChange = MetersToStuds(bulletSpeed * timeOffset)
    local yChange = VerticalPositionAtTime(bulletSpeed, shootingAngle, timeOffset)

    local raycastedPoint: CFrame = (origin * CFrame.new(0, yChange, 0)) + ((origin.LookVector + spread) * xChange)
    local rayStart = origin.Position
    local rayDistance = (origin.Position - raycastedPoint.Position).Magnitude
    local rayDirection = (raycastedPoint.Position - origin.Position).Unit * rayDistance
    
    return rayStart, rayDirection, raycastedPoint
end

function CombatSystem:FindHitLocation(player, calculatedRayData, ignoreWater)
    local rayStart, rayDirection = unpack(calculatedRayData)
    
    local raycastParams = RaycastParams.new()
    raycastParams.IgnoreWater = ignoreWater == nil and true or false
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { CurrentCamera, player.Character, Workspace.Debris, Workspace.Bullets }

    local ray: RaycastResult = Workspace:Raycast(rayStart, rayDirection, raycastParams)

    return ray
end

return CombatSystem