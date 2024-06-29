local RandomNumberGenerator = Random.new(math.pi)
return function(min, max)
    return RandomNumberGenerator:NextInteger(min, max)
end