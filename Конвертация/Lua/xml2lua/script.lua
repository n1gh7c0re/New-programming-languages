local xml2lua = require("xml2lua")
local yaml = require("lyaml")

-- Парсер XML
local handler = require("xmlhandler.tree")

-- Функция для рекурсивной конвертации дерева в структуру с _attr, _text, массивами
local function convert_tree(node)
  if type(node) ~= "table" then
    return node
  end

  local result = {}

  -- Текст
  if node._text then
    result["_text"] = node._text
  end

  -- Атрибуты
  if node._attr and next(node._attr) then
    result["_attr"] = node._attr
  end

  -- Дочерние элементы
  for key, value in pairs(node) do
    if type(key) == "number" then
      -- Повторяющиеся — в массив
      result[key] = convert_tree(value)
    elseif key ~= "_attr" and key ~= "_text" then
      result[key] = convert_tree(value)
    end
  end

  -- Если есть только числовые ключи — превратить в массив
  local is_array = true
  for k in pairs(result) do
    if type(k) ~= "number" then is_array = false end
  end
  if is_array then
    table.sort(result) -- для правильного порядка
  end

  return result
end

-- Главная функция
local parser = xml2lua.parser(handler)
local xml_str = io.open("input.xml", "r"):read("*all")
parser:parse(xml_str)

local tree = handler.root
local converted = convert_tree(tree)

local yaml_str = yaml.dump(converted)
io.open("output.yaml", "w"):write(yaml_str)

print("Готово! Результат в output.yaml")