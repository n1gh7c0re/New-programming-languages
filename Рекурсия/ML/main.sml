(* Функция для чтения всего файла в строку *)
fun readFile filename =
    let
        val ins = TextIO.openIn filename
        val content = TextIO.inputAll ins
    in
        TextIO.closeIn ins;
        content
    end;

(* Функция для очистки строки от кавычек и пробелов *)
fun cleanString s = 
    String.translate (fn c => if c = #"\"" orelse Char.isSpace c then "" else String.str c) s;

(* Функция парсинга input.json *)
(* Возвращает кортеж (список строк, число k) *)
fun parseInput filename =
    let
        val content = readFile filename
        val sub = Substring.full content
        
        (* --- Парсинг K --- *)
        (* Находим "k", затем двоеточие, затем пропускаем не-цифры, берем цифры *)
        val (_, afterK) = Substring.position "\"k\"" sub
        val (_, afterColon) = Substring.position ":" afterK
        val numPart = Substring.dropl (fn c => not (Char.isDigit c)) afterColon
        val kStr = Substring.takel Char.isDigit numPart
        val kVal = valOf (Int.fromString (Substring.string kStr))
        
        (* --- Парсинг Items --- *)
        (* Находим "items", затем [, затем берем всё до ] *)
        val (_, afterItems) = Substring.position "\"items\"" sub
        val (_, afterBracket) = Substring.position "[" afterItems
        val listContentSub = Substring.dropl (fn c => c = #"[") afterBracket
        val (innerContent, _) = Substring.position "]" listContentSub
        
        (* Разбиваем по запятой и чистим элементы *)
        val rawItems = String.tokens (fn c => c = #",") (Substring.string innerContent)
        val itemsList = map cleanString rawItems
    in
        (itemsList, kVal)
    end;

(* === Часть 2: Основная логика Combinations === *)

(* Рекурсивная генерация k-сочетаний *)
fun combinations ([] : string list, 0) = [[]]
  | combinations (_, 0) = [[]]
  | combinations ([], _) = []
  | combinations (x::xs, k) =
      let
        val with_x = map (fn comb => x::comb) (combinations(xs, k-1))
        val without_x = combinations(xs, k)
      in
        with_x @ without_x
      end;

(* === Часть 3: Исполнение === *)

(* 1. Считываем данные из файла *)
val (items, k) = parseInput "input.json"

(* 2. Генерируем сочетания *)
val combs = combinations(items, k)

(* 3. Записываем в файл *)
val out = TextIO.openOut "combinations.txt"
val _ = app (fn comb =>
    TextIO.output(out, String.concatWith " " comb ^ "\n")
) combs
val _ = TextIO.closeOut out

(* 4. Вывод в консоль для подтверждения *)
val _ = print ("Done! Loaded k=" ^ Int.toString k ^ 
               ". Generated " ^ Int.toString(length combs) ^ 
               " lines in combinations.txt\n");