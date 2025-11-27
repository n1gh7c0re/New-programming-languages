open Yojson.Basic
open Yojson.Basic.Util

let rec take n l =
  if n <= 0 then []
  else match l with
  | [] -> []
  | h :: t -> h :: take (n - 1) t

let rec drop n l =
  if n <= 0 then l
  else match l with
  | [] -> []
  | h :: t -> drop (n - 1) t

let rec merge_two a b cnt =
  match a, b with
  | [], b -> b, cnt
  | a, [] -> a, cnt
  | ha::ta, hb::tb ->
      if ha <= hb then
        let r, c = merge_two ta b (cnt + 1) in ha :: r, c
      else
        let r, c = merge_two a tb (cnt + 1) in hb :: r, c

let rec merge_k lists cnt =
  match lists with
  | [] -> [], cnt
  | [x] -> x, cnt
  | _ ->
      let mid = List.length lists / 2 in
      let left = take mid lists in
      let right = drop mid lists in
      let merged_left, cnt1 = merge_k left cnt in
      let merged_right, cnt2 = merge_k right cnt1 in
      merge_two merged_left merged_right cnt2

let () =
  let json = Yojson.Basic.from_file "lists.json" in
  let lists = json |> to_list |> List.map (fun x -> x |> to_list |> List.map to_int) in
  let result, comparisons = merge_k lists 0 in

  let output = `Assoc [
    "result", `List (List.map (fun x -> `Int x) result);
    "comparisons", `Int comparisons
  ] in

  let json_str = Yojson.Basic.pretty_to_string output in
  let oc = open_out "merged.json" in
  output_string oc json_str;
  close_out oc;
  Printf.printf "Done! Comparisons: %d → merged.json\n" comparisons