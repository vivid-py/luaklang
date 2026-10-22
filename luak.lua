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
local parse = require("libs.parser")
local printAST = require("libs.debug")

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
local parsedTokens = parse(tokens)

-- Виводимо кожну інструкцію з масиву parsedTokens
for i, statement in ipairs(parsedTokens) do
    print("--- Statement " .. i .. " ---")
    printAST(statement)
end


-- for _, tok in ipairs(tokens) do
--     print(string.format("[%s] %s", tok.type, tok.value))
-- end


