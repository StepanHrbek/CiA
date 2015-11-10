{$N+,E+}
type
 string20=string[20];
 TRod=(muzsky,zensky,stredni);
 TNumberLevel=
  record
   rod:TRod;
   koren:string20;
   koncovka:array[0..2] of string[1];
  end;

function rawpower(a,b:real):real;
begin rawpower:=exp(b*ln(a)); end;

function pad(n:word):byte;
var d:byte;
begin
 n:=n mod 100;
 d:=n div 10;
 n:=n mod 10;
 if (d=1) and (n>0) then pad:=2 else
  case n of
  1:     pad:=0;
  2,3,4: pad:=1;
  else   pad:=2;
  end;
end;

function cisloslovy(n:extended;rod:TRod):string;
 function cislodotisiceslovy(n:word;rod:TRod):string;
  function cisliceslovy(n:byte;rod:TRod):string20;
  const
   jednotky:array[3..9] of string20=('tri','ctyri','pet','sest','sedm','osm','devet');
   jednadve:array[1..2,muzsky..stredni] of string20=(
   ('jeden','jedna','jedno'),
   ('dva','dve','dve'));
  begin
   case n of
   0: cisliceslovy:='';
   1,2: cisliceslovy:=jednadve[n,rod];
   else cisliceslovy:=jednotky[n];
   end;
  end;
 const
  stovky:array[0..2] of string20=('sto','sta','set');
  desitky:array[2..9] of string20=('dvacet','tricet','ctyricet','padesat','sedesat','sedmdesat','osmdesat','devadesat');
  nact:array[1..9] of string20=('jede','dva','tri','ctr','pat','sest','sedm','osm','devate');
 var
  j,d,s:byte;
  result:string;
 begin
  j:=n mod 10; n:=n div 10;
  d:=n mod 10; n:=n div 10;
  s:=n mod 10;
  if s=0
  then result:=''
  else result:=cisliceslovy(s,stredni)+' '+stovky[pad(s)]+' ';
  if d<>0 then
   if d=1 then
    begin
     if j<>0
     then result:=result+nact[j]+'nact '
     else result:=result+'deset ';
     j:=0;
    end
   else result:=result+desitky[d]+' ';
  if j<>0 then result:=result+cisliceslovy(j,rod)+' ';
  while result[length(result)]=' ' do dec(result[0]);
  cislodotisiceslovy:=result;
 end;
const
 ex:array[1..6] of TNumberLevel=(
 (rod:muzsky; koren:'tisic'; koncovka:('','e','')),
 (rod:muzsky; koren:'milion'; koncovka:('','y','u')),
 (rod:zensky; koren:'miliard'; koncovka:('a','y','')),
 (rod:muzsky; koren:'bilion'; koncovka:('','y','u')),
 (rod:muzsky; koren:'trilion'; koncovka:('','y','u')),
 (rod:muzsky; koren:'kvadrilion'; koncovka:('','y','u')));
 iny:array[1..3] of TNumberLevel=(
 (rod:zensky; koren:'desetin'; koncovka:('a','y','')),
 (rod:zensky; koren:'setin'; koncovka:('a','y','')),
 (rod:zensky; koren:'tisicin'; koncovka:('a','y','')));
 celych:array[TRod] of string[4]=('cely','cela','cele');
var
 result:string;
 temp:extended;
 len,m:word;
 expcounter:byte;
begin
 if n=0 then
  begin
   cisloslovy:='nula';
   exit;
  end
 else if n<0 then
  begin
   result:='minus ';
   n:=-n;
  end
 else result:='';
 expcounter:=0;
 repeat
  if n<1000.0 then break;
  temp:=ln(n)/ln(10);
  len:=trunc(temp);
  if expcounter=0
  then
   begin
    expcounter:=len div 3;
    if expcounter>6 then {n>10^18}
     begin
      cisloslovy:='moc :)';
      exit;
     end;
   end
  else dec(expcounter);
  temp:=rawpower(1000.0,expcounter);
  m:=trunc(n/temp);
  with ex[expcounter] do
  if m<>0 then result:=result+cislodotisiceslovy(m,rod)+' '+koren+koncovka[pad(m)]+' ';
  n:=n-m*temp;
 until false;
 result:=result+cislodotisiceslovy(trunc(n),rod);
 while result[length(result)]=' ' do dec(result[0]);
{Doplni desetinnou cast slovy. Pouze do tisicin. Vzhledem k chybam v cislech
 s plovouci destinnou carkou behem vypoctu jsem se rozhodl tuto cast vynechat}
{ m:=trunc(n); expcounter:=3; n:=frac(n)*1000;
 while (expcounter>0) and (frac(n/10)=0.0) do
  begin
   dec(expcounter);
   n:=n/10;
  end;
 if expcounter>0 then
  with iny[expcounter] do
  begin
   case pad(m) of
   0: result:=result+' '+celych[rod]+' ';
   1: result:=result+' cele ';
   2: result:=result+' celych ';
   end;
   m:=trunc(n+0.00005);
   result:=result+cislodotisiceslovy(m,rod)+' '+koren+koncovka[pad(m)];
  end;}
 cisloslovy:=result;
end;

begin
 writeln('"'+cisloslovy(6.1,zensky)+'"');
end.