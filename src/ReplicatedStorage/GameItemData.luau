-- The single source of truth for item data in the game.
local ItemData = {
    ["Wood"] = {
        MaxStack = 1000
    },

    ["Double Barrel"] = {
        Equipable = true,
        WeaponType = "Gun", -- Bow, Gun, Melee,

        PlayerDamage = 15, -- The amount a projectile can damage from this weapon

        BulletPattern = "Spread", -- Single, Spread
        BulletSpread = 0.03, -- If spread, how much spread outwards (radius)
        BulletSpreadCount = 6, -- Amount of actual projectiles that come from spread
        BulletSpeed = 80, -- Measured in meters/sec

        FireRate = 0.4 -- Rate of fire in seconds
    }
}

export type WeaponType = "Bow" | "Gun" | "Melee"
export type BulletPattern = "Spread" | "Single"

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