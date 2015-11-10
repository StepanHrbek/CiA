unit Joy;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
interface
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
type
 t_joyNumber=1..2;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
const
 GamePortPresent:boolean=false;
 JoystickPresent:array [t_joyNumber] of boolean=(false,false);
 {Souradnice a tlacitka joysticku se daji zjistovat dvema zpusoby:
  Bud' pres port joysticku a nebo pres INT 15h. Metoda pres port me pripada
  spolehlivejsi, metoda pres INT 15h se zase zda byt rychla a nezavisla na
  rychlosti pocitace, ale nekdy zlobi. Je jen na Vas, jak si vyberete.}
 JoySouradnicePresPort:boolean=true;
 JoyTlacitkaPresPort:boolean=true;
 SelectedJoystick:byte=0; {0=zadny, jinak viz. t_joyNumber.}
 {Doufam, ze nebude vadit, kdyz pouziju par defajnu..}
 {$DEFINE CarefulJoystick}
   {Pred akci ceka nez klesne hodnota portu na nulu.
    Pokud neklesa podezrele dlouho, vrati false resp. -1 a skonci.
    Po ziskani hodnoty jeste radsi nepatrnou chvilicku ceka.}
 {$DEFINE SafeJoystick}
   {Zakaze maskovatelne preruseni behem hlavni smycky. Nevim, jestli je nutny,
    ale nekde jsem to videl, takze jsem tam tuto moznost radsi dal.}
 {konstanty pro SetupJoystick}
 c_joySetupResetVariables=0;
 c_joySetupPromtUpLeft   =1;
 c_joySetupPromtDownRight=2;
 c_joySetupPromtCenter   =3;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function JoyPriButton(number:t_joyNumber):boolean;
function JoySecButton(number:t_joyNumber):boolean;
function JoyX(number:t_joyNumber):word;
function JoyY(number:t_joyNumber):word;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
implementation
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
const
 c_JoystickPort =$201; {port joysticku}
 c_JoyFunction  =$84;  {Funkce preruseni 15h}
 c_Joy1X        =1 shl 0;
 c_Joy1Y        =1 shl 1;
 c_Joy2X        =1 shl 2;
 c_Joy2Y        =1 shl 3;
 c_Joy1PriButton=1 shl 4;
 c_Joy1SecButton=1 shl 5;
 c_Joy2PriButton=1 shl 6;
 c_Joy2SecButton=1 shl 7;
 c_MaxCount=10000;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
var
 JoyXMin,JoyXMax,JoyYMin,JoyYMax,JoyXCenter,JoyYCenter:word;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function JoyPriButton(number:t_joyNumber):boolean; assembler;
asm {JoyPriButton}
 cmp  JoyTlacitkaPresPort,false
 jne  @2
 mov  ah,c_Joy2PriButton
 cmp  number,1
 je   @1
 mov  ah,c_Joy1PriButton
@1:
 mov  dx,c_JoystickPort
 {$IFDEF CarefulJoystick}
 mov  cx,c_MaxCount
@cj:
 dec  cx
 jcxz @cjout
 in   al,dx
 cmp  al,0
 je   @cj
@cjout:
 cmp  cx,0
 jne  @cjcontinue
 xor  ax,ax
 jmp  @end
@cjcontinue:
 {$ENDIF}
 out  dx,al
 in   al,dx
 and  al,ah
 jmp  @end
@2:
 mov  ah,84h
 xor  dx,dx
 int  15h
 mov  ah,c_Joy2PriButton
 cmp  number,1
 je   @3
 mov  ah,c_Joy1PriButton
@3:
 and  al,ah
@end:
 {$IFDEF CarefulJoystick}
 mov  cx,10
@wait:
 nop
 loop @wait
 {$ENDIF}
end;{JoyPriButton}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function JoySecButton(number:t_joyNumber):boolean; assembler;
asm {JoySecButton}
 cmp  JoyTlacitkaPresPort,false
 jne  @2
 mov  ah,c_Joy2SecButton
 cmp  number,1
 je   @1
 mov  ah,c_Joy1SecButton
@1:
 mov  dx,c_JoystickPort
 {$IFDEF CarefulJoystick}
 mov  cx,c_MaxCount
@cj:
 dec  cx
 jcxz @cjout
 in   al,dx
 cmp  al,0
 je   @cj
@cjout:
 cmp  cx,0
 jne  @cjcontinue
 xor  ax,ax
 jmp  @end
@cjcontinue:
 {$ENDIF}
 out  dx,al
 in   al,dx
 and  al,ah
 jmp  @end
@2:
 mov  ah,c_JoyFunction
 xor  dx,dx
 int  15h
 mov  ah,c_Joy2SecButton
 cmp  number,1
 je   @3
 mov  ah,c_Joy1SecButton
@3:
 and  al,ah
@end:
 {$IFDEF CarefulJoystick}
 mov  cx,10
@wait:
 nop
 loop @wait
 {$ENDIF}
end;{JoySecButton}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function JoyX(number:t_joyNumber):word; assembler;
{Pozn. Hodnota teto funkce je zavisla na rychlosti pocitace.}
asm {JoyX}
 cmp  JoySouradnicePresPort,false
 je   @3
 mov  ah,c_Joy1X
 cmp  number,1
 je   @1
 mov  ah,c_Joy2X
@1:
 mov  dx,c_JoystickPort
 {$IFDEF CarefulJoystick}
 mov  cx,c_MaxCount
@cj:
 dec  cx
 jcxz @cjout
 in   al,dx
 cmp  al,0
 je   @cj
@cjout:
 cmp  cx,0
 jne  @cjcontinue
 mov  ax,0FFFFh
 jmp  @end
@cjcontinue:
 {$ENDIF}
 mov  cx,0FFFFh
 out  dx,al
 {$IFDEF SafeJoystick} sti {$ENDIF}
@2:
 in   al,dx
 inc  cx
 test al,ah
 jnz  @2
 {$IFDEF SafeJoystick} cli {$ENDIF}
 mov  ax,cx
 jmp  @end
@3:
 mov  al,c_JoyFunction
 mov  dx,1
 int  15h
 cmp  number,1
 je   @end
 mov  ax,cx
@end:
 {$IFDEF CarefulJoystick}
 mov  cx,10
@wait:
 nop
 loop @wait
 {$ENDIF}
end;{JoyX}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function JoyY(number:t_joyNumber):word; assembler;
{Pozn. Hodnota teto funkce je zavisla na rychlosti pocitace.}
asm {JoyY}
 cmp  JoySouradnicePresPort,false
 je   @3
 mov  ah,c_Joy1Y
 cmp  number,1
 je   @1
 mov  ah,c_Joy2Y
@1:
 mov  dx,c_JoystickPort
 {$IFDEF CarefulJoystick}
 mov  cx,c_MaxCount
@cj:
 dec  cx
 jcxz @cjout
 in   al,dx
 cmp  al,0
 je   @cj
@cjout:
 cmp  cx,0
 jne  @cjcontinue
 mov  ax,0FFFFh
 jmp  @end
@cjcontinue:
 {$ENDIF}
 mov  cx,0FFFFh
 out  dx,al
 {$IFDEF SafeJoystick} sti {$ENDIF}
@2:
 in   al,dx
 inc  cx
 test al,ah
 jnz  @2
 {$IFDEF SafeJoystick} cli {$ENDIF}
 mov  ax,cx
 jmp  @end
@3:
 mov  al,c_JoyFunction
 mov  dx,1
 int  15h
 mov  ax,bx
 cmp  number,1
 je   @end
 mov  ax,dx
@end:
 {$IFDEF CarefulJoystick}
 mov  cx,10
@wait:
 nop
 loop @wait
 {$ENDIF}
end;{JoyY}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function DetectJoystick(number:t_joyNumber):boolean; assembler;
{Kdyz joystick neni pripojen, jeho port by mel vracet samy jednicky.
 Tato rutina %MaxCount-krat zkousi jestli neklesl bit odpovidajici
 X-ove souradnici joystiku na nulu. Kdyz neklesl a tvrdosijne dal
 vraci jednicky, predpoklada se, ze je joystick odpojen. Pokud mate
 nahodou Pentium ]I[ ci rovnou Silicon GFX a Detect Joystick vam vraci
 false, i kdyz mate joystick pripojen, zkuste zvysit MaxCount.
Pozn. Tato metoda je zavisla na rychlosti pocitace.}
asm {DetectJoystick}
 mov  ah,c_Joy1X
 cmp  number,1
 je   @1
 mov  ah,c_Joy2X
@1:
 mov  dx,c_JoystickPort
 {$IFDEF CarefulJoystick}
 mov  cx,c_MaxCount
@cj:
 dec  cx
 jcxz @cjout
 in   al,dx
 cmp  al,0
 je   @cj
@cjout:
 cmp  cx,0
 jne  @cjcontinue
 xor  ax,ax
 jmp  @end
@cjcontinue:
 {$ENDIF}
 mov  cx,c_MaxCount
 out  dx,al
 {$IFDEF SafeJoystick} sti {$ENDIF}
@2:
 in   al,dx
 dec  cx
 jcxz @3
 test ah,al
 jnz  @2
@3:
 {$IFDEF SafeJoystick} cli {$ENDIF}
 mov  ax,cx
@end:
 {$IFDEF CarefulJoystick}
 mov  cx,10
@wait:
 nop
 loop @wait
 {$ENDIF}
end;{DetectJoystick}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
function GameAdapterPresent:boolean; assembler;
{Tato metoda udajne neni z nejspolehlivejsich, ale jiny zpusob neznam}
asm {GameAdapterPresent}
 int  11h
 and  ah,10h
 mov  al,ah
end;{GameAdapterPresent}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
procedure SetUpJoyStick(akce:byte);
{Tohle funguje nasledovne:
 Pokud se rozhodnete, ze budete pouzivat joystick, zavolate SetUpJoystick(0).
 Zjistite, jestli je Joystick pritomnej, napisete nejakym zpusobem uzivateli,
 aby pohnul joystikem do leveho horniho rohu a tam stiskl jeho tlacitko, a
 zavolate SetUpJoyStick(1). Pak napisete, aby pohl joystickem dolu doprava a
 zavolate SetUpJoyStick(2). Nakonec napisete, aby joystick vycentroval a
 zavolate SetUpJoyStick(3). Tak budou nastaveny hodnoty JoyX/Y-Min/Max/Center.
>Napadlo me, ze po zavolani teto procedury nebude mit uzivatel moc prostoru
 na interakci (hejbani mysi, eventy..), takze by mozna bylo lepsi, kdyby si
 uzivatel repeat..until cykly z teto procedury opsal do jeho programu a tam
 do nej nacpal, co by uznal za vhodny. Potom by, ovsem, mely repeat..until
 cykly z tyto procedury zmizet.}
begin {SetUpJoyStick}
 case akce of
 c_joySetupResetVariables:
    begin {(re)setting promennych souvisejicich s joystickem}
     GamePortPresent:=GameAdapterPresent; {GamePort budu radsi ignorovat a spolehat se na DetectJoystick}
     JoystickPresent[1]:=DetectJoystick(1);
     JoystickPresent[2]:=DetectJoystick(2);
     SelectedJoystick:=byte(JoystickPresent[1])+byte(JoystickPresent[2] and not(JoystickPresent[1])) shl 1;
    end;
 c_joySetupPromtUpLeft:
    if SelectedJoystick>0
    then
     begin {predpoklada, ze paka je pohnuta do leveho horniho rohu}
      repeat until not(JoyPriButton(SelectedJoystick) or JoySecButton(SelectedJoystick));
      JoyXMin:=JoyX(SelectedJoystick); JoyYMin:=JoyY(SelectedJoystick)
     end;
 c_joySetupPromtDownRight:
    if SelectedJoystick>0
    then
     begin {predpoklada, ze paka je pohnuta do praveho dolniho rohu}
      repeat until not(JoyPriButton(SelectedJoystick) or JoySecButton(SelectedJoystick));
      JoyXMax:=JoyX(SelectedJoystick); JoyYMax:=JoyY(SelectedJoystick)
     end;
 c_joySetupPromtCenter:
    if SelectedJoystick>0
    then
     begin {predpoklada, ze paka je ve ztoporene poloze}
      repeat until not(JoyPriButton(SelectedJoystick) or JoySecButton(SelectedJoystick));
      JoyXCenter:=JoyX(SelectedJoystick); JoyYCenter:=JoyY(SelectedJoystick)
     end
 end
end;  {SetUpJoyStick}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
{Ted' jeste zbyva to nejdulezitejsi - funkce pro *skutecne* souradnice
 joystiku a booleanovske funkce pro ctryri hlavni smery nakloneni paky.
 Btw, na programovani joysticku je neprijemnych par veci - za prvy, rutiny
 pro zjisteni souradnic jsou zavisle na rychlosti pocitace (napr. JoyXMax
 je u 286-ky 200, u 386-ky 500, u 486-ky 980 a u Pentia 2100).
 Za dalsi, rozsah souradnic neni linearni! Plati priblizne, ze polovina
 visualne = tretina podle souradnic joysticku. A to je peknej humus :).
 A za dalsi jsem se prave ted' dozvedel, ze DMA prenosy vyrazne snizi
 spolehlivost joystiku. A jeste jsem se dozvedel, ze se JoyX/YCenter
 diferencialne snizuji asi na 97% hodnot namerenych pri zapnuti pocitace(!)
 Jestli chces, budu 'zahrivani' pocitace brat v uvahu. 
 Mimochodem, funkce JoyX a JoyY nejsou zrovna dvakrat spolehlivy; cas od casu
 vraceji bludne vysledky. Chci jeste udelat higher-level funkce, ktere by
 mely ty bludy vyskrtavat. Btw, jak budes chtit ty souradnice? Napadlo me,
 ze kdyz joystick nema striktne dane rozmezi souradnic, neni tim padem
 zavisly na rozliseni, takze v kazdem bude fungovat (to je asi jedina jeho
 vyhoda). Takze bych Ti misto nejake souradnice mohl vracet realne cislo
 mezi nulou a jednickou, kde nula by bylo uplne nahore nebo nalevo a jednicka
 uplne dole nebo napravo. Jen mam starost, aby to nebylo dost pomaly, zvlast 
 na slabejch pocitacich, ktery budou navic bez FPU. Anebo bych Ti misto
 toho realnyho cisla mohl zvracet word od 0 do 65535, resp byte od 0..255.}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
begin
end.
{Napis mi o vsech chybach, na ktery prijdes.
 Myslim, ze bude lepsi, kdyz si design unity upravis podle svyho
 gusta. Tim myslim vzhled (ja bych moh' treba na neco zapomenout) }
