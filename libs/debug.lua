local function printAST(node, depth)
    depth = depth or 0
    local indent = string.rep("  ", depth) -- 2 пробіли на кожен рівень
    
    -- Якщо це не таблиця (наприклад, число чи рядок), просто виводимо
    if type(node) ~= "table" then
        print(indent .. tostring(node))
        return
    end
    
    -- Якщо таблиця, перебираємо всі ключі (tag, name, value тощо)
    for key, value in pairs(node) do
        if type(value) == "table" then
            print(indent .. key .. " = {")
            printAST(value, depth + 1)
            print(indent .. "}")
        else
            print(indent .. key .. " = " .. tostring(value))
        end
    end
end
return printAST