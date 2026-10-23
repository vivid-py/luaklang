local function typecheck(ast)
    local env = {}
    local Checkers = {}
    local walk -- Форвард-декларація

    Checkers["Number"] = function(node) return "int" end
    Checkers["String"] = function(node) return "string" end
    
    Checkers["Identifier"] = function(node)
        if node.name == "args" then return "[string]" end
        if node.name == "print" or node.name == "read_file" or node.name == "write_file" then return "function" end
        
        local var_type = env[node.name]
        if not var_type then
            error("TypeError: Undefined variable '" .. node.name .. "'")
        end
        return var_type
    end

    Checkers["Let"] = function(node)
        local value_type = Checkers[node.value.tag](node.value)
        if node.var_type ~= "any" and node.var_type ~= value_type and value_type ~= "any" and value_type ~= "function" then
            error("TypeError: Cannot assign " .. value_type .. " to variable of type " .. node.var_type)
        end
        env[node.name] = node.var_type
        return node.var_type
    end

    Checkers["BinaryOp"] = function(node)
        local left_type = Checkers[node.left.tag](node.left)
        local right_type = Checkers[node.right.tag](node.right)
        if left_type ~= right_type then
            error("TypeError: Cannot apply '" .. node.op .. "' to " .. left_type .. " and " .. right_type)
        end
        return left_type
    end

    Checkers["Assign"] = function(node)
        local target_type = Checkers[node.target.tag](node.target)
        local value_type = Checkers[node.value.tag](node.value)
        if target_type ~= value_type then
            error("TypeError: Cannot assign " .. value_type .. " to " .. target_type)
        end
    end

    -- ДОДАНО ПЕРЕВІРКУ ДЛЯ СТРУКТУР (потрібно для return { add: add })
    Checkers["Struct"] = function(node)
        for _, field in ipairs(node.fields) do
            walk(field.value)
        end
        return "struct"
    end

    -- ДОДАНО ПЕРЕВІРКУ ДЛЯ МАСИВІВ
    Checkers["Array"] = function(node)
        for _, el in ipairs(node.elements) do
            walk(el)
        end
        return "array"
    end

    Checkers["ExprStmt"] = function(node) walk(node.expression) end
    Checkers["If"] = function(node) return "void" end
    Checkers["While"] = function(node) return "void" end
    
    Checkers["Call"] = function(node)
        if node.target then walk(node.target) end
        for _, arg in ipairs(node.args) do walk(arg) end
        return "any"
    end

    Checkers["Import"] = function(node)
        env[node.name] = "module"
        return "void"
    end

    Checkers["Index"] = function(node)
        walk(node.target)
        walk(node.index)
        return "any"
    end

    Checkers["Property"] = function(node)
        walk(node.target)
        return "any"
    end

    Checkers["Fn"] = function(node)
        local old_env = {}
        for k, v in pairs(env) do old_env[k] = v end
        
        for _, param in ipairs(node.params) do
            env[param.name] = param.type
        end
        
        for _, stmt in ipairs(node.body) do
            walk(stmt)
        end
        
        env = old_env
        env[node.name] = "function" -- ДОДАНО: реєструємо функцію в середовищі
        return "function"
    end

    Checkers["Return"] = function(node)
        if node.value then
            return walk(node.value)
        end
        return "void"
    end

    -- ВИПРАВЛЕНО: прибрано 'local' перед function walk, щоб не затіняти змінну
    walk = function(node)
        local checker = Checkers[node.tag]
        if not checker then
            error("TypeChecker: Unknown node type " .. tostring(node.tag))
        end
        return checker(node)
    end

    for _, stmt in ipairs(ast) do
        walk(stmt)
    end
    
    print("Type check passed successfully!")
end

return typecheck