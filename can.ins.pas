{   Public include file for the Embed Inc CAN library.  This library provides a
*   procedural interface to a CAN bus via one of the supported devices.
}
const
  can_subsys_k = -58;                  {ID of this subsystem}
  can_stat_devtype_bad_k = 1;          {unrecognized CAN device type ID}
  can_stat_nodev_k = 2;                {no device found to open}

  can_speclen_k = 80;                  {number of optional device spec bytes}
{
*   Derived constants.
}
  can_spec_last_k = can_speclen_k - 1; {last optional device spec byte index}

type
  can_p_t = ^can_t;                    {pointer to library use state}

  can_dev_k_t = (                      {types of CAN devices supported by this library}
    can_dev_none_k,                    {no device type specified}
    can_dev_usbcan_k);                 {device supported by USBCAN library}

  can_dev_p_t = ^can_dev_t;
  can_dev_t = record                   {info about one CAN device available to this system}
    name: string_var80_t;              {user-visible device name}
    path: string_treename_t;           {system device pathname, as appropriate}
    nspec: sys_int_machine_t;          {number of bytes in SPEC array}
    spec:                              {optional device specification bytes}
      array[0 .. can_spec_last_k] of int8u_t;
    devtype: can_dev_k_t;              {device type}
    end;

  can_dev_ent_p_t = ^can_dev_ent_t;
  can_dev_ent_t = record               {one entry in list of CAN devices}
    next_p: can_dev_ent_p_t;
    dev: can_dev_t;                    {info about this CAN device}
    end;

  can_devs_t = record                  {list of known CAN devices available to this system}
    mem_p: util_mem_context_p_t;       {points to context for list memory}
    n: sys_int_machine_t;              {number of devices in this list}
    list_p: can_dev_ent_p_t;           {points to first list entry}
    last_p: can_dev_ent_p_t;           {points to last list entry}
    end;

  can_frflag_k_t = (                   {CAN frame flags}
    can_frflag_ext_k,                  {extended frame, not standard frame}
    can_frflag_rtr_k);                 {remote request, not data frame}
  can_frflag_t = set of can_frflag_k_t; {all the flags in one word}

  can_dat_t =                          {CAN frame data bytes}
    array[0..7] of int8u_t;

  can_frame_p_t = ^can_frame_t;
  can_frame_t = record                 {info about any one CAN frame}
    id: sys_int_conv32_t;              {frame ID}
    ndat: sys_int_conv8_t;             {number of data bytes, 0-8}
    dat: can_dat_t;                    {data bytes array}
    flags: can_frflag_t;               {set of option flags}
    end;

  can_listent_p_t = ^can_listent_t;
  can_listent_t = record               {one entry in list of CAN frames}
    next_p: can_listent_p_t;           {points to next list entry}
    prev_p: can_listent_p_t;           {points to previous list entry}
    frame: can_frame_t;                {the CAN frame data}
    end;

  can_queue_t = record                 {queue of can frames}
    lock: sys_sys_threadlock_t;        {single thread interlock for queue access}
    ev: sys_sys_event_id_t;            {event signalled when entry added to queue}
    mem_p: util_mem_context_p_t;       {points to context for dynamic memory}
    nframes: sys_int_machine_t;        {number of frames in the queue}
    first_p: can_listent_p_t;          {points to first frame in queue}
    last_p: can_listent_p_t;           {points to last frame in queue}
    free_p: can_listent_p_t;           {points to chain of unused queue entries}
    quit: boolean;                     {closing queue, return with nothing immediately}
    end;

  can_send_p_t = ^procedure (          {subroutine to send a CAN frame}
    in      can_p: can_p_t;            {pointer to library use state}
    in      dat_p: univ_ptr;           {pointer to private driver state}
    in      frame: can_frame_t;        {the CAN frame to send}
    out     stat: sys_err_t);          {completion status}
    val_param;

  can_recv_p_t = ^function (           {function to get next received CAN frame}
    in      can_p: can_p_t;            {pointer to library use state}
    in      dat_p: univ_ptr;           {pointer to private driver state}
    in      tout: real;                {max seconds to wait}
    out     frame: can_frame_t;        {returned CAN frame}
    out     stat: sys_err_t)           {completion status}
    :boolean;                          {TRUE with frame, FALSE with timeout or error}
    val_param;

  can_close_p_t = ^procedure (         {subroutine to close connection to the device}
    in      can_p: can_p_t;            {pointer to library use state}
    in      dat_p: univ_ptr;           {pointer to private driver state}
    out     stat: sys_err_t);          {completion status}
    val_param;

  can_t = record                       {state for one use of this library}
    dev: can_dev_t;                    {specifies the CAN device}
    mem_p: util_mem_context_p_t;       {points to private memory context}
    dat_p: univ_ptr;                   {points to data private to the driver}
    send_p: can_send_p_t;              {pointer to driver send routine}
    recv_p: can_recv_p_t;              {pointer to driver receive routine}
    close_p: can_close_p_t;            {pointer to driver close routine}
    end;
{
*   Public libary routines.
}
procedure can_add8 (                   {add one 8 bit byte to a CAN frame being built}
  in out  frame: can_frame_t;          {the frame to add a byte to}
  in      b: sys_int_conv8_t);         {byte value in the low bits}
  val_param; extern;

procedure can_add16 (                  {add a 16 bit word to a CAN frame being built}
  in out  frame: can_frame_t;          {the frame to add a byte to}
  in      w: sys_int_conv16_t);        {word value in the low bits, high to low byte order}
  val_param; extern;

procedure can_add24 (                  {add a 24 bit word to a CAN frame being built}
  in out  frame: can_frame_t;          {the frame to add a byte to}
  in      w: sys_int_conv24_t);        {word value in the low bits, high to low byte order}
  val_param; extern;

procedure can_add32 (                  {add a 32 bit word to a CAN frame being built}
  in out  frame: can_frame_t;          {the frame to add a byte to}
  in      w: sys_int_conv32_t);        {word value in the low bits, high to low byte order}
  val_param; extern;

procedure can_close (                  {end a use of this library}
  in out  cl: can_t;                   {library use state, returned initialized but unused}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure can_devlist_del (            {delete CAN devices list}
  in out  devs: can_devs_t);           {list to delete, returned unusable}
  val_param; extern;

procedure can_devlist_get (            {get list of known CAN devices available to this system}
  in out  mem: util_mem_context_t;     {parent context for list memory}
  out     devs: can_devs_t);           {returned list of devices}
  val_param; extern;

procedure can_init (                   {init library use state, must be first call}
  out     cl: can_t);                  {returned library use state}
  val_param; extern;

procedure can_open (                   {open new library use}
  in out  cl: can_t;                   {library use state}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

function can_recv (                    {get next received CAN frame}
  in out  cl: can_t;                   {state for this use of the library}
  in      tout: real;                  {timeout seconds or SYS_TIMEOUT_NONE_k}
  out     frame: can_frame_t;          {CAN frame if function returns TRUE}
  out     stat: sys_err_t)             {completion status}
  :boolean;                            {TRUE with frame, FALSE with timeout or error}
  val_param; extern;

function can_recv_avail (              {find whether received CAN frame available}
  in out  cl: can_t)                   {state for this use of the library}
  :boolean;                            {CAN frame is immediately available}
  val_param; extern;

procedure can_send (                   {send a CAN frame}
  in out  cl: can_t;                   {state for this use of the library}
  in      frame: can_frame_t;          {the CAN frame to send}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;
