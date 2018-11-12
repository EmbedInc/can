{   Routines that manipulate CAN devices lists.
}
module can_devlist;
define can_devlist_create;
define can_devlist_add;
define can_devlist_del;
define can_devlist_get;

%include 'can2.ins.pas';
{
********************************************************************************
*
*   Subroutine CAN_DEVLIST_CREATE (MEM, DEVS)
*
*   Create and initialize a new blank CAN devices list.  MEM is the parent
*   memory context.  A new memory context subordinate to it will be created, and
*   all dynamic memory of the list will be allocated under the new subordinate
*   memory context.  The list is returned initialized and ready for use, but
*   empty.
}
procedure can_devlist_create (         {create new CAN devices list}
  in out  mem: util_mem_context_t;     {parent context for dynamic memory}
  out     devs: can_devs_t);           {returned initialized and empty list}
  val_param;

begin
  util_mem_context_get (mem, devs.mem_p); {make private memory context for the list}
  devs.n := 0;                         {init to no list entries}
  devs.list_p := nil;
  devs.last_p := nil;
  end;
{
********************************************************************************
*
*   Subroutine CAN_DEVLIST_ADD (DEVS, DEV_P)
*
*   Create a new entry to the CAN devices list DEVS.  The new entry will be
*   initialized to default or benign values and added to the end of the list.
*   DEV_P will be returned pointing to the contents of the new entry.
}
procedure can_devlist_add (            {add entry to CAN devices list}
  in out  devs: can_devs_t;            {list to add entry to}
  out     dev_p: can_dev_p_t);         {returned pointing to new entry}
  val_param;

var
  ent_p: can_dev_ent_p_t;              {pointer to new list entry}
  ii: sys_int_machine_t;               {scratch integer and loop counter}

begin
  util_mem_grab (                      {allocate memory for the new entry}
    sizeof(ent_p^), devs.mem_p^, false, ent_p);
{
*   Initialize the entry data.
}
  ent_p^.next_p := nil;                {new entry will be at end of list}
  ent_p^.dev.name.max := size_char(ent_p^.dev.name.str);
  ent_p^.dev.name.len := 0;
  for ii := 1 to ent_p^.dev.name.max do begin
    ent_p^.dev.name.str[ii] := chr(0);
    end;
  ent_p^.dev.path.max := size_char(ent_p^.dev.path.str);
  ent_p^.dev.path.len := 0;
  for ii := 1 to ent_p^.dev.path.max do begin
    ent_p^.dev.path.str[ii] := chr(0);
    end;
  ent_p^.dev.nspec := 0;
  for ii := 0 to can_spec_last_k do begin {init all device spec bytes to zero}
    ent_p^.dev.spec[ii] := 0;
    end;
  ent_p^.dev.devtype := can_dev_none_k;
{
*   Link the new entry to the end of the list.
}
  if devs.last_p = nil
    then begin                         {the list is empty}
      devs.list_p := ent_p;
      end
    else begin                         {there is at least one previous entry}
      devs.last_p^.next_p := ent_p;
      end
    ;
  devs.last_p := ent_p;
  devs.n := devs.n + 1;                {count one more entry in the list}

  dev_p := addr(ent_p^.dev);           {return pointer to new list entry contents}
  end;
{
********************************************************************************
*
*   Subroutine CAN_DEVLIST_DEL (DEVS)
*
*   Delete the CAN devices list DEVS.  All system resources allocated to the
*   list are released.  DEVS can not be used after this call except to pass to
*   CAN_DEVLIST_CREATE to create a new list.
}
procedure can_devlist_del (            {delete CAN devices list}
  in out  devs: can_devs_t);           {list to delete, returned unusable}
  val_param;

begin
  util_mem_context_del (devs.mem_p);   {deallocate all dynamic memory used by the list}
  devs.n := 0;
  devs.list_p := nil;
  devs.last_p := nil;
  end;
{
********************************************************************************
*
*   Subroutine CAN_DEVLIST_GET (MEM, DEVS)
*
*   Get the list of all CAN devices known to be availble to this system thru
*   this library.  MEM is the parent memory context.  A subordinate memory
*   context will be created, which will be used for all dynamically allocated
*   list memory.  This subordinate memory context will be deleted when the list
*   is deleted.
}
procedure can_devlist_get (            {get list of known CAN devices available to this system}
  in out  mem: util_mem_context_t;     {parent context for list memory}
  out     devs: can_devs_t);           {returned list of devices}
  val_param;

begin
  can_devlist_create (mem, devs);      {create a new empty CAN devices list}
{
*   Call the ADDLIST entry point for each driver.  If a new driver is added that
*   supports enumeratable devices, a call to its ADDLIST entry point must be
*   added here.
}
  can_addlist_usbcan (devs);
  end;
