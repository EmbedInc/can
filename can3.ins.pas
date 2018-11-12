{   Include file for the downstream interface of the CAN library.  This
*   interface is for optional use by subsystems that provide device dependent
*   CAN I/O.
*
*   The CAN library presents device independent CAN I/O to applications.  The
*   unique handlers for each of the supported device dependent CAN I/O
*   subsystems are built into the CAN library.  This is necessary since some
*   of these subsystems may have been developed without any knowledge of the
*   CAN library.
*
*   This interface provides general resources from the CAN library that may be
*   useful for subsystems implementing CAN I/O.  Using these resources is not a
*   requirement for support from the CAN library, but may make such support more
*   efficient and easier to implement both for the CAN library driver and the
*   device dependent subsystem.
}
procedure can_devlist_add (            {add entry to CAN devices list}
  in out  devs: can_devs_t;            {list to add entry to}
  out     dev_p: can_dev_p_t);         {returned pointing to new entry}
  val_param; extern;

procedure can_devlist_create (         {create new CAN devices list}
  in out  mem: util_mem_context_t;     {parent context for dynamic memory}
  out     devs: can_devs_t);           {returned initialized and empty list}
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
