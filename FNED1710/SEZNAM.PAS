const
 MaxBufferSize=$FFF0;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
type
 PBuf=^TBuf;
 TBuf=
  record
   d:pointer; {ukazatel na dalsi buffer: prvnich sizeof(TBuf) bytu je}
   s:word;
  end;
{Objekt TPolySeznam obsahuje ukazatel na obecny spojovy seznam, ktery muze
 byt libovolne dlouhy (maximalni delka 65535 polozek), jeho polozky mohou mit
 ruznou, delku (maximalne vsak 6553). Objekt TPolySeznam obsahuje metody, kter‚ s t¡mto
 seznamem zach zej¡.}
 PPolySeznam=^TPolySeznam;
 TPolySeznam=
  object
   root,temp:TBuf; {ukazatel na koren spojov‚ho seznamu a pomocn  promenn }
   count:longint; {d‚lka seznamu}
   constructor Init;
   destructor  Done; {zrus¡ spojovy seznam}
   function  AppendItem(var item:TBuf):boolean; {prida polozku na konec}
   function  GetItem(n:longint; var item:TBuf):boolean; {vrati obsah n-te polozky}
   function  AddItem(n:longint; item:TBuf):boolean; {prida polozku na n-tou pozici}
   function  ReplaceItem(n:longint; item:TBuf):boolean; {zmeni data n-te polozky}
   function  DeleteItem(n:longint):boolean; {vymaze n-tou polozku}
  end;  {TPolySeznam}
{Objekt TSimpleSeznam je potomkem objektu TPolySeznam. Lisi se v tom, ze
 polozky maji konstantni velikost (kterou si muze uzivatel urcit) pri inicializaci}
 TSimpleSeznam=
  object(TPolySeznam)
   itemsize:word; {pevn  d‚lka polozky}
   constructor Init(_itemsize:word);
   destructor  Done; {zrus¡ spojovy seznam}
   function  AppendItem(var item:pointer):boolean; {prida polozku na konec}
   function  GetItem(n:word; var item:pointer):boolean; {vrati obsah n-te polozky}
   function  AddItem(n:word; item:pointer):boolean; {prida polozku na n-tou pozici}
   function  ReplaceItem(n:word; item:pointer):boolean; {zmeni data n-te polozky}
   function  DeleteItem(n:word):boolean; {vymaze n-tou polozku}
  end;  {TSimpleSeznam}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure ZrusPolySeznam(var root:TBuf);
{Zrusi obecny polymorfni spojovy seznam, na ktery ukazuje promenna root.
 Podminkou je, aby root mel strukturu tohoto typu seznamu.}
var temp,prev:TBuf;
begin {ZrusPolySeznam}
 if root.d=nil then exit;
 repeat
  temp:=root;
  prev.d:=nil;
  while pointer(temp.d^)<>nil do
   begin
    move(temp.d^,temp,sizeof(TBuf));
    if prev.d=nil then prev:=root else prev.d:=pointer(prev.d^);
   end;
  with temp do freemem(d,s);
  if root.d=temp.d then break;
  pointer(prev.d^):=nil; memW[seg(prev.d^):ofs(prev.d^)+2]:=0;
 until false;
 with root do
 begin
  d:=nil;
  s:=0;
 end;
end;  {ZrusPolySeznam}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure ZrusSimpleSeznam(var root:pointer; itemsize:word);
{Zrusi monomorfni spojovy seznam s konstantni sirkou zaznamu, na ktery ukazuje
 promenna root. Podminkou je, aby root mel strukturu tohoto typu seznamu.}
var temp,prev:pointer;
begin {ZrusSimpleSeznam}
 if root=nil then exit;
 repeat
  temp:=root;
  prev:=nil;
  while pointer(temp^)<>nil do
   begin
    temp:=pointer(temp^);
    if prev=nil then prev:=root else prev:=pointer(prev^);
   end;
  freemem(temp,itemsize);
  if root=temp then break;
  pointer(prev^):=nil;
 until false;
 root:=nil;
end;  {ZrusSimpleSeznam}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function DelkaSeznamu(root:pointer):longint;
{Vrati pocet polozek obecneho polymorfniho i monomorfniho spojoveho seznamu.}
var
 n:word;
 temp:pointer;
begin {DelkaSeznamu}
 n:=0;
 while (root<>nil) and (n<$FFFF) do
  begin
   root:=pointer(root^);
   inc(n);
  end;
 DelkaSeznamu:=n;
end;  {DelkaSeznamu}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
constructor TPolySeznam.Init;
begin {TPolySeznam.Init}
 with root,temp do
 begin
  d:=nil;
  s:=0;
 end;
 count:=0;
end;  {TPolySeznam.Init}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
destructor  TPolySeznam.Done;
begin {TPolySeznam.Done}
 ZrusPolySeznam(root);
 count:=0;
end;  {TPolySeznam.Done}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TPolySeznam.AppendItem(var item:TBuf):boolean;
{Prida polozku na konec spojoveho seznamu. Vraci uspesnost teto operace.}
begin {TPolySeznam.AppendItem}
 AppendItem:=false;
 with item do if (d=nil) or (s<sizeof(TBuf)) then exit;
 if root.d=nil then root:=item else
  begin
   temp:=root;
   while pointer(memL[seg(temp.d^):ofs(temp.d^)])<>nil do
    move(temp.d^,temp,sizeof(TBuf));
   move(item,temp.d^,sizeof(TBuf));
  end;
 pointer(item.d^):=nil; memW[seg(item.d^):ofs(item.d^)+sizeof(pointer)]:=0;
 inc(count);
 AppendItem:=true;
end;  {TPolySeznam.AppendItem}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TPolySeznam.GetItem(n:longint; var item:TBuf):boolean;
{Naplni promennou item n-tou polozkou seznamu. Vraci uspesnost teto operace.}
var i:longint;
begin {TPolySeznam.GetItem}
 GetItem:=false;
 temp:=root;
 for i:=1 to n do
  if temp.d=nil then exit else move(temp.d^,temp,sizeof(TBuf));
 item:=temp;
 GetItem:=true;
end;  {TPolySeznam.GetItem}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TPolySeznam.AddItem(n:longint; item:TBuf):boolean;
{Vlozi (ale neprepise) polozku item na n-tou pozici spojoveho seznamu.}
var
 i:longint;
 prev:TBuf;
begin {TPolySeznam.AddItem}
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
end;  {TPolySeznam.AddItem}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TPolySeznam.DeleteItem(n:longint):boolean;
{Vymaze n-tou polozku. Vraci uspesnost teto operace.}
var
 prev:TBuf;
 i:longint;
begin {TPolySeznam.DeleteItem}
 DeleteItem:=false;
 if n=0 then
  if root.d<>nil then
   begin
    move(root.d^,temp,sizeof(TBuf));
    with root do freemem(d,s);
    root:=temp;
    DeleteItem:=true;
    exit;
   end
  else exit;
 temp:=root;
 prev.d:=nil;
 for i:=1 to n do
  if temp.d=nil then exit else
   begin
    move(temp.d^,temp,sizeof(TBuf));
    if prev.d=nil then prev:=root else move(prev.d^,prev,sizeof(TBuf));
   end;
 if temp.d=nil then exit;
 move(temp.d^,prev.d^,sizeof(TBuf));
 with temp do freemem(d,s);
 dec(count);
 DeleteItem:=true;
end;  {TPolySeznam.DeleteItem}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TPolySeznam.ReplaceItem(n:longint; item:TBuf):boolean;
{Zmeni obsah n-te polozky (starou polozku uvolni z pameti a na seznam
 napoji novou polozku - item). Vraci uspesnost teto operace.}
var
 prev:TBuf;
 i:longint;
begin {TPolySeznam.ReplaceItem}
 ReplaceItem:=false;
 if n=0 then
  if root.d<>nil then
   begin
    move(root.d^,temp,sizeof(TBuf));
    with root do freemem(d,s);
    root:=item;
    move(temp,item.d^,sizeof(TBuf));
    ReplaceItem:=true;
    exit;
   end
  else exit;
 temp:=root;
 prev.d:=nil;
 for i:=1 to n do
  if temp.d=nil then exit else
   begin
    move(temp.d^,temp,sizeof(TBuf));
    if prev.d=nil then prev:=root else move(prev.d^,prev,sizeof(TBuf));
   end;
 if temp.d=nil then exit;
 move(temp.d^,prev.d^,sizeof(TBuf));
 with temp do freemem(d,s);
 temp:=item;
 move(prev.d^,item.d^,sizeof(TBuf));
 move(item,prev.d^,sizeof(TBuf));
 ReplaceItem:=true;
end;  {TPolySeznam.ReplaceItem}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}

constructor TSimpleSeznam.Init(_itemsize:word);
begin {TSimpleSeznam.Init}
 if _itemsize<sizeof(pointer) then fail;
 inherited Init;
 itemsize:=_itemsize;
end;  {TSimpleSeznam.Init}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
destructor TSimpleSeznam.Done;
begin {TSimpleSeznam.Done}
 ZrusSimpleSeznam(root.d,itemsize);
end;  {TSimpleSeznam.Done}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TSimpleSeznam.AppendItem(var item:pointer):boolean; {Prida polozku na konec}
begin {TSimpleSeznam.AppendItem}
 AppendItem:=false;
 if item=nil then exit;
 temp:=root;
 if root.d=nil then
  root.d:=item
 else
  begin
   while pointer(temp.d^)<>nil do move(temp.d^,temp,sizeof(pointer));
   pointer(temp.d^):=item;
  end;
 pointer(item^):=nil;
 inc(count);
 AppendItem:=true;
end;  {TSimpleSeznam.AppendItem}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TSimpleSeznam.GetItem(n:word; var item:pointer):boolean; {Vrati obsah n-te polozky}
var i:longint;
begin {TSimpleSeznam.GetdItem}
 GetItem:=false;
 GetItem:=true;
end;  {TSimpleSeznam.GetdItem}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TSimpleSeznam.AddItem(n:word; item:pointer):boolean; {Prida polozku na n-tou pozici}
begin {TSimpleSeznam.AddItem}
 AddItem:=false;
 AddItem:=true;
end;  {TSimpleSeznam.AddItem}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TSimpleSeznam.ReplaceItem(n:word; item:pointer):boolean; {Zmeni data n-te polozky}
begin {TSimpleSeznam.ReplaceItem}
 ReplaceItem:=false;
 ReplaceItem:=true;
end;  {TSimpleSeznam.ReplaceItem}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TSimpleSeznam.DeleteItem(n:word):boolean; {vymaze n-tou polozku}
begin {TSimpleSeznam.AppendItem}
 DeleteItem:=false;
 DeleteItem:=true;
end;  {TSimpleSeznam.AppendItem}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
var
 b:TBuf;
 r:TSimpleSeznam;
 i:word;
begin
 writeln(#13#10,memavail);
 with r do
 begin
  if not init(10) then halt;
  for i:=0 to 2 do
   begin
    with b do
    begin
     s:=itemsize;
     getmem(d,s);
     if d=nil then halt;
    end;
    appenditem(b.d);
    writeln(memavail);
   end;
  with b do
  begin
   s:=itemsize;
   getmem(d,s);
   if d=nil then halt;
  end;
  ReplaceItem(1,b.d);
  done;
 end;
 writeln(memavail);
end.

_2_DO:

- Hodila by se funkce, ktera by za parametr pozadovala pointer na
  polozku a zaroven by byla typu pointer na polozku. Slo by pak
  vytvaret x polozek jednim (byt slozitejsim) prikazem.
