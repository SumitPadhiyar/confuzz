val get_next_job_notification_id : unit -> int
(** Returns notification id for next job  *)

val reset_notificatons : unit -> unit
(** Resets job notification mechanism  *)

val init_job_notification : int -> Unix.file_descr

val send_notification : int -> unit