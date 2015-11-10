{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      Lang2;
Interface {$i define.inc}
Uses      Chyby, Stringy,Fajly;
Function  Init:TError;
Procedure Done;

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

 {define lang_in_DS} {vsechny hlasky mohou byt v poli v datasegmentu}
                     {ale zabiraji tam pak desne mista}
 {$i lang1.inc}
 {$i lang2.inc}

 var      old_:function(code:TError):string;

{$ifdef lang_in_DS}

 function my_(code:TError):string;far;
 begin
  if code>__ then my_:=old_(code) else
  if language=lang1str then my_:=Pc2Str(hlasky1DS[code]) else
  if language=lang2str then my_:=Pc2Str(hlasky2DS[code]) else
   my_:=old_(code);
 end;

{$else}

 function my_(code:TError):string;far;
 var  p:pchar;
      st:string;
 type PWords=^TWords;
      TWords=array[0..32766] of word;
 begin
  p:=nil;
  if code<=__ then
  if language=lang1str then p:=@hlasky1CS else
  if language=lang2str then p:=@hlasky2CS;
  if p=nil then my_:=old_(code) else begin
    st[0]:=chr(PWords(p)^[ord(code)+1]-PWords(p)^[ord(code)]);
    move((p+PWords(p)^[ord(code)])^,st[1],length(st));
    my_:=st;
    end;
 end;

{$endif}

{°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°INIT/DONE°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°}

const unita='lang2';
var result:TError;

procedure UserInit;
 var i:integer;
 begin
  old_     :=_;
  _        :=my_;
  language :=GetCmdlineLanguage;
  if language='' then language :=lang1str;{implicitni jazyk nastaveny po spusteni programu}
  fileRegister(lang1str,isLanguage);
  fileRegister(lang2str,isLanguage);
 end;

procedure UserDone;
 begin
  _        :=old_;
 end;

{$i initdone.inc}
{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.