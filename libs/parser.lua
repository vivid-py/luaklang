local function parse (tokens)
    local pos = 1
    local function peek()
        return tokens[pos]
    end
    local function consume(expected_type, expected_value)
        local tok = tokens[pos]
        if not tok then error("Unexpected end of file") end
        if expected_type and tok.type ~= expected_type then
            error("Expected ".. expected_type .. " but got " .. tok.type .. " at pos" .. pos)
        end
        if expected_value and tok.value ~= expected_value then
            error("Expected '" .. expected_value .. "' but got '" .. tok.value .. "'")
        end
        pos = pos + 1
        return tok
    end
    local function parse_let()
        consume("KEYWORD", "let")
        local var_type = consume("KEYWORD").value 
        local name = consume("IDENT").value
        consume("SYMBOL", "=")

        local next_tok = peek()
        local value_node
        
        if next_tok.type == "NUMBER" then
            local value_tok = consume("NUMBER")
            value_node = { tag = "Number", value = value_tok.value }
        elseif next_tok.type == "STRING" then
            local value_tok = consume("STRING")
            value_node = { tag = "String", value = value_tok.value }
        else
            error("Expected NUMBER or STRING, got " .. next_tok.type)
        end

        return {
            tag = "Let",
            var_type = var_type,
            name = name,
            value = value_node
        }
    end
    local ast = {}
    while pos <= #tokens do
        if peek().value == "let" then
            table.insert(ast, parse_let())
        else
            error("Unknown statement starting with: " .. peek().value)
        end
    end
    return ast
end
return parse