{$G+}
{Jednoduchy programek pro vypocet vyrazu s temito omezenimi:
 zadne funkce, promenne ci retezce, pouze ciselne konstanty(literaly)
 pouze zakladni aritmeticke operace (+,-,*,/) a zavorky
 vyhodnocovani pouze aritmetickych vyrazu (zadne logicke vyrazy)
 pouze v desitkove soustave (ale to se rychle zmeni)
 neni vymyslene diagnoza a osetreni chyb}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
{$M 60000,20000,160000}
uses memo,chyby,sys,stringy;
type
 string11=string[11];
(* string32=string[32];
FUNCTION  Strir(num:real; dm:byte):string32;
var
 st:string32; {* buganec. napr: strir(3.140000E+20,2)='3.14'}
 koef:integer;
begin
 str(num,st);
 delete(st,1,1-byte(ptr(seg(num),ofs(num)+5)^) shr 7); {u kladnych cisel urizne pocatecni mezeru}
 if Pos('E',st)=0
 then koef:=0
 else
  begin
   koef:=Valu(Copy(st,Pos('E',st)+1,5));
   delete(st,Pos('E',st),5);
  end;
 if Pos('.',st)<>0 then
  begin
   if koef<0 then
    if Pos('.')
  end;
 strir:=st;
end;*)
{----------------------------------------------------------------------8<----}
type
 single=-128..127;
 TypUzlu=(konstanta,operace);
 TypOperace=(op_plus,op_minus,op_mul,op_div,op_not,op_E,op_NE,op_L,op_G,op_LE,op_GE);
 Puzel=^Tuzel;
 Tuzel=
  record
   case typ:TypUzlu of
   konstanta:
    (konst:real);
   operace:
    (op:TypOperace;
     levy,pravy:Puzel);
  end;
 Tvyraz=
  object
   s:string;
   root:Puzel;
   index:byte;
   Constructor Init(_s:string);
   Destructor Done;
   Function  Zkontroluj(odkud,kolik:byte):boolean;
   Procedure Uprav;
   Procedure VymazUzel(strom:Puzel);
   Function  CtiKonstantu:real;
   Function  CtiCinitel:Puzel;
   Function  CtiFaktor:Puzel;
   Function  CtiVyraz(odkud,kolik:byte):Puzel;
   Function  VZavorce(kde:byte):string;
   Function  LogickyVyraz(odkud,kolik:byte):byte;
   Function  Vycisli(uzel:Puzel):real;
  end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
{trida VYRAZ}
Constructor Tvyraz.Init(_s:string);
begin
 s:=_s;
 root:=nil;
end;  {Tvyraz.Init}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Destructor Tvyraz.Done;
begin
 VymazUzel(root);
end;  {Tvyraz.Done}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Procedure Tvyraz.VymazUzel(strom:Puzel);
begin {Tvyraz.VymazUzel}
 if strom=nil then exit;
 if strom^.typ=operace then
  begin
   VymazUzel(strom^.levy);
   VymazUzel(strom^.pravy);
  end
 else
  Dispose(strom);
end;  {Tvyraz.VymazUzel}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function Tvyraz.VZavorce(kde:byte):string;
{Vrati vyraz v zavorce, ktera zacina na %kde-tem znaku.
 Predpoklada, ze vyraz prosel metodou 'Uprav'.}
var
 zavorka:integer;
 i:byte;
begin {Tvyraz.VZavorce}
 repeat
  if s[kde]<>'(' then break;
  zavorka:=0;
  for i:=kde to length(s) do
   case s[i] of
   '(': inc(zavorka);
   ')': begin
         dec(zavorka);
         if zavorka<0 then break else
         if zavorka=0 then
          begin
           VZavorce:=Copy(s,kde+1,i-kde-1);
           exit;
          end;
        end;
   end; {/case}
 until true;
 VZavorce:='';
end;  {Tvyraz.VZavorce}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function Tvyraz.Zkontroluj(odkud,kolik:byte):boolean;
var
 zavorka,rem:integer;
 i:byte;
begin {Tvyraz.Zkontroluj}
 Zkontroluj:=false;
 if kolik<1 then exit;
 zavorka:=0;
 rem:=0;
 i:=odkud;
 for i:=odkud to odkud+kolik-1 do
  case s[i] of
  '{': if rem<1 then inc(rem);
  '}': begin
        dec(rem);
        if rem<0 then break;
       end;
  '(': if rem<1 then inc(zavorka);
  ')': begin
        if rem<1 then dec(zavorka);
        if zavorka<0 then break;
       end;
  end; {/case}
 Zkontroluj:=(zavorka=0) and (rem=0);
end;  {Tvyraz.Zkontroluj}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Procedure Tvyraz.Uprav;
var i:byte;
begin {Tvyraz.Uprav}
 if not(Zkontroluj(1,length(s))) then exit;
 s:=WithoutChar(' ',s);
 while (length(s)>0) and (s[1]='(') and (s[length(s)]=')') and
       Zkontroluj(2,length(s)-2) do
  begin
   Delete(s,1,1);
   dec(s[0]);
  end;
 while (Pos('}',s)>Pos('{',s)) do
  Delete(s,Pos('{',s),Pos('}',s)-Pos('{',s)+1);
 while Pos('()',s)>0 do
  Delete(s,Pos('()',s),2);
 while Pos('(+',s)>0 do
  Delete(s,Pos('(+',s)+1,1);
 while Pos('*+',s)>0 do
  Delete(s,Pos('*+',s)+1,1);
 while Pos('/+',s)>0 do
  Delete(s,Pos('/+',s)+1,1);
 if (length(s)>0) and (s[1]='+') then Delete(s,1,1);
 if length(s)<255 then s[length(s)+1]:=#0;
end;  {Tvyraz.Uprav}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function Tvyraz.CtiKonstantu:real; {*vypilovat}
var
 res:string[80];
 r:real;
 code:integer;
 tecka,znamenko:boolean;
begin {Tvyraz.CtiKonstantu}
 res:='';
 tecka:=false;
 if s[index]='-' then
  begin
   znamenko:=true;
   inc(index);
  end
 else
  znamenko:=false;
 while (index<=length(s)) and (s[index] in ['0'..'9','.','a'..'f','h','o','A'..'F','H','O']) do
  begin
   res:=res+DnCase(s[index]);
   inc(index);
  end;  {/while}
{ if (Pos('a',res)+Pos('b',res)+Pos('c',res)+Pos('d',res)+Pos('e',res)+Pos('f',res)+Pos('h',res)+Pos('o',res)>0) then
  if Pos('.',res)>0
  then exit else
  case res[length(res)] of
  'b':
  'd':
  'g':
  'o':
  end;}
 if znamenko then res:='-'+res;
 Val(res,r,code);
 if code=0 then CtiKonstantu:=r
 else CtiKonstantu:=0;
end;  {Tvyraz.CtiKonstantu}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function Tvyraz.CtiCinitel:Puzel;
var novyuzel:Puzel;
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
 function KonecZavorky:byte;
 var
  i:byte;
  zavorka:integer;
 begin {KonecZavorky}
  zavorka:=0;
  for i:=index to length(s) do
   case s[i] of
   '(': inc(zavorka);
   ')': begin
         dec(zavorka);
         if zavorka=-1 then break;
        end;
   end;
  KonecZavorky:=i-1;
 end;  {KonecZavorky}
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
begin {Tvyraz.CtiCinitel}
 CtiCinitel:=nil;
 novyuzel:=nil;
 case s[index] of
 '0'..'9','.','-':
  begin
   New(novyuzel);
   if novyuzel=nil then exit;
   with novyuzel^ do
    begin
     typ:=konstanta;
     konst:=CtiKonstantu;
    end;
  end;
 {*rozsirit o "not cinitel" a "not(vyraz)"}
 '(':
  begin
   inc(index);
   novyuzel:=CtiVyraz(index,KonecZavorky);
  end;
 end; {/case}
 CtiCinitel:=novyuzel;
end;  {Tvyraz.CtiCinitel}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function Tvyraz.CtiFaktor:Puzel;
var
 levycinitel,pravycinitel,novyuzel:Puzel;
begin {Tvyraz.CtiFaktor}
 CtiFaktor:=nil;
 levycinitel:=CtiCinitel;
 while (index<=length(s)) and (s[index] in ['*','/']) do
  begin
   New(novyuzel);
   if novyuzel=nil then exit;
   with novyuzel^ do
    begin
     typ:=operace;
     if s[index]='*' then op:=op_mul else
     if s[index]='/' then op:=op_div;
     inc(index);
     levy:=levycinitel;
     pravy:=CtiCinitel;
    end;
   levycinitel:=novyuzel;
   if s[index]=')' then
    begin
     inc(index);
     break;
    end;
  end; {/while}
 CtiFaktor:=levycinitel;
end;  {Tvyraz.CtiFaktor}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function Tvyraz.LogickyVyraz(odkud,kolik:byte):byte;
var
 zavorka:integer;
 i:byte;
begin {Tvyraz.LogickyVyraz}
 LogickyVyraz:=0;
 zavorka:=0;
 for i:=odkud to MinI(odkud+kolik-1,length(s)) do
  case s[i] of
  '(':
   inc(zavorka);
  ')':
   begin
    dec(zavorka);
    if zavorka<0 then exit;
   end;
  '>','<','=':
   if zavorka=0 then
    begin
     LogickyVyraz:=i;
     exit;
    end;
  end; {/case}
end;  {Tvyraz.LogickyVyraz}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function Tvyraz.CtiVyraz(odkud,kolik:byte):Puzel;
var
 res,levyfaktor,pravyfaktor,novyuzel:Puzel;
begin {Tvyraz.CtiVyraz}
 CtiVyraz:=nil;
 index:=odkud;
 if LogickyVyraz(odkud,kolik)>0 then
  begin {logicky vyraz}
   New(novyuzel);
   if novyuzel=nil then exit;
   with novyuzel^ do
    begin
     typ:=operace;
     if Copy(s,LogickyVyraz(odkud,kolik),2)='<>' then op:=op_NE else
     if Copy(s,LogickyVyraz(odkud,kolik),2)='<=' then op:=op_LE else
     if Copy(s,LogickyVyraz(odkud,kolik),2)='>=' then op:=op_GE else
     if s[LogickyVyraz(odkud,kolik)]='<' then op:=op_L else
     if s[LogickyVyraz(odkud,kolik)]='>' then op:=op_G else
     if s[LogickyVyraz(odkud,kolik)]='=' then op:=op_E;
     levy:=CtiVyraz(odkud,LogickyVyraz(odkud,kolik)-odkud);
     pravy:=CtiVyraz(LogickyVyraz(odkud,kolik)+1+byte(op in [op_NE,op_LE,op_GE])
     ,kolik-LogickyVyraz(odkud,kolik)-byte(op in [op_NE,op_LE,op_GE]));
    end;
   CtiVyraz:=novyuzel;
   exit;
  end   {/logicky vyraz}
 else
 if s[index]='-' then
  begin {unarni minus}
   inc(index);
   pravyfaktor:=CtiFaktor;
   if pravyfaktor^.typ=konstanta then {konstantu jenom vynasobi -1}
    begin
     pravyfaktor^.konst:=-pravyfaktor^.konst;
     levyfaktor:=pravyfaktor;
     if s[index]=')' then inc(index);
    end
   else
    begin {z "-(vyraz)" udela uzel "(0-vyraz)"}
     New(levyfaktor);
     if levyfaktor=nil then exit;
     with levyfaktor^ do
      begin
       typ:=konstanta;
       konst:=0.0;
      end;
     New(novyuzel);
     if novyuzel=nil then exit;
     with novyuzel^ do
      begin
       typ:=operace;
       op:=op_minus;
       levy:=levyfaktor;
       pravy:=pravyfaktor;
      end;
     levyfaktor:=novyuzel;
    end
  end   {/unarni minus}
 else
  levyfaktor:=CtiFaktor;
 while (index<=odkud+kolik-1) and (s[index] in ['+','-']) do
  begin
   New(novyuzel);
   if novyuzel=nil then exit;
   with novyuzel^ do
    begin
     typ:=operace;
     if s[index]='+' then op:=op_plus else
     if s[index]='-' then op:=op_minus;
     inc(index);
     levy:=levyfaktor;
     pravy:=CtiFaktor;
    end; {/with}
   levyfaktor:=novyuzel;
   if s[index]=')' then
    begin
     inc(index);
     break;
    end;
  end; {/while}
 CtiVyraz:=levyfaktor;
end;  {Tvyraz.CtiVyraz}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function Tvyraz.Vycisli(uzel:Puzel):real;
begin {Tvyraz.Vycisli}
 if uzel=nil then
  begin
   Vycisli:=0.0;
   exit;
  end;
 with uzel^ do
  case typ of
  konstanta:
   Vycisli:=konst;
  operace:
   case op of
   op_plus:
    Vycisli:=Vycisli(levy)+Vycisli(pravy);
   op_minus:
    Vycisli:=Vycisli(levy)-Vycisli(pravy);
   op_mul:
    Vycisli:=Vycisli(levy)*Vycisli(pravy);
   op_div:
    if Vycisli(pravy)=0.0
    then Vycisli:=$FFFFFFFF
    else Vycisli:=Vycisli(levy)/Vycisli(pravy);
   op_not:
    vycisli:=not(trunc(Vycisli(levy)));
   op_E:
    vycisli:=byte(Vycisli(levy)=Vycisli(pravy)); {pro TRUE bude davat 1.0}
   op_NE:
    vycisli:=byte(Vycisli(levy)<>Vycisli(pravy)); {pro FALSE bude davat 0.0}
   op_L:
    vycisli:=byte(Vycisli(levy)<Vycisli(pravy));
   op_G:
    vycisli:=byte(Vycisli(levy)>Vycisli(pravy));
   op_LE:
    vycisli:=byte(Vycisli(levy)<=Vycisli(pravy));
   op_GE:
    vycisli:=byte(Vycisli(levy)>=Vycisli(pravy));
   end; {/case}
  end; {/case}
end;  {Tvyraz.Vycisli}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function pisinfix(uzel:Puzel):string;
const
 opstr:array[TypOperace] of string2=('+','-','*','/','¿','=','<>','<','>','<=','>=');
begin {pisinfix}
 with uzel^ do
  case typ of
  konstanta:
   pisinfix:=stri(konst{,2});
  operace:
   pisinfix:='('
    +pisinfix(levy)
    +' '+opstr[op]+' '
    +pisinfix(pravy)
    +')';
  end; {/case}
end;  {pisinfix}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
var
 v:Tvyraz;
 s:string;
begin
 writeln(memavail);
 writeln('Zadej vyraz (jen z konstant, +-*/ a zavorek):');
 readln(s);
 if s='' then s:='4.5+2*3/1-5*(8-6)';
 v.init(s);
 v.Uprav;
 v.root:=v.ctivyraz(1,length(v.s));
 writeln(pisinfix(v.root));
 writeln(v.s,' = ',v.vycisli(v.root):10:2);
 v.done;
 writeln(memavail);
 repeat until keypressed;
end.
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
{                   ÚÄÄÄ¿
                   Ú´<> Ã¿
                   ³ÀÄÄÄÙ³
                   ³ÚÄÄÄ¿³
                   Ã´ = Ã´
                   ³ÀÄÄÄÙ³
            ÚÄÄÄÄÄ¿³ÚÄÄÄ¿³ÚÄÄÄÄÄ¿
 LOGICKY: ÃÄ´VYRAZÃÅ´ < ÃÅ´VYRAZÃÄ´
 VYRAZ      ÀÄÄÄÄÄÙ³ÀÄÄÄÙ³ÀÄÄÄÄÄÙ
                   ³ÚÄÄÄ¿³
                   Ã´ > Ã´
                   ³ÀÄÄÄÙ³
                   ³ÚÄÄÄ¿³
                   Ã´<= Ã´
                   ³ÀÄÄÄÙ³
                   ³ÚÄÄÄ¿³
                   À´>= ÃÙ
                    ÀÄÄÄÙ
             ÚÄÄÄ¿
            Ú´ + Ã¿
            ³ÀÄÄÄÙ³   ÚÄÄÄÄÄÄ¿
 VYRAZ:   ÃÄÅÄÄÄÄÄÅÄÂÄ´FAKTORÃÄÄÂÄ´
            ³ÚÄÄÄ¿³ ³ ÀÄÄÄÄÄÄÙ  ³
            À´ - ÃÙ ³           ³
             ÀÄÄÄÙ  ³ ÚÄÄÄ¿     ³
                    ÃÄ´ + ÃÄÄÄÄÄ´
                    ³ ÀÄÄÄÙ     ³
                    ³ ÚÄÄÄ¿     ³
                    ÀÄ´ - ÃÄÄÄÄÄÙ
                      ÀÄÄÄÙ
                  ÚÄÄÄÄÄÄÄ¿
 FAKTOR:  ÃÄÄÄÂÄÄÄ´CINITELÃÄÄÄÂÄÄÄ´
              ³   ÀÄÄÄÄÄÄÄÙ   ³
              ³     ÚÄÄÄ¿     ³
              ÃÄÄÄÄÄ´ * ÃÄÄÄÄÄ´
              ³     ÀÄÄÄÙ     ³
              ³     ÚÄÄÄ¿     ³
              ÀÄÄÄÄÄ´ / ÃÄÄÄÄÄÙ
                    ÀÄÄÄÙ
                 ÚÄÄÄÄÄÄÄÄÄ¿
 CINITEL: ÃÂÄÄÄÄÄ´KONSTANTAÃÄÄÄÄÄÂ´
           ³     ÀÄÄÄÄÄÄÄÄÄÙ     ³
           ³ÚÄ¿ÚÄÄÄÄÄÄÄÄÄÄÄÄÄ¿ÚÄ¿³
           À´(Ã´LOGICKY VYRAZÃ´)ÃÙ
            ÀÄÙÀÄÄÄÄÄÄÄÄÄÄÄÄÄÙÀÄÙ
}
begin {Tvyraz.CtiKonstantu}
 res:='';
 tecka:=false;
 if s[index]='-'
 then begin znamenko:=true; inc(index); end
 else znamenko:=false;
 while index<=length(s) do
  begin
   case s[index] of
   '0'..'9':
    res:=res+s[index];
   '.':
    if not(tecka) then
     begin
      res:=res+'.';
      tecka:=true
     end;
   else break;
   end; {/case}
   inc(index);
  end; {/while}
 if znamenko then res:='-'+res;
 Val(res,r,code);
 if code=0 then CtiKonstantu:=r
 else CtiKonstantu:=0;
end;  {Tvyraz.CtiKonstantu}

_2_doo:
 dodelat not a logicky vyrazy at all
 vychytat stack overflow error