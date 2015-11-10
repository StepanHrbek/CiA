{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

(*
Podpora pro standardni Init/Done procedury vsech unit.
Konec kazde unity by mel vypadat takto:

var result:TError;

procedure UserInit;
 begin
  pokus o inicializaci unity
  pri neuspechu nastavit do result kod chyby a skoncit (unita neni! inicializovana)
  pri uspechu dokoncit inicializaci a skoncit (nemusis nastavovat result)
 end;

procedure UserDone;
 begin
  deinicializace unity
  nemusis hlidat jestli uz byla inicializovana, urcite byla
 end;

{$i initdone.inc}
{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.
*)

{$ifdef debuginit}
var old:longint;
FUNCTION  _Stri(n:longint):string;
var st:string[10];
begin
 str(n,st);
 _stri:=st;
end;
{$endif}

const inited:boolean=false;

{$ifdef autodone}
var oldExitProc:pointer;
procedure RuntimeExit;far;
 begin
  asm mov ax,seg @data;mov ds,ax;end;
  exitProc:=oldExitProc;
  {Zastavi proud HW interruptu ktere by mohly delat problemy.}
  while @ShutDownInts<>nil do ShutDownInts;
  {Dej pozor abys tady volal ZDEJSI Done (deklaruj Done v interface)}
  Done;
 end;
{$endif}

function Init:TError;
 begin
  result:=erOk;
  if not inited then begin
    {$ifdef debuginit}
    old:=memavail;
    {$endif}
    UserInit;
    {$ifdef debuginit}
    bioswriteln(unita+'.init eats '+_stri(old-memavail));
    {$endif}
    if result=erOk then begin
      {$ifdef autodone}
      oldExitProc:=exitProc;
      exitProc:=@RuntimeExit;
      {$endif}
      inited:=true;
      end;
    end;
  Init:=result;
 end;

procedure Done;
 begin
  if inited then begin
   {$ifdef debuginit}
   old:=memavail;
   bioswrite(unita+'.');
   {$endif}
   UserDone;
   {$ifdef debuginit}
   bioswrite('done vomits '+_stri(memavail-old));
   if erroraddr<>nil then bioswrite(' ErrorAddr<>nil!');
   bioswriteln('');
   {$endif}
   inited:=false;
   end;
 end;
