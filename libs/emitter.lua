local function emit(ast)
    -- 1. Створюємо таблицю, де ключі — це теги вузлів, а значення — функції
    local Emitters = {}

    Emitters["Number"] = function(node) return node.value end
    Emitters["String"] = function(node) return '"' .. node.value .. '"' end
    Emitters["Identifier"] = function(node) return node.name end
    
    Emitters["BinaryOp"] = function(node)
        return "(" .. Emitters[node.left.tag](node.left) .. " " .. node.op .. " " .. Emitters[node.right.tag](node.right) .. ")"
    end

    Emitters["Call"] = function(node)
        local args = {}
        for _, arg in ipairs(node.args) do
            table.insert(args, Emitters[arg.tag](arg))
        end
        return node.name .. "(" .. table.concat(args, ", ") .. ")"
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
        return node.name .. " = " .. Emitters[node.value.tag](node.value)
    end
    -- 2. Головна функція просто шукає потрібну функцію в таблиці за тегом!
    local function emit_node(node)
        local handler = Emitters[node.tag]
        if not handler then
            error("Unknown node: " .. tostring(node.tag))
        end
        return handler(node)
    end
    
    -- Головний цикл
    local lines = {}
    for _, node in ipairs(ast) do
        table.insert(lines, emit_node(node))
    end
    
    return table.concat(lines, "\n")
end
return emit