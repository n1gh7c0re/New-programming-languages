# Task 04 (Haskell) — Рекурсивное вычисление пути в дереве (DFS)
## Описание
Программа читает ориентированный граф в виде списка рёбер из файла `graph.txt` и выполняет рекурсивный поиск в глубину (DFS) для нахождения пути от вершины `start` до `target`. Если путь найден, выводится список вершин, иначе — `null`.
## Входные данные
* Файл `graph.txt` — каждая строка содержит ребро в формате `from to`
* Файл `query.json`:
```json
{ "start": "A", "target": "Z" }
```
## Выходные данные
Файл `path.json` вида:
```json
{ "path": ["A","B","..."] }
```
или
```json
{ "path": null }
```
## Как запускать
* Убедитесь, что `graph.txt` и `query.json` находятся в корне проекта
* Установите зависимости:
```
cabal install aeson aeson-pretty containers --lib --force-reinstalls
```
* Скомпилируйте:
```
ghc Main.hs -o dfs -package aeson -package aeson-pretty -package containers -package bytestring
```
* Запустите:
```
.\dfs.exe
```
* Итоговый файл: `path.json`
