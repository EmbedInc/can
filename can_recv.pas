{   Routines for sending CAN frames.
}
module can_recv;
define can_recv_avail;
define can_recv;

%include 'can2.ins.pas';
{
********************************************************************************
*
*   Function CAN_RECV_AVAIL (CL)
*
*   Returns TRUE if a received CAN frame is immediately available, and FALSE if
*   none is.
}
function can_recv_avail (              {find whether received CAN frame available}
  in out  cl: can_t)                   {state for this use of the library}
  :boolean;                            {CAN frame is immediately available}
  val_param;

begin
  writeln ('Function CAN_RECV_AVAIL not implemented yet.');
  sys_bomb;
  can_recv_avail := false;
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
  can_recv := cl.recv_p^ (addr(cl), cl.dat_p, tout, frame, stat);
  end;
