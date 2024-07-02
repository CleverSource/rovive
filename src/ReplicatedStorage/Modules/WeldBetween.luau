return function(a, b)
    local weld = Instance.new("Weld", a)
    weld.C0 = a.CFrame:Inverse() * b.CFrame
    weld.Part0 = a
    weld.Part1 = b
end