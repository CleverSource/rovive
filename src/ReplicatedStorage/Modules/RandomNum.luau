local RandomNumberGenerator = Random.new()
return function(min, max)
    return RandomNumberGenerator:NextNumber(min, max)
end