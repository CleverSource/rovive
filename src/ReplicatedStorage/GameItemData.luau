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
        MaxAmmo: number -> The maximum amount of ammo the weapon can hold
        AmmoType: Item -> The type of ammo the weapon uses, links to an in-game item
        PlayerDamage: number -> The amount of damage the weapon can deal
        BulletPattern: BulletPattern (default: "Single") -> The pattern of the bullet
        BulletSpread: number -> The spread of the bullet, only applicable if BulletPattern is set to "Spread"
        BulletSpreadCount: number -> The amount of bullets that are shot from a spread, only applicable if BulletPattern is set to "Spread"
        BulletSpeed: number (default: 100) -> The speed of the bullet in meters/sec
        BulletMaxDistance: number -> The maximum distance the bullet can travel in studs. This is a HARD stop on the bullet -- if it reaches this distance, it won't register any hit.
        BulletAcceleration: Vector3 -> The acceleration of the bullet, this is a vector, because, in theory you can make bullets get pushed sideways -- wind for example
                                        or even upwards, like a rocket launcher
                                        Simply increasing bullet fall speed can be done by setting the Y-axis to a negative value (meters/sec)
                                        This is useful for causing bullets to end sooner than their max distance, or to make them fall faster.
        FireRate: number -> The rate of fire in seconds
]]

-- Custom types
export type WeaponType = "Bow" | "Gun" | "Melee"
export type BulletPattern = "Spread" | "Single"

export type StaticData = {
    Name: string,
    MaxStack: number,
    Equipable: boolean,
    WeaponType: WeaponType,
    PlayerDamage: number,
    BulletPattern: BulletPattern,
    BulletSpread: number,
    BulletSpreadCount: number,
    BulletSpeed: number,
    BulletMaxDistance: number,
    BulletAcceleration: Vector3,
    FireRate: number
}

-- The single source of truth for item data in the game.
local ItemData = {
    ["Wood"] = {
        MaxStack = 1000
    },

    ["Double Barrel"] = {
        Equipable = true,
        WeaponType = "Gun",
        MaxAmmo = 2,
        AmmoType = "Buckshot",

        PlayerDamage = 15,

        BulletPattern = "Spread",
        BulletSpread = 0.03,
        BulletSpreadCount = 6,
        BulletSpeed = 235,
        --BulletMaxDistance = 500,
        BulletMaxDistance = 80,
        BulletAcceleration = Vector3.new(0, -6, 0),

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