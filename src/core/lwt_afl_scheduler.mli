val fuzz : (unit -> unit) list -> unit
(* Fuzzes an array of functions *)

val get_fuzzed_calls : (unit -> 'a) list -> (unit -> 'a) list