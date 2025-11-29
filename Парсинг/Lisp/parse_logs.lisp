;; Загрузка библиотеки для регулярных выражений.
;; Требует установленного Quicklisp и (ql:quickload "cl-ppcre") хотя бы раз.
(ql:quickload "cl-ppcre" :silent t)

(defpackage #:log-parser
  (:use #:cl #:cl-ppcre)
  (:export #:process-logs))

(in-package #:log-parser)

;; Определение регулярного выражения для парсинга лога.
;; Группы захвата: 1. IP; 2. Timestamp; 3. Path.
(defparameter *log-regex* (create-scanner "^(\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}).*?\\[(.*?)\\].*?\"(?:GET|POST|PUT|DELETE)\\s+(\\S+)\\s+.*"))

;; -----------------------------------------------------------------------------
;; Основная функция для парсинга и агрегации
;; -----------------------------------------------------------------------------

(defun parse-log-line (line)
  "Парсит строку лога, используя регулярное выражение, и возвращает IP, Timestamp и Path."
  (multiple-value-bind (match-start match-end reg-starts reg-ends)
      (scan *log-regex* line)
    (declare (ignore match-start match-end))
    
    (if reg-starts
        ;; Извлекаем IP (Группа 1), Timestamp (Группа 2), Path (Группа 3)
        (list (subseq line (aref reg-starts 0) (aref reg-ends 0))
              (subseq line (aref reg-starts 1) (aref reg-ends 1))
              (subseq line (aref reg-starts 2) (aref reg-ends 2)))
        nil)))

(defun aggregate-data (filename)
  "Считывает лог-файл, парсит строки и агрегирует счетчики IP и Path."
  (let ((ip-counts (make-hash-table :test 'equal)) ; Хэш-таблица для подсчета IP
        (path-counts (make-hash-table :test 'equal)) ; Хэш-таблица для подсчета Path
        (total-lines 0))
    
    (with-open-file (stream filename :direction :input :if-does-not-exist :error)
      (loop for line = (read-line stream nil nil)
            while line do
              (incf total-lines)
              (let ((parsed-data (parse-log-line line)))
                (when parsed-data
                  (let ((ip (first parsed-data))
                        (path (third parsed-data)))
                    
                    ;; Агрегация IP
                    (incf (gethash ip ip-counts 0))
                    
                    ;; Агрегация Path
                    (incf (gethash path path-counts 0)))))))
    
    (format t "Обработано ~a строк лога.~%" total-lines)
    (values ip-counts path-counts)))

;; -----------------------------------------------------------------------------
;; Функция для записи результатов в CSV
;; -----------------------------------------------------------------------------

(defun write-summary-csv (ip-counts path-counts output-filename)
  "Записывает агрегированные данные в CSV файл."
  (with-open-file (stream output-filename :direction :output :if-exists :supersede)
    ;; Заголовок CSV
    (format stream "type,key,count~%")
    
    ;; Запись статистики по IP
    (maphash (lambda (key value)
               (format stream "ip,~a,~a~%" key value))
             ip-counts)
    
    ;; Запись статистики по Path
    (maphash (lambda (key value)
               (format stream "path,~a,~a~%" key value))
             path-counts))
  (format t "Сводка сохранена в файл: ~a~%" output-filename))

;; -----------------------------------------------------------------------------
;; Главная функция программы
;; -----------------------------------------------------------------------------

(defun process-logs (input-file output-file)
  "Основная функция: запускает парсинг и сохранение."
  (multiple-value-bind (ip-counts path-counts)
      (aggregate-data input-file)
    (write-summary-csv ip-counts path-counts output-file)))

;; Запуск программы
(process-logs "access.log" "summary.csv")