local function prepareFile (filepath)
    local file = io.open(filepath, "r")
    if not file then return nil end
    local source = file:read("*a")
    file:close()
    return source
    
end

return prepareFile