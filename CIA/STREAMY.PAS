{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      Streamy;
Interface {$i define.inc}
Uses      Objects;

{
 Zde by se postupne mohly objevovat dalsi uzitecne streamy.

 Pro zacatek tu mame abstraktni FilterStream a
 jeho potomka XlatStream prekladajiciho zadane znaky na jine znaky
 (uplatneni napr. pri konverzich znakovych sad).
}

Type
 PFilterStream=^TFilterStream;
 TFilterStream=object(TStream)
    base        :PStream;
    constructor Init(a:PStream);
    procedure   Flush; virtual;
    function    GetPos: Longint; virtual;
    function    GetSize: Longint; virtual;
    procedure   Read(var Buf; Count: Word); virtual;
    procedure   Seek(Pos: Longint); virtual;
    procedure   Truncate; virtual;
    procedure   Write(var Buf; Count: Word); virtual;
    destructor  Done; virtual;
 end;

 PXlatStream=^TXlatStream;
 TXlatStream=object(TFilterStream)
    src         :string;
    dest        :string;
    constructor Init(a:PStream;asrc,adest:string);
    procedure   Read(var Buf; Count: Word); virtual;
    procedure   Write(var Buf; Count: Word); virtual;
 end;

Implementation

Constructor TFilterStream.Init(a:PStream);            begin if a=nil then Fail else base:=a;end;
Procedure   TFilterStream.Flush;                      begin base^.Flush;end;
Function    TFilterStream.GetPos: Longint;            begin GetPos:=base^.GetPos;end;
Function    TFilterStream.GetSize: Longint;           begin GetSize:=base^.GetSize;end;
Procedure   TFilterStream.Read(var Buf; Count: Word); begin base^.Read(buf,count);end;
Procedure   TFilterStream.Seek(Pos: Longint);         begin base^.Seek(pos);end;
Procedure   TFilterStream.Truncate;                   begin base^.Truncate;end;
Procedure   TFilterStream.Write(var Buf; Count: Word);begin base^.Write(buf,count);end;
Destructor  TFilterStream.Done;                       begin base^.Free;end;

Constructor TXlatStream.Init(a:PStream;asrc,adest:string);
begin
 inherited Init(a);
 src:=asrc;
 dest:=adest;
end;

Procedure   TXlatStream.Read(var Buf; Count: Word);
var   i,j:word;
begin
 inherited Read(buf,count);
 for i:=ofs(buf) to ofs(buf)+count-1 do begin
   j:=pos(pchar(ptr(seg(buf),i))^,src);
   if j>0 then pchar(ptr(seg(buf),i))^:=dest[j];
   end;
end;

Procedure   TXlatStream.Write(var Buf; Count: Word);
var   i,j:word;
begin
 for i:=ofs(buf) to ofs(buf)+count-1 do begin
   j:=pos(pchar(ptr(seg(buf),i))^,src);
   if j>0 then pchar(ptr(seg(buf),i))^:=dest[j];
   end;
 inherited Write(buf,count);
end;

End.