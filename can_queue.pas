{   Routines that manipulate queues of CAN frames.
}
module can_queue;
define can_queue_init;
define can_queue_release;
define can_queue_ent_new;
define can_queue_ent_del;
define can_queue_ent_put;
define can_queue_ent_get;
define can_queue_ent_avail;
define can_queue_put;
define can_queue_get;

%include 'can2.ins.pas';
{
********************************************************************************
*
*   Subroutine CAN_QUEUE_INIT (Q, MEM)
*
*   Initialize the queue of CAN frames, Q.  MEM is the parent memory context.  A
*   subordinate memory context will be created that will be private to the
*   queue.  This subordinate memory context and other system resources allocated
*   to the queue will be released when CAN_QUEUE_RELEASE is called.
}
procedure can_queue_init (             {initialize a can frames queue}
  out     q: can_queue_t;              {the queue to initialize}
  in out  mem: util_mem_context_t);    {parent memory context}
  val_param;

var
  stat: sys_err_t;                     {completion status}

begin
  sys_thread_lock_create (q.lock, stat);
  sys_error_abort (stat, 'can', 'err_lock_qinit', nil, 0);
  sys_event_create_bool (q.ev);        {create event for new entry added to queue}
  util_mem_context_get (mem, q.mem_p); {create new memory context for the queue}
  q.nframes := 0;                      {init queue to empty}
  q.first_p := nil;
  q.last_p := nil;
  q.free_p := nil;
  q.quit := false;                     {init to not closing the queue}
  end;
{
********************************************************************************
*
*   Subroutine CAN_QUEUE_RELEASE (Q)
*
*   Release all system resources allocated to the CAN frames queue Q.  The queue
*   is returned unusable.  It must be initialized before it is used again.
}
procedure can_queue_release (          {release system resources of a CAN frames queue}
  in out  q: can_queue_t);             {the queue, will be returned unusable}
  val_param;

var
  stat: sys_err_t;                     {completion status}

begin
  q.quit := true;                      {indicate the queue is being closed}
  sys_event_notify_bool (q.ev);        {release any waiting thread}
  sys_thread_yield;

  sys_thread_lock_enter (q.lock);      {get exclusive access to this queue}
  sys_event_del_bool (q.ev);
  q.first_p := nil;
  q.last_p := nil;
  q.free_p := nil;
  q.nframes := 0;
  util_mem_context_del (q.mem_p);      {delete the private memory context}
  sys_thread_lock_leave (q.lock);      {release exclusive access to the queue}

  sys_thread_lock_delete (q.lock, stat);
  sys_error_abort (stat, 'can', 'err_lock_del_queue', nil, 0);
  end;
{
********************************************************************************
*
*   Subroutine CAN_QUEUE_ENT_NEW (Q, ENT_P)
*
*   Get a new unused entry associated with the CAN frames queue Q.  The entry
*   will be empty and not enqueued, and will be automatically deallocated when
*   the queue is deleted.  ENT_P is returned NIL if the queue is being closed.
}
procedure can_queue_ent_new (          {return pointer to new queue entry}
  in out  q: can_queue_t;              {queue to get new unused entry for}
  out     ent_p: can_listent_p_t);     {returned pointer to the new entry}
  val_param;

begin
  ent_p := nil;                        {init to not returning with queue entry}
  if q.quit then return;               {queue is being closed ?}

  sys_thread_lock_enter (q.lock);      {get exclusive access to this queue}
  if q.quit then begin                 {queue is being close ?}
    sys_thread_lock_leave (q.lock);    {release exclusive access to the queue}
    return;
    end;
  if q.free_p = nil
    then begin                         {no existing unused entries available}
      util_mem_grab (sizeof(ent_p^), q.mem_p^, false, ent_p); {allocate new queue entry}
      end
    else begin                         {grab from free list}
      ent_p := q.free_p;               {get first entry from free list}
      q.free_p := ent_p^.next_p;
      end
    ;
  sys_thread_lock_leave (q.lock);      {release exclusive access to the queue}

  ent_p^.next_p := nil;
  ent_p^.prev_p := nil;
  end;
{
********************************************************************************
*
*   Subroutine CAN_QUEUE_ENT_DEL (Q, ENT_P)
*
*   Delete a entry associated with the queue Q.  ENT_P is returned NIL since the
*   entry can no longer be accessed.
}
procedure can_queue_ent_del (          {delete a CAN frames queue entry}
  in out  q: can_queue_t;              {queue to delete etnry entry for}
  in out  ent_p: can_listent_p_t);     {pointer to unused entry, returned NIL}
  val_param;

begin
  if q.quit then begin                 {queue is being closed ?}
    ent_p := nil;
    return;
    end;

  sys_thread_lock_enter (q.lock);      {get exclusive access to this queue}
  if not q.quit then begin
    ent_p^.next_p := q.free_p;
    q.free_p := ent_p;
    end;
  sys_thread_lock_leave (q.lock);      {release exclusive access to the queue}

  ent_p := nil;                        {return NIL pointer}
  end;
{
********************************************************************************
*
*   Subroutine CAN_QUEUE_ENT_PUT (Q, ENT_P)
*
*   Add a entry to the end of the CAN frames queue Q.  ENT_P is pointing to the
*   entry to add.  It is returned NIL because once the entry is in the queue it
*   may be accessed by other threads.  It should no longer be accessed directly
*   without going thru the CAN_QUEUE_xxx routines.
}
procedure can_queue_ent_put (          {add entry to end of can frames queue}
  in out  q: can_queue_t;              {queue to add entry to}
  in out  ent_p: can_listent_p_t);     {pointer to the entry to add, returned NIL}
  val_param;

begin
  if q.quit then begin                 {queue is being closed ?}
    ent_p := nil;
    return;
    end;

  ent_p^.next_p := nil;                {init to this entry will be at end of queue}

  sys_thread_lock_enter (q.lock);      {get exclusive access to this queue}
  if not q.quit then begin
    if q.first_p = nil
      then begin                       {this is first queue entry}
        q.first_p := ent_p;
        ent_p^.prev_p := nil;
        end
      else begin                       {adding to end of existing list}
        q.last_p^.next_p := ent_p;
        ent_p^.prev_p := q.last_p;
        end
      ;
    q.last_p := ent_p;
    q.nframes := q.nframes + q.nframes + 1; {count one more CAN frame in the queue}
    sys_event_notify_bool (q.ev);      {signal event for entry added to the queue}
    end;
  sys_thread_lock_leave (q.lock);      {release exclusive access to the queue}

  ent_p := nil;
  end;
{
********************************************************************************
*
*   Subroutine CAN_QUEUE_ENT_GET (Q, TOUT, ENT_P)
*
*   Get the next entry from the CAN frames queue Q.  TOUT is the maximum seconds
*   to wait for a queue entry to become available.  ENT_P is returned pointing
*   to the queue entry.  ENT_P will be NIL if no queue entry was available
*   within the timeout TOUT.  When returning with a queue entry (ENT_P not NIL),
*   the entry will have been removed from the queue.  The caller therefore has
*   exclusive access to the entry.  When done with the entry it should be
*   deleted with CAN_QUEUE_ENT_DEL to release its memory.
}
procedure can_queue_ent_get (          {get next queue entry, wait with timeout}
  in out  q: can_queue_t;              {queue to get entry for}
  in      tout: real;                  {maximum wait time, seconds}
  out     ent_p: can_listent_p_t);     {returned pnt to entry, NIL if none}
  val_param;

var
  stat: sys_err_t;

label
  retry;

begin
  ent_p := nil;                        {init to returning without queue entry}

retry:
  if q.quit then return;               {queue is being closed ?}

  sys_thread_lock_enter (q.lock);      {get exclusive access to this queue}
  if q.quit then begin
    sys_thread_lock_leave (q.lock);
    return;
    end;
  if q.first_p <> nil then begin       {a entry is immediately available ?}
    ent_p := q.first_p;                {return pointer to the entry}
    q.first_p := ent_p^.next_p;        {remove this entry from the queue}
    if ent_p^.next_p = nil
      then begin                       {this is last entry in queue}
        q.last_p := nil;
        end
      else begin                       {there is a subsequent entry}
        ent_p^.next_p^.prev_p := nil;
        end
      ;
    q.nframes := q.nframes - 1;        {count one less entry on the queue}
    sys_thread_lock_leave (q.lock);    {release exclusive access to the queue}
    ent_p^.next_p := nil;
    ent_p^.prev_p := nil;
    return;                            {return with unlinked queue entry}
    end;
  sys_thread_lock_leave (q.lock);      {release exclusive access to the queue}

  if sys_event_wait_tout (q.ev, tout, stat) then begin
    if q.quit then return;
    sys_error_abort (stat, 'can', 'err_queue_wait', nil, 0);
    return;                            {return due to timeout}
    end;
  goto retry;                          {event signalled, try getting entry again}
  end;
{
********************************************************************************
*
*   Function CAN_QUEUE_ENT_AVAIL (Q)
*
*   Indicate whether a queue entry is available to get.  The function returns
*   TRUE when at least one queue entry can be retrieved, and FALSE if the queue
*   is empty.
}
function can_queue_ent_avail (         {indicate whether entry from queue available}
  in out  q: can_queue_t)              {queue to check}
  :boolean;                            {TRUE for queue not empty, FALSE for empty}
  val_param;

begin
  can_queue_ent_avail := false;        {init to no entry immediately available}
  if q.quit then return;

  sys_thread_lock_enter (q.lock);      {get exclusive access to this queue}
  if q.quit then begin
    sys_thread_lock_leave (q.lock);
    return;
    end;
  can_queue_ent_avail := q.nframes > 0;
  sys_thread_lock_leave (q.lock);      {release exclusive access to the queue}
  end;
{
********************************************************************************
*
*   Subroutine CAN_QUEUE_PUT (Q, FRAME)
*
*   Add the CAN frame in FRAME to the end of the CAN frames QUEUE Q.
}
procedure can_queue_put (              {add CAN frame to end of queue}
  in out  q: can_queue_t;              {the CAN frames queue}
  in      frame: can_frame_t);         {the CAN frame to add}
  val_param;

var
  ent_p: can_listent_p_t;              {pointer to CAN frames queue entry}

begin
  if q.quit then return;
  can_queue_ent_new (q, ent_p);        {create new queue entry, unlinked for now}
  if q.quit then return;
  ent_p^.frame := frame;               {copy CAN frame information into the entry}
  can_queue_ent_put (q, ent_p);        {enqueue the entry}
  end;
{
********************************************************************************
*
*   Function CAN_QUEUE_GET (Q, TOUT, FRAME)
*
*   Get the next CAN frame from the CAN frames queue Q.  This routine will wait
*   up to TOUT seconds for a CAN frame to be available.  If one is available
*   within that time, then the function returns TRUE and the frame informaion
*   is returned in FRAME.  If no frame is available within the timeout, then the
*   function returns FALSE and the contents of FRAME is undefined.
}
function can_queue_get (               {get next CAN frame from queue}
  in out  q: can_queue_t;              {queue to get entry for}
  in      tout: real;                  {maximum wait time, seconds}
  out     frame: can_frame_t)          {the returned CAN frame}
  :boolean;                            {TRUE with frame, FALSE with timeout}
  val_param;

var
  ent_p: can_listent_p_t;              {pointer to CAN frames queue entry}

begin
  can_queue_get := false;              {init to not returning with a CAN frame}
  can_queue_ent_get (q, tout, ent_p);  {try to get next queue entry}
  if ent_p = nil then return;          {no frame available within the timeout ?}

  frame := ent_p^.frame;               {return the CAN frame information}
  can_queue_ent_del (q, ent_p);        {done with this queue entry}
  can_queue_get := true;               {indicate returning with a frame}
  end;
