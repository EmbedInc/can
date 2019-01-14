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
