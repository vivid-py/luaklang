local function lex(source, keywords) 
    local tokens = {}
    local pos = 1
    while pos <= #source do
        local char = source:sub(pos, pos)
        if char == " " or char == "\n" or char == "\t" then
            pos = pos + 1
        elseif char:match("%d") then
            local number = source:match("^%d+%.?%d*", pos)
            table.insert(tokens, { type = "NUMBER", value = number })
            pos = pos + #number
        elseif char:match("%a") then
            local word = string.match(source, "^%a+", pos)
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
        else
            table.insert(tokens, { type = "SYMBOL", value = char })
            pos = pos + 1
        end
    end
    return tokens
end
return lex