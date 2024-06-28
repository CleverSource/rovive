local gravity = 9.81 -- TODO: Get this from the workspace
return function(velocity, angle, time)
    return velocity * math.sin(angle * math.pi/180) * time - 0.5 * gravity * time * time
end