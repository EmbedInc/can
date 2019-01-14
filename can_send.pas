{   Routines for sending CAN frames.
}
module can_send;
define can_send;

%include 'can2.ins.pas';
{
********************************************************************************
*
*   Subroutine CAN_SEND (CL, FRAME, STAT)
*
*   Send the CAN frame described by FRAME.  The CAN frame may be transmitted
*   after this routine returns.
}
procedure can_send (                   {send a CAN frame}
  in out  cl: can_t;                   {state for this use of the library}
  in      frame: can_frame_t;          {the CAN frame to send}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  sys_error_none (stat);               {init to no error encountered}

  if cl.send_p <> nil then begin       {send routine supplied ?}
    cl.send_p^ (addr(cl), cl.dat_p, frame, stat); {send the frame}
    end;
  end;
