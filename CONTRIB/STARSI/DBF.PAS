{$N+,E-}
const
 dbfOpened   =$80; {externi databazovy soubor je momentalne otevren}
 dbfAssigned =$40;
 dbfError    =$01;
type
 string11=string[11];
 PathStr=string[80];
 PString=^string;
 TDBFDate=
  record
   y:array[0..3] of char;
   m:array[0..1] of char;
   d:array[0..1] of char;
  end;
 PDBFParam=^TDBFParam;
 TDBFParam=
  record
   next:PDBFParam;
   len:byte;
   decimals:byte;
   case typ:char of
   'C': (PStr:PString);
   'N': (n:double);
   'L': (l:char);
   'D': (d:TDBFDate);
   ' ': (name:string[10]); {nazev pole (btw, typ bude stejne jiny)}
  end;
 TDBFHeader=
  record
   signature:byte;
   creationYear,
   creationMonth,
   creationDay:byte;
   records:longint;
   size:word;
   recordsize:word;
   reserved:array[$0C..$1F] of char;
  end;
 PDBFHeader=^TDBFHeader;
 TDBF=
  object
  private
   status:byte;
   version:byte;      {signatura souboru}
   filename:PathStr;
   f:file;
   reccount:longint;  {pocet zaznamu}
   hdrsize:word;      {velikost hlavicky}
   recsize:word;      {velikost jednoho zaznamu v bajtech}
   position:longint;  {kolikaty zaznam to je}
   fields:PDBFParam;  {nazvy poli}
   fieldcount:word;  {jejich pocet}
   dataset:PDBFParam; {aktualni data}
   Function  OpenTheFile:boolean;
   Function  LoadData:boolean;
   Procedure SetState(flags:byte; value:boolean);
  public
   Constructor Init;
   Function  State(flags:byte):boolean;
   Function  Open(_filename:PathStr):boolean;
   Function  BOF:boolean;
   Function  EOF:boolean;
   Procedure MoveNext;
   Procedure MovePrevious;
   Procedure MoveFirst;
   Procedure MoveLast;
   Procedure MoveTo(rec:longint);
   Function  GetPosition:longint;
   Function  GetFieldCount:word;
   Function  GetField(index:integer):PDBFParam;
   Function  GetItem(index:integer):PDBFParam;
   Procedure Clear;
  end;

FUNCTION GetCore(st:string):string;
begin
 while (st>'') and (st[length(st)] in [' ',#0]) do dec(st[0]);
 while (st>'') and (st[1] in [' ',#0]) do delete(st,1,1);
 GetCore:=st;
end;

Procedure DisposeDBFParams(var param:PDBFParam; erasechars:boolean);
var hand:PDBFParam;
begin
 while param<>nil do
  begin
   hand:=param^.next;
   with param^ do
   if erasechars and (typ='C') and (length(PStr^)<>0) then
    freemem(PStr,succ(length(PStr^)));
   dispose(param);
   param:=hand;
  end;
 param:=nil;
end;

Function  DBFParamValue(param:PDBFParam):string;
var
 temp:string[20];
begin
 if param=nil then
  begin
   DBFParamValue:='';
   exit;
  end;
 with param^ do
 case typ of
 'C': if PStr=nil then DBFParamValue:='' else DBFParamValue:=PStr^;
 'N': begin
       str(n:20:8,temp);
       temp:=GetCore(temp);
       if pos('.',temp)<>0 then
        begin
         while temp[length(temp)] in ['0'] do dec(temp[0]);
         if temp[length(temp)]='.' then temp:=temp+'0';
        end;
       DBFParamValue:=temp;
      end;
 'L': if l in ['Y','T'] then DBFParamValue:='TRUE' else if l='?' then DBFParamValue:='FUZZY' else DBFParamValue:='FALSE';
 'D': DBFParamValue:=d.d[0]+d.d[1]+'.'+d.m[0]+d.m[1]+'.'+d.y[0]+d.y[1]+d.y[2]+d.y[3];
 end;
end;

Function  TDBF.State(flags:byte):boolean;
begin
 State:=status and flags<>0;
end;

Procedure TDBF.SetState(flags:byte; value:boolean);
begin
 if value
 then status:=status or flags
 else status:=status and not flags;
end;

Constructor TDBF.Init;
begin
 status:=0;
 fields:=nil;
 fieldcount:=0;
 dataset:=nil;
 position:=-1;
end;

Procedure TDBF.Clear;
begin
 SetState(dbfAssigned,false);
 DisposeDBFParams(fields,false);
 DisposeDBFParams(dataset,true);
 Init;
end;

Function  TDBF.BOF:boolean; begin BOF:=position=0; end;

Function  TDBF.EOF:boolean; begin EOF:=position=pred(reccount); end;

Function  TDBF.OpenTheFile:boolean;
begin
 OpenTheFile:=false;
 if State(dbfOpened) then exit;
 assign(f,filename);
 FileMode:=0;
 reset(f,1);
 if IOResult=0 then
  begin
   SetState(dbfOpened,true);
   OpenTheFile:=true;
  end
 else
  begin
   SetState(dbfError,true);
   SetState(dbfOpened,false);
  end;
end;

Function  TDBF.LoadData:boolean;
var
 flag:char;
 check,i:word;
 watch,tmp,top:PDBFParam;
 s:string;
begin
 LoadData:=false;
 if not State(dbfOpened) then OpenTheFile;
 repeat
  if State(dbfError) then break;
  SetState(dbfError,true);
  DisposeDBFParams(dataset,true);
  seek(f,hdrsize+position*recsize);
  blockread(f,flag,1,check);
  if check<>1 then break;
  if flag='*' then
   begin
    inc(position);
    continue;
   end
  else if flag<>' ' then break;
  watch:=fields;
  for i:=pred(fieldcount) downto 0 do
   begin
    new(tmp); if (tmp=nil) or (watch=nil) then break;
    blockread(f,s[1],watch^.len,check);
    s[0]:=chr(watch^.len); if check<>length(s) then break;
    with tmp^ do
    begin
     next:=nil;
     PStr:=nil;
     typ:=watch^.typ;
     case typ of
     'C':
      begin
       if (PStr<>nil) and (length(PStr^)<>0) then
        begin freemem(PStr,succ(length(PStr^))); PStr:=nil; end;
       while s[length(s)]=' ' do dec(s[0]);
       if s<>'' then
        begin
         getmem(PStr,succ(length(s)));
         if PStr=nil then break;
         PStr^:=s;
        end;
      end;
     'N':
      begin
       val(s,n,check);
       if check<>0 then break;
      end;
     'L':
      l:=UpCase(s[1]);
     'D':
      move(s[1],d,sizeof(d));
     end;
     if dataset=nil then dataset:=tmp else top^.next:=tmp;
     top:=tmp;
     watch:=watch^.next;
    end;
    if i=0 then SetState(dbfError,false);
   end;
 until true;
 if State(dbfOpened) then
  begin
   close(f);
   SetState(dbfOpened,false);
  end;
 LoadData:=not State(dbfError);
end;

Function  TDBF.Open(_filename:PathStr):boolean;
var
 phdr:PDBFHeader;
 tmp,top:PDBFParam;
 s:string[$12];
 check:word;
begin
 Open:=false;
 if State(dbfAssigned) then Clear;
 new(phdr); if phdr=nil then exit;
 filename:=_filename;
 if not OpenTheFile then exit;
 blockread(f,phdr^,sizeof(phdr^),check);
 if check<>sizeof(phdr^) then
  begin
   close(f);
   exit;
  end;
 with phdr^ do
 begin
  version:=signature;
  reccount:=records;
  hdrsize:=size;
  recsize:=recordsize;
  if (recsize<2) or (hdrsize<$43) or ((recsize or hdrsize) and $8000<>0) then
   begin
    SetState(dbfError,true);
    exit;
   end;
 end;
 dispose(phdr);
 seek(f,$20);
 SetState(dbfError,true);
 repeat
  s[0]:=#11;
  blockread(f,s[1],2,check);
  if check<>2 then break;
  if s[1]=#$0D then
   begin
    if pred((filepos(f))=hdrsize) and (fieldcount>0) then
     status:=status and not dbfError;
    break;
   end;
  blockread(f,s[3],$10,check);
  if check<>$10 then break;
  seek(f,filepos(f)+$0E);
  s[0]:=chr(pos(#0,s)); if s='' then break;
  dec(s[0]); inc(fieldcount);
  new(tmp); if tmp=nil then break;
  with tmp^ do
  begin
   next:=nil;
   typ:=s[12];
   len:=ord(s[17]); if succ(len)<=1 then break;
   decimals:=ord(s[18]);
   name:=s; {u fields nas ostatni polozky nezajimaji}
  end;
  if fields=nil
  then fields:=tmp
  else top^.next:=tmp;
  top:=tmp;
 until false;
 if filesize(f)<hdrsize+fieldcount*recsize+1 then
  SetState(dbfError,true)
 else
  begin
   position:=0;
   LoadData;
  end;
 if State(dbfOpened) then
  begin
   close(f);
   SetState(dbfOpened,false);
  end;
 if (IOResult=0) and not State(dbfError) then
  begin
   Open:=true;
   SetState(dbfAssigned,true);
  end;
end;

Procedure TDBF.MoveNext; begin inc(position); LoadData; end;
Procedure TDBF.MovePrevious; begin dec(position); LoadData; end;
Procedure TDBF.MoveFirst; begin position:=0; LoadData; end;
Procedure TDBF.MoveLast; begin position:=pred(reccount); LoadData; end;
Procedure TDBF.MoveTo(rec:longint); begin position:=rec; LoadData; end;
Function  TDBF.GetPosition:longint; begin GetPosition:=position; end;
Function  TDBF.GetFieldCount:word; begin GetFieldCount:=fieldcount; end;

Function  TDBF.GetField(index:integer):PDBFParam;
var result:PDBFParam;
begin
 if index>=0 then result:=fields else result:=nil;
 while (result<>nil) and (index>0) do
  begin
   result:=result^.next;
   dec(index);
  end;
 GetField:=result;
end;

Function  TDBF.GetItem(index:integer):PDBFParam;
var result:PDBFParam;
begin
 if index>=0 then result:=dataset else result:=nil;
 while (result<>nil) and (index>0) do
  begin
   result:=result^.next;
   dec(index);
  end;
 GetItem:=result;
end;

var
 d:TDBF;
 m:longint;
 i:integer;
begin
 m:=memavail; writeln(#10,m);
 with d do
 begin
  init;
  open('zbozi.dbf');
  for i:=0 to GetFieldCount-1 do
   writeln(getfield(i)^.name);
  writeln('----');
  for i:=0 to GetFieldCount-1 do
   writeln('"',DBFParamValue(getitem(i)),'"');
  clear;
 end;
 writeln('rozdil v pameti: ',memavail-m);
end.