(* Minimal Candle compatibility surface needed by the legacy Flyspeck file. *)
module Big_int = struct
  type big_int = int
  let zero_big_int = 0
  let big_int_of_string s =
    match Cake.Int.fromString s with
    | None -> failwith "Big_int.big_int_of_string"
    | Some i -> i
  let big_int_of_int value = value
  let sign_big_int value =
    if value < 0 then ~-1 else if value > 0 then 1 else 0
  let abs_big_int value = abs value
  let add_big_int left right = left + right
  let succ_big_int value = value + 1
  let sub_big_int left right = left - right
  let pred_big_int value = value - 1
  let mult_big_int left right = left * right
  let mult_int_big_int left right = left * right
  let quomod_big_int dividend divisor =
    let quotient = dividend / divisor and remainder = dividend mod divisor in
    if remainder < 0 then quotient + 1, remainder - divisor
    else quotient, remainder
  let div_big_int dividend divisor = fst (quomod_big_int dividend divisor)
  let mod_big_int dividend divisor = snd (quomod_big_int dividend divisor)
  let power_int_positive_int base exponent =
    if exponent < 0 then failwith "Big_int.power_int_positive_int" else
    let rec power accumulator factor remaining =
      if remaining = 0 then accumulator
      else
        let square = factor * factor in
        if remaining mod 2 = 0 then
          power accumulator square (remaining / 2)
        else
          power (accumulator * factor) square (remaining / 2) in
    power 1 base exponent
  let eq_big_int left right = left = right
  let le_big_int left right = left <= right
  let lt_big_int left right = left < right
  let sqrt_big_int value =
    if value < 0 then failwith "Big_int.sqrt_big_int"
    else if value < 2 then value
    else
      let rec descend estimate =
        let next = (estimate + value / estimate) / 2 in
        if next >= estimate then estimate else descend next in
      descend value
end;;

let num_of_big_int i = Int i;;

let big_int_of_num n =
  match n with
  | Int i -> i
  | Rat r ->
      if Cake.Rat.denominator r = 1 then Cake.Rat.numerator r
      else failwith "big_int_of_ratio";;

let compare_num x y =
  let compare_rat left right =
    if Cake.Rat.(<) left right then -1
    else if Cake.Rat.(>) left right then 1
    else 0 in
  match x,y with
  | Int i,Int j -> if i < j then -1 else if i > j then 1 else 0
  | Int i,Rat r -> compare_rat (Cake.Rat.fromInt i) r
  | Rat r,Int j -> compare_rat r (Cake.Rat.fromInt j)
  | Rat i,Rat j -> compare_rat i j;;
