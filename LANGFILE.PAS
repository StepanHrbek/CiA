{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 1.00ÄÄÄ¿
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
  Pokud das tuto unitu do Uses, budou se vsechny hlasky za behu tahat
  z prilozeneho souboru 'lang.'+language - napriklad 'lang.cz'.
  Navic pujde i za behu menit jazyk.
  Jestli ti staci jeden jazyk a radsi nez v prilozenem souboru bys mel
  hlasky uvnitr programu, podivej se na unitu Lang1.
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
     else if fileLoad2Pchar(path,nil,p)
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
  language :='eng';{implicitni jazyk nastaveny po spusteni programu}
  textpack :=nil;
  lastlang :='';
  for i:=1 to paramcount do
   if (copy(paramstr(i),1,1)=':') and (length(paramstr(i))>1)
    then language:=copy(paramstr(i),2,255);
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