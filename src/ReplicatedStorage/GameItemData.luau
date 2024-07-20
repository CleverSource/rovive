--[[
    Note that some item data manipulates what an item literally is.
    For example, if an item has a weapon type, it is EXPECTED to be a weapon, with appropriate weapon data filled.
    If a default is not listed, then it's default is nil, or "blank."

    Under the hood, thrown melee items are just bullets.

    Formatted: [property_name]: property_type (default: default_value) -> Description

    ItemData:
        MaxStack: number (default: 1) -> The maximum amount of items that can be stacked in a single slot
        Icon: string or number -> The icon of the item, links to an in-game icon

        Weapon data properties:
        Equipable: boolean (default: false) -> Whether or not the item can be equipped
        WeaponType: WeaponType -> The type of weapon the item is
        MaxAmmo: number -> The maximum amount of ammo the weapon can hold
        AmmoType: Item -> The type of ammo the weapon uses, links to an in-game item
        PlayerDamage: number -> The amount of damage the weapon can deal

        MeleeMaxDistance: number -> The maximum distance the melee weapon can reach in studs

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
        Icon = 18568899548,
        MaxStack = 1000
    },

    ["Sawblade Axe"] = {
        Icon = 18568881613,

        Equipable = true,
        WeaponType = "Melee",

        PlayerDamage = 20,

        MeleeMaxDistance = 7,

        BulletMaxDistance = 120,
        BulletAcceleration = Vector3.new(0, -80, 0),

        FireRate = 1
    },

    ["Double Barrel"] = {
        Icon = 18568905098,

        Equipable = true,
        WeaponType = "Gun",
        MaxAmmo = 2,
        AmmoType = "Buckshot",

        PlayerDamage = 15,

        BulletPattern = "Spread",
        BulletSpread = 0.03,
        BulletSpreadCount = 6,
        BulletSpeed = 235,
        BulletMaxDistance = 105,
        BulletAcceleration = Vector3.new(0, -6, 0),

        FireRate = 0.4
    },

    ["Buckshot"] = {
        Icon = 18568910433,
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
    
    if itemData.Icon then
        itemData.Icon = "rbxassetid://" .. itemData.Icon
    end
end

table.freeze(ItemData)
return ItemData