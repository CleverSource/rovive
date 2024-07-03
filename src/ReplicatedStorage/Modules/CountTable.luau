return function(tbl: table): () -> number 
    local i = 0
    for _, tbl in pairs(tbl) do
        i += 1
    end
    return i
end