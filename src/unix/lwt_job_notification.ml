external reset_notificatons : unit -> unit  = "lwt_unix_reset_and_close_notifications"
external init_job_notification : int -> Unix.file_descr = "lwt_unix_init_job_notification"
external send_notification : int -> unit = "lwt_send_job_notification"
external get_next_job_notification_id : unit -> int = "lwt_unix_get_next_available_job_notification_id"

