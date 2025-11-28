require 'csv'
require 'json'
require 'date'

# Нормализация заголовка: trim, to lower snake_case
def normalize_header(header)
  header.strip.downcase.gsub(/\s+/, '_')
end

# Конвертация значения: число, дата (dd.mm.yyyy → ISO) или строка
def normalize_value(value)
  value = value.to_s.strip 
  if value =~ /^\d+$/
    value.to_i
  elsif value =~ /^\d+\.\d+$/
    value.to_f
  elsif value =~ /^\d{2}\.\d{2}\.\d{4}$/
    Date.strptime(value, '%d.%m.%Y').iso8601
  elsif value =~ /^\d{4}-\d{2}-\d{2}$/
    value 
  else
    value
  end
end

# Главная функция
def convert_csv_to_json(csv_file, json_file)
  data = []
  headers = nil

  CSV.foreach(csv_file, headers: true) do |row|
    if headers.nil?
      headers = row.headers.map { |h| normalize_header(h) }
    end

    normalized_row = {}
    row.fields.each_with_index do |value, index| 
      normalized_row[headers[index]] = normalize_value(value)
    end
    data << normalized_row
  end

  File.open(json_file, 'w') do |f|
    f.write(JSON.pretty_generate(data))
  end
end

convert_csv_to_json('input.csv', 'output.json')
puts "Готово! Результат в output.json"