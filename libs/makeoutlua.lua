local function makeOut(lua_code, fileName)
    local out_file = io.open(fileName, "w")
    if out_file then
        out_file:write(lua_code)
        out_file:close()
        print("Succesfully compilated into " .. fileName)
    else
        print("Error: cant create file " .. fileName)
    end
end

return makeOut