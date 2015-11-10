{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

 Priklad: vse v jednom

 Ukazka prace s nastavenim grafickeho modu, bitmapou, fontem,
 handlerem klavesnice, INI souborem.
 Vyzaduje soubory PRIKLAD.INI, MODERN.FN.
 V souboru define.inc musi byt zapnut autoinit a autodone.
 ---
 Program nastavi mod 640x480 a necha te hybat mysi. Mezitim
 na pozadi pribyvaji ctverecky. Skonci po stisku libovolne klavesy
 a ulozi si do INI souboru polohu mysi.
 Tu priste nacte a mys se objevi tam kdes ji posledne nechal.

}

{$M 10000,0,40000}
{$i define.inc}

Uses Chyby,Memo,Objects,Strings,Sys,Ini,Vga,Cache,Fonty,Key,Lang1;

Var s      :TScreen;{obrazovka}
    ahoj   :PBitmap;{nejaka bitmapka}
    f      :PFont;  {nejaky font}
    mx,my  :integer;{poloha mysi}
    i      :word;
    x,y,r,dx,dy:real;{promenne pro vypocty pohybu se setrvacnosti}
    event  :TEvent;
    pos    :TPoint;

Const
    napis  ='Ahoj!';

Procedure Vars;assembler;
{Seznam promennych v INI souboru.
 Podporovane typy a flagy jsou nadeklarovane na zacatku ini.pas.
 SYNTAXE: nazev malymi pismeny,0,flags,typ,offset promenne v datasegmentu;
          uplne na konci nula}
 asm
  db 'mys.x'     ,0,0,i_intg;dw offset mx         {mistni promenne}
  db 'mys.y'     ,0,0,i_intg;dw offset my
  db 'mousespeed',0,0,i_byte;dw offset MouseSpeed {globalni promenna z vga}
  db 0
 end;

Begin
 {zavesi handler klavesnice}
 {v teto ukazce pouze kvuli cteni leveho shiftu}
 kSetHandler(true);

 {cte promenne z ini}
 iniSetup(nil,@vars);
 iniRead('priklad.ini');

 {nahraje si do pameti nejaky font}
 {v teto ukazce kvuli vypsani Ahoj!}
 f:=cacheGetFont(fnDefault);
 if f=nil then Halt(_erWritten);

 {nastavi nejblizsi graficky mod, vyzkousej si ruzna rozliseni a modely}
 if not s.Init(model_gfx,640,480,0) then Halt(_erBadMode);
 {kdybys chtel nastavit konkretni mod a zadny jiny, volej init treba takto:
  if not s.Init(model_packed,0,0,P640x480) then Halt(erBadMode);
  viz seznam modelu a modu na zacatku vga.pas}

 {nastavi polohu mysi tak, jak ji nacet z priklad.ini}
 s.MouseSetPos(mx,my);

 {vygeneruje bitmapku s napisem}
 New(ahoj,Init(s.MapModel,50,50));                {alokuje malou bitmapku}
 if ahoj=nil then Halt(erLowMem);                 {pri neuspechu skonci}
 ahoj^.Col2Ful(s.Color(255,255,255,255));         {vyplni ji jednou barvou}
 ahoj^.Col2Box(1,1,47,47,s.Color(0,0,0,255));     {vnitrek vyplni jinou}
 ahoj^.Col2Box(2,2,44,44,s.Color(0,0,210,255));   {vnitrek vyplni jinou}
 OutStr(napis,ahoj,7,27,f,0,s.Color(255,255,255,255));{pise napis}

 {rozsviti paletu}
 s.Fade(+0);

 {inicializace pohybu}
 dx:=1000;
 dy:=0;
 x:=100;
 y:=200;

 {dokud nezareagujes, neco dela}
 {btw, kdyz GetEvent skonci uspechem, mas udalost ulozenou v event a pos}
 while not s.GetEvent(event,pos) do begin
   r:=sqrt(x*x+y*y)+1;                     {vygeneruje nejake souradnice}
   dx:=dx-r/100*x+random(100)-50;
   dy:=dy-r/100*y+random(100)-50;
   x:=x+dx/101;
   y:=y+dy/100;
   s.MouseHide;                            {skryje sipku}
   s.BtF2Box(ahoj,word(s.Xres div 2+round(x)),{hodi bitmapku na obrazovku}
                  word(s.Yres div 2+round(y)));
   s.MouseShow;                            {zobrazi sipku}

   if not kPressed[kLShift]                {neni-li stisknut levy shift}
    then s.Sync;                           {ceka na paprsek a obslouzi mys}

   end;

 {uvolni bitmapku "ahoj"}
 KillObj(ahoj);

 {nastavi polohu mysi do promennych, ktere pote ulozi do INI}
 mx:=s.mouse.X;
 my:=s.mouse.Y;

 {vrati puvodni (textovy) mod}
 s.Done;

 {zahodi font}
 caLeave(f);

 {zapise promenne do ini}
 iniWrite('priklad.ini',0);

 {odpoji handler klavesnice}
 {btw, neni nutne, odpojeni je v autodone}
 kSetHandler(false);

 {rozlouci se}
 writeln('Bye!');
End.