local function emit(ast)
    local lines = {}
    
    for _, node in ipairs(ast) do
        if node.tag == "Let" then
            local value_str = ""
            
            if node.value.tag == "Number" then
                value_str = node.value.value
            
            elseif node.value.tag == "String" then
                value_str = '"' .. node.value.value .. '"'
            end
            
            table.insert(lines, "local " .. node.name .. " = " .. value_str)
        else
            error("Unknown AST node: " .. tostring(node.tag))
        end
    end
    
    -- З'єднуємо всі рядки через перенос рядка
    return table.concat(lines, "\n")
end

return emit