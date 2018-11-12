{   Program CANLIST
*
*   List all CAN controllers connected to the system.
}
program canlist;
%include 'base.ins.pas';
%include 'can.ins.pas';

var
  devs: can_devs_t;                    {devices list}
  dev_p: can_dev_ent_p_t;              {pointer to current devices list entry}

begin
  can_devlist_get (util_top_mem_context, devs); {get list of known CAN devices}

  if devs.n = 1
    then begin                         {exactly one device found}
      writeln (devs.n, ' CAN device found.');
      end
    else begin
      writeln (devs.n, ' CAN devices found.');
      end
    ;

  dev_p := devs.list_p;                {init to first list entry}
  while dev_p <> nil do begin          {once for each list entry}
    writeln;
    writeln ('Name: ', dev_p^.dev.name.str:dev_p^.dev.name.len);
    writeln ('Path: ', dev_p^.dev.path.str:dev_p^.dev.path.len);
    dev_p := dev_p^.next_p;            {advance to next list entry}
    end;                               {back to do this new list entry}
  end.
