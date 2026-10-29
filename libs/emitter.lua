local function emit(ast)
    -- 1. Створюємо таблицю, де ключі — це теги вузлів, а значення — функції
    local Emitters = {}
    Emitters["Bool"] = function(node) 
        return tostring(node.value) 
    end
    Emitters["Number"] = function(node) return node.value end
    Emitters["String"] = function(node) return '"' .. node.value .. '"' end
    Emitters["Identifier"] = function(node)
        if node.name == "args" then return "arg" end 
        return node.name 
    end
    
    Emitters["BinaryOp"] = function(node)
        local op = node.op
        if op == "!=" then op = "~=" end -- Lua використовує ~=
        if op == "**" then op = "^" end
        return "(" .. Emitters[node.left.tag](node.left) .. " " .. op .. " " .. Emitters[node.right.tag](node.right) .. ")"
    end
    Emitters["UnaryOp"] = function(node)
        if node.op == "not" then
            return "(not " .. Emitters[node.operand.tag](node.operand) .. ")"
        else
            return "(-" .. Emitters[node.operand.tag](node.operand) .. ")"
        end
    end

    Emitters["Call"] = function(node)
        -- Визначаємо ім'я функції (воно може бути в target або просто name)
        local func_name = ""
        if node.target then
            func_name = Emitters[node.target.tag](node.target)
        elseif node.name then
            func_name = node.name
        end

        local name_str = node.name or (node.target and node.target.name)

        -- Вбудовані функції
        if name_str == "print" then
            local args = {}
            for _, arg in ipairs(node.args) do
                table.insert(args, Emitters[arg.tag](arg))
            end
            -- Використовуємо io.write, щоб НЕ було переносу рядка
            return "io.write(" .. table.concat(args, ", ") .. "); io.flush()"
        elseif name_str == "println" then
            local args = {}
            for _, arg in ipairs(node.args) do
                table.insert(args, Emitters[arg.tag](arg))
            end
            -- Використовуємо стандартний print, який додає \n
            return "print(" .. table.concat(args, ", ") .. ")"
        elseif name_str == "len" then
            return "#(" .. Emitters[node.args[1].tag](node.args[1]) .. ")"
        elseif name_str == "read_file" then
            return "(function() local f = io.open(" .. Emitters[node.args[1].tag](node.args[1]) .. ", 'r'); if f then local c = f:read('*a'); f:close(); return c end end)()"
        elseif name_str == "write_file" then
            return ";(function() local f = io.open(" .. Emitters[node.args[1].tag](node.args[1]) .. ", 'w'); if f then f:write(" .. Emitters[node.args[2].tag](node.args[2]) .. "); f:close() end end)()"
        elseif name_str == "exec" then
        -- Просто виконує команду в терміналі (os.execute)
            return "os.execute(" .. Emitters[node.args[1].tag](node.args[1]) .. ")"
        elseif name_str == "exec_out" then
        -- Виконує команду і повертає вивід як рядок (io.popen)
            return "(function() local handle = io.popen(" .. Emitters[node.args[1].tag](node.args[1]) .. ", 'r'); if handle then local res = handle:read('*a'); handle:close(); return res end end)()"
        elseif name_str == "push" then
            return "table.insert(" .. Emitters[node.args[1].tag](node.args[1]) .. ", " .. Emitters[node.args[2].tag](node.args[2]) .. ")"
        -- Вставити за індексом
        elseif name_str == "insert_at" then
            -- Додаємо +1 до індексу, бо в luak 0-based, а в Lua 1-based
            return "table.insert(" .. Emitters[node.args[1].tag](node.args[1]) .. ", " .. Emitters[node.args[2].tag](node.args[2]) .. " + 1, " .. Emitters[node.args[3].tag](node.args[3]) .. ")"
        elseif name_str == "remove_at" then
            return "table.remove(" .. Emitters[node.args[1].tag](node.args[1]) .. ", " .. Emitters[node.args[2].tag](node.args[2]) .. " + 1)"
        -- Отримати довжину рядка або масиву
        elseif name_str == "len" then
            return "#(" .. Emitters[node.args[1].tag](node.args[1]) .. ")"
        elseif name_str == "substring" then
            -- Теж додаємо +1 до start та end
            return "string.sub(" .. Emitters[node.args[1].tag](node.args[1]) .. ", " .. Emitters[node.args[2].tag](node.args[2]) .. " + 1, " .. Emitters[node.args[3].tag](node.args[3]) .. " + 1)"
        elseif name_str == "char_at" then
            -- Отримати один символ
            return "string.sub(" .. Emitters[node.args[1].tag](node.args[1]) .. ", " .. Emitters[node.args[2].tag](node.args[2]) .. ", " .. Emitters[node.args[2].tag](node.args[2]) .. ")"
        elseif name_str == "read_key" then
         -- 1. Читаємо перший байт. 
         -- 2. Якщо це ESC (\27), намагаємось прочитати другий байт.
         -- 3. Якщо другого байта немає (nil або "") - це чистий ESC.
         -- 4. Якщо другий байт є, але це НЕ '[' і НЕ 'O' - це все одно чистий ESC (а сміття ігноруємо).
         return "(function() local c = io.read(1); if not c then return '' end; if c == '\\27' then local c2 = io.read(1); if not c2 or c2 == '' then return '\\27' end; if c2 == '[' or c2 == 'O' then local c3 = io.read(1); return c .. c2 .. (c3 or '') else return '\\27' end else local b = string.byte(c); if b >= 128 then local n = 0; if b >= 240 then n = 3 elseif b >= 224 then n = 2 elseif b >= 192 then n = 1 end; local rest = ''; while #rest < n do local chunk = io.read(1); if not chunk then break end; rest = rest .. chunk end; return c .. rest else return c end end end)()"
        elseif name_str == "utf8_len" then
            return "utf8.len(" .. Emitters[node.args[1].tag](node.args[1]) .. ")"
        elseif name_str == "split_lines" then
            -- Надійний спліт: додаємо \n в кінець, щоб захопити останній рядок,
            -- і НЕ фільтруємо порожні рядки.
            return "(function(text) local lines = {}; for line in (text .. '\\n'):gmatch('(.-)\\n') do table.insert(lines, line) end; return lines end)(" .. Emitters[node.args[1].tag](node.args[1]) .. ")"
        elseif name_str == "join_lines" then
            -- Склеює масив рядків у один текст
            return "table.concat(" .. Emitters[node.args[1].tag](node.args[1]) .. ", '\\n')" 
        elseif name_str == "utf8_sub" then
            -- Безпечне обрізання: якщо finish виходить за межі, беремо кінець рядка
            return "(function(s, i, j) local start = utf8.offset(s, i + 1); if not start then return '' end; local finish = utf8.offset(s, j + 2); if not finish then finish = #s + 1 end; return string.sub(s, start, finish - 1) end)(" .. Emitters[node.args[1].tag](node.args[1]) .. ", " .. Emitters[node.args[2].tag](node.args[2]) .. ", " .. Emitters[node.args[3].tag](node.args[3]) .. ")"
        end
  
        
        -- Звичайний виклик
        local args = {}
        for _, arg in ipairs(node.args) do
            table.insert(args, Emitters[arg.tag](arg))
        end
        return func_name .. "(" .. table.concat(args, ", ") .. ")"
    end

    Emitters["Let"] = function(node)
        return "local " .. node.name .. " = " .. Emitters[node.value.tag](node.value)
    end

    Emitters["If"] = function(node)
        local code = "if " .. Emitters[node.condition.tag](node.condition) .. " then\n"
        for _, stmt in ipairs(node.then_block) do
            code = code .. "  " .. Emitters[stmt.tag](stmt) .. "\n"
        end
        if node.else_block then
            code = code .. "else\n"
            for _, stmt in ipairs(node.else_block) do
                code = code .. "  " .. Emitters[stmt.tag](stmt) .. "\n"
            end
        end
        code = code .. "end"
        return code
    end
    Emitters["While"] = function(node)
        local code = "while " .. Emitters[node.condition.tag](node.condition) .. " do\n"
        
        for _, stmt in ipairs(node.body) do
            code = code .. "  " .. Emitters[stmt.tag](stmt) .. "\n"
        end
        
        code = code .. "end"
        return code
    end
    Emitters["ForRange"] = function(node)
        local code = "for " .. node.var_name .. " = " .. 
                    Emitters[node.start.tag](node.start) .. ", " .. 
                    Emitters[node.finish.tag](node.finish) .. " do\n"
        for _, stmt in ipairs(node.body) do
            code = code .. "  " .. Emitters[stmt.tag](stmt) .. "\n"
        end
        code = code .. "end"
        return code
    end

    Emitters["ForIn"] = function(node)
        local code = "for _, " .. node.var_name .. " in ipairs(" .. 
                    Emitters[node.collection.tag](node.collection) .. ") do\n"
        for _, stmt in ipairs(node.body) do
            code = code .. "  " .. Emitters[stmt.tag](stmt) .. "\n"
        end
        code = code .. "end"
        return code
    end
    Emitters["Assign"] = function(node)
        -- target тепер може бути змінною або властивістю
        return Emitters[node.target.tag](node.target) .. " = " .. Emitters[node.value.tag](node.value)
    end
    -- 2. Головна функція просто шукає потрібну функцію в таблиці за тегом!
    local function emit_node(node)
        local handler = Emitters[node.tag]
        if not handler then
            error("Unknown node: " .. tostring(node.tag))
        end
        return handler(node)
    end
    Emitters["Fn"] = function(node)
        local param_names = {}
        for _, p in ipairs(node.params) do
            table.insert(param_names, p.name)
        end
        
        local code = "local function " .. node.name .. "(" .. table.concat(param_names, ", ") .. ")\n"
        
        -- ОСЬ ВОНА, МАГІЯ ДЕФОЛТНИХ ЗНАЧЕНЬ
        for _, p in ipairs(node.params) do
            if p.default then
                code = code .. "  if " .. p.name .. " == nil then " .. p.name .. " = " .. Emitters[p.default.tag](p.default) .. " end\n"
            end
        end
        
        for _, stmt in ipairs(node.body) do
            code = code .. "  " .. Emitters[stmt.tag](stmt) .. "\n"
        end
        code = code .. "end"
        return code
    end
    Emitters["Return"] = function(node)
        if node.value then
            return "return " .. Emitters[node.value.tag](node.value)
        else
            return "return"
        end
    end
    Emitters["Array"] = function(node)
        local elements = {}
        for _, el in ipairs(node.elements) do
            table.insert(elements, Emitters[el.tag](el))
        end
        return "{" .. table.concat(elements, ", ") .. "}"
    end

    Emitters["Index"] = function(node)
        local target_code = Emitters[node.target.tag](node.target)
        local index_code = Emitters[node.index.tag](node.index)
        -- ОСЬ ВОНА, МАГІЯ 0-BASED -> 1-BASED
        return target_code .. "[" .. index_code .. " + 1]"
    end
    Emitters["Struct"] = function(node)
        local fields = {}
        for _, f in ipairs(node.fields) do
            -- У Lua структура це { key = value }, тому міняємо : на =
            table.insert(fields, f.key .. " = " .. Emitters[f.value.tag](f.value))
        end
        return "{ " .. table.concat(fields, ", ") .. " }"
    end
    Emitters["Property"] = function(node)
        -- Генеруємо a.b.c
        return Emitters[node.target.tag](node.target) .. "." .. node.property
    end
    Emitters["ExprStmt"] = function(node)
        return Emitters[node.expression.tag](node.expression)
    end
    Emitters["Import"] = function(node)
        local req_path = node.path or node.name
        req_path = req_path:gsub("/", ".")
        return "local " .. node.name .. " = require(\"" .. req_path .. "\")"
    end
    -- Головний цикл
    local lines = {}
    for _, node in ipairs(ast) do
        table.insert(lines, emit_node(node))
    end
    
    return table.concat(lines, "\n")
end
return emit