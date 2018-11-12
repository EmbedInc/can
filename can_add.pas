{   Routines to add data to CAN frames.
}
module can_add;
define can_add8;
define can_add16;
define can_add24;
define can_add32;
%include 'can2.ins.pas';
{
********************************************************************************
*
*   Subroutine CAN_ADD8 (FRAME, B)
*
*   Add the byte in the low bits of B as the next data byte in the CAN frame
*   FRAME.  Nothing is done if the CAN frame already contains the maximum number
*   of data bytes.
}
procedure can_add8 (                   {add one 8 bit byte to a CAN frame being built}
  in out  frame: can_frame_t;          {the frame to add a byte to}
  in      b: sys_int_conv8_t);         {byte value in the low bits}
  val_param;

begin
  if frame.ndat >= 8 then return;      {CAN frame already full ?}

  frame.dat[frame.ndat] := b & 255;    {add the new byte to the list}
  frame.ndat := frame.ndat + 1;        {update number of bytes in the frame}
  end;
{
********************************************************************************
*
*   Subroutines CAN_ADDn (FRAME, W)
*
*   Add the N bytes in the low bits of the word W to the CAN frame FRAME.  The
*   bytes are added in most to least significant order.  No new bytes are added
*   when the CAN frame already contains the maximum number of bytes.
}
procedure can_add16 (                  {add a 16 bit word to a CAN frame being built}
  in out  frame: can_frame_t;          {the frame to add a byte to}
  in      w: sys_int_conv16_t);        {word value in the low bits, high to low byte order}
  val_param;

begin
  can_add8 (frame, rshft(w, 8));
  can_add8 (frame, w);
  end;
{
********************
}
procedure can_add24 (                  {add a 24 bit word to a CAN frame being built}
  in out  frame: can_frame_t;          {the frame to add a byte to}
  in      w: sys_int_conv24_t);        {word value in the low bits, high to low byte order}
  val_param;

begin
  can_add8 (frame, rshft(w, 16));
  can_add8 (frame, rshft(w, 8));
  can_add8 (frame, w);
  end;
{
********************
}
procedure can_add32 (                  {add a 32 bit word to a CAN frame being built}
  in out  frame: can_frame_t;          {the frame to add a byte to}
  in      w: sys_int_conv32_t);        {word value in the low bits, high to low byte order}
  val_param;

begin
  can_add8 (frame, rshft(w, 24));
  can_add8 (frame, rshft(w, 16));
  can_add8 (frame, rshft(w, 8));
  can_add8 (frame, w);
  end;
