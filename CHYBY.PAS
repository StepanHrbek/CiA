{⁄ƒƒƒC.I.A.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒverze 0.32ƒƒƒø
 ≥S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi≥
 ≥v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.≥
 ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ}

Unit      Chyby;
Interface {$i define.inc}
Uses      Dos,Objects, Stringy;
Function  Init:word;
Procedure Done;

{
---------------------------------------------------------------------------
                          Uvod k chybam
---------------------------------------------------------------------------

Dojde-li k fatalni chybe, bylo by dobre pred ukoncenim programu jeste
odalokovat pamet, zastavit procesy atd. Nejlepsi zpusob jak toho dosahnout
je pouzit ExitProc (viz help k ExitProc).

Je nekolik zpusobu jak ukoncit program.
Prvni ctyri jsou ekvivalentni

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
Proto pouzivam jiny zpusob hlaseni, proceduru erMsg(string).
Ta vypise chybovou hlasku okamzite a az pote vola ExitProc.
To ma ale jeden nedostatek. K bezpecnemu vypsani hlasky je nutno prepnout
do textmodu, coz vetsinou nevadi, ale nekdy to muze vest az ke zhrouceni
pocitace. Konkretne v pripade, kdy hardwarovy interrupt nebo jine okolnosti
vyvolaji tvoji rutinu, ktera dosud nevi, ze bylo prepnuto do textmodu.
V CiA obsazene handlery klavesnice i mysi jsou zcela bezpecne, nebezpecny
ale je handler timeru z unity Timer. Je naprosto nutne ho pred prepnutim
do textmodu vypnout. K tomu slouzi retez procedur ShutDownInts, ktery je
volan pred prepnutim do textmodu.

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
k necemu dojde, podruhe uz je retez ShutDownInts prazdny). Ovsem pokud si
pridas dalsi clanek ExitProc, nezapomen v nem volat a vyprazdnit ShutDownInts.

Pro snazsi hlaseni chybovych situaci zavadi unita chyby tuto nadstavbu:
 - erMsg(String)       vypise string a skonci
 - erBetaMsg(String)   totez jen pro betaverzi
 - erFile(String)      ohlasi ze zadany soubor chybi nebo je poruseny
 - erCheck(N)          pro N<>erOk udela Halt(N)
 - erDumb(N)           pro N<>erOK a not dumb udela Halt(N)

Zakladem jsou Halt(N) a erMsg(string), ostatni jsou specialni pripady jejich
volani.

Pri vypnutem autodone nejsou chyby nijak hlidany, runtime error skonci stejnou
hlaskou, halt program okamzite ukonci.

}
type  TError = integer;


{konstanty typu errXXXX jsou prevzaty z Midasu 0.40, erXXXX jsou vlastni}
{dalsi konstanty si zavadeji dalsi unity}
const
      errOutOfMemory      = 02;{ out of memory }
      errFileOpen         = 13;{ unable to open file }
      errFileRead         = 14;{ unable to read file }
      errFileNotFound     = 23;{ file not found }
      errFileWrite        = 31;{ unable to write file }
      errDPMIFailure      = 35;{ DMPI failure }

      erOk         =  0; { zadna chyba }
      erLowMem     =  2; { nedostatek pameti }
      erLowDosMem  = 77; { nedostatek dosove pameti }
      erLowBuffer  = 78; { malo pameti v bufferu }
      erMsgWritten = 79; { kod pro rychle ukonceni, hlaska je na obrazovce }
      erFileTooBig = 85; { prilis velky soubor }
      erBreak      =255; { ukonceni vyvolano stiskem Ctrl-Break }

{
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

      TBugList    =object(TCollection)  {seznam chybovych hlasek}
                    procedure Register(akod:TError;ahlaska:string);
                    procedure Report(akod:TError);
                   end;

Var   debug       :boolean;  {debugovaci rezim: vypis ruznych hlasek za behu}
      dumb        :boolean;  {strategie zpracovani nefatalnich chyb:
                              if Dumb then zkus_chybu_nejak_ututlat
                              else haltni_to_a_vyhod_errormsg;}
      cestina     :boolean;  {psat ceske chybove hlasky s diakritikou?}
      ShutDownInts:procedure;{procedura volana pri nahlem ukonceni programu,
                              urcena pro zastaveni aktivit, ktere by mohly
                              po prepnuti do textmodu zpusobit skody}
      BugList     :TBugList;

PROCEDURE BiosWrite(st:string);
PROCEDURE BiosWriteln(st:string);

PROCEDURE erMsg(st:string);
PROCEDURE erFile(st:PathStr);
PROCEDURE erCheck(n:integer);
FUNCTION  erDumb(n:integer):integer;
{$ifdef beta}
PROCEDURE erBetaMsg(st:string);
{$endif}

{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
                          IMPLEMENTATION
{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}

{---------------------------------------------------------------------------
 Nekolik kousku zkopirovanych z jinych unit za ucelem snizeni poctu uses.
 ---------------------------------------------------------------------------}
Type  PtrRec    = record
                   Ofs, Seg: Word;
                  end;
PROCEDURE WaitKey; inline($b8/$0c08/$cd/$21);{mov ax,0c08h;int 21h}
PROCEDURE FixInts; inline($b0/$0  /$e6/$21   /$b0/$20   /$e6/$20   /$fb);



{---------------------------------------------------------------------------
 Vlastni Write a Writeln.
 ---------------------------------------------------------------------------}
{
 Stary poctivy BiosWrite jsem nahradil novym BiosWritem, ktery
 ve skutecnosti pise do standardniho vystupu, stejne jako obycejny Write,
 ale na rozdil od nej neprestane fungovat pri I/O chybe.
 Nazev BiosWrite zustava abych to nemusel vsade prepisovat na DosWrite.. :)

PROCEDURE BiosWrite(st:string);assembler;
 var p:pointer absolute st;
 asm
     push bp
     mov ax,300h;xor bx,bx;int 10h
     mov ax,1301h;mov bx,7;xor cx,cx
     les bp,p;mov cl,[es:bp];inc bp
     int 10h
     pop bp
 end;

PROCEDURE BiosWriteln(st:string);assembler;
 var p:pointer absolute st;
 asm
     push bp
     mov ax,300h;xor bx,bx;int 10h
     mov ax,1301h;mov bx,7;xor cx,cx
     les bp,p;mov cl,[es:bp];inc bp
     int 10h
      mov ax,1301h;mov bx,7;mov cx,2
      push cs;pop es;lea bp,@newline
      int 10h
     pop bp
      jmp @end
      @newline:
      db 13,10
      @end:
 end;
}
PROCEDURE BiosWrite(st:string);assembler;
 var p:pointer absolute st;
 asm
     push ds
      mov ah,40h
      lds bx,p
      mov cl,[bx]
      mov dx,bx
      mov ch,0
      inc dx
      mov bx,1
      int 21h
     pop ds
 end;

PROCEDURE BiosWriteln(st:string);assembler;
 var p:pointer absolute st;
 asm
     push ds
      mov ah,40h
      lds bx,p
      mov cl,[bx]
      mov dx,bx
      mov ch,0
      inc dx
      mov bx,1
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
 Hlasic chyb.
 ---------------------------------------------------------------------------}
var errors:word;

PROCEDURE ReportError(st:string);
begin
 {pred hlasenim prvni chyby prepne do textmodu}
 if errors=0 then asm mov ax,3;int 10h;end;
 {neni-li hlaska zakoncena mezerou, zvysi citac chyb}
 if st[length(st)]<>' ' then inc(errors);
 {pise a volitelne maze diakritiku}
 if cestina
  then BiosWriteln(st)
  else BiosWriteln(Kamenici2Ascii(st));
end;


{---------------------------------------------------------------------------
 Objekty TBug a TBugList.
 ---------------------------------------------------------------------------}
Type PBug = ^TBug;
     TBug = object(TObject)      {jedna chybova hlaska}
             constructor Init(akod:TError;ahlaska:string);
             procedure Report;
             destructor Done;virtual;
            private
             kod:TError;
             hlaska:PString;
            end;

Constructor TBug.Init(akod:TError;ahlaska:string);
begin
 inherited Init;
 kod:=akod;
 hlaska:=NewStr(ahlaska);
end;

Procedure TBug.Report;
begin
 ReportError(hlaska^);
end;

Destructor TBug.Done;
begin
 DisposeStr(hlaska);
 inherited Done;
end;

Procedure TBugList.Register(akod:TError;ahlaska:string);
 function KodMatches(bug:PBug):boolean;far;
 begin
  KodMatches:=bug^.kod=akod;
 end;
var bug:^TBug;
begin
 bug:=FirstThat(@KodMatches);
 if bug<>nil then erMsg('Pokus o registraci dvou chyb se stejnòm k¢dem ('+stri(akod)+').');
 New(bug,Init(akod,ahlaska));
 if bug=nil then Halt(erLowMem) else Insert(bug);
end;

Procedure TBugList.Report(akod:TError);
 function KodMatches(bug:PBug):boolean;far;
 begin
  KodMatches:=bug^.kod=akod;
 end;
var bug:^TBug;
begin
 bug:=FirstThat(@KodMatches);
 if bug<>nil then bug^.Report else
  if akod<>erOk then ReportError('Nezn†m† chyba á°slo '+stri(akod)+'.');
end;


{---------------------------------------------------------------------------
 Prepne do textmodu, vypise hlasku a ukonci program.
 ---------------------------------------------------------------------------}
var ReportThis:string[80];

PROCEDURE erMsg(st:string);
begin
 if @ShutDownInts=nil
  {k chybe doslo po shutdownu, zavolame jen ReportError}
  then ReportError(st)
  {k chybe doslo pred shutdownem, zavolame shutdown,
  ale musime mu rict, aby za nas ohlasil tuhle chybu}
  else begin
   ReportThis:=st;
   ExitCode:=erMsgWritten;
   ShutDownInts;
   ShutDownInts:=nil;
   end;
 Halt(erMsgWritten);
end;

{---------------------------------------------------------------------------
 Casto pouzivana varianta erMsg.
 ---------------------------------------------------------------------------}
PROCEDURE erFile(st:PathStr);
begin
 erMsg('Soubor '+st+' chyb° nebo je poru®enò.');
end;

{---------------------------------------------------------------------------
 Pokud je n<>erOk, ohlasi chybu n.
 ---------------------------------------------------------------------------}
PROCEDURE erCheck(n:integer);
begin
 if n<>erOk then Halt(n);
end;

{---------------------------------------------------------------------------
 Pokud je n<>erOk a not dumb, ohlasi chybu n.
 ---------------------------------------------------------------------------}
FUNCTION erDumb(n:integer):integer;
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


{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

var result:integer;
    oldmem:longint;

procedure ShutDown;far;
 var i:word;
 begin
  if ReportThis<>'' then begin
    ReportError(ReportThis);
    ReportThis:='';
    end;
  if ExitCode<>erMsgWritten then BugList.Report(ExitCode);
  if longint(ErrorAddr)<>0 then begin
    ReportError('Adresa '+hexed(PtrRec(ErrorAddr).Seg)+':'+hexed(PtrRec(ErrorAddr).Ofs)+'.');
    ErrorAddr:=nil;
    end;
  i:=IOResult;
  if i<>0 then ReportError('IOResult='+stri(i)+'.');
  if errors>0 then begin
    FixInts;
    WaitKey;
    end;
 end;

procedure UserInit;
 begin
  oldmem:=system.memavail;
  ReportThis:='';
  errors:=0;
  debug:=false;
  dumb:=true;
  cestina:=false;
  ShutDownInts:=ShutDown;
  if BugList.Init(100,100) then begin
    {vsechny chyby zdedene z midasu}
    BugList.Register(errOutOfMemory   ,'Nedostatek pamàti.');
    BugList.Register(errFileOpen      ,'Nelze otev©°t soubor.');
    BugList.Register(errFileRead      ,'Chyba p©i áten° ze souboru.');
    BugList.Register(errFileNotFound  ,'Soubor nenalezen.');
    BugList.Register(errFileWrite     ,'Chyba p©i z†pisu do souboru.');
    BugList.Register(errDPMIFailure   ,'Chyba p©i pr†ci s DPMI.');
    {chyby CiA}
    BugList.Register(erLowDosMem      ,'Nedostatek konvenán° pamàti.');
    BugList.Register(erFileTooBig     ,'P©°li® velkò soubor.');
    BugList.Register(erBreak          ,'Break, taky ©e®en°.');
    {runtime chyby}
    BugList.Register(200              ,'Dàlen° nulou.');
    BugList.Register(201              ,'P©ekroáen° mez° pole nebo typu.');
    BugList.Register(202              ,'P©eteáen° stacku.');
    BugList.Register(203              ,'P©eteáen° heapu.');
    BugList.Register(204              ,'Invalid pointer operation.');
    BugList.Register(205              ,'Floating point overflow.');
    BugList.Register(206              ,'Floating point underflow.');
    BugList.Register(207              ,'Invalid floating point operation.');
    BugList.Register(208              ,'Overlay manager not installed.');
    BugList.Register(209              ,'Overlay file read error.');
    BugList.Register(210              ,'Pouëit° neinicializovanÇho objektu.');
    BugList.Register(211              ,'Vol†n° abstraktn° metody.');
    BugList.Register(212              ,'Stream registration error.');
    BugList.Register(213              ,'Indexov†n° v kolekci mimo rozsah.');
    BugList.Register(214              ,'P©eteáen° kolekce.');
    BugList.Register(215              ,'AritmetickÇ p©eteáen°.');
    BugList.Register(216              ,'General Protection Fault, hehe :).');
    exit;
    end;
  result:=erLowMem;
 end;

procedure UserDone;
 begin
  BugList.Done;
  if debug then begin
    BiosWriteln('memstart='+stri(oldmem));
    BiosWriteln('memend  ='+stri(system.memavail));
    BiosWriteln('rozdil  ='+stri(oldmem-system.memavail));
    end;
  ExitCode:=erOk;
 end;

{$i initdone.inc}
{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.