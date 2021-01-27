(* This file is part of Lwt, released under the MIT license. See LICENSE.md for
   details, or visit https://github.com/ocsigen/lwt/blob/master/LICENSE.md. *)



(* [Lwt_sequence] is deprecated – we don't want users outside Lwt using it.
   However, it is still used internally by Lwt. So, briefly disable warning 3
   ("deprecated"), and create a local, non-deprecated alias for
   [Lwt_sequence] that can be referred to by the rest of the code in this
   module without triggering any more warnings. *)
[@@@ocaml.warning "-3"]
module Lwt_sequence = Lwt_sequence
[@@@ocaml.warning "+3"]

(* +-----------------------------------------------------------------+
   | Parameters                                                      |
   +-----------------------------------------------------------------+ *)

(* Minimum number of preemptive threads: *)
let min_threads : int ref = ref 0

(* Maximum number of preemptive threads: *)
let max_threads : int ref = ref 0

(* Size of the waiting queue: *)
let max_thread_queued = ref 1000

let get_max_number_of_threads_queued _ =
  !max_thread_queued

let set_max_number_of_threads_queued n =
  if n < 0 then invalid_arg "Lwt_preemptive.set_max_number_of_threads_queued";
  max_thread_queued := n

(* The total number of preemptive threads currently running: *)
let threads_count = ref 0

(* +-----------------------------------------------------------------+
   | Preemptive threads management                                   |
   +-----------------------------------------------------------------+ *)

module CELL :
sig
  type 'a t

  val make : unit -> 'a t
  val get : 'a t -> 'a
end =
struct
  type 'a t = {
    m  : Mutex.t;
    cv : Condition.t;
    mutable cell : 'a option;
  }

  let make () = { m = Mutex.create (); cv = Condition.create (); cell = None }

  let get t =
    let rec await_value t =
      match t.cell with
      | None ->
        Condition.wait t.cv t.m;
        await_value t
      | Some v ->
        t.cell <- None;
        Mutex.unlock t.m;
        v
    in
    Mutex.lock t.m;
    await_value t
end

type thread = {
  task_cell: (int * (unit -> unit)) CELL.t;
  (* Channel used to communicate notification id and tasks to the
     worker thread. *)

  mutable thread : Thread.t;
  (* The worker thread. *)

  mutable reuse : bool;
  (* Whether the thread must be re-added to the pool when the work is
     done. *)
}

(* Pool of worker threads: *)
let workers : thread Queue.t = Queue.create ()

(* Queue of clients waiting for a worker to be available: *)
let waiters : thread Lwt.u Lwt_sequence.t = Lwt_sequence.create ()

(* Code executed by a worker: *)
let rec worker_loop worker =
  let id, task = CELL.get worker.task_cell in
  task ();
  (* If there is too much threads, exit. This can happen if the user
     decreased the maximum: *)
  if !threads_count > !max_threads then worker.reuse <- false;
  (* Tell the main thread that work is done: *)
  Lwt_unix.send_notification id;
  if worker.reuse then worker_loop worker

(* create a new worker: *)
let make_worker () =
  incr threads_count;
  let worker = {
    task_cell = CELL.make ();
    thread = Thread.self ();
    reuse = true;
  } in
  worker.thread <- Thread.create worker_loop worker;
  worker

(* Add a worker to the pool: *)
let add_worker worker =
  match Lwt_sequence.take_opt_l waiters with
  | None ->
    Queue.add worker workers
  | Some w ->
    Lwt.wakeup w worker

(* +-----------------------------------------------------------------+
   | Initialisation, and dynamic parameters reset                    |
   +-----------------------------------------------------------------+ *)

let get_bounds () = (!min_threads, !max_threads)

let set_bounds (min, max) =
  if min < 0 || max < min then invalid_arg "Lwt_preemptive.set_bounds";
  let diff = min - !threads_count in
  min_threads := min;
  max_threads := max;
  (* Launch new workers: *)
  for _i = 1 to diff do
    add_worker (make_worker ())
  done

let initialized = ref false

let init min max _errlog =
  initialized := true;
  set_bounds (min, max)

let simple_init () =
  if not !initialized then begin
    initialized := true;
    set_bounds (0, 4)
  end

let nbthreads () = !threads_count
let nbthreadsqueued () = Lwt_sequence.fold_l (fun _ x -> x + 1) waiters 0
let nbthreadsbusy () = !threads_count - Queue.length workers

(* +-----------------------------------------------------------------+
   | Detaching                                                       |
   +-----------------------------------------------------------------+ *)

let tasks_to_fuzz : (unit -> unit) list ref = ref [] 
let fuzzed_task : (unit -> unit) list ref = ref [] 

let init_result = Result.Error (Failure "Lwt_preemptive.detach")

let detach f args =
  let result = ref init_result in
  (* The task for the worker thread: *)
  let id = Lwt_job_notification.get_next_job_notification_id () in
  let task () =
    let exec () = 
      try
        result := Result.Ok (f args)
      with exn ->
        result := Result.Error exn
    in
    exec ();
    Lwt_job_notification.send_notification id
  in

  tasks_to_fuzz := task :: !tasks_to_fuzz;
  let waiter, wakener = Lwt.wait () in
  let handle_notification ev = 
    Lwt_engine.stop_event ev;
    Lwt.wakeup_result wakener !result
  in
  ignore (Lwt_engine.on_readable (Lwt_job_notification.init_job_notification id) handle_notification);
  waiter

(* +-----------------------------------------------------------------+
   |Lwt_afl intergration                                             |
   +-----------------------------------------------------------------+ *)

let fuzz_tasks () =

  let rec execute_calls calls  = match calls with 
    | [] -> ()
    | hd :: tl -> fuzzed_task := tl; hd (); execute_calls !fuzzed_task
  in

  (* Printf.printf "Preemptive tasks - %d\n%!" (List.length !tasks_to_fuzz); *)
  fuzzed_task :=  !fuzzed_task @ (Lwt_afl_scheduler.get_fuzzed_calls !tasks_to_fuzz);
  tasks_to_fuzz := [];
  execute_calls !fuzzed_task

let () = ignore (Lwt_main.Enter_iter_hooks.add_last (fun () ->  fuzz_tasks ()))

(* +-----------------------------------------------------------------+
   | Running Lwt threads in the main thread                          |
   +-----------------------------------------------------------------+ *)


let run_in_main f =
  (* print_endline "In run_in_main"; *)
  let s = Lwt_main.run (f ()) in
  (* print_endline "Out run_in_main"; *)
  s
