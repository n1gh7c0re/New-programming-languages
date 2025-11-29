# Task 10 (Elixir) — Простой HTTP-сервер (REST) и конфиг через файл
## Описание
HTTP-сервер на Plug/Cowboy читает конфигурацию из файла при старте и обрабатывает GET /ping и POST /echo с логированием запросов.
## Входные данные
Файл `server_config.json`: 
```json
{ "port": 4000, "greeting": "hello" }
```
## Выходные данные
Файл `requests.log`:
```json
{"method":"POST","path":"/echo","body":"test body","time_ms":1234567890}
```
## Как запускать
* Убедитесь, что Elixir установлен и `server_config.json` в корне проекта.
* Добавьте зависимости:
  ```
  mix deps.get
  ```
* Запустите:
  ```
  iex -S mix
  ```
* В IEx выполните:
  ```
  MyHttpServer.start_link()
  ```
* Тестируйте запросы в отдельном терминале:
  ```
  curl http://localhost:4000/ping
  curl -X POST -d "test body" http://localhost:4000/echo
  ```
* Результаты в файле `requests.log`
