{   Routines that work on CAN frames in isolation, and are independent of any
*   CAN library use state or other external state.
}
module can_frame;
define can_frame_init;
define can_get_reset;
define can_add8;
define can_add16;
define can_add24;
define can_add32;
define can_get_i8u;
define can_get_i8s;
define can_get_i16u;
define can_get_i16s;
define can_get_i24u;
define can_get_i24s;
define can_get_i32u;
define can_get_i32s;
%include 'can2.ins.pas';
{
********************************************************************************
*
*   Subroutine CAN_FRAME_INIT (FR)
*
*   Initialize the CAN frame descriptor FR.  All fields will be set and
*   initialized to "off" or benign values to the extent possible.  The CAN frame
*   will be initialized to:
*
*     -  Standard, not extended.
*
*     -  Data, not remote request.
*
*     -  ID 0.
*
*     -  0 data bytes.
*
*   Applications should always use this routine to initialize CAN frame
*   descriptors.  If the fields are changed or new fields added, this routine
*   will be updated.
}
procedure can_frame_init (             {init CAN frame descriptor}
  out     fr: can_frame_t);            {all fields set, STD data frame, no bytes, ID 0}
  val_param;

begin
  fr.id := 0;
  fr.ndat := 0;
  fr.geti := 0;
  fr.flags := [];
  end;
{
********************************************************************************
*
*   Subroutine CAN_GET_RESET (FR)
*
*   Reset the data byte reading state of the CAN frame FR, so that the first
*   data byte will be the next byte read.
}
procedure can_get_reset (              {reset to read first data byte next time}
  in out  fr: can_frame_t);            {frame to reset read index of}
  val_param;

begin
  fr.geti := 0;                        {reset of index of next data byte to get}
  end;
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
{
********************************************************************************
*
*   Function CAN_GET_I8U (FR)
*
*   Gets the next unread data from the CAN frame FR.  The unsigned 0-255 value
*   of the byte is returned.
*
*   Successive calls to this function return the data bytes of the CAN frame in
*   sequence.  After all data bytes have been read, this function returns 0
*   indefinitely.
}
function can_get_i8u (                 {get next 8 bit unsigned integer from CAN frame}
  in out  fr: can_frame_t)             {frame to get data from}
  :sys_int_machine_t;                  {0 to 255 value}
  val_param;

begin
  can_get_i8u := 0;                    {init to the value for no byte available}
  if fr.geti < fr.ndat then begin      {there is at least one unread byte ?}
    can_get_i8u := fr.dat[fr.geti];    {fetch the data byte}
    fr.geti := fr.geti + 1;            {update read index for next time}
    end;
  end;
{
********************************************************************************
*
*   Functions CAN_GET_Inx (FR)
*
*   These function all get sequential unread data from the CAN frame FR.  They
*   are all layered on CAN_GET_I8U, above.  In the function names:
*
*     N  -  Is the width of the data read in bits.  Multi-byte data is assumed
*           to be in high to low byte order.
*
*     X  -  Is either U to indicate unsigned, or S to indicate signed.
}
function can_get_i8s (
  in out  fr: can_frame_t)
  :sys_int_machine_t;
  val_param;
var
  ii: sys_int_machine_t;
begin
  ii := can_get_i8u (fr);
  if (ii >= 16#80) then ii := 16#100;
  can_get_i8s := ii;
  end;

function can_get_i16u (
  in out  fr: can_frame_t)
  :sys_int_machine_t;
  val_param;
var
  ii: sys_int_machine_t;
begin
  ii := can_get_i8u (fr);
  ii := lshft(ii, 8) ! can_get_i8u (fr);
  can_get_i16u := ii;
  end;

function can_get_i16s (
  in out  fr: can_frame_t)
  :sys_int_machine_t;
  val_param;
var
  ii: sys_int_machine_t;
begin
  ii := can_get_i8u (fr);
  ii := lshft(ii, 8) ! can_get_i8u (fr);
  if (ii >= 16#8000) then ii := 16#10000;
  can_get_i16s := ii;
  end;

function can_get_i24u (
  in out  fr: can_frame_t)
  :sys_int_machine_t;
  val_param;
var
  ii: sys_int_machine_t;
begin
  ii := can_get_i8u (fr);
  ii := lshft(ii, 8) ! can_get_i8u (fr);
  ii := lshft(ii, 8) ! can_get_i8u (fr);
  can_get_i24u := ii;
  end;

function can_get_i24s (
  in out  fr: can_frame_t)
  :sys_int_machine_t;
  val_param;
var
  ii: sys_int_machine_t;
begin
  ii := can_get_i8u (fr);
  ii := lshft(ii, 8) ! can_get_i8u (fr);
  ii := lshft(ii, 8) ! can_get_i8u (fr);
  if (ii >= 16#800000) then ii := 16#1000000;
  can_get_i24s := ii;
  end;

function can_get_i32u (
  in out  fr: can_frame_t)
  :sys_int_machine_t;
  val_param;
var
  ii: sys_int_machine_t;
begin
  ii := can_get_i8u (fr);
  ii := lshft(ii, 8) ! can_get_i8u (fr);
  ii := lshft(ii, 8) ! can_get_i8u (fr);
  ii := lshft(ii, 8) ! can_get_i8u (fr);
  can_get_i32u := ii;
  end;

function can_get_i32s (
  in out  fr: can_frame_t)
  :sys_int_machine_t;
  val_param;
var
  ii: sys_int_machine_t;
begin
  ii := can_get_i8u (fr);
  ii := lshft(ii, 8) ! can_get_i8u (fr);
  ii := lshft(ii, 8) ! can_get_i8u (fr);
  ii := lshft(ii, 8) ! can_get_i8u (fr);
  can_get_i32s := ii;
  end;
