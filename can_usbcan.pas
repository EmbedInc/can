{   Device driver for USBCAN devices.
}
module can_usbcan;
define can_addlist_usbcan;
define can_open_usbcan;

%include 'can2.ins.pas';
%include 'usbcan.ins.pas';

type
  dev_p_t = ^dev_t;
  dev_t = record                       {private device data for this driver}
    uc: usbcan_t;                      {USBCAN library use state}
    end;

procedure can_usbcan_send (            {driver routine to send CAN frame}
  in out  cl: can_t;                   {CAN library use state}
  in out  dev: dev_t;                  {private driver data}
  in      frame: can_frame_t;          {the CAN frame to send}
  out     stat: sys_err_t);
  val_param; forward;

function can_usbcan_recv (             {driver routine to get next CAN frame}
  in out  cl: can_t;                   {CAN library use state}
  in out  dev: dev_t;                  {private driver data}
  in      tout: real;                  {max seconds to wait}
  out     frame: can_frame_t;          {returned CAN frame}
  out     stat: sys_err_t)
  :boolean;                            {TRUE with frame, FALSE with timeout or error}
  val_param; forward;

procedure can_usbcan_close (           {driver routine to close the device}
  in out  cl: can_t;                   {CAN library use state}
  in out  dev: dev_t;                  {private driver data}
  out     stat: sys_err_t);
  val_param; forward;
{
********************************************************************************
*
*   Subroutine CAN_ADDLIST_USBCAN (DEVS)
*
*   Add all the devices connected to the system that are known to this driver to
*   the list DEVS.
}
procedure can_addlist_usbcan (         {add USBCAN devices to list}
  in out  devs: can_devs_t);           {list to add known devices to}
  val_param;

var
  ddv: usbcan_devs_t;                  {list of devices known to this driver}
  dent_p: usbcan_dev_p_t;              {pointer to current devices list entry}
  dev_p: can_dev_p_t;                  {pnt to contents of one returned list entry}

begin
  usbcan_devs_get (util_top_mem_context, ddv); {get list of devices}

  dent_p := ddv.list_p;                {init to first list entry}
  while dent_p <> nil do begin         {scan the private devices list}
    can_devlist_add (devs, dev_p);     {make new master list entry}
    string_copy (dent_p^.name, dev_p^.name); {set device name}
    string_copy (dent_p^.path, dev_p^.path); {set system device pathname}
    dent_p := dent_p^.next_p;          {advance to next entry in local list}
    end;

  usbcan_devs_dealloc (ddv);           {done with local devices list}
  end;
{
********************************************************************************
*
*   Subroutine CAN_OPEN_USBCAN (CL, STAT)
*
*   Open a device managed by this driver for the CAN library use state CL.
}
procedure can_open_usbcan (            {open USBCAN device}
  in out  cl: can_t;                   {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  dev_p: dev_p_t;                      {pointer to private device state}

label
  abort;

begin
  util_mem_grab (                      {allocate private driver data for this device}
    sizeof(dev_p^), cl.mem_p^, true, dev_p);
  usbcan_init (dev_p^.uc);             {init USBCAN library state}
  string_copy (cl.dev.name, dev_p^.uc.name); {set name of device to open}
  usbcan_open (dev_p^.uc, stat);       {try to open the device}
  if sys_error(stat) then goto abort;
{
*   The device was successfully opened.
}
  string_copy (dev_p^.uc.name, cl.dev.name); {indicate name of device actually opened}
  cl.dat_p := dev_p;                   {save pointer to driver state}
  cl.send_p := univ_ptr(addr(can_usbcan_send)); {install pointer to driver routines}
  cl.recv_p := univ_ptr(addr(can_usbcan_recv));
  cl.close_p := univ_ptr(addr(can_usbcan_close));
  return;                              {device opened successfully}
{
*   Unable to open the device.  STAT is indicating the error.
}
abort:
  util_mem_ungrab (dev_p, cl.mem_p^);  {deallocate the driver data}
  end;
{
********************************************************************************
*
*   Subroutine CAN_USBCAN_SEND (CL, DEV, FRAME, STAT)
*
*   Send the CAN frame in FRAME.  CL is the CAN library use state and DEV is the
*   private driver state for this connection.
}
procedure can_usbcan_send (            {driver routine to send CAN frame}
  in out  cl: can_t;                   {CAN library use state}
  in out  dev: dev_t;                  {private driver data}
  in      frame: can_frame_t;          {the CAN frame to send}
  out     stat: sys_err_t);
  val_param;

begin
  usbcan_frame_send (dev.uc, frame, stat); {send the frame}
  end;
{
********************************************************************************
*
*   Function CAN_USBCAN_RECV (CL, DEV, TOUT, FRAME, STAT)
*
*   Get the next CAN frame into FRAME.  CL is the CAN library use state and DEV
*   is the private driver state for this connection.  TOUT is the maximum time
*   to wait in seconds for a CAN frame to be available.  TOUT may have the
*   special value of SYS_TIMEOUT_NONE_K, which causes this routine to wait
*   indefinitely until a CAN frame is available.
*
*   The function return value will be TRUE when returninig with a CAN frame, and
*   FALSE if returning because no frame was available or a hard error occurred.
*   STAT will be set to indicate the error in the latter case.  STAT will always
*   indicate no error when the function returns TRUE.
}
function can_usbcan_recv (             {driver routine to get next CAN frame}
  in out  cl: can_t;                   {CAN library use state}
  in out  dev: dev_t;                  {private driver data}
  in      tout: real;                  {max seconds to wait}
  out     frame: can_frame_t;          {returned CAN frame}
  out     stat: sys_err_t)
  :boolean;                            {TRUE with frame, FALSE with timeout or error}
  val_param;

begin
  can_usbcan_recv := usbcan_frame_recv (dev.uc, tout, frame, stat);
  end;
{
********************************************************************************
*
*   Subroutine CAN_USBCAN_CLOSE (CL, DEV, STAT)
*
*   Close the CAN library connection to the USBCAN device.  CL is the CAN
*   library state.  DEV is the private state for this use of this device.  Any
*   dynamic memory subordinate to the CAN library memory context in CL will be
*   automatically deallocated by the CAN library after this routine returns.
}
procedure can_usbcan_close (           {driver routine to close the device}
  in out  cl: can_t;                   {CAN library use state}
  in out  dev: dev_t;                  {private driver data}
  out     stat: sys_err_t);
  val_param;

begin
  usbcan_close (dev.uc, stat);         {close this use of the USBCAN library}
  end;
