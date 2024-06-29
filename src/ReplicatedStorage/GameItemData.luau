--[[
    Note that some item data manipulates what an item literally is.
    For example, if an item has a weapon type, it is EXPECTED to be a weapon, with appropriate weapon data filled.
    If a default is not listed, then it's default is nil, or "blank."

    Formatted: [property_name]: property_type (default: default_value) -> Description

    ItemData:
        MaxStack: number (default: 1) -> The maximum amount of items that can be stacked in a single slot

        Weapon data properties:
        Equipable: boolean (default: false) -> Whether or not the item can be equipped
        WeaponType: WeaponType -> The type of weapon the item is
        PlayerDamage: number -> The amount of damage the weapon can deal
        BulletPattern: BulletPattern (default: "Single") -> The pattern of the bullet
        BulletSpread: number -> The spread of the bullet, only applicable if BulletPattern is set to "Spread"
        BulletSpreadCount: number -> The amount of bullets that are shot from a spread, only applicable if BulletPattern is set to "Spread"
        BulletSpeed: number (default: 100) -> The speed of the bullet in meters/sec
        BulletMaxDistance: number -> The maximum distance the bullet can travel in studs
        BulletAcceleration: Vector3 -> The acceleration of the bullet, this is a vector, because, in theory you can make bullets get pushed sideways -- wind for example
                                        or even upwards, like a rocket launcher
                                        Simply increasing bullet fall speed can be done by setting the Y-axis to a negative value (meters/sec)
        FireRate: number -> The rate of fire in seconds
]]

-- Custom types
export type WeaponType = "Bow" | "Gun" | "Melee"
export type BulletPattern = "Spread" | "Single"

-- The single source of truth for item data in the game.
local ItemData = {
    ["Wood"] = {
        MaxStack = 1000
    },

    ["Double Barrel"] = {
        Equipable = true,
        WeaponType = "Gun",

        PlayerDamage = 15,

        BulletPattern = "Spread",
        BulletSpread = 0.03,
        BulletSpreadCount = 6,
        BulletSpeed = 235,
        BulletMaxDistance = 500,

        FireRate = 0.4
    },

    ["Buckshot"] = {
        MaxStack = 60
    }
}

for itemName, itemData in ItemData do
    itemData.Name = itemName

    if itemData.MaxStack == nil then
        itemData.MaxStack = 1
    end

    if itemData.Equipable == nil then
        itemData.Equipable = false
    end
end

table.freeze(ItemData)
return ItemData