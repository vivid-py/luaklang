local filePath = "main.luak"
local KEYWORDS = {
    ["let"] = true,
    ["if"] = true,
    ["do"] = true,
    ["int"] = true,
    ["float"] = true,
    ["string"] = true,
    ["print"] = true,
}
local lex = require("libs.lex")

local function prepareFile (filepath)
    local file = io.open(filepath, "r")
    if not file then return nil end

    local source = file:read("*a")
    file:close()
    return source
end

local file = prepareFile(filePath)
if not file then
    print("Error, could not read file. ")
    os.exit(1)
end
local tokens = lex(file, KEYWORDS)

for _, tok in ipairs(tokens) do
    print(string.format("[%s] %s", tok.type, tok.value))
end


