import groovy.json.JsonSlurper
import groovy.json.JsonBuilder
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.time.Duration
import java.time.Instant
import java.util.concurrent.CompletableFuture

class AsyncClient {
    static void main(String[] args) {
        println "--- Запуск HTTP клиента Groovy ---"

        // 1. Чтение и парсинг входного файла
        def inputFile = new File('requests.json')
        if (!inputFile.exists()) {
            println "Ошибка: файл requests.json не найден!"
            return
        }

        def jsonSlurper = new JsonSlurper()
        def requestsData = jsonSlurper.parse(inputFile)

        println "Загружено ${requestsData.size()} запросов. Начинаем выполнение..."

        // 2. Настройка HTTP клиента (Java 11+)
        def client = HttpClient.newBuilder()
                .version(HttpClient.Version.HTTP_2)
                .connectTimeout(Duration.ofSeconds(10))
                .build()

        // 3. Формирование списка Future задач (асинхронный запуск)
        List<CompletableFuture<Map>> futures = requestsData.collect { reqItem ->
            // Подготовка JSON тела запроса
            String requestBody = new JsonBuilder(reqItem.payload).toString()

            def request = HttpRequest.newBuilder()
                    .uri(URI.create(reqItem.url))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(requestBody))
                    .build()

            long startTime = System.currentTimeMillis()

            // Асинхронная отправка (возвращает CompletableFuture)
            client.sendAsync(request, HttpResponse.BodyHandlers.ofString())
                .thenApply { HttpResponse<String> response ->
                    // Успешная обработка ответа
                    long duration = System.currentTimeMillis() - startTime
                    return [
                        url: reqItem.url,
                        status: response.statusCode(),
                        body: response.body(), // Можно распарсить JSON, если нужно, но оставим строкой
                        time_ms: duration,
                        error: null
                    ]
                }
                .exceptionally { Throwable ex ->
                    // Обработка ошибок (например, нет сети)
                    long duration = System.currentTimeMillis() - startTime
                    return [
                        url: reqItem.url,
                        status: 0,
                        body: null,
                        time_ms: duration,
                        error: ex.message
                    ]
                }
        }

        // 4. Ожидание завершения всех запросов (Parallel Wait)
        // join() блокирует поток до выполнения всех futures
        CompletableFuture.allOf(futures as CompletableFuture[]).join()

        // Сбор результатов
        def results = futures.collect { it.get() }

        // 5. Запись результатов в файл
        def outputFile = new File('responses.json')
        // toPrettyString() делает JSON красивым и читаемым
        outputFile.text = new JsonBuilder(results).toPrettyString()

        println "--- Готово! ---"
        println "Обработано запросов: ${results.size()}"
        println "Результат сохранен в responses.json"
    }
}