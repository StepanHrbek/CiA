{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 1.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      Lang1;
Interface {$i define.inc}
Uses      Chyby, Stringy,Fajly;
Function  Init:TError;
Procedure Done;

{
  Pokud das tuto unitu do Uses, budou vsechny hlasky uvnitr programu.
  To znamena, ze program nebude vyzadovat nejaky prilozeny soubor,
  ale zas bude umet jen jednim jazykem.
  Kdybys chtel vic jazyku, podivej se na unitu LangFile,
  ktera nahrava hlasky ze souboru a podporuje prepinani jazyku
  za behu programu.
}

Implementation

 {$i lang1.inc}

 var      old_:function(code:TError):string;

 function my_(code:TError):string;far;
 begin
  my_:=Pc2Str(hlasky[code]);
 end;

{°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°INIT/DONE°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°}

const unita='lang1';
var result:TError;

procedure UserInit;
 var i:integer;
 begin
  old_     :=_;
  _        :=my_;
  language :='cz';
  fileRegister('CZ',isLanguage);
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