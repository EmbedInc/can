{   Routines for opening and closing a use of the CAN library.
}
module can_open;
define can_init;
define can_open;
define can_close;
%include 'can2.ins.pas';
{
********************************************************************************
*
*   Subroutine CAN_INIT (CL)
*
*   Initialize the CAN library state CL.  System resources will be allocated
*   that will be released when the library use state is closed by calling
*   CAN_CLOSE.
*
*   After this call, the library use state is fully functional, but with no
*   driver installed.  This means that attempts to send CAN frames are silently
*   ignored, and no CAN frames are ever received.
}
procedure can_init (                   {init CAN library use state}
  out     cl: can_t);                  {library use state to initialize}
  val_param;

var
  ii: sys_int_machine_t;

begin
  cl.dev.name.max := size_char(cl.dev.name.str);
  cl.dev.name.len := 0;
  cl.dev.path.max := size_char(cl.dev.path.str);
  cl.dev.path.len := 0;
  cl.dev.nspec := 0;
  for ii := 0 to can_spec_last_k do begin
    cl.dev.spec[ii] := 0;
    end;
  cl.dev.devtype := can_dev_none_k;

  util_mem_context_get (util_top_mem_context, cl.mem_p); {create memory context}
  can_queue_init (cl.inq, cl.mem_p^);  {set up and init the input queue}

  cl.dat_p := nil;
  cl.send_p := nil;
  cl.recv_p := nil;
  cl.close_p := nil;
  end;
{
********************************************************************************
*
*   Subroutine CAN_OPEN (CL, STAT)
*
*   Open a use of the CAN library using CL as the library state.  CL must have
*   been previously initialized with CAN_INIT, with some modifications made
*   afterwards.  CL.DEV specifies the CAN device to use.  If this does not
*   specify a particular device, then the first compatible device that is found
*   and not already in use is used.
}
procedure can_open (                   {open new library use}
  in out  cl: can_t;                   {library use state}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  scandev: boolean;                    {scan the device types until find a device}

label
  try_dev;

begin
  sys_error_none(stat);                {init to no error encountered}

  scandev := false;                    {init to try device type specified only}
  if cl.dev.devtype = can_dev_none_k then begin {no device type specified ?}
    scandev := true;                   {indicate scanning the device types}
    cl.dev.devtype := succ(can_dev_custom_k); {init first device type to try}
    end;

try_dev:                               {try opening the current device type}
  case cl.dev.devtype of               {which type of device to try to open ?}
can_dev_none_k: begin                  {not a real device type}
      sys_stat_set (sys_subsys_k, sys_stat_failed_k, stat);
      end;
can_dev_usbcan_k: begin                {USBCAN device type}
      can_open_usbcan (cl, stat);
      end;
otherwise
    sys_stat_set (can_subsys_k, can_stat_devtype_bad_k, stat);
    sys_stat_parm_int (ord(cl.dev.devtype), stat);
    return;
    end;
  if sys_error(stat) then begin        {device not opened ?}
    if scandev then begin              {scanning device types ?}
      if cl.dev.devtype = lastof(cl.dev.devtype) then begin {done scanning all device types ?}
        cl.dev.devtype := can_dev_none_k;
        sys_stat_set (can_subsys_k, can_stat_nodev_k, stat);
        return;                        {hit end of devices list}
        end;
      cl.dev.devtype := succ(cl.dev.devtype); {advance to next device type}
      goto try_dev;                    {back to try this new device type}
      end;
    return;                            {failed to open specific device}
    end;
  end;
{
********************************************************************************
*
*   Subroutine CAN_CLOSE (CL, STAT)
*
*   Close a use of the CAN library.  CL is the library use state, which will be
*   returned invalid.
}
procedure can_close (                  {end a use of this library}
  in out  cl: can_t;                   {library use state, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  sys_error_none (stat);               {init to no error}

  if cl.close_p <> nil then begin      {driver close routine exists ?}
    cl.close_p^ (addr(cl), cl.dat_p, stat); {call driver close routine}
    end;

  can_queue_release (cl.inq);          {release input queue resources}
  util_mem_context_del (cl.mem_p);     {delete all dynamic memory of this lib use}
  end;
