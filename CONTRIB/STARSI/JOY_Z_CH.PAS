{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function Joyx:word; assembler; {Vraci horizontalni souradnici Joysticku}
var count:word;
asm {Joyx}
 mov word ptr count,0
 cli
 mov dx,201h
 out dx,al
@joystickloop:
 inc count
 cmp count,$FFFF
 je  @done
 in  al,dx
 and al,1
 jne @joystickloop
@done:
 sti
 mov ax,count
end;{Joyx}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
{Pred tim,nez budete chtit pouzit pouze hodnotu teto funkce,
radsi ji zavolejte tesne predtim,nez ji budete potrebovat a naplnte
libovolnou promennou typu "word" hodnotou teto funkce.
Co za to? Bude to aspon trochu fungovat, jak ma.}
function Joyy:word; assembler; {Vraci vertikalni souradnici Joysticku}
var count:word;
asm {Joyy}
 mov word ptr count,0
 cli
 mov dx,201h
 out dx,al
@joystickloop:
 inc count
 cmp count,$FFFF
 je  @done
 in  al,dx
 and al,2
 jne @joystickloop
@done:
 sti
 mov ax,count
end;{Joyy}
{Existuji take funkce:
 J1F, ktera vraci 'True', pokud je stlaceno primarni tlacitko na joysticku1
 J2F, ktera vraci 'True', pokud je stlaceno sekundarni tlacitko na joysticku1}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function joystickX(number:byte):word; assembler;
{IN: number (1 or 2)  OUT: ax
 LABELS: @@1,@@2,@@3  MODIFIES: ax,dx,cx}
asm {joystickX}
 cli            {zakaze maskovatelne preruseni}
 mov  al,number {snazi se dostat do ah jednicku, kdyz number=1 nebo ctyrku, kdyz number=2}
 mul  al        {nejjednodussi je asi umocnit number, pro 1 je to 1*1=1, pro 2 je to 2*2=4}
 mov  ah,al     {v al je nyni number*number. Soupneme ho tedy do ah}
 mov  dx,c_JOYSTICKPORT {do dx dame cislo portu joysticku}
@@1:            {nejdrive pockame, dokud nebude port vracet nulu}
 in   al,dx     {nacteme hodnotu z portu dx do al}
 cmp  al,0      {porovname ho s nulou}
 jnz  @@1       {jestlize se lisi al od nuly, skoci na @@1, jinak pokracuje}
 out  dx,al     {nyni posleme hodnotu registru al na port dx}
 mov  cx,0      {nastavime cx na pocatecni hodnotu+1 (neboj, pak ji zase odecteme)}
@@2:
 in   al,dx     {precteme data z portu dx a ulozime je do al}
 inc  cx        {zvysime hodnotu citace}
 jcxz @@3       {jestlize cx prosel vsechna cisla od 0..$FFFF tak radsi skoncime}
 test al,ah     {testujeme, jestli al (nactena hodnota) ma ah-ty bit roven jednicce}
 jnz  @@2       {pokud ano, pak se cyklus opakuje, pokud ne..}
@@3:
 dec  cx        {v cx je nyni skutecny pocet cyklu, ktere beh programu projel}
 sti            {znovu povoli maskovatelne preruseni}
 mov  ax,cx     {vlozime do vystupu hodnotu citace}
{Pozn. Tento zpusob je zavisly na vykonu a typu procesoru a proto bych
 s vracenou hodnotou pocital relativne.}
end;{joystickX}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function joystickY(number:byte):word; assembler;
{IN: number (1 or 2)  OUT: ax
 LABELS: @@1,@@2,@@3  MODIFIES: ax,dx,cx
 pozn. je uplne stejna jako joystickx, jen s operuje s jinou hodnotou ah}
asm {joystickY}
 cli            {zakaze maskovatelne preruseni}
 mov  al,number {snazi se dostat do ah dvojku, kdyz number=1 nebo osmicku, kdyz number=2}
 mul  al        {umocnime number na druhou a vynasobime dvema, takze pro 1 je to 1*1=1, pro 2 je to 2*2=4}
 shl  al,1      {my ale potrebujem dostat hodnoty dvakrat vetsi a proto vynasobime al dvema}
 mov  ah,al     {v al je nyni 2*number*number. Soupneme ho tedy do ah}
 mov  dx,c_JOYSTICKPORT {do dx dame cislo portu joysticku}
@@1:            {nejdrive pockame, dokud nebude port vracet nulu}
 in   al,dx     {nacteme hodnotu z portu dx do al}
 cmp  al,0      {porovname ho s nulou}
 jnz  @@1       {jestlize se lisi al od nuly, skoci na @@1, jinak pokracuje}
 out  dx,al     {posleme hodnotu registru al na port dx}
 mov  cx,0      {nastavime cx na pocatecni hodnotu}
@@2:
 in   al,dx     {precteme data z portu dx a ulozime je do al}
 inc  cx        {zvysime hodnotu citace}
 jcxz @@3       {jestlize cx prosel vsechna cisla od 0..$FFFF tak radsi skoncime}
 test al,ah     {testujeme, jestli al (nactena hodnota) ma ah-ty bit roven jednicce}
 jnz  @@2       {pokud ano, pak se cyklus opakuje, pokud ne..}
@@3:
 dec  cx        {v cx je nyni skutecny pocet cyklu, ktere beh programu projel}
 sti            {znovu povoli maskovatelne preruseni}
 mov  ax,cx     {vlozime do vystupu hodnotu citace}
{Pozn. Tento zpusob je zavisly na vykonu a typu procesoru.}
end;{joystickY}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function ju:boolean; {"J"oystick "U"p?}
var sax:word;
begin {ju}
 if not isjoy then begin  ju:=false; exit end;
 sax:=asb(joyy div 4,0,319); sax:=asb(joyy div 4,0,319);
 if sax<mem[0:$4F0] then ju:=true else ju:=false;
end; {ju}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function jd:boolean; {"J"oystick "D"own?}
var sax:word;
begin {jd}
 if not isjoy then begin  jd:=false; exit end;
 sax:=asb(joyy div 4,0,319); sax:=asb(joyy div 4,0,319);
 if sax>mem[0:$4F0] then jd:=true else jd:=false;
end;  {jd}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function jl:boolean; {"J"oystick "L"eft?}
var sax:word;
begin {jl}
 if not isjoy then begin  jl:=false; exit end;
 sax:=asb(joyx div 4,0,319); sax:=asb(joyx div 4,0,319);
 if sax>mem[0:$4F0] then jl:=true else jl:=false;
end;  {jl}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function jr:boolean; {"J"oystick "R"ight?}
var sax:word;
begin {jr}
 if not isjoy then begin  jr:=false; exit end;
 sax:=asb(joyx div 4,0,319); sax:=asb(joyx div 4,0,319);
 if sax>mem[0:$4F0] then jr:=true else jr:=false;
end;  {jr}
