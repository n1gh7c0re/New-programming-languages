-- Настройка путей (оставляем как было)
package.path = package.path .. ";./xml2lua/?.lua;./xml2lua/xmlhandler/?.lua"

local xml2lua = require("xml2lua")
local handler = require("xmlhandler.tree")

-- Хелпер для экранирования строк в YAML
local function escape_yaml_string(val)
    if type(val) ~= "string" then return tostring(val) end
    
    -- Если строка пустая, возвращаем пустые кавычки
    if val == "" then return '""' end
    
    -- Если это число, записанное как строка (но не начинается с 0, если это не просто "0")
    if tonumber(val) and not (string.len(val) > 1 and string.sub(val, 1, 1) == "0") then
        return val 
    end

    -- Проверяем, нужны ли кавычки (наличие двоеточий, #, скобок или пробелов в начале/конце)
    -- Простейший вариант: если есть опасные символы, берем в кавычки.
    if val:match("[:#%[%]{},&*!|>'\"%s]") or val:match("^%s") or val:match("%s$") then
        -- Экранируем двойные кавычки внутри строки
        return '"' .. val:gsub('"', '\\"') .. '"'
    end
    
    return val
end

-- Функция для определения, является ли таблица массивом (списком)
local function is_array(t)
    if type(t) ~= "table" then return false end
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then return false end
    end
    return i > 0
end

-- Основная рекурсивная функция сериализации
local function serialize_node(obj, indent_level, buffer)
    local indent = string.rep("  ", indent_level)
    
    -- 1. Если это массив (список однотипных элементов)
    if is_array(obj) then
        for _, item in ipairs(obj) do
            if type(item) == "table" then
                table.insert(buffer, indent .. "-")
                -- Хитрый момент YAML: первый элемент объекта после тире не требует нового отступа,
                -- но в Lua-структуре удобнее обработать это, передав флаг или обработав вручную.
                -- Здесь мы делаем перенос строки и отступ для чистоты:
                -- - 
                --   key: val
                -- Либо компактный вариант (сложнее в реализации). 
                -- Пойдем путем компактности для простых объектов:
                
                local keys = {}
                for k in pairs(item) do table.insert(keys, k) end
                
                -- Если объект сложный, делаем перенос
                table.insert(buffer, "\n") 
                serialize_node(item, indent_level + 1, buffer) -- Увеличиваем отступ для содержимого массива
            else
                -- Простой массив строк/чисел
                table.insert(buffer, indent .. "- " .. escape_yaml_string(item) .. "\n")
            end
        end
        return
    end

    -- 2. Если это объект (таблица ключей)
    
    -- Сначала выводим атрибуты (_attr), чтобы они были сверху
    if obj._attr then
        table.insert(buffer, indent .. "_attr:\n")
        for k, v in pairs(obj._attr) do
            table.insert(buffer, indent .. "  " .. k .. ": " .. escape_yaml_string(v) .. "\n")
        end
    end

    -- Затем выводим текст (_text)
    if obj._text then
        table.insert(buffer, indent .. "_text: " .. escape_yaml_string(obj._text) .. "\n")
    end

    -- Затем все остальные ключи
    for k, v in pairs(obj) do
        if k ~= "_attr" and k ~= "_text" and k ~= "_name" then -- xml2lua добавляет _name, его пропускаем
            if type(v) == "table" then
                table.insert(buffer, indent .. k .. ":\n")
                serialize_node(v, indent_level + 1, buffer)
            else
                table.insert(buffer, indent .. k .. ": " .. escape_yaml_string(v) .. "\n")
            end
        end
    end
end

local function to_yaml(root_table)
    local buffer = {}
    -- xml2lua обычно возвращает корневой тег как ключ. Нам нужно начать с него.
    for k, v in pairs(root_table) do
        if k ~= "_attr" then -- обычно корень один, но на всякий случай
            table.insert(buffer, k .. ":\n")
            serialize_node(v, 1, buffer)
        end
    end
    return table.concat(buffer)
end


-- Главная функция
local function main()    
    local f_in = io.open("input.xml", "r")
    if not f_in then
        print("ERROR: input.xml not found.")
        return
    end
    local xml_content = f_in:read("*a")
    f_in:close()
    
    local parser = xml2lua.parser(handler)
    parser:parse(xml_content)
    
    -- Получаем чистое дерево
    local tree = handler.root
    
    local yaml_output = to_yaml(tree)
    
    local f_out = io.open("output.yaml", "w")
    if not f_out then
        print("ERROR: Cannot write to output.yaml")
        return
    end
    f_out:write(yaml_output)
    f_out:close()
    
    print("Success! Saved to output.yaml")
end

main()