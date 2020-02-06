{   Private include file for the routines that implement the CAN library.
}
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'pic.ins.pas';
%include 'can.ins.pas';
%include 'can3.ins.pas';

{   Driver OPEN routines.
}
procedure can_open_usbcan (            {open USBCAN device}
  in out  cl: can_t;                   {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

{  Driver ADDLIST routines.
}
procedure can_addlist_usbcan (         {add USBCAN devices to list}
  in out  devs: can_devs_t);           {list to add known devices to}
  val_param; extern;
