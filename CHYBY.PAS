{⁄ƒƒƒC.I.A.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒverze 2.00ƒƒƒø
 ≥S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi≥
 ≥v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.≥
 ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ}

Unit      Chyby;
Interface {$i define.inc}
Uses      Objects,Dos;
{$i lang-.inc}
Function  Init:TError;
Procedure Done;

{
---------------------------------------------------------------------------
                          Uvod k chybam
---------------------------------------------------------------------------

Chyby muzeme tak nejak od oka delit na fatalni a nefatalni.
Ty nefatalni staci ohlasit a program muze pokracovat.
Nefatalni chyby se hlasi zasadne volanim procedury ReportErr(string).
To je ve skutecnosti pointer na proceduru, takze si muzes nastavit
vlastni hlasic chyb.
Implicitne se v initu chyby.pas nastavi ReportErr:=erWrite
a o chvili pozdeji v initu dialogy.pas ReportErr:=erDialog.
Diky tomu se chybove hlasky objevuji vetsinou v okne, jinak
na standardnim vystupu.

Dojde-li k fatalni chybe, bylo by dobre pred ukoncenim programu jeste
odalokovat pamet, zastavit procesy atd. Nejlepsi zpusob jak toho dosahnout
je pouzit ExitProc (viz borlandi help k ExitProc).

Je nekolik zpusobu jak ukoncit program.

 - prikaz Halt nebo Halt(N)
 - runtime error N, generuje Halt(N)
 - stisk klavesy Break, generuje Halt(255)
 - normalni prubeh celym programem, generuje Halt(ExitCode) (obvykle 0)

Co se v takove chvili deje? Zavola se retez procedur ExitProc.
Retez obsahuje volani UserDone procedur jednotlivych unit.
Poslednim prvkem je standardni pascalska hlaska Runtime Error N,
ale jelikoz kazdy clanek retezu muze zmenit kod chyby, k poslednimu
clanku uz dojde kod 0 a Runtime Error hlasen nebude.

Tohle by melo teoreticky stacit pro kvalitni obsluhu chybovych situaci,
ale praxe ukazuje neco jineho. Mezi prikazem Halt(N) a ohlasenim chyby
na obrazovce musi byt provedeny vsechny clanky ExitProc az k tomu,
ktery ma pravo treba prepnout do textmodu a neco natriskat na obrazovku.
Za tu dobu muze dojit k dalsim chybam a puvodni chyba zustane neohlasena.
Proto je tu i jiny zpusob hlaseni, proceduru erMsg(string).
Ta vypise chybovou hlasku okamzite a az pote vola ExitProc.
Ma to ale jeden nedostatek. K bezpecnemu vypsani hlasky je nutno prepnout
do textmodu, coz vetsinou nevadi, ale nekdy to muze vest az ke zhrouceni
pocitace. Konkretne v pripade, kdy hardwarovy interrupt nebo jine okolnosti
vyvolaji tvoji rutinu, ktera dosud nevi, ze bylo prepnuto do textmodu.
V CiA obsazene handlery klavesnice i mysi jsou zcela bezpecne, nebezpecny
ale je handler timeru z unity Timer. Je naprosto nutne ho pred prepnutim
do textmodu vypnout. K provedeni takovych nezbytnych akci slouzi retez
procedur ShutDownInts, ktery je volan pred prepnutim do textmodu.

Posledni clanek ShutDownInts prepne do textmodu a vypise chybovou hlasku.
Teprve potom normalne probiha ExitProc. Jsou tu tedy dva nezavisle retezy,
v kazde unite se muzes rozhodnout co das do prvniho, co do druheho.

Zvlastni pripad je jeste ukoncovani programu z interrupt handleru.
Zde v CiA k tomu muze dojit pouze v unite scrol, ktera se vesi na timer.
Pri volani handleru je nastaven jiny stack a nejblizsi stack check
skonci chybou (runtime error 202).

P.S. ShutDownInts ma i jiny ucel. Mohlo by se stat, ze dojde k runtime erroru
v handleru timeru. Jeste nez ho obsluha chyby odpoji se zavola znova a dojde
k dalsimu runtime erroru. Proto by mely byt ShutDownInts volany minimalne
v nejsvrchnejsim clanku ExitProc, ale nic se nestane kdyz budou ve vsech.
Tak to je i v CiA (vola se ze vsech clanku, ale samozrejme jen poprve
k necemu dojde, podruhe uz je retez ShutDownInts vyprazdneny). Ovsem pokud si
pridas dalsi clanek ExitProc, nezapomen v nem volat a vyprazdnit ShutDownInts.

Pro snazsi hlaseni chybovych situaci zavadi unita chyby tuto nadstavbu:
 - erMsg(String)       vypise string a skonci
 - erBetaMsg(String)   totez jen pro betaverzi
 - erCheck(N)          pro N<>erOk udela Halt(N)
 - erDumb(N)           pro N<>erOK a not dumb udela Halt(N)

Zakladem jsou Halt(N) a erMsg(string), ostatni jsou specialni pripady jejich
volani.

Pri vypnutem autodone nejsou chyby nijak hlidany, runtime error skonci stejnou
hlaskou, halt program okamzite ukonci.


---------------------------------------------------------------------------
 BETAVERZE:
---------------------------------------------------------------------------

Chybove hlasky betaverze (objevuji se pri kompilaci unit s definem beta)
obsahuji bud misto chyby (nazev procedury, cislo) nebo strucny popis chyby.
Program, ktery v betaverzi funguje, by mel bez define beta fungovat
naprosto stejne, pouze rychleji.
}


Type  TReporter   =procedure(st:string);{procedura ktera ohlasi chybu
                                         a necha program pokracovat}

Var   language    :ExtStr;   {jazyk ve kterem komunikujeme s uzivatelem}
      _           :function(code:TError):string;
                             {funkce, ktera vraci hlasky v tom jazyce}

      debug       :boolean;  {debugovaci rezim: vypis ruznych hlasek za behu}
      SafeMode    :boolean;  {nouzovy bezpecny mod (scrol:movsd+notimer,mys:nohandler)}
      dumb        :boolean;  {strategie zpracovani nefatalnich chyb:
                              if Dumb then zkus_chybu_nejak_ututlat
                              else haltni_to_a_vyhod_errormsg;}
      ShutDownInts:procedure;{procedura volana pri nahlem ukonceni programu,
                              urcena pro zastaveni aktivit, ktere by mohly
                              po prepnuti do textmodu zpusobit skody}
      errorLevel  :byte;     {kod ktery program po skonceni vrati systemu}
      lastMsg     :string[100];{posledni hlaska, ktera se vypise pred koncem programu}

      ReportErr   :TReporter;{tvuj hlasic nefatalnich chyb}
      outhandle   :word;     {handle souboru do ktereho pisou BiosWrite*, implicitne 1 (stdout)}
      paramUsed   :array[1..40] of boolean;{byl uz tolikaty parametr nekym pouzit/zpracovan?}


PROCEDURE BiosWrite(st:string);
PROCEDURE BiosWriteln(st:string);

PROCEDURE Halt(code:TError);

PROCEDURE erMsg(st:string);
PROCEDURE erWrite(st:string);
PROCEDURE erWriteAndWait(st:string);
PROCEDURE erIgnore(st:string);

PROCEDURE erCheck(n:TError);
FUNCTION  erDumb(n:TError):TError;
{$ifdef beta}
PROCEDURE erBetaMsg(st:string);
{$endif}
FUNCTION  GetCmdlineLanguage:ExtStr;

FUNCTION  _i(code:TError;param1:PathStr):string;
FUNCTION  _2(code:TError;param1,param2:PathStr):string;
FUNCTION  _3(code:TError;param1,param2,param3:PathStr):string;


{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
                          IMPLEMENTATION
{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}

{---------------------------------------------------------------------------
 Nekolik kousku zkopirovanych z jinych unit za ucelem snizeni poctu uses.
 ---------------------------------------------------------------------------}
Type      string8=string[8];
          string11=string[11];
FUNCTION  Stri(num:longint):string11;
var st:string11;
begin
 str(num,st);
 stri:=st;
end;
FUNCTION Hexed(d:longint):string8; assembler;
asm
 push es
 les  di,@result
 mov  si,di
 inc  di
 xor  bx,bx   {bl=delka vysledneho stringu}
 mov  al,byte ptr d+3
 call @hex
 mov  al,byte ptr d+2
 call @hex
 mov  al,byte ptr d+1
 call @hex
 mov  al,byte ptr d
 call @hex
 jmp  @end
@hex:
 mov  ah,al
 shr  ah,4
 test bh,1    {bh=either("narazili jsme na 1. nenulovy hex (zleva)",1,0)}
 jnz  @hex0
 or   ax,ax
 jz   @hexdone
 or   bh,1
 or   ah,ah
 jz   @nextnibble
@hex0:
 cmp  ah,9
 jbe  @hex1
 add  ah,'A'-'0'-0Ah
@hex1:
 add  ah,'0'
 mov  es:[di],ah
 inc  di
 inc  bl
@nextnibble:
 and  al,0Fh
 or   ax,ax
 jz   @hexdone
 cmp  al,9
 jbe  @hex2
 add  al,'A'-'0'-0Ah
@hex2:
 add  al,'0'
 stosb
 inc  bl
@hexdone:
 retn
@end:
 mov  es:[si],bl
 pop  es
end;
Type  PtrRec    = record
                   Ofs, Seg: Word;
                  end;
PROCEDURE WaitKey; inline($b8/$0c08/$cd/$21);{mov ax,0c08h;int 21h}


{---------------------------------------------------------------------------
 Vlastni Write a Writeln.
 ---------------------------------------------------------------------------}
{
 Stary poctivy BiosWrite jsem nahradil novym BiosWritem, ktery
 ve skutecnosti pise do standardniho vystupu, stejne jako obycejny Write,
 ale na rozdil od nej neni bufferovany a neprestane fungovat pri I/O chybe.
 Nazev BiosWrite zustava abych to nemusel vsade prepisovat na DosWrite.. :)
}
PROCEDURE BiosWrite(st:string);assembler;
 var p:pointer absolute st;
 asm
     mov ah,40h
     mov bx,outhandle
     push ds
      lds si,p
      mov cl,[si]
      mov dx,si
      mov ch,0
      inc dx
      int 21h
     pop ds
 end;

PROCEDURE BiosWriteln(st:string);assembler;
 var p:pointer absolute st;
 asm
     mov ah,40h
     mov bx,outhandle
     push ds
      lds si,p
      mov cl,[si]
      mov dx,si
      mov ch,0
      inc dx
      int 21h
      mov ah,40h
      push cs
      pop ds
      lea dx,@newline
      mov cl,2
      int 21h
     pop ds
     jmp @end
      @newline:
      db 13,10
     @end:
 end;

{---------------------------------------------------------------------------
 Obycejny halt, jen misto integeru ocekava TError.
 ---------------------------------------------------------------------------}
PROCEDURE Halt(code:TError);
begin
 system.halt(integer(code));
end;

{---------------------------------------------------------------------------
 Hlasic chyb.
 ---------------------------------------------------------------------------}
var errors:word;

PROCEDURE ReportError(st:string);
begin
 {pred hlasenim prvni chyby prepne do textmodu}
 if errors=0 then asm mov ax,3;int 10h;end;
 {neni-li hlaska zakoncena #255, zvysi citac chyb}
 if st[length(st)]<>#255 then inc(errors);
 {pise}
 BiosWriteln(st);
end;

{---------------------------------------------------------------------------
 Prepne do textmodu, vypise hlasku a ukonci program.
 ---------------------------------------------------------------------------}
PROCEDURE erMsg(st:string);
begin
 if @ShutDownInts=nil
  {k chybe doslo po shutdownu, zavolame jen ReportError}
  then ReportError(st)
  {k chybe doslo pred shutdownem, zavolame shutdown,
  ale musime mu rict, aby za nas ohlasil tuhle chybu}
  else begin
   lastMsg:=st;
   ExitCode:=integer(_erWritten);
   while @ShutDownInts<>nil do ShutDownInts;
   end;
 Halt(_erWritten);
end;

{---------------------------------------------------------------------------
 Alternativni zpusoby hlaseni chyb.
 Urceny pro fajly.ReportErr.
 ---------------------------------------------------------------------------}
PROCEDURE erIgnore(st:string);
begin
end;

PROCEDURE erWrite(st:string);
begin
 BiosWriteln(st);
end;

PROCEDURE erWriteAndWait(st:string);
begin
 BiosWriteln(st);
 waitkey;
end;

{---------------------------------------------------------------------------
 Pokud je n<>erOk, ohlasi chybu n.
 ---------------------------------------------------------------------------}
PROCEDURE erCheck(n:TError);
begin
 if n<>erOk then Halt(n);
end;

{---------------------------------------------------------------------------
 Pokud je n<>erOk a not dumb, ohlasi chybu n.
 ---------------------------------------------------------------------------}
FUNCTION erDumb(n:TError):TError;
begin
 if (n<>erOk) and not dumb then Halt(n);
 erDumb:=n;
end;

{$ifdef beta}
{---------------------------------------------------------------------------
 Hlaska kterou pouzivam v betaverzich.
 ---------------------------------------------------------------------------}
PROCEDURE erBetaMsg(st:string);
begin
 erMsg('Betaverze hl†s°: '+st);
end;
{$endif}


{---------------------------------------------------------------------------
 _* vraci hlasku v aktualnim jazyce jako _, ale za $ dosadi parametry.
 ---------------------------------------------------------------------------}
function debuck(st:string;param1:string):string;
var n:word;
begin
 n:=pos('$',st);
 if n=0
  then debuck:=st+' ('+param1+')'
  else debuck:=copy(st,1,n-1)+param1+copy(st,n+1,255);
end;

FUNCTION  _i(code:TError;param1:PathStr):string;
begin
 _i:=debuck(_(code),param1);
end;

FUNCTION  _2(code:TError;param1,param2:PathStr):string;
begin
 _2:=debuck(debuck(_(code),param1),param2);
end;

FUNCTION  _3(code:TError;param1,param2,param3:PathStr):string;
begin
 _3:=debuck(debuck(debuck(_(code),param1),param2),param3);
end;


FUNCTION GetCmdlineLanguage:ExtStr;
var i,j:integer;
    s:ExtStr;
begin
 GetCmdlineLanguage:='';
 for i:=1 to paramcount do
  if (copy(paramstr(i),1,1)=':') and (length(paramstr(i))>1) then begin
    s:=copy(paramstr(i),2,255);
    for j:=1 to length(s) do if s[j] in ['A'..'Z'] then inc(s[j],32);
    GetCmdlineLanguage:=s;
    paramUsed[i]:=true;
    end;
end;


var oldStreamError:pointer;

procedure myStreamError(var s:TStream);far;
begin
 case s.status of
  -1:ReportErr(_(_erStream1)+', info='+stri(s.errorinfo)+'.');
  -2:case s.errorinfo of
      2:ReportErr(_(_erStream2)+'. '+_(errFileNotFound));
      3:ReportErr(_(_erStream2)+'. '+_(errInvalidPath));
      5:ReportErr(_(_erStream2)+'. '+_(errAccessDenied));
      19{kod ktery ma dos vracet},150{kod ktery dos vraci}:
        ReportErr(_(_erStream2)+'. '+_(_erIsWriteProtcted));
      else ReportErr(_(_erStream2)+', info='+stri(s.errorinfo)+'.');
      end;
  -3:ReportErr(_(_erStream3)+', info='+stri(s.errorinfo)+'.');
  -4:ReportErr(_(_erStream4)+', info='+stri(s.errorinfo)+'.');
  -5:ReportErr(_(_erStream5)+', info='+stri(s.errorinfo)+'.');
  -6:ReportErr(_(_erStream6)+', info='+stri(s.errorinfo)+'.');
  else ReportErr('Stream error '+stri(s.status)+', info='+stri(s.errorinfo)+'.');
  end;
end;

function my_(code:TError):string;far;
begin
 my_:='#'+stri(integer(code));
end;


{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

const unita='chyby';
var result:TError;

procedure ShutDown;far;
 var i:word;
 begin
  ShutDownInts:=nil;
  if lastMsg<>'' then begin
    ReportError(lastMsg);
    lastMsg:='';
    end;
  if TError(ExitCode)<>_erWritten then
   if (_(TError(ExitCode))<>'') and (_(TError(ExitCode))<>'#0') then ReportError(_(TError(ExitCode)));
  if longint(ErrorAddr)<>0 then begin
    ReportError(_(_Adresa)+' '+hexed(PtrRec(ErrorAddr).Seg)+':'+hexed(PtrRec(ErrorAddr).Ofs)+'.');
    ErrorAddr:=nil;
    end;
  i:=IOResult;
  if i<>0 then ReportError('IOResult='+stri(i)+'.');
  if errors>0 then begin
    asm
      mov al,0;out 21h,al
      mov al,20h;out 20h,al
      sti
    end;
    WaitKey;
    end;
 end;

procedure UserInit;
 var i:integer;
 begin
  {nastavi jazyk}
  language         :='';
  _                :=my_;
  language         :=GetCmdlineLanguage;
  {vynuluje dalsi veci}
  lastMsg          :='';
  errors           :=0;
  debug            :=false;
  SafeMode         :=false;
  dumb             :=true;
  errorLevel       :=0;
  ShutDownInts     :=ShutDown;
  ReportErr        :=erWrite;
  outhandle        :=1;
  fillchar(paramUsed,sizeof(paramUsed),false);
  {$ifdef beta}
  {zavesi StreamError handler}
  oldStreamError   :=StreamError;
  StreamError      :=@myStreamError;
  {$endif}
 end;

procedure UserDone;
 begin
  {$ifdef beta}
  StreamError      :=oldStreamError;
  {$endif}
  ExitCode         :=errorLevel;
 end;

{$i initdone.inc}
{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.