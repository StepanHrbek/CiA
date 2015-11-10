{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
type
 PBuf=^TBuf;
 TBuf=
  record
   d:pointer;
   s:word;
  end;
 PSpojSez=^TSpojSez;
 TSpojSez=
  object
   root,temp:TBuf;
   count:word;
   constructor Init;
   destructor  Done; {zrusi spojovy seznam}
   function  AppendItem(var item:TBuf):boolean; {Prida polozku na konec}
   function  GetItem(n:word; var item:TBuf):boolean; {Vrati obsah n-te polozky}
   function  AddItem(n:word; item:TBuf):boolean; {Prida polozku na n-tou pozici}
   function  DeleteItem(n:word):boolean; {vymaze n-tou polozku}
   function  EditItem(n:word; item:TBuf):boolean; {Zmeni data n-te polozky}
  end; {TSpojSez}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure ZrusSpojSez(var root:TBuf);
var temp,prev:TBuf;
begin {ZrusSpojSez}
 if root.d=nil then exit;
 repeat
  temp:=root;
  prev.d:=nil;
  while pointer(memL[seg(temp.d^):ofs(temp.d^)])<>nil do
   begin
    move(temp.d^,temp,sizeof(TBuf));
    if prev.d=nil then prev:=root else move(prev.d^,prev,sizeof(TBuf));
   end;
  with temp do freemem(d,s);
  if root.d=temp.d then break;
  fillchar(prev.d^,sizeof(TBuf),0);
 until false;
 with root do
 begin
  d:=nil;
  s:=0;
 end;
end;  {ZrusSpojSez}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
constructor TSpojSez.Init;
begin {TSpojSez.Init}
 with root,temp do
 begin
  d:=nil;
  s:=0;
 end;
 count:=0;
end;  {TSpojSez.Init}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
destructor  TSpojSez.Done;
begin {TSpojSez.Done}
 ZrusSpojSez(root);
 count:=0;
end;  {TSpojSez.Done}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TSpojSez.AppendItem(var item:TBuf):boolean;
begin {TSpojSez.AppendItem}
 AppendItem:=false;
 with item do if (d=nil) or (s<sizeof(TBuf)) then exit;
 if root.d=nil then root:=item else
  begin
   temp:=root;
   while pointer(memL[seg(temp.d^):ofs(temp.d^)])<>nil do
    move(temp.d^,temp,sizeof(TBuf));
   move(item,temp.d^,sizeof(TBuf));
  end;
 fillchar(item.d^,sizeof(TBuf),0);
 inc(count);
 AppendItem:=true;
end;  {TSpojSez.AppendItem}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TSpojSez.GetItem(n:word; var item:TBuf):boolean;
var i:word;
begin {TSpojSez.GetItem}
 GetItem:=false;
 temp:=root;
 for i:=1 to n do
  if temp.d=nil then exit else move(temp.d^,temp,sizeof(TBuf));
 item:=temp;
 GetItem:=true;
end;  {TSpojSez.GetItem}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TSpojSez.AddItem(n:word; item:TBuf):boolean;
var
 i:word;
 prev:TBuf;
begin {TSpojSez.AddItem}
 AddItem:=false;
 with item do if (d=nil) or (s<sizeof(TBuf)) then exit;
 if n=0 then
  begin
   move(root,item.d^,sizeof(TBuf));
   root:=item;
   AddItem:=true;
   exit;
  end;
 temp:=root;
 prev.d:=nil;
 for i:=1 to n do
  if temp.d=nil then exit else
   begin
    move(temp.d^,temp,sizeof(TBuf));
    if prev.d=nil then prev:=root else move(prev.d^,prev,sizeof(TBuf));
   end;
 move(item,prev.d^,sizeof(TBuf));
 move(temp,item.d^,sizeof(TBuf));
 AddItem:=true;
end;  {TSpojSez.AddItem}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TSpojSez.DeleteItem(n:word):boolean;
var
 i:word;
 prev:TBuf;
begin {TSpojSez.DeleteItem}
 DeleteItem:=false;
 with root.d=nil then exit;
 {*}
 DeleteItem:=true;
end;  {TSpojSez.DeleteItem}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TSpojSez.EditItem(n:word; item:TBuf):boolean;
{Zmeni data n-te polozky. Protoze zaznam muze mit libovolnou delku, musi polozku smazat a potom znovu vytvorit.}
var
 i:word;
 prev:TBuf;
begin {TSpojSez.EditItem}
 EditItem:=false;
 with item do if (d=nil) or (s<sizeof(TBuf)) or (root.d=nil) then exit;
 if n=0 then
  begin
   prev:=root;
   move(root.d^,root,sizeof(TBuf));
   with prev do freemem(d,s);
   move(root,item.d^,sizeof(TBuf));
   root:=item;
   EditItem:=true;
   exit;
  end;
 temp:=root;
 prev.d:=nil;
 for i:=1 to n do
  if temp.d=nil then exit else
   begin
    move(temp.d^,temp,sizeof(TBuf));
    if prev.d=nil then prev:=root else move(prev.d^,prev,sizeof(TBuf));
   end;

 EditItem:=true;
end;  {TSpojSez.EditItem}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
var
 b:TBuf;
 r:TSpojSez;
 i:word;
begin {main}
 writeln(#13#10,memavail);
 r.init;
 for i:=1 to 3 do
  begin
   with b do
   begin
    s:=10;
    getmem(d,s);
    if d=nil then halt;
   end;
   r.appenditem(b);
   writeln(memavail);
  end;
 with b do
 begin
  s:=17;
  getmem(d,s);
  if d=nil then halt;
 end;
 r.edititem(0,b);
 r.done;
 writeln(memavail);
end.  {main}
