local script_path = debug.getinfo(1, "S").source:sub(2)  -- прибираємо @
local script_dir = script_path:match("(.*/)") or "./"
package.path = script_dir .. "?.lua;" .. script_dir .. "?/init.lua;" .. package.path
local KEYWORDS = {
    ["let"] = true, ["if"] = true, ["do"] = true,
    ["int"] = true, ["float"] = true, ["string"] = true, ["bool"] = true,
    ["true"] = true, ["false"] = true, ["else"] = true, ["end"] = true,
    ["while"] = true, ["for"] = true, ["in"] = true,  -- <-- МАЄ БУТИ ТУТ
    ["return"] = true, ["import"] = true, ["from"] = true, ["and"] = true, ["or"] = true, ["not"] = true,
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
            
            -- Отримуємо папку, в якій лежить поточний файл (наприклад, "libs/tui/")
            local current_dir = filepath:match("(.*/)") or "./"
            
            local f = nil
            
            -- 1. Шукаємо в тій самій папці, де лежить поточний файл
            f = io.open(current_dir .. dep_luak, "r")
            if f then
                dep_luak = current_dir .. dep_luak
            else
                -- 2. Шукаємо в корені проєкту
                f = io.open(dep_luak, "r")
            end
            
            -- 3. Якщо не знайшли, шукаємо в папці компілятора (std/)
            if not f then
                local script_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)") or "./"
                f = io.open(script_dir .. dep_luak, "r")
                if f then
                    dep_luak = script_dir .. dep_luak 
                end
            end

            if f then
                f:close()
                build_file(dep_luak) -- Рекурсивно компілюємо залежність
            else
                print("Warning: Could not find module '" .. dep_path .. "'")
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
-- Запуск
local output_file = target_file:gsub("%.luak$", ".lua")
print("\n--- Running output --- \n")

local script_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)") or "./"
local current_dir = target_file:match("(.*/)") or "./"

-- Додаємо current_dir, щоб Lua бачила локальні файли
local lua_path_env = string.format("LUA_PATH='%s?.lua;%s?/init.lua;%s?.lua;%s?/init.lua;;' ", current_dir, current_dir, script_dir, script_dir)

os.execute(lua_path_env .. "lua " .. output_file)
