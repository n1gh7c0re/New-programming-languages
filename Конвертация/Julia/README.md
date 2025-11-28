# Task 09 (Julia) — Конвертация Markdown → HTML
## Описание
Программа читает файл Markdown и преобразует его в HTML-файл. Поддерживаемые конструкты:
- заголовки `#`...`######` → `<h1>`...`<h6>`
- абзацы
- списки упорядоченные и неупорядоченные
- кодовые блоки (fenced ``` ) → `<pre><code>`
- inline-код (`` ` ``) → `<code>`
- жирный/курсив (`**bold**`, `*italic*`, `__bold__`, `_italic_`)
- ссылки `[text](url)` и изображения `![alt](url)`

## Входные данные
Файл `input.md`:

## Выходные данные
Файл `output.html`:
```html
<!doctype html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>Document</title>
        <style>
            body { 
                font-family: Arial, sans-serif; 
                line-height: 1.6; 
                margin: 40px;
                max-width: 800px;
            }
            h1 { color: #333; border-bottom: 2px solid #333; }
            h2 { color: #555; }
            code { 
                background: #f4f4f4; 
                padding: 2px 5px; 
                border-radius: 3px;
            }
            pre { 
                background: #f4f4f4; 
                padding: 15px; 
                overflow: auto;
                border-radius: 5px;
            }
            blockquote {
                border-left: 4px solid #ddd;
                margin-left: 0;
                padding-left: 20px;
                color: #666;
            }
        </style>
    </head>
    <body>
    $html_content
    </body>
    </html>
```

## Как запускать
* Убедитесь, что `input.md` находится в корне проекта
* Установите зависимости:
  ```julia
  using Pkg
  Pkg.add("CommonMark")
  ```
* Запустите:
  ```
  julia script.jl
  ```
* Итоговый файл: `output.html`
