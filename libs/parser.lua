 -- parser.lua
local function parse (tokens)
    local pos = 1
    
    local function peek()
        return tokens[pos]
    end
    
    local function consume(expected_type, expected_value)
        local tok = tokens[pos]
        if not tok then error("Unexpected end of file") end
        if expected_type and tok.type ~= expected_type then
            error("Expected ".. expected_type .. " but got " .. tok.type .. " at pos " .. pos)
        end
        if expected_value and tok.value ~= expected_value then
            error("Expected '" .. expected_value .. "' but got '" .. tok.value .. "'")
        end
        pos = pos + 1
        return tok
    end

    local PRECEDENCE = {
        ["+"] = 10, ["-"] = 10,
        ["*"] = 20, ["/"] = 20,
        ["<"] = 5,  [">"] = 5, ["<="] = 5, [">="] = 5
    }
    
    -- Форвард-декларація (щоб уникнути помилок рекурсії)
    local parse_expression
    local parse_block
    local parse_let
    local parse_call
    local parse_if
    local parse_while
    local parse_assign
    local parse_fn
    local parse_return
    local parse_import

    -- 1. ПАРСЕР ВИРАЗІВ (математика, дужки)
    local function parse_primary()
        local tok = peek()

        if tok.value == "(" then
            consume("SYMBOL", "(")
            local expr = parse_expression()
            consume("SYMBOL", ")")
            return expr
        end
        if tok.value == "[" then
            consume("SYMBOL", "[")
            local elements = {}
            while peek() and peek().value ~= "]" do
                table.insert(elements, parse_expression())
                if peek() and peek().value == "," then consume("SYMBOL", ",") end
            end
            consume("SYMBOL", "]")
            return { tag = "Array", elements = elements }
        end
        if tok.value == "{" then
            consume("SYMBOL", "{")
            local fields = {}
            while peek() and peek().value ~= "}" do
                local key = consume("IDENT").value -- ім'я поля
                consume("SYMBOL", ":")             -- двокрапка
                local value = parse_expression()   -- значення
                
                table.insert(fields, { key = key, value = value })
                
                if peek() and peek().value == "," then consume("SYMBOL", ",") end
            end
            consume("SYMBOL", "}")
            return { tag = "Struct", fields = fields }
        end

        if tok.type == "NUMBER" then
            consume("NUMBER")
            return { tag = "Number", value = tok.value }
        elseif tok.type == "STRING" then
            consume("STRING")
            return { tag = "String", value = tok.value }
        elseif tok.type == "IDENT" then
            consume("IDENT")
            local node = { tag = "Identifier", name = tok.value }

            -- Нескінченний цикл для обробки ланцюжків: a.b.c(), a[0].name
            while true do
                if peek() and peek().value == "." then
                    consume("SYMBOL", ".")
                    local prop_name = consume("IDENT").value
                    node = { tag = "Property", target = node, property = prop_name }
                elseif peek() and peek().value == "[" then
                    consume("SYMBOL", "[")
                    local index_expr = parse_expression()
                    consume("SYMBOL", "]")
                    node = { tag = "Index", target = node, index = index_expr }
                elseif peek() and peek().value == "(" then
                    consume("SYMBOL", "(")
                    local args = {}
                    while peek() and peek().value ~= ")" do
                        table.insert(args, parse_expression())
                        if peek() and peek().value == "," then consume("SYMBOL", ",") end
                    end
                    consume("SYMBOL", ")")
                    node = { tag = "Call", target = node, args = args }
                else
                    break -- Якщо далі нічого немає, виходимо з циклу
                end
            end
            return node
        end
    end

    parse_expression = function(min_prec)
        min_prec = min_prec or 0
        local left = parse_primary()

        while true do
            local op_tok = peek()
            if not op_tok then break end
            
            local op = op_tok.value
            local prec = PRECEDENCE[op]

            if not prec or prec < min_prec then break end
            
            consume("SYMBOL")
            local right = parse_expression(prec + 1)
            
            left = { tag = "BinaryOp", op = op, left = left, right = right }
        end
        return left
    end

    -- 2. ПАРСЕРИ ІНСТРУКЦІЙ (let, if, call)
    parse_fn = function()
        -- Ми вже з'їли "let", тому починаємо з імені
        local name = consume("IDENT").value
        consume("SYMBOL", "(")
        
        local params = {}
        -- Парсимо параметри: int ab, string bc
        while peek() and peek().value ~= ")" do
            local p_type = consume("KEYWORD").value -- тип (int, string)
            local p_name = consume("IDENT").value   -- ім'я (ab, bc)
            table.insert(params, { type = p_type, name = p_name })
            
            if peek() and peek().value == "," then consume("SYMBOL", ",") end
        end
        
        consume("SYMBOL", ")")
        consume("KEYWORD", "do") -- твій маркер початку тіла функції
        
        local body = parse_block()
        consume("KEYWORD", "end")
        
        return { tag = "Fn", name = name, params = params, body = body }
    end

    parse_let = function()
        consume("KEYWORD", "let")
        
        -- ОСЬ ВОНА, МАГІЯ ФУНКЦІЙ: якщо бачимо Ім'я + Дужку, це функція!
        if peek().type == "IDENT" and tokens[pos+1] and tokens[pos+1].value == "(" then
            return parse_fn()
        end
        
        -- Далі йде парсинг звичайних змінних
        local var_type = ""
        local name = ""

        if peek().value == "[" then
            consume("SYMBOL", "[")
            var_type = "[" .. consume(peek().type).value .. "]"
            consume("SYMBOL", "]")
            name = consume("IDENT").value
        elseif peek().type == "KEYWORD" or peek().type == "IDENT" then
            var_type = consume(peek().type).value 
            name = consume("IDENT").value
        else
            error("Invalid let declaration")
        end

        consume("SYMBOL", "=")
        local value_node = parse_expression()

        return { tag = "Let", var_type = var_type, name = name, value = value_node }
    end

    parse_call = function()
        local name = consume("IDENT").value
        consume("SYMBOL", "(")
        local args = {}
        if peek() and peek().value ~= ")" then
            table.insert(args, parse_expression())
            while peek() and peek().value == "," do
                consume("SYMBOL", ",")
                table.insert(args, parse_expression())
            end
        end
        consume("SYMBOL", ")")
        return { tag = "Call", name = name, args = args }
    end

    parse_if = function()
        consume("KEYWORD", "if")
        local condition = parse_expression()
        consume("KEYWORD", "do")
        
        local then_block = parse_block()
        
        local else_block = nil
        if peek() and peek().value == "else" then
            consume("KEYWORD", "else")
            else_block = parse_block() -- тут вже НЕМАЄ consume("KEYWORD", "do") для else!
        end
        
        consume("KEYWORD", "end")
        
        return { tag = "If", condition = condition, then_block = then_block, else_block = else_block }
    end

    parse_while = function()
        consume("KEYWORD", "while")
        local condition = parse_expression()
        consume("KEYWORD", "do")
        
        local body = parse_block() -- використовуємо твій готовий блок!
        
        consume("KEYWORD", "end")
        
        return { 
            tag = "While", 
            condition = condition, 
            body = body 
        }
    end
    parse_assign = function()
        -- Парсимо ліву частину (це може бути просто 'a', або 'user.name')
        local target_expr = parse_expression()
        
        consume("SYMBOL", "=")
        
        -- Парсимо праву частину
        local value_node = parse_expression()
        
        -- Повертаємо вузол з полем 'target' (як очікує емітер)
        return { tag = "Assign", target = target_expr, value = value_node }
    end
    parse_return = function()
        consume("KEYWORD", "return")
        local value = nil
        
        -- Якщо після return йде щось, крім end (наприклад, вираз), парсимо його
        if peek() and peek().value ~= "end" and peek().value ~= "else" then
            value = parse_expression()
        end
        
        return { tag = "Return", value = value }
    end
    parse_import = function()
        consume("KEYWORD", "import")
        local name = consume("IDENT").value
        
        local path = nil
        -- Якщо далі йде слово "from", значить ми вказуємо шлях
        if peek() and peek().value == "from" then
            consume("KEYWORD", "from")
            path = consume("STRING").value -- шлях буде рядком у лапках
        end
        
        return { tag = "Import", name = name, path = path }
    end

    -- 3. ОСЬ ВОНА, МАГІЯ ТАБЛИЦЬ
    -- Ми кажемо: "якщо бачиш слово 'let' — виклич parse_let", і т.д.
    local StatementParsers = {
        ["let"] = parse_let,
        ["if"]  = parse_if,
        ["while"]  = parse_while,
        ["return"] = parse_return,
        ["import"] = parse_import,
    }

    -- 4. ПАРСЕР БЛОКІВ (використовує таблицю)
    parse_block = function()
        local block = {}
        -- Читаємо, поки не натрапимо на кінець блоку
        while peek() and peek().value ~= "end" and peek().value ~= "else" do
            local tok = peek()
            
            -- ШУКАЄМО В ТАБЛИЦІ: чи є парсер для цього слова?
            local parser_fn = StatementParsers[tok.value]
            
            if parser_fn then
                table.insert(block, parser_fn())
            elseif tok.type == "IDENT" then
                if tokens[pos + 1] and tokens[pos + 1].value == "=" then
                    table.insert(block, parse_assign()) -- якщо далі "=", це присвоєння
                else
                    table.insert(block, parse_call())   -- інакше це виклик функції
                end
                -- В parse_block:
            else
                -- Парсимо ліву частину (наприклад, a, user.name, print(...))
                local expr = parse_expression()
                
                -- Якщо після цього йде =, то це присвоєння
                if peek() and peek().value == "=" then
                    consume("SYMBOL", "=")
                    local value = parse_expression()
                    table.insert(block, { tag = "Assign", target = expr, value = value })
                else
                    -- Інакше це просто вираз (наприклад, виклик функції)
                    table.insert(block, { tag = "ExprStmt", expression = expr })
                end
            end
        end
        return block
    end
    
    -- 5. ГОЛОВНИЙ ЦИКЛ (теж використовує таблицю)
    local ast = {}
    while pos <= #tokens do
        local tok = peek()
        local parser_fn = StatementParsers[tok.value]
        
        if parser_fn then
            table.insert(ast, parser_fn())
        else
            local expr = parse_expression()
            if peek() and peek().value == "=" then
                consume("SYMBOL", "=")
                local value = parse_expression()
                table.insert(ast, { tag = "Assign", target = expr, value = value })
            else
                table.insert(ast, { tag = "ExprStmt", expression = expr })
            end
        end
    end
    
    return ast
end

return parse