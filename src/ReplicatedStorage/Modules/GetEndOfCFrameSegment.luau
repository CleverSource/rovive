return function(start: CFrame, last: CFrame)
    local distance = (start.Position - last.Position).Magnitude
    return CFrame.new(start.Position, last.Position) * CFrame.new(0, 0, -distance / 2)
end