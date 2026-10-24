local KEYWORDS = {
    ["let"] = true, ["if"] = true, ["do"] = true,
    ["int"] = true, ["float"] = true, ["string"] = true, ["bool"] = true,
    ["true"] = true, ["false"] = true, ["else"] = true, ["end"] = true,
    ["while"] = true, ["return"] = true, ["import"] = true, ["from"] = true,
    ["for"] = true, ["in"] = true,
}

local lex = require("libs.lex")
local parse = require("libs.parser")
local emit = require("libs.emitter")
local typecheck = require("libs.typechecker")
local prepareFile = require("libs.filePreparator")
local makeLuaOutFile = require("libs.makeoutlua")

-- Головна функція збірки
local function build_file(filepath)
    print("Compiling: " .. filepath)
    
    -- 1. Читаємо файл за допомогою ТВОГО модуля
    local source = prepareFile(filepath)
    if not source then
        print("Error: Could not read " .. filepath)
        return
    end

    -- 2. Компілюємо
    local tokens = lex(source, KEYWORDS)
    local ast = parse(tokens)
    typecheck(ast)

    -- 3. ШУКАЄМО ІМПОРТИ (рекурсія)
    for _, node in ipairs(ast) do
        if node.tag == "Import" then
            local dep_path = node.path or node.name
            local dep_luak = dep_path .. ".luak"
            
            -- Перевіряємо, чи існує файл .luak
            local f = io.open(dep_luak, "r")
            if f then
                f:close()
                build_file(dep_luak) -- Рекурсивно компілюємо залежність
            end
        end
    end

    -- 4. Генеруємо код і зберігаємо (за допомогою ТВОГО модуля)
    local lua_code = emit(ast)
    local out_path = filepath:gsub("%.luak$", ".lua") -- змінюємо розширення на .lua
    makeLuaOutFile(lua_code, out_path)
end

-- Запуск (можна передавати файл через термінал: lua luak.lua main.luak)
local target_file = arg[1] or "main.luak"
build_file(target_file)

print("\n \n")
local output_file = target_file:gsub("%.luak$", ".lua")
print("\n--- Running output --- \n")
os.execute("lua " .. output_file) -- запускаємо main.lua, а не main.luak!
