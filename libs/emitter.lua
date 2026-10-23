local function emit(ast)
    -- 1. Створюємо таблицю, де ключі — це теги вузлів, а значення — функції
    local Emitters = {}

    Emitters["Number"] = function(node) return node.value end
    Emitters["String"] = function(node) return '"' .. node.value .. '"' end
    Emitters["Identifier"] = function(node)
        if node.name == "args" then return "arg" end 
        return node.name 
    end
    
    Emitters["BinaryOp"] = function(node)
        return "(" .. Emitters[node.left.tag](node.left) .. " " .. node.op .. " " .. Emitters[node.right.tag](node.right) .. ")"
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
        if name_str == "read_file" then
            return "(function() local f = io.open(" .. Emitters[node.args[1].tag](node.args[1]) .. ", 'r'); if f then local c = f:read('*a'); f:close(); return c end end)()"
        elseif name_str == "write_file" then
            return ";(function() local f = io.open(" .. Emitters[node.args[1].tag](node.args[1]) .. ", 'w'); if f then f:write(" .. Emitters[node.args[2].tag](node.args[2]) .. "); f:close() end end)()"
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