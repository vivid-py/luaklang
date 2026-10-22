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
local prepareFile = require("libs.filePreparator")
local emit = require("libs.emitter")
local makeLuaOutFile = require("libs.makeoutlua")

local file = prepareFile(filePath)
if not file then
    print("Error, could not read file. ")
    os.exit(1)
end
local tokens = lex(file, KEYWORDS)
local parsedTokens = parse(tokens)

local lua_code = emit(parsedTokens)

local outfile = makeLuaOutFile(lua_code, "out.lua")

-- for i, statement in ipairs(parsedTokens) do
--     print("--- Statement " .. i .. " ---")
--     printAST(statement)
-- end


-- for _, tok in ipairs(tokens) do
--     print(string.format("[%s] %s", tok.type, tok.value))
-- end


