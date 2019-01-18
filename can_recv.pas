{   Routines for sending CAN frames.
}
module can_recv;
define can_recv_check;
define can_recv;

%include 'can2.ins.pas';
{
********************************************************************************
*
*   Function CAN_RECV_CHECK (CL)
*
*   Returns TRUE if a received CAN frame is immediately available, and FALSE if
*   none is.
}
function can_recv_check (              {find whether received CAN frame available}
  in out  cl: can_t)                   {state for this use of the library}
  :boolean;                            {CAN frame is immediately available}
  val_param;

var
  fr: can_frame_t;
  stat: sys_err_t;

begin
  can_recv_check := false;             {init to no CAN frame available}

  if can_queue_ent_avail (cl.inq) then begin {a frame is in the input queue ?}
    can_recv_check := true;
    return;
    end;

  if cl.recv_p <> nil then begin       {explicit frame fetch routine exists ?}
    if cl.recv_p^(addr(cl), cl.dat_p, 0.0, fr, stat) then begin {got a new frame ?}
      can_queue_put (cl.inq, fr);      {save the frame in the input queue}
      can_recv_check := true;          {a frame is now immediately available ?}
      end;
    end;
  end;
{
********************************************************************************
*
*   Function CAN_RECV (CL, TOUT, FRAME, STAT)
*
*   Get the next received CAN frame.  This routine waits up to TOUT seconds.  If
*   a received CAN frame is available in that time, the description of the frame
*   is returned in FRAME and the function returns TRUE.  If no CAN frame is
*   available within the timeout, then the function returns FALSE and the
*   contents of FRAME is undefined.
}
function can_recv (                    {get next received CAN frame}
  in out  cl: can_t;                   {state for this use of the library}
  in      tout: real;                  {timeout seconds or SYS_TIMEOUT_NONE_k}
  out     frame: can_frame_t;          {CAN frame if function returns TRUE}
  out     stat: sys_err_t)             {completion status}
  :boolean;                            {TRUE with frame, FALSE with timeout or error}
  val_param;

begin
  sys_error_none (stat);               {init to no error}

  if cl.recv_p = nil then begin        {driver pushes frames asynchronously onto queue ?}
    can_recv := can_queue_get(cl.inq, tout, frame); {get next frame from queue with timeout}
    return;
    end;
{
*   The driver has a explicit frame get routine for us to call.
}
  if can_queue_get(cl.inq, 0.0, frame) then begin {get frame from queue, if any}
    can_recv := true;                  {indicate returning with a frame ?}
    return;
    end;

  can_recv := cl.recv_p^ (             {call driver routine to get the frame}
    addr(cl), cl.dat_p, tout, frame, stat);
  end;
