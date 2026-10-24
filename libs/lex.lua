local function lex(source, keywords) 
    keywords = keywords or {
        ["let"] = true, ["if"] = true, ["do"] = true, 
        ["int"] = true, ["float"] = true, ["string"] = true, ["bool"] = true, 
        ["while"] = true, ["return"] = true, ["import"] = true, ["from"] = true,
        ["for"] = true, ["in"] = true,
    }
    local tokens = {}
    local pos = 1
    while pos <= #source do
        local char = source:sub(pos, pos)
        if char == " " or char == "\n" or char == "\t" or char == "\r" then
            pos = pos + 1
        elseif char:match("%d") then
            local number = source:match("^%d+%.?%d*", pos)
            table.insert(tokens, { type = "NUMBER", value = number })
            pos = pos + #number
        elseif char:match("%a") then
            local word = string.match(source, "^[%a_][%a%d_]*", pos)
            if keywords[word] then
                table.insert(tokens, { type = "KEYWORD", value = word })
            else
                table.insert(tokens, { type = "IDENT", value = word })
            end
            pos = pos + #word
        elseif char == '"' then
            local word = source:match('^"(.-)"', pos)
            table.insert(tokens, { type = "STRING", value = word })
            pos = pos + #word + 2
            
        elseif char == "#" then
            -- Ігноруємо все до кінця рядка
            while pos <= #source and source:sub(pos, pos) ~= "\n" do
                pos = pos + 1
            end
        else
            local two_chars = source:sub(pos, pos + 1)
            if two_chars == ">=" or two_chars == "<=" or two_chars == "==" or two_chars == "!=" 
            or two_chars == "**" or two_chars == "//" or two_chars == ".." then
                table.insert(tokens, { type = "SYMBOL", value = two_chars })
                pos = pos + 2
            else
                table.insert(tokens, { type = "SYMBOL", value = char })
                pos = pos + 1
            end
        end
    end
    return tokens
end
return lex