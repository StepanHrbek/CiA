{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 0.10ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      Chyby;
Interface {$i define.inc}
Uses      Dos;
Function  Init:word;
Procedure Done;

{
---------------------------------------------------------------------------
                          Uvod k chybam
---------------------------------------------------------------------------

Dojde-li k fatalni chybe, bylo by dobre pred ukoncenim programu jeste
odalokovat pamet, zastavit procesy atd. Doporucuji udelat si v hlavnim
programu jednu rutinu, ktera toto vsechno zaridi a nastavit na ni
ExitProc (viz help k ExitProc).

Pote mas dva zpusoby jak odkudkoliv ukoncit program:
 Halt(erXXX)    - Zavola tvoji obsluhu s parametrem erXXX.
                  Nemas-li svou obsluhu, zavola zdejsi nouzovou.
 erMsg(string)  - Nastavi textmod, vypise hlasku, pocka na stisk
                  a zavola tvoji obsluhu s parametrem erOk (podle toho
                  by mela tva obsluha usoudit, ze pripadna chybova hlaska
                  uz je zobrazena a neni zahodno mazat obrazovku!).
                  Nemas-li svou obsluhu, zavola zdejsi nouzovou.
}
const erOk        =0;  {kod pro korektni ukonceni programu}
      erBreak     =255;{ukonceni vyvolano stiskem Ctrl-Break}
      erLowMem    =2;  {ukonceni kvuli nedostatku pameti}
      erMsgWritten=79; {rychle ukonceni, hlaska je na obrazovce}
      erBadMode   =80; {nejde nastavit zobrazovaci mod}
      {$ifdef dement}
      erBadPage   =81;
      erBadButt   =82;
      erBadTex    =83;
      erDeath     =99;
      {$endif}

    {*system chyb bude kompatibilni s midasem}
    { funkce nebudou vracet uspesnost jako boolean, ale jako word}
    { casem to precisluju a zapracuju dohromady s timto z midasu 0.40:}

    errUndefined = 01;                  { undefined error }
    errOutOfMemory = 02;                { out of (conventional) memory }
    errHeapCorrupted = 03;              { (conventional memory) heap corrupted }
    errInvalidBlock = 04;               { invalid memory block }
    errFileOpen = 13;                   { unable to open file }
    errFileRead = 14;                   { unable to read file }
    errFileNotFound = 23;               { file not found }
    errInvalidFileHandle = 24;          { invalid file handle }
    errAccessDenied = 25;               { access denied }
    errFileExists = 26;                 { file exists }
    errTooManyFiles = 27;               { too many open files }
    errDiskFull = 28;                   { disk full }
    errEndOfFile = 29;                  { unexpected end of file }
    errInvalidPath = 30;                { invalid path }
    errFileWrite = 31;                  { unable to write file }
    errDPMIFailure = 35;                { DPMI failure }
    errInvalidDescriptor = 36;          { invalid segment descriptor }

{
---------------------------------------------------------------------------
 BETAVERZE:
---------------------------------------------------------------------------

Chybove hlasky betaverze (objevuji se pri kompilaci unit s definem beta)
obsahuji bud misto chyby (nazev procedury, cislo) nebo strucny popis chyby.
Program, ktery v betaverzi funguje, by mel bez define beta fungovat
naprosto stejne, pouze rychleji.


---------------------------------------------------------------------------
 MIDAS:
---------------------------------------------------------------------------

Rutiny z Midasu vzdy vraci uspesnost ve wordu - vyznamy jednotlivych
hodnot jsou nadefinovany v midasovske unite Errors. Na overeni vysledku
Midasovske funkce muzes pouzit zde nadefinovane funkce midasXXXX.


}


Type  TReporter   =procedure(st:string);{procedura ktera ohlasi chybu
                                   a necha program pokracovat}


Var   debug       :boolean;  {debugovaci rezim: vypis ruznych hlasek za behu}
      dumb        :boolean;  {strategie zpracovani nefatalnich chyb:
                              if Dumb then zkus_chybu_nejak_ututlat
                              else haltni_to_a_vyhod_errormsg;}

PROCEDURE BrutalWrite(st:string);
PROCEDURE erMsg(st:string);
PROCEDURE erFile(st:PathStr);
PROCEDURE erCheck(n:integer);
{$ifdef beta}
PROCEDURE erBetaMsg(st:string);
{$endif}

procedure midasError(errNum:integer);
function  midasDumbError(errNum:integer):integer;


{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
                          IMPLEMENTATION
{ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ}

{$ifdef midas}
 Uses Midas;
 {$else}
  {$ifdef timer}
   Uses Timer;
  {$endif}
{$endif}

{---------------------------------------------------------------------------
 Nekolik kousku zkopirovanych z jinych unit za ucelem snizeni poctu
 unit v uses.
 ---------------------------------------------------------------------------}
Type  PtrRec    = record
                   Ofs, Seg: Word;
                  end;
PROCEDURE WaitKey; inline($b8/$0c08/$cd/$21);{mov ax,0c08h;int 21h}
PROCEDURE FixInts; inline($b0/$0  /$e6/$21   /$b0/$20   /$e6/$20   /$fb);
                         {mov al,0;out 21h,al;mov al,20h;out 20h,al;sti}
FUNCTION  Stri(n:longint):string;
var st:string[10];
begin
 str(n,st);
 stri:=st;
end;
FUNCTION Hexed(l:longint):string;
var   st:string[8];
const hex:array[0..15] of char='0123456789ABCDEF';
begin
 st:='';
 repeat
   insert(hex[l mod 16],st,1);
   l:=l shr 4;
 until l=0;
 Hexed:=st;
end;


{---------------------------------------------------------------------------
 Zcela spolehlivy vypis, problem uz muze zpusobit jedine maly stack.
 ---------------------------------------------------------------------------}
PROCEDURE BrutalWrite(st:string);
var   i:word;
begin
 asm mov ax,3;int 10h;end;
 for i:=1 to length(st) do mem[segb800:2*i-2]:=ord(st[i]);
 FixInts;
 waitkey;
end;

{---------------------------------------------------------------------------
 Tato procedura se provadi po runtime erroru a po haltu.
 Kdyz neni ExitCode erOk, skoci do textmodu a vypise hlasku.
 ---------------------------------------------------------------------------}
var   OldExitProc:pointer;
      Old9:pointer;

PROCEDURE RuntimeExit;far;
var   st:string[80];
begin
 {obnovi ds}
 asm mov ax,seg @data;mov ds,ax;end;
 {obnovi ExitProc}
 ExitProc:=OldExitProc;
 {nouzove ukonceni pokud jsi chybu nezpracoval vlastnim errorhandlerem}
 if ExitCode<>erOk then begin
   {obnovi beh interruptu, ukonci pripadny HW interrupt}
   FixInts;
   {pokud jeste neni vypsana chybova hlaska, zobrazi ji}
   if ExitCode<>erMsgWritten then begin
     case ExitCode of erLowMem:st:='nedostatek pameti';
                          else st:='chyba '+stri(ExitCode);
                          end;
     if longint(ErrorAddr)<>0 then st:=st+' na adrese '+hexed(PtrRec(erroraddr).Seg)+':'+hexed(PtrRec(erroraddr).Ofs);
     BrutalWrite('Nouzove ukonceni, '+st+'.');
     end;
   {$ifdef midas}
    _tmrClose;
    {$else}
     {$ifdef timer}
     tmrClose;
     {$endif}
   {$endif}
   {zrusi pripadny keyboard handler}
   SetIntVec(9,old9);
   {zrusi pripadny mouse event handler}
   asm mov ax,12;xor cx,cx;xor dx,dx;mov es,dx;int 33h;end;
   end;
 Halt(erOk);
end;


{---------------------------------------------------------------------------
 Prepne do textmodu, vypise hlasku a zavola Halt(0).
 ---------------------------------------------------------------------------}
PROCEDURE erMsg(st:string);
begin
 BrutalWrite(st);
 Halt(erMsgWritten);
end;

{---------------------------------------------------------------------------
 Casto pouzivana chybova hlaska.
 ---------------------------------------------------------------------------}
PROCEDURE erFile(st:PathStr);
begin
 erMsg('Soubor '+st+' chybi nebo je poruseny.');
end;

{---------------------------------------------------------------------------
 Pokud je n<>0, ohlasi chybu n.
 ---------------------------------------------------------------------------}
PROCEDURE erCheck(n:integer);
begin
 if n<>0 then Halt(n);
end;

{$ifdef beta}
{---------------------------------------------------------------------------
 Hlaska kterou pouzivam v betaverzich.
 ---------------------------------------------------------------------------}
PROCEDURE erBetaMsg(st:string);
begin
 erMsg('Betaverze hlasi: '+st);
end;
{$endif}

{---------------------------------------------------------------------------
 Pro kompatibilitu s Midasem.
 ---------------------------------------------------------------------------}
procedure midasError(errNum : integer);
begin
 {$ifdef midas}
 midas.midasError(errNum);
 {$else}
 erMsg('Chyba '+stri(errNum)+' podle cislovani Midasu.');
 {$endif}
end;

{---------------------------------------------------------------------------
 Overeni vysledku midasovske funkce.
 Pri chybe se zachova podle promenne dumb: ohlasi chybu a skonci
  nebo pouze vrati cislo chyby.
 ---------------------------------------------------------------------------}
function  midasDumbError(errNum : integer):integer;
begin
 midasDumbError:=errNum;
 if (errNum<>0) and not dumb then midasError(errNum);
end;


{°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°INIT/DONE°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°}

const
 inited:boolean=false;

function Init:word;
 begin
  Init:=erOk;
  if not inited then begin
   debug        :=false;
   dumb         :=true;
   GetIntVec(9,old9);
   OldExitProc  :=ExitProc;
   ExitProc     :=@RuntimeExit;
   inited       :=true;
   end;
 end;

procedure Done;
 begin
  if inited then begin
   if ExitProc=@RuntimeExit then ExitProc:=OldExitProc;
   inited       :=false;
   end;
 end;

{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.