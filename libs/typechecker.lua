local function typecheck(ast)
    local env = {}
    local Checkers = {}
    local walk

    Checkers["Number"] = function(node)
        if string.find(node.value, "%.", 1, true) then
            return "float"
        end
        return "int"
    end
    Checkers["String"] = function(node) return "string" end
    Checkers["Bool"] = function(node) return "bool" end
    
    Checkers["Identifier"] = function(node)
        if node.name == "args" then return "[string]" end
        if node.name == "print" or node.name == "println" or node.name == "read_file" or node.name == "write_file" or node.name == "exec" or node.name == "exec_out" or node.name == "read_key" or node.name == "len" or node.name == "push"  or node.name == "insert_at" or node.name == "remove_at" or node.name == "substring" or node.name == "char_at" then return "function" end
        
        local var_type = env[node.name]
        if not var_type then
            error("TypeError: Undefined variable '" .. node.name .. "'")
        end
        return var_type
    end

    Checkers["Let"] = function(node)
        local value_type = walk(node.value)
        if node.var_type ~= "any" and node.var_type ~= value_type and value_type ~= "any" and value_type ~= "function" then
            error("TypeError: Cannot assign " .. value_type .. " to variable of type " .. node.var_type)
        end
        env[node.name] = node.var_type
        return node.var_type
    end

    Checkers["BinaryOp"] = function(node)
        local left_type = walk(node.left)
        local right_type = walk(node.right)
        
        local op = node.op
        if op == "and" or op == "or" then
            if left_type ~= "bool" or right_type ~= "bool" then
                error("TypeError: Operator '" .. op .. "' requires bool operands")
            end
            return "bool"
        end
        if op == ".." then
            -- Можна склеювати рядки з чим завгодно
            if left_type == "string" or right_type == "string" then
                return "string"
            end
            error("TypeError: Concatenation requires at least one string")
        end
        -- Математика: дозволяємо змішувати int та float
        if op == "+" or op == "-" or op == "*" or op == "/" or op == "%" or op == "**" then
            if left_type == "float" or right_type == "float" then
                return "float"
            end
            return "int"
        end
        
        -- Порівняння: типи мають співпадати (окрім int/float)
        if left_type ~= right_type and left_type ~= "any" and right_type ~= "any" 
           and not (left_type == "float" and right_type == "int") 
           and not (left_type == "int" and right_type == "float") then
            error("TypeError: Cannot compare " .. left_type .. " and " .. right_type)
        end
        
        -- Оператори порівняння повертають bool
        if op == "==" or op == "!=" or op == "<" or op == ">" or op == "<=" or op == ">=" then
            return "bool"
        end
        
        return left_type
    end

    Checkers["UnaryOp"] = function(node)
        local operand_type = walk(node.operand)
        if node.op == "not" and operand_type ~= "bool" then
            error("TypeError: Operator 'not' requires a bool operand")
        end
        return operand_type
    end

    Checkers["Assign"] = function(node)
        local target_type = walk(node.target)
        local value_type = walk(node.value)
        if target_type ~= value_type then
            error("TypeError: Cannot assign " .. value_type .. " to " .. target_type)
        end
    end

    Checkers["Struct"] = function(node)
        for _, field in ipairs(node.fields) do
            walk(field.value)
        end
        return "struct"
    end

    Checkers["Array"] = function(node)
        if #node.elements == 0 then
            return "[any]" -- порожній масив
        end
        
        -- Беремо тип першого елемента
        local first_type = walk(node.elements[1])
        
        -- Перевіряємо, чи всі інші елементи такого ж типу
        for i = 2, #node.elements do
            local el_type = walk(node.elements[i])
            if el_type ~= first_type then
                error("TypeError: Array elements must have the same type")
            end
        end
        
        -- Повертаємо тип у дужках, наприклад "[int]"
        return "[" .. first_type .. "]"
    end

    Checkers["ExprStmt"] = function(node) walk(node.expression) end
    Checkers["While"] = function(node) return "void" end
    
    Checkers["If"] = function(node)
        walk(node.condition)
        for _, stmt in ipairs(node.then_block) do
            walk(stmt)
        end
        if node.else_block then
            for _, stmt in ipairs(node.else_block) do
                walk(stmt)
            end
        end
        return "void"
    end
    
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
            
            -- Перевіряємо дефолтне значення
            if param.default then
                local def_type = walk(param.default)
                if def_type ~= param.type then
                    error("TypeError: Default value for '" .. param.name .. "' must be of type " .. param.type)
                end
            end
        end
        
        for _, stmt in ipairs(node.body) do
            walk(stmt)
        end
        
        env = old_env
        env[node.name] = "function"
        return "function"
    end

    Checkers["Return"] = function(node)
        if node.value then
            return walk(node.value)
        end
        return "void"
    end
    Checkers["ForRange"] = function(node)
        walk(node.start)
        walk(node.finish)
        local old_env = {}
        for k, v in pairs(env) do old_env[k] = v end
        env[node.var_name] = "int" -- змінна циклу це int
        for _, stmt in ipairs(node.body) do
            walk(stmt)
        end
        env = old_env
        return "void"
    end

    Checkers["ForIn"] = function(node)
        walk(node.collection)
        local old_env = {}
        for k, v in pairs(env) do old_env[k] = v end
        env[node.var_name] = "any" -- елемент колекції
        for _, stmt in ipairs(node.body) do
            walk(stmt)
        end
        env = old_env
        return "void"
    end
    walk = function(node)
        if not node then error("TypeChecker: got nil node") end
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