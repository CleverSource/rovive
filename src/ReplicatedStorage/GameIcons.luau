local Icons = {
    ["InventorySlot"] = 18568697614,
    ["DirtOverlay"] = 18568771810,
    ["Null"] = 18568859928
}

for iconName, icon in Icons do
    Icons[iconName] = "rbxassetid://" .. icon
end

return Icons