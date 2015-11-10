{$G+,R+,Q+}
const
 errUnexpected=$0100; {neocekavany znak}
 errUnknown   =$0200; {neznamy identifikator}
 errUndefined =$0400; {x neni v definicnim oboru funkce nebo operace}
 errInvalid   =$0800; {neplatny ciselny format}
{$I num.inc}
type
 string8=string[8];
 Tdatatyp=(dtKonstanta,dtPromenna,dtOperace,dtFunkce);
 PUzel=^TUzel;
 TUzel=
  record
   case datatyp:Tdatatyp of
   dtKonstanta:
    (konstanta:real);
   dtPromenna:
    (promenna:string8);
   dtOperace:
    (operace:char;
     levy,pravy:PUzel);
   dtFunkce:
    (funkce:string8;
     parametr:PUzel)
  end;
 TVyraz=
  object
   vstup:string;
   buffer:string[40];
   koren:pointer;
   index:byte;
   znak:char;
   chyba:word; {horni byte je kod chyby a dolni je prvni znak}
   procedure Init(_vstup:string);
   function  CtiZnak:char;
   function  CtiFaktor(a:byte):PUzel;
   function  CtiCinitel(a:byte):PUzel;
   function  CtiVyraz(a:byte):PUzel;
   function  Vycisli(uzel:Puzel):real;
   procedure Done;
  end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure TVyraz.Init(_vstup:string);
begin
 vstup:=_vstup;
 index:=1;
 koren:=nil;
 chyba:=0;
end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TVyraz.CtiZnak:char;
begin
 if (index>0) and (index<=length(vstup)) then
  repeat
   znak:=vstup[index];
   inc(index);
  until (znak<>' ') or not(index in [1..length(vstup)])
 else znak:=' ';
 CtiZnak:=znak;
end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TVyraz.CtiFaktor(a:byte):PUzel;
var
 uzel:PUzel;
 kontrola:integer;
begin
 index:=a;
 new(uzel);
 with uzel^ do
 case UpCase(CtiZnak) of
 '-':
  begin
   datatyp:=dtOperace;
   operace:='\'; {unarni minus}
   pravy:=nil;
   levy:=CtiCinitel(index);
  end;
 '0'..'9','.':
  begin
   datatyp:=dtKonstanta;
   buffer:=znak;
   while CtiZnak in ['0'..'9','.'] do buffer:=buffer+znak;
   if UpCase(znak)='E' then
    begin {nacitani cisla v semilogaritmickem tvaru}
     buffer:=buffer+znak;
     CtiZnak;
     if znak in ['+','-'] then buffer:=buffer+znak;
     while CtiZnak in ['0'..'9'] do buffer:=buffer+znak;
    end;
   if buffer[1]='.' then buffer:='0'+buffer;
   val(buffer,konstanta,kontrola);
   if kontrola<>0 then chyba:=chyba or errInvalid and $FF00 or index;
  end;
 'A'..'Z','_':
  begin
   datatyp:=dtPromenna;
   buffer:=znak;
   while UpCase(CtiZnak) in ['A'..'Z','0'..'9','_'] do buffer:=buffer+znak;
   if znak='(' then {neni to promenna ale funkce!}
    begin
     datatyp:=dtFunkce;
     funkce:=buffer;
     znak:=vstup[index];
     parametr:=CtiVyraz(index);
    end
   else promenna:=buffer;
  end;
 '(':
  begin
   datatyp:=dtOperace;
   operace:='(';
   pravy:=nil;
   levy:=CtiVyraz(index); {precte vyraz v zavorce}
   if CtiZnak<>')' then {prehupsne pres ')'}
    chyba:=chyba or errUnexpected and $FF00 or index;
  end;
 '#': {nasleduje cele cislo ve dvojkove, osmickove, desitkove nebo sestnactkove soustave}
  begin
   datatyp:=dtKonstanta;
   buffer:=CtiZnak;
   while UpCase(CtiZnak) in ['0'..'9','A'..'F'] do buffer:=buffer+znak;
   if UpCase(znak) in ['H','O'] then
    begin
     if UpCase(znak)='H' then kontrola:=16 else kontrola:=8;
     buffer:=any2any(buffer,kontrola,10,chyba);
     if hi(chyba)<>0 then chyba:=chyba and $FF00 or index;
     CtiZnak;
    end
   else
    case UpCase(buffer[length(buffer)]) of
    'D': dec(buffer[0]);
    'B': buffer:=any2any(Copy(buffer,1,length(buffer)-1),2,10,chyba);
    end;
   val(buffer,konstanta,kontrola);
   if kontrola<>0 then chyba:=chyba or errInvalid and $FF00 or index;
  end
 else
  begin
   chyba:=chyba or errUnexpected and $FF00 or index;
   dispose(uzel);
   uzel:=nil;
  end;
 end;
 CtiFaktor:=uzel;
end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TVyraz.CtiCinitel(a:byte):PUzel;
var
 uzel,novyuzel:PUzel;
begin
 index:=a;
 uzel:=CtiFaktor(index);
 novyuzel:=uzel;
 while znak in ['*','/','^','&','|','{','}'] do
 begin
  new(novyuzel);
  with novyuzel^ do
  begin
   datatyp:=dtOperace;
   operace:=znak;
   levy:=uzel;
   pravy:=CtiFaktor(index);
   uzel:=novyuzel;
  end;
 end;
 CtiCinitel:=novyuzel;
end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TVyraz.CtiVyraz(a:byte):PUzel;
var uzel,novyuzel:PUzel;
begin
 index:=a;
 uzel:=CtiCinitel(index);
 novyuzel:=uzel;
 while znak in ['+','-','=','>','<'] do
 begin
  new(novyuzel);
  with novyuzel^ do
  begin
   datatyp:=dtOperace;
   case znak of
   '+','-','=': operace:=znak;
   '<': case vstup[index+1] of
        '>': begin operace:='!'; inc(index); end;
        '=': begin operace:='l'; inc(index); end;
        else operace:='L';
        end;
   '>': if vstup[index+1]='=' then
         begin
          operace:='g';
          inc(index);
         end
        else operace:='G';
   end;
   levy:=uzel;
   pravy:=CtiCinitel(index);
   uzel:=novyuzel;
  end;
 end;
 CtiVyraz:=novyuzel;
end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
type
 TPromenna=
  record
   fce:string8;
   hodn:real;
  end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
const
 _promennych=16;
var
 tabulkapromennych:array[0.._promennych-1] of TPromenna;
{Tabulka promennych bude pouzita pri vycislovani vyrazu, ktery obsahuje
 identifikatory promennych. Pokud se nebude jednat o zname konstanty,
 program se zepta na hodnotu promenne a zapise si ji do tabulky. Od te
 doby promennou bude znat a bude pri dalsi otazce vracet primo jeji hodnotu.}
function  HodnotaPromenne(promenna:string8):real;
var
 i:byte;
 h:real;
begin
 for i:=0 to _promennych-1 do
  with tabulkapromennych[i] do
  if fce=promenna then
   begin
    HodnotaPromenne:=hodn;
    exit;
   end;
 if promenna='pi' then HodnotaPromenne:=pi else {zname konstanty}
 if promenna='e' then HodnotaPromenne:=exp(1.0) else
 if promenna='true' then HodnotaPromenne:=1.0 else
 if promenna='false' then HodnotaPromenne:=0.0
 else {nezname konstanty}
  begin
   write(promenna,' = '); readln(h);
   for i:=0 to _promennych-1 do
    with tabulkapromennych[i] do
    if fce='' then
     begin
      fce:=promenna;
      hodn:=h;
      break;
     end;
   HodnotaPromenne:=h;
  end;
end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function VycisliFunkci(funkce:string8; x:real; var chyba:word):real;
var
 y:longint;
 kontrola:integer;
begin
 if funkce='int' then VycisliFunkci:=int(x) else
 if funkce='round' then VycisliFunkci:=round(x) else
 if funkce='sin' then VycisliFunkci:=sin(x) else
 if funkce='cos' then VycisliFunkci:=cos(x) else
 if (funkce='ln') or (funkce='loge') then {prirozeny logaritmus}
  if x<=0.0 then chyba:=chyba or errUndefined else VycisliFunkci:=ln(x) else
 if funkce='log' then {dekadicky logaritmus}
  if x<0.0 then chyba:=chyba or errUndefined else VycisliFunkci:=ln(x)/ln(10) else
 if funkce='exp' then VycisliFunkci:=exp(x) else
 if funkce='sqr' then VycisliFunkci:=sqr(x) else
 if funkce='sqrt' then
  if x<0.0 then chyba:=chyba or errUndefined else VycisliFunkci:=sqrt(x) else
 if (funkce='arctg') or (funkce='arctan') then VycisliFunkci:=arctan(x) else
 if (funkce='arccotg') or (funkce='arccotan') then VycisliFunkci:=pi/2-arctan(x) else
 if funkce='arcsin' then
  if (x<-1.0) or (x>1.0) then chyba:=chyba or errUndefined else VycisliFunkci:=ArcTan(x/sqrt(1-sqr(x))) else
 if funkce='arccos' then
  if (x<-1.0) or (x>1.0) then chyba:=chyba or errUndefined else VycisliFunkci:=ArcTan(sqrt(1-sqr(x))/x) else
 if (funkce='tg') or (funkce='tan') then
  if Frac((x+pi/2)/pi)=0.0 then chyba:=chyba or errUndefined else VycisliFunkci:=sin(x)/cos(x) else
 if (funkce='cotg') or (funkce='cotan') then
  if Frac(x/pi)=0.0 then chyba:=chyba or errUndefined else VycisliFunkci:=cos(x)/sin(x) else
 if funkce='sinh' then VycisliFunkci:=(exp(x)-exp(-x))/2 else
 if funkce='cosh' then VycisliFunkci:=(exp(x)+exp(-x))/2 else
 {btw, nevite nekdo, jak udelat argsinh, argcosh, argtgh a argcotgh?}
 if copy(funkce,1,3)='log' then
  begin {obecny logaritmus napr. log3}
   val(copy(funkce,4,255),y,kontrola);
   if kontrola=0 then
    VycisliFunkci:=ln(x)/ln(y);
  end else
 chyba:=chyba or errUnknown;
end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function  TVyraz.Vycisli(uzel:Puzel):real;
var x:real;
begin
 if uzel=nil then
  begin
   Vycisli:=0.0;
   exit;
  end;
 with uzel^ do
 case datatyp of
 dtKonstanta:
  Vycisli:=konstanta;
 dtPromenna:
  Vycisli:=HodnotaPromenne(promenna);
 dtOperace:
  case operace of
  '+': Vycisli:=Vycisli(levy)+Vycisli(pravy);
  '-': Vycisli:=Vycisli(levy)-Vycisli(pravy);
  '*': Vycisli:=Vycisli(levy)*Vycisli(pravy);
  '/': begin
        x:=Vycisli(pravy);
        if x=0.0 then chyba:=chyba or errUndefined and $FF00 or index
        else Vycisli:=Vycisli(levy)/x;
       end;
  '^': Vycisli:=realpower(Vycisli(levy),Vycisli(pravy)); {umocneni, mocnitel muze byt realny}
  '\': Vycisli:=-Vycisli(levy); {unarni minus}
  '(': Vycisli:=Vycisli(levy); {vyraz v zavorce}
  '=': Vycisli:=byte(Vycisli(levy)=Vycisli(pravy)); {rovnost}
  '!': Vycisli:=byte(Vycisli(levy)<>Vycisli(pravy)); {nerovnost}
  'G': Vycisli:=byte(Vycisli(levy)>Vycisli(pravy)); {ostre vetsi}
  'g': Vycisli:=byte(Vycisli(levy)>=Vycisli(pravy)); {vetsi nebo rovno}
  'L': Vycisli:=byte(Vycisli(levy)<Vycisli(pravy)); {ostre mensi}
  'l': Vycisli:=byte(Vycisli(levy)<=Vycisli(pravy)); {mensi nebo rovno}
  '&': Vycisli:=trunc(Vycisli(levy)) and trunc(Vycisli(pravy)); {logicky soucin}
  '|': Vycisli:=trunc(Vycisli(levy)) or trunc(Vycisli(pravy)); {logicky soucet}
  '}': Vycisli:=trunc(Vycisli(levy)) shl trunc(Vycisli(pravy)); {bitovy posun vlevo}
  '{': Vycisli:=trunc(Vycisli(levy)) shr trunc(Vycisli(pravy)); {bitovy posun vpravo}
  end;
 dtFunkce:
  begin
   x:=Vycisli(parametr);
   Vycisli:=VycisliFunkci(funkce,x,chyba);
   if hi(chyba)<>0 then chyba:=chyba and $FF00 or index;
  end;
 end;
end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure ZrusUzel(uzel:PUzel);
begin
 if uzel=nil then exit;
 with uzel^ do
 if datatyp=dtOperace then
  begin
   ZrusUzel(levy);
   ZrusUzel(pravy);
  end else
 if datatyp=dtFunkce then
  ZrusUzel(parametr);
 dispose(uzel);
end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure TVyraz.Done;
begin
 ZrusUzel(koren);
end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
var
 vyraz:string;
 v:TVyraz;
 h:real;
begin
 writeln('memavail=',memavail);
 writeln('Zadej algebraicky nebo logicky vyraz:');
 readln(vyraz); if vyraz='' then vyraz:='ln(512)/ln(2)';
 with v do
 begin
  init(vyraz);
  koren:=ctivyraz(index);
  h:=vycisli(koren);
  writeln(vstup+'=',h:10:4);
  if chyba<>0 then writeln('chyba=',hi(chyba),',',lo(chyba));
  done;
 end;
 writeln('memavail=',memavail);
end.

Umi:
 þ nacitat algebraicky logicky vyraz do polymorfniho binarniho stromu
 þ vycislit hodnotu vyrazu
 þ jednoduche i slozitejsi algebraicke i logicke operace a relace
 þ zakladni i pokrocilejsi funkce
 þ nacist cislo v libovolne konvencni ciselne soustave
 þ signalizovat chybu
Neumi:
 þ optimalizovat vyraz s unarnim minusem
 þ viceargumentove funkce
 þ pracovat s komplexnimi cisly (musel bych si vytvorit format a funkce
   pro komplexni cisla, abych s nima mohl pracovat)
 þ faktorial jako '!', funkci gamma, hyperbolometricke a dalsi funkce
 þ dokonale presne vyhodnotit chybu a jeji pozici (muze nastat preteceni)
Udelat:
 þ zbavit se '#'.