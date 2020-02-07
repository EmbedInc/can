/*   Messages related to the CAN library.
/*
msg err1
  lan english
    Unexpected CAN device type ID of value %p1i encountered.
msg err2
  lan english
    No CAN device found to open.
msg err3
  lan english
    Unread data bytes left in CAN frame.  %p1i bytes available, %p2i read.
msg err4
  lan english
    Attempt to read past end of CAN frame data bytes.  Only %p1i bytes
    available.

msg err_lock_qinit
  lan english
    Error on attempt to create multi-thread interlock while initializing a CAN
    frames queue.
msg err_lock_del_queue
  lan english
    Error on attemp to delete the multi-thread interlock while releasing the
    system resources of a CAN frames queue.
msg err_queue_wait
  lan english
    Error on wait for next queue entry to become available.
