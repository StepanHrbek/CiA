{⁄ƒƒƒC.I.A.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒverze 0.10ƒƒƒø
 ≥S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi≥
 ≥v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.≥
 ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ}

Unit      Fajly;
Interface {$i define.inc}
Uses      Chyby,Memo, Dos, Stringy,Sys;
Function  Init:word;
Procedure Done;

{
 Pozn: Tato unita ma par nedodelanych mist.
}

Var       ReadOnlyMod:boolean;{readonly rezim, potlaceni zapisu na disk}

{disky}
FUNCTION  VratInstalovaneDisky: string;
FUNCTION  VratPocetDisku: byte;
FUNCTION  IdentifikujDisk(dsk:char): byte;
FUNCTION  ZapisovatelnyDisk(dsk:char): boolean;
FUNCTION  JeReady(dsk: char) : boolean;

{adresare}
FUNCTION  GetOnlyDir(path:PathStr):DirStr;
FUNCTION  GetExeDir               :DirStr;
FUNCTION  GetCurDir               :DirStr;
FUNCTION  GetTempDir              :DirStr;

{PCK}
FUNCTION  PCK_Init(name:PathStr): boolean;
PROCEDURE PCK_Close;
PROCEDURE PCK_Open(var f:file;name:PathStr);

{ostatni}
Type      FileStr=string[13]; {13.znak kvuli pripadnemu pouziti Str2Pc}
          TLoadFileRes=(none,part,full);
          TLoadFile=function(filename:pathStr;var p:pointer;onlyfull:boolean;
                             var maxsize:longint;freesize:longint):TLoadFileRes;
Var       LoadFile:TLoadFile;

FUNCTION  CallCommand(st:string):integer;
FUNCTION  LoadDosFile(filename:pathStr;var p:pointer;onlyfull:boolean;var maxsize:longint;freesize:longint):TLoadFileRes;
FUNCTION  SaveFile(filename:pathStr;p:pointer;size:longint):boolean;


{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
                          IMPLEMENTATION
{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}


{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹ DISKY ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}


{---------------------------------------------------------------------------
 Vrati vsechny instalovane disky ve stringu jako napr. ABCD.
 ---------------------------------------------------------------------------}
FUNCTION  VratInstalovaneDisky;
var disky:string;
begin
 asm
  mov ah, 19h;int 21h;push ax { v AL soucasny disk }
  push ss;pop es;lea di, disky;push di;inc di
  mov cx, 27 { Projede se od A az po Z }
  xor dx,dx
  @1: mov ah, 0eh;int 21h; { CD disk v DL }
      {aktualni disk =}mov ah, 19h;int 21h;cmp al,dl;jne @konec{kdyz neni stejny}
      mov al, dl;add al,65;stosb;inc dl;loop @1
  @konec: pop di;mov al,dl;stosb; {nakonec delka stringu}
	  pop ax;mov ah, 0eh;mov dl, al;int 21h {a cd na puvodni disk}
 end;
 VratInstalovaneDisky:=disky;
end;

{---------------------------------------------------------------------------
 Vrati pocet vsech disku.
 ---------------------------------------------------------------------------}
FUNCTION  VratPocetDisku;
begin
 VratPocetDisku:=length(VratInstalovaneDisky);
end;

{---------------------------------------------------------------------------
 Identifikuje zadany disk a vrati:
 0 - Neznamy/Neexistuje
 1 - Disketa
 2 - Hard disk
 3 - Sitovy
 4 - CD-ROM              {* nefunguje
 ---------------------------------------------------------------------------}
FUNCTION  IdentifikujDisk;
var r:registers; {obcas kaslu na asm}
begin
 IdentifikujDisk:=0;
 r.AX:=$1500;r.BX:=0;Intr($2f,r);	{ nejdriv test na cd-rom }
 if (r.BX<>0) and (r.CX=Ord(Dsk)-65) then begin IdentifikujDisk:=4;exit;end;
 Dsk:=UpCase(Dsk);R.BL:=Ord(Dsk)-64;R.AX:=$4409;MsDos(R);
 if (R.Flags and FCarry)=FCarry then Exit; { kdyz chyba tak pryc }
 if (R.DH and 16)=16 then {sitovej} IdentifikujDisk:=3 else begin
   R.AX:=$4408;MsDos(R);if R.AL<>$0F then IdentifikujDisk:=R.AL+1;
 end;
end;

{---------------------------------------------------------------------------
 Vraci jestli jde na disk zapisovat.
 Neznate nejakou lepsi detekci ?
 ---------------------------------------------------------------------------}
FUNCTION  ZapisovatelnyDisk(dsk:char): boolean;
var   st:string[20];
      i:word;
begin
 ZapisovatelnyDisk:=false;
 if IdentifikujDisk(dsk) in [1,2,3] then begin
   st:=dsk+':\'#0;
   i:=ofs(st[1]);
   asm
    PUSH DS
    push ss
    pop ds
    {create file}
    mov ah,5ah;mov cx,0;mov dx,i;int 21h;jc @err
    {close file}
    mov bx,ax;mov ah,3eh;int 21h;jc @err
    {delete file}
    mov ah,41h;int 21h;jc @err
    {wow, ok}
    mov @result,1
    @err:
    POP DS
   end;
 end;
end;

{---------------------------------------------------------------------------
 Prekontroluje disk a vrati true/false.
 ---------------------------------------------------------------------------}
FUNCTION  JeReady;
var disk:byte;dummy:string[20];
begin
 { Nic chytrejsiho me nenapadlo, jak otestovat pripravenost u jakehokoliv
   media, nez precist aktualni adresar, mozna to jde sikovneji ...}

 JeReady:=false;
 if IdentifikujDisk(dsk) = 0 then Exit;
 disk:=ord(upcase(dsk))-64;
 asm
  mov ah,47h;mov dl,disk;push ds;push ss;pop ds;lea si,dummy;int 21h;pop ds;
  jc @konec;mov @result,1
  @konec:
 end;
end;






{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹ ADRESARE ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}

{---------------------------------------------------------------------------
 Ze zadane cesty k souboru vraci pouze disk+adresar.
 Vysledek je vzdy velkymi pismeny, expandovany a zakonceny lomitkem.
 ---------------------------------------------------------------------------}
FUNCTION GetOnlyDir(path:PathStr):DirStr;
var   dir:DirStr;
      name:NameStr;
      ext:ExtStr;
begin
 fSplit(path,dir,name,ext);
 GetOnlyDir:=fExpand(dir);
end;

{---------------------------------------------------------------------------
 Vraci adresar ve kterem je spusteny exe soubor.
 Vysledek je vzdy velkymi pismeny, expandovany a zakonceny lomitkem.
 ---------------------------------------------------------------------------}
FUNCTION GetExeDir:DirStr;
begin
 GetExeDir:=GetOnlyDir(paramstr(0));
end;

{---------------------------------------------------------------------------
 Vraci bezny adresar.
 Vysledek je vzdy velkymi pismeny, expandovany a zakonceny lomitkem.
 ---------------------------------------------------------------------------}
FUNCTION GetCurDir:DirStr;
var   st:DirStr;
begin
 GetDir(0,st);
 GetCurDir:=st+'\';
end;

{---------------------------------------------------------------------------
 Vraci pracovni adresar.
 Vysledek je vzdy velkymi pismeny, expandovany a zakonceny lomitkem.
 ---------------------------------------------------------------------------}
FUNCTION GetTempDir:DirStr;
var   st:PathStr;
begin
 st:=fExpand(GetEnv('temp'));
 if st='' then begin
   st:=VratInstalovaneDisky;
   {*sem nejaky chytry prioritni nalezeni nejlepsiho disku}
   {*vytvoreni adresare temp}
   st:='C:\';
   end;
 if st[length(st)]<>'\' then st:=st+'\';
 GetTempDir:=st;
end;





{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹ PCK ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}


{ Nasledujou procedury pro praci s PCK souborem. Moc jsem to neupravoval,
  je to pres clipboard z diskmag.pas :), akorat jsem misto UpStr, dal
  UpCased, aby to slo uz na stringy.

  Neni tady nic, cim by se dal pck vytvorit. Ja to delal vesmes pres
  copy /b apod. Chtelo by to nejakou proceduru PCK_Create. }

const MaxIndex  = 1024;		{ Maximalni pocet fajlu v jednom PCK }
type
      Index      = record	{ Jeden index v zahlavi }
           Name  : ^String;	{ Jmeno fajlu }
           Start : Longint;	{ Startovni pozice v PCK }
           Size  : Longint;	{ Velikost }
      end;
      ListP      = Array[0..MaxIndex] of Index;	{ Seznam indexu }

var   Pocetfajlu : Word;
      List       : ^ListP;

      PCK_F      : File;

{---------------------------------------------------------------------------
 Vrati cislo indexu v seznamu.
 ---------------------------------------------------------------------------}
function GetIndex(Name:String):Word;
var I:Word;
begin;
  if (List=NIL) or (List^[0].Size=MaxIndex) then begin GetIndex:=0;exit;end;
  Name:=UpCased(Name);
  i:=1;
  while (i<=pocetfajlu) and (List^[i].Name^<>Name) do Inc(i);
  if List^[i].Name^=Name then GetIndex:=i else GetIndex:=0;
end;

{---------------------------------------------------------------------------
 Otevre fajl v PCK -> Naseekuje na jeho startovni pozici. Cist se muze uz
 normalne pres blockread.
 ---------------------------------------------------------------------------}
procedure PCK_Open(var f:File;Name:PathStr);
var I:Word;
begin;
  I:=GetIndex(Name);
  if i>0 then begin move(PCK_F,f,sizeof(f)); Seek(f,List^[i].Start); end;
end;

{---------------------------------------------------------------------------
 Otevre PCK soubor a pripravi fajllist.
 ---------------------------------------------------------------------------}
function PCK_Init(Name:PathStr):boolean;
var I,J:longint;s:string;
begin;
  Assign(PCK_F,Name);{I-}Reset(PCK_F,1);{I+}
{*Hej Erixone, ja nechci $I+ :). Neda se to nejak globalne vyresit ?
 Myslim tim fajlsystem, kterej by se o vsechno staral, misto open,close..
 by se volaly funkce toho fajlsystemu a mimo jine by tim sly otvirat
 i soubory v PCK nebo v necem jinym (nebyl by zadnej rozdil mezi fajlem
 v PCK a mimo).}
  if (IOResult<>0) or (List<>NIL) then begin PCK_Init:=False;exit;end;
  BlockRead(PCK_F,pocetfajlu,2);
  if pocetfajlu>=MaxIndex then pocetfajlu:=MaxIndex-1;
  GetMem(pointer(List),(Pocetfajlu+1)*SizeOf(Index));
  List^[0].Size:=pocetfajlu;
  for i:=1 to pocetfajlu do begin
    BlockRead(PCK_F,s[0],1);BlockRead(PCK_F,s[1],Ord(s[0]));
    GetMem(pointer(List^[i].Name),length(s)+1);
    List^[i].Name^:=UpCased(s);			{ jde to na stringy :) }
    BlockRead(PCK_F,List^[i].Start,4);BlockRead(PCK_F,List^[i].Size,4);
  end;
end;

{---------------------------------------------------------------------------
 Zavre PCK, uvolni pamet.
 ---------------------------------------------------------------------------}
procedure PCK_Close;
var I:Word;
begin;
  if PocetFajlu > 0 then begin
    for i:=1 to PocetFajlu do FreeMem(pointer(List^[i].Name),length(List^[i].Name^)+1);
    FreeMem(pointer(List),(PocetFajlu+1)*SizeOf(Index));
    List:=NIL;
    System.Close(PCK_F);
  end;
  PocetFajlu:=0;
end;





{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹ OSTATNI ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}



{---------------------------------------------------------------------------
 Vola command.com se zadanym parametrem.
 Vraci uspesnost (doserror).
 ---------------------------------------------------------------------------}
FUNCTION CallCommand(st:string):integer;
begin
 swapvectors;
 exec(getenv('comspec'),st);
 CallCommand:=doserror;
 swapvectors;
end;


{$i loadfile.inc}

FUNCTION  SaveFile(filename:pathStr;p:pointer;size:longint):boolean;
var   f:file;
      towrite,written:word;
label clos;
begin
 SaveFile:=false;
 assign(f,filename);
 rewrite(f,1);
 if ioresult<>0 then exit;
 while size>0 do begin
   if size>65535 then towrite:=32768 else towrite:=size;
   blockwrite(f,p^,towrite,written);
   if (ioresult<>0) or (towrite<>written) then goto clos;
   dec(size,towrite);
   if size>0 then
    if PtrRec(p).Ofs=0 then PtrRec(p).Ofs:=32768
                       else p:=ptr(PtrRec(p).Seg+SelectorInc,0);
   end;
 SaveFile:=true;
 clos:
 close(f);
end;


{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

const
 inited:boolean=false;

function Init:word;
 begin
  Init:=erOk;
  if not inited then begin
   ReadOnlyMod  :=false;
   Pocetfajlu   :=0;
   List         :=nil;
   LoadFile     :=LoadDosFile;
   inited       :=true;
   end;
 end;

procedure Done;
 begin
  if inited then begin
   inited       :=false;
   end;
 end;

{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.