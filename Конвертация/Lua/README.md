# Task 08 (Lua) — Конвертация XML → YAML

## Описание
Программа читает XML-файл и конвертирует его в эквивалентное представление в формате YAML. Поддерживаются:
- элементы и вложенные элементы (структуры/мапы)
- атрибуты элемента (переносятся под ключ `_attr` внутри соответствующего узла)
- текстовые содержимые (если элемент содержит только текст — ключ `_text`)
- повторяющиеся дочерние элементы собираются в массивы

## Входные данные
Файл `input.xml` — любой корректный XML, например:
```xml
<?xml version="1.0" encoding="utf-8"?>
<company>
	<name>Tech Solutions Inc.</name>
	<employees>
		<employee id="1">
			<name>John Doe</name>
			<position>Developer</position>
			<department>IT</department>
			<salary>50000</salary>
		</employee>
	</employees>
	<departments>
		<department>IT</department>
	</departments>
</company>
```

## Выходные данные
Файл `output.yaml` — эквивалент в YAML:
```yaml
company:
  departments:
    department:
      - IT
  employees:
    employee:
      - 
        _attr:
          id: 1
        department: IT
        name: "John Doe"
        position: Developer
        salary: 50000
  name: "Tech Solutions Inc."
```

## Как запускать
* Убедитесь, что `input.xml` находится в корне проекта
* Установите зависимости:
  ```
  luarocks install xml2lua
  ```
* Запустите:
  ```
  lua converter_final.lua
  ```
* Итоговый файл: `output.yaml`
