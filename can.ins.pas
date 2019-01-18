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
    can_dev_custom_k,                  {custom driver, not built into CAN library}
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
    geti: sys_int_conv8_t;             {next data byte to get, 0-7}
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
    lk_send: sys_sys_threadlock_t;     {lock for calling SEND_P^}
    mem_p: util_mem_context_p_t;       {points to private memory context}
    inq: can_queue_t;                  {received CAN frames queue}
    dat_p: univ_ptr;                   {points to data private to the driver}
    send_p: can_send_p_t;              {pointer to driver send routine}
    recv_p: can_recv_p_t;              {pointer to driver receive routine}
    close_p: can_close_p_t;            {pointer to driver close routine}
    quit: boolean;                     {trying to close this library use}
    end;
{
*   Template for application-supplied routine to create a CAN library use with a
*   custom driver.  See header comments in CAN_CUSTOM.PAS for details.
}
  can_open_p_t = ^procedure (          {open CAN library use to custom driver}
    in out  cl: can_t;                 {CAN library use state to set up}
    in      cfg: sys_int_conv32_t;     {optional 32 bit configuration parameter}
    in      pnt: univ_ptr;             {optional pointer to additional config parameters}
    in out  stat: sys_err_t);          {completion status}
    val_param;
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

procedure can_frame_init (             {init CAN frame descriptor}
  out     fr: can_frame_t);            {all fields set, STD data frame, no bytes, ID 0}
  val_param; extern;

function can_get_i8u (                 {get next 8 bit unsigned integer from CAN frame}
  in out  fr: can_frame_t)             {frame to get data from}
  :sys_int_machine_t;                  {0 to 255 value}
  val_param; extern;

function can_get_i8s (                 {get next 8 bit signed integer from CAN frame}
  in out  fr: can_frame_t)             {frame to get data from}
  :sys_int_machine_t;                  {-128 to +127 value}
  val_param; extern;

function can_get_i16u (                {get next 16 bit unsigned integer from CAN frame}
  in out  fr: can_frame_t)             {frame to get data from}
  :sys_int_machine_t;                  {0 to 65535 value}
  val_param; extern;

function can_get_i16s (                {get next 16 bit signed integer from CAN frame}
  in out  fr: can_frame_t)             {frame to get data from}
  :sys_int_machine_t;                  {-32768 to +32767 value}
  val_param; extern;

function can_get_i24u (                {get next 24 bit unsigned integer from CAN frame}
  in out  fr: can_frame_t)             {frame to get data from}
  :sys_int_machine_t;                  {returned value}
  val_param; extern;

function can_get_i24s (                {get next 24 bit signed integer from CAN frame}
  in out  fr: can_frame_t)             {frame to get data from}
  :sys_int_machine_t;                  {returned value}
  val_param; extern;

function can_get_i32u (                {get next 32 bit unsigned integer from CAN frame}
  in out  fr: can_frame_t)             {frame to get data from}
  :sys_int_machine_t;                  {returned value}
  val_param; extern;

function can_get_i32s (                {get next 32 bit signed integer from CAN frame}
  in out  fr: can_frame_t)             {frame to get data from}
  :sys_int_machine_t;                  {returned value}
  val_param; extern;

procedure can_init (                   {init CAN library use state}
  out     cl: can_t);                  {library use state to initialize}
  val_param; extern;

procedure can_open (                   {open new library use}
  in out  cl: can_t;                   {library use state}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure can_open_custom (            {create new CAN library use, custom driver}
  out     cl: can_t;                   {library use state to initialize and open}
  in      open_p: can_open_p_t;        {pointer to routine to perform custom open}
  in      cfg: sys_int_conv32_t;       {optional 32 bit configuration parameter}
  in      pnt: univ_ptr;               {optional pointer to configuration parameters}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

function can_queue_ent_avail (         {indicate whether entry from queue available}
  in out  q: can_queue_t)              {queue to check}
  :boolean;                            {TRUE for queue not empty, FALSE for empty}
  val_param; extern;

procedure can_queue_ent_new (          {return pointer to new queue entry}
  in out  q: can_queue_t;              {queue to get new unused entry for}
  out     ent_p: can_listent_p_t);     {returned pointer to the new entry}
  val_param; extern;

procedure can_queue_ent_del (          {delete a CAN frames queue entry}
  in out  q: can_queue_t;              {queue to delete etnry entry for}
  in out  ent_p: can_listent_p_t);     {pointer to unused entry, returned NIL}
  val_param; extern;

procedure can_queue_ent_get (          {get next queue entry, wait with timeout}
  in out  q: can_queue_t;              {queue to get entry for}
  in      tout: real;                  {maximum wait time, seconds}
  out     ent_p: can_listent_p_t);     {returned pnt to entry, NIL if none}
  val_param; extern;

procedure can_queue_ent_put (          {add entry to end of can frames queue}
  in out  q: can_queue_t;              {queue to add entry to}
  in out  ent_p: can_listent_p_t);     {pointer to the entry to add, returned NIL}
  val_param; extern;

function can_queue_get (               {get next CAN frame from queue}
  in out  q: can_queue_t;              {queue to get entry for}
  in      tout: real;                  {maximum wait time, seconds}
  out     frame: can_frame_t)          {the returned CAN frame}
  :boolean;                            {TRUE with frame, FALSE with timeout}
  val_param; extern;

procedure can_queue_init (             {initialize a can frames queue}
  out     q: can_queue_t;              {the queue to initialize}
  in out  mem: util_mem_context_t);    {parent memory context}
  val_param; extern;

procedure can_queue_put (              {add CAN frame to end of queue}
  in out  q: can_queue_t;              {the CAN frames queue}
  in      frame: can_frame_t);         {the CAN frame to add}
  val_param; extern;

procedure can_queue_release (          {release system resources of a CAN frames queue}
  in out  q: can_queue_t);             {the queue, will be returned unusable}
  val_param; extern;

function can_recv (                    {get next received CAN frame}
  in out  cl: can_t;                   {state for this use of the library}
  in      tout: real;                  {timeout seconds or SYS_TIMEOUT_NONE_k}
  out     frame: can_frame_t;          {CAN frame if function returns TRUE}
  out     stat: sys_err_t)             {completion status}
  :boolean;                            {TRUE with frame, FALSE with timeout or error}
  val_param; extern;

function can_recv_check (              {find whether received CAN frame available}
  in out  cl: can_t)                   {state for this use of the library}
  :boolean;                            {CAN frame is immediately available}
  val_param; extern;

procedure can_send (                   {send a CAN frame}
  in out  cl: can_t;                   {state for this use of the library}
  in      frame: can_frame_t;          {the CAN frame to send}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;
