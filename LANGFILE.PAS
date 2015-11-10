{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      LangFile;
Interface {$i define.inc}
Uses      Chyby,Memo, Dos,Strings, Texty,Fajly;
Function  Init:TError;
Procedure Done;

PROCEDURE InitLanguages;

{
 ---------------------------------------------------------------------------
             Ulozeni textovych resourcu (chybovych hlasek apod)
 ---------------------------------------------------------------------------

 Pokud ve svem programu chces mit chybove hlasky, ne jen kody chyb,
 mel bys v jeho Uses uvest prave jednu Lang* unitu.

 Lang1    zajisti ze soucasti vysledneho .exe budou hlasky v jednom jazyce.
 Lang2    zajisti ze soucasti vysledneho .exe budou hlasky ve dvou jazycich
          s moznosti za behu prepinat.
 LangFile zajisti ze hlasky v libovolne mnoha jazycich budou v samostatnych
          souborech, samozrejme s moznosti za behu prepinat.
}

Implementation

 var      old_:function(code:TError):string;
          lastlang:string[3];
          textpack:PText2;

 function dirLang:PathStr;
 begin
  dirLang:=dirExe;
 end;

 {pozor, zvlada max 64K soubor a prekroceni nehlida}
 {pokud chces vic nez 64K, staci opravit tridu TText1 aby umela vic}
 function my_(code:TError):string;far;
 var p:pchar;
     path:PathStr;
 begin
  if lastlang<>language then begin
    KillObj(textpack);
    lastlang:=language;
    path:=dirLang+'lang.'+language;
    if not fileExists(path)
     then ReportErr('Missing language file '+path+'.')
     else if fileLoadPchar(path,nil,p)
           then New(textpack,Init(p,StrLen(p)+1));
    end;
  if textpack=nil
   then my_:=old_(code)
   else begin
     textpack^.Reset;
     textpack^.nlGoto(+word(code));
     my_:=textpack^.nlGet;
     end;
 end;

 {zaregistruje jazyky, pro ktere nalezl prislusne soubory}
 procedure InitLanguages;
 var t:searchrec;
 begin
  FindFirst(dirLang+'lang.*',AnyFile-Directory-VolumeID,t);
  while doserror=0 do begin
    if debug then BiosWriteln(t.name);
    fileRegister(PathSlice(t.name,psExt),isLanguage);
    FindNext(t);
    end;
 end;

{°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°INIT/DONE°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°}

const unita='langfile';
var result:TError;

procedure UserInit;
 var i:integer;
 begin
  old_     :=_;
  _        :=my_;
  textpack :=nil;
  lastlang :='';
  language :=GetCmdlineLanguage;
  if language='' then language :='eng';{implicitni jazyk nastaveny po spusteni programu}
  InitLanguages;
 end;

procedure UserDone;
 begin
  KillObj(textpack);
  _        :=old_;
 end;

{$i initdone.inc}
{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.