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

(* Основная функция *)
val items = ["a", "b", "c", "d"]
val k = 2
val combs = combinations(items, k)

(* Запись в файл *)
val out = TextIO.openOut "combinations.txt"
val _ = app (fn comb =>
    TextIO.output(out, String.concatWith " " comb ^ "\n")
) combs
val _ = TextIO.closeOut out

val _ = print ("Ready! " ^ Int.toString(length combs) ^ " combinations → combinations.txt\n")