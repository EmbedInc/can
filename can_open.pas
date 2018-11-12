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
*   Initialize the CAN library state CL.  No system resources will be allocated
*   to CL, but it will be valid to make settings in before opening the library
*   with it.
}
procedure can_init (                   {init library use state, must be first call}
  out     cl: can_t);                  {returned library use state}
  val_param;

begin
  cl.dev.name.max := size_char(cl.dev.name.str);
  cl.dev.name.len := 0;
  cl.dev.path.max := size_char(cl.dev.path.str);
  cl.dev.path.len := 0;
  cl.dev.nspec := 0;
  cl.dev.devtype := can_dev_none_k;
  cl.mem_p := nil;
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
  try_dev, abort;

begin
  sys_error_none(stat);                {init to no error encountered}

  util_mem_context_get (util_top_mem_context, cl.mem_p); {create memory context}

  scandev := false;                    {init to try device type specified only}
  if cl.dev.devtype = can_dev_none_k then begin {no device type specified ?}
    scandev := true;                   {indicate scanning the device types}
    cl.dev.devtype := firstof(cl.dev.devtype); {init first device type to try}
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
    goto abort;
    end;
  if sys_error(stat) then begin        {device not opened ?}
    if scandev then begin              {scanning device types ?}
      if cl.dev.devtype = lastof(cl.dev.devtype) then begin {done scanning all device types ?}
        cl.dev.devtype := can_dev_none_k;
        sys_stat_set (can_subsys_k, can_stat_nodev_k, stat);
        goto abort;
        end;
      cl.dev.devtype := succ(cl.dev.devtype); {advance to next device type}
      goto try_dev;                    {back to try this new device type}
      end;
    goto abort;                        {failed to open specific device}
    end;

  return;                              {device opened, normal return}

abort:                                 {error after mem context created, STAT set}
  util_mem_context_del (cl.mem_p);     {delete the memory context}
  end;
{
********************************************************************************
*
*   Subroutine CAN_CLOSE (CL, STAT)
*
*   Close a use of the CAN library.  CL is the library use state and will be
*   returned initialized.
}
procedure can_close (                  {end a use of this library}
  in out  cl: can_t;                   {library use state, returned initialized but unused}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  sys_error_none (stat);               {init to no error}

  if cl.close_p <> nil then begin      {driver close routine exists ?}
    cl.close_p^ (addr(cl), cl.dat_p, stat); {call driver close routine}
    end;
  util_mem_context_del (cl.mem_p);     {delete all dynamic memory of this lib use}

  can_init (cl);                       {return CL in initialized state}
  end;
