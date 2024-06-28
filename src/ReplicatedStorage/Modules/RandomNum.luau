local RandomNumberGenerator = Random.new(math.pi * os.clock())
return function(min, max)
    return RandomNumberGenerator:NextInteger(min, max)
end