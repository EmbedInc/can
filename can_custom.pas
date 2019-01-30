{   Routines for interfacing the CAN library to custom application-supplied
*   drivers.
*
*   The purpose of the CAN library is to provide generic routines for
*   manipulating CAN frames, and to provide a device-independent CAN frame I/O
*   interface.
*
*   Drivers for some known CAN I/O devices are built into the CAN library.
*   These can never include all possible CAN I/O means.  The routines in this
*   module provide a mechanism for applications to supply the minimum necessary
*   device-dependent routines themselves, and then be able to use the normal
*   CAN library device-independent interface for sending and receiving CAN
*   frames.
*
*   CAN_OPEN_CUSTOM is used to set up a CAN library use state with application
*   supplied low level drivers for CAN frame I/O.  CAN_OPEN_CUSTOM initializes
*   the CAN library use state, then calls the application-specific open routine
*   supplied to it.
*
*   The CAN library use state is initialized to the following state before the
*   custom open routine is called:
*
*     - MEM_P is pointing to a memory context that is private to this CAN
*       library use state.
*
*     - DAT_P, SEND_P, RECV_P, and CLOSE_P are all initialized to NIL.
*
*     - DEV is initialized to empty and unused.  DEV.NAME and DEV.PATH are
*       empty strings, all the SPEC bytes are initialized to 0, and NSPEC is
*       set to 0.  It is intended that custom drivers not use DEV.
*
*     - The input queue (INQ) is set up and initialized to empty.
*
*   The responsibilities of the custom open routine are:
*
*     - Set CL.SEND_P pointing to the device-specific CAN frame send routine, if
*       the interface is capable of sending CAN frames.  If not, leave SEND_P
*       NIL.  In that case, CAN_SEND will silently ignore requests to send
*       frames.
*
*     - Set CL.RECV_P pointing to the device-specific CAN frame receiving
*       routine, if the interface is capable of receiving CAN frames and the CAN
*       library code needs to specifically ask for each received frame.
*
*       If not, leave RECV_P NIL.  In that case, it is assumed that the driver
*       will automatically push received frames onto the input queue without
*       explicit action by the CAN library to cause it.  If no frames are ever
*       pushed onto the queue, then no frames will be received at the
*       application level.
*
*     - Set CL.CLOSE_P pointing to a custom close routine, if one is needed.
*       When such a routine is referenced, it will be called by CAN_CLOSE before
*       and CAN library memory is deallocated.  A custom close routine is only
*       required if additional actions need to be taken to deallocate system
*       resources other than those built into the CAN library use, and that are
*       not deallocated by deleting the memory context pointed to by CL.MEM_P.
*       CAN_CLOSE always deallocates the resources built into the CAN library
*       use state, which includes deleting the CL.MEM_P memory context as the
*       last step.
*
*     - CL.DAT_P can be used to provide use-specific persistant state between
*       calls to the low level driver routines.  DAT_P is a generic pointer left
*       for exclusive use by driver routines.  It should point to memory that is
*       allocated under the CL.MEM_P^ context.  This causes such memory to be
*       automatically deallocated when the CAN library use state is closed.
*
*     - Set STAT on error.  STAT is initialized to no error before the open
*       routine is called.  When the open routine detects a error, it should
*       set STAT accordingly.  This will be passed to the caller of
*       CAN_OPEN_CUSTOM.  In that case, CAN_OPEN_CUSTOM will deallocate any
*       system resources allocated to that CAN library use, and return the
*       library use descriptor invalid.
*
*       When the open routine returns with STAT indicating error, it must not
*       have any additional system resources allocated.  The custom close
*       routine, if any, will not be called.
*
*   The CAN library use state always includes a queue for received CAN frames,
*   although custom receive routines need not be aware of this.  The application
*   interface for receiving frames is thru this queue.  The driver can supply
*   received CAN frames in two different ways:
*
*     - Supply a explicit receive routine via the RECV_P pointer.  The CAN
*       library will automatically call this routine when the application
*       requests a CAN frame and the input queue is empty.
*
*     - Push received frames asynchronously onto the input queue.  In this case,
*       RECV_P should be left NIL.
*
*   If a queue for sending CAN frames is desirable for the driver, then it must
*   create such a queue itself.
*
*   Sending and receiving drivers only need to be simple, but can be arbitrarily
*   complex as desired.  Additional tasks can be launched, various system
*   resources, allocated, etc.  The only restriction is that a custom close
*   routine must then be provided to deallocate any such system resources other
*   than dynamic memory under the CL.MEM_P^ context.
*
*   RECV_P routine
*
*     This routine is optional.  The driver needs to do nothing at all if it
*     is not capable of receiving CAN frames.  Otherwise, there are two choices.
*     The driver can asynchronously push received CAN frames onto the input
*     queue, or it can provide a routine for the CAN library to explicitly call
*     via the RECV_P pointer.  There is no mutex around calling RECV_P^.  If the
*     application will call CAN_RECV from multiple threads, then the driver
*     should push received frames onto the input queue.  Reads and writes to and
*     from the queue are multi-thread safe.
*
*   SEND_P routine
*
*     The CAN library has no queue for sending CAN frames.  Each frame is passed
*     to the driver when CAN_SEND is called.  A mutex is used to guarantee that
*     only one thread at a time is calling SEND_P^, even if multiple threads
*     call CAN_SEND simultaneously.
}
module can_custom;
define can_open_custom;
%include 'can2.ins.pas';
{
********************************************************************************
*
*   Subroutine CAN_OPEN_CUSTOM (CL, OPEN_P, CFG, PNT, STAT)
*
*   Initialize and set up the CAN library use state CL with custom routines for
*   sending and receiving CAN frames.
*
*   OPEN_P points to the application routine to call to install the custom
*   driver routines.  See the header comments of this module for details.
*
*   I32 and PNT are optional configuration parameters that are passed to the
*   custom open routine pointed to by OPEN_P.
}
procedure can_open_custom (            {create new CAN library use, custom driver}
  out     cl: can_t;                   {library use state to initialize and open}
  in      open_p: can_open_p_t;        {pointer to routine to perform custom open}
  in      cfg: sys_int_conv32_t;       {optional 32 bit configuration parameter}
  in      pnt: univ_ptr;               {optional pointer to configuration parameters}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  stat2: sys_err_t;                    {to avoid corrupting STAT}

begin
  sys_error_none (stat);               {init to no error encountered}
  can_init (cl);                       {init CAN library state descriptor}

  open_p^ (cl, cfg, pnt, stat);        {call app routine to install drivers}
  if sys_error(stat) then begin        {driver not installed ?}
    cl.close_p := nil;                 {do not run any custom close routine}
    can_close (cl, stat2);             {deallocate resources, CL invalid}
    end;
  end;
