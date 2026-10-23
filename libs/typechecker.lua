local function typecheck(ast)
    -- 1. Середовище (Environment). Тут ми зберігаємо типи змінних: env["a"] = "int"
    local env = {}

    -- 2. Таблиця перевірок (як Emitters у емітері)
    local Checkers = {}

    Checkers["Number"] = function(node) return "int" end
    Checkers["String"] = function(node) return "string" end
    
    -- Перевірка змінної: чи існує вона в середовищі?
    Checkers["Identifier"] = function(node)
        local var_type = env[node.name]
        if not var_type then
            error("TypeError: Undefined variable '" .. node.name .. "'")
        end
        return var_type
    end

    -- Оголошення змінної (let)
    Checkers["Let"] = function(node)
        -- Спочатку перевіряємо, який тип у значення (правої частини)
        local value_type = Checkers[node.value.tag](node.value)
        
        -- Порівнюємо з оголошеним типом (лівою частиною)
        if node.var_type ~= value_type then
            error("TypeError: Cannot assign " .. value_type .. " to variable of type " .. node.var_type)
        end
        
        -- Якщо все ок, запам'ятовуємо тип змінної
        env[node.name] = node.var_type
        return node.var_type
    end

    -- Математика та оператори
    Checkers["BinaryOp"] = function(node)
        local left_type = Checkers[node.left.tag](node.left)
        local right_type = Checkers[node.right.tag](node.right)
        
        -- Можна додавати тільки однакові типи (int + int, string + string)
        if left_type ~= right_type then
            error("TypeError: Cannot apply '" .. node.op .. "' to " .. left_type .. " and " .. right_type)
        end
        return left_type
    end

    -- Присвоєння (a = 5)
    Checkers["Assign"] = function(node)
        local target_type = Checkers[node.target.tag](node.target)
        local value_type = Checkers[node.value.tag](node.value)
        
        if target_type ~= value_type then
            error("TypeError: Cannot assign " .. value_type .. " to " .. target_type)
        end
    end

    -- Інші вузли (поки що просто заглушки, щоб не падало)
    Checkers["ExprStmt"] = function(node) Checkers[node.expression.tag](node.expression) end
    Checkers["If"] = function(node) return "void" end
    Checkers["While"] = function(node) return "void" end
    Checkers["Call"] = function(node)
        -- Перевіряємо КОЖЕН аргумент, який передається у функцію
        for _, arg in ipairs(node.args) do
            Checkers[arg.tag](arg) 
        end
        return "void" -- поки що вважаємо, що функції нічого не повертають
    end

    -- 3. Головна функція обходу дерева
    local function walk(node)
        local checker = Checkers[node.tag]
        if not checker then
            error("TypeChecker: Unknown node type " .. tostring(node.tag))
        end
        return checker(node)
    end

    -- Запускаємо перевірку для кожного вузла верхнього рівня
    for _, stmt in ipairs(ast) do
        walk(stmt)
    end
    
    print("Type check passed successfully!")
end

return typecheck