{
 Ukazka prace s INI souborem, nastavenim grafickeho modu, bitmapou, fontem,
 handlerem klavesnice.
 Vyzaduje soubory PRIKLAD.INI, MODERN.FN.
 V souboru define.inc musi byt zapnut autoinit.
 ---
 Program nastavi mod 640x480 a necha te hybat mysi. Mezitim
 na pozadi pribyvaji ctverecky. Skonci po stisku libovolne klavesy
 a ulozi si do INI souboru polohu mysi.
 Tu priste nacte a mys se objevi tam kdes ji posledne nechal.
}

{$m 10000,100000,100000} 

Uses Chyby,Sys,Mys,Ini,Vga,Fonty,Key;

Var s    :TScreen;{obrazovka}
    b    :PBitmap;{nejaka bitmapka}
    f    :PFont;  {nejaky font}
    mx,my:integer;{poloha mysi}
    i    :word;
    x,y,r,dx,dy:real;{promenne pro vypocty pohybu se setrvacnosti}

Const
    napis:string[6]='Ahoj!';
    mezer:word=0;
    sirmez:word=0;

Procedure Vars;assembler;
{Seznam promennych v INI souboru.
 SYNTAXE: nazev malymi pismeny,0,flags,typ,offset promenne v datasegmentu;
          uplne na konci nula}
 asm
  db 'mys.x'     ,0,i_wral,i_intg;dw offset mx         {mistni promenne}
  db 'mys.y'     ,0,i_wral,i_intg;dw offset my
  db 'mousespeed',0,     0,i_word;dw offset MouseSpeed {globalni promenna z vga}
  db 0
 end;

Begin
 {zavesi handler klavesnice}
 {v teto ukazce pouze kvuli cteni leveho shiftu}
 Int9Handler(true);

 {cte promenne z ini}
 iniSetup(nil,nil,@vars);
 iniRead('priklad.ini');

 {nahraje si do pameti nejaky font}
 {v teto ukazce kvuli vypsani Ahoj!}
 f:=CFontGet(fnDefault);
 if f=nil then erFile(fnDefault);

 {nastavi nejaky mod (nejblizsi k tomuto rozliseni)}
 {muzes si zkusit jine packed a unchained mody}
 if not s.Init(model_packed,640,480,0) then Halt(erBadMode);

 {nastavi polohu mysi tak, jak ji nacet z priklad.ini}
 s.MouseSetPos(mx,my);

 {vygeneruje bitmapku s napisem}
 New(b,Init(model_packed,50,50));    {alokuje malou bitmapku}
 if b=nil then Halt(erLowMem);       {pri neuspechu skonci}
 b^.Col2Ful(20);                     {vyplni ji jednou barvou}
 b^.Col2Box(1,1,47,47,31);           {vnitrek vyplni jinou}
 b^.Col2Box(2,2,44,44,32);           {vnitrek vyplni jinou}
 OutText(length(napis),@napis[1],mezer,sirmez,b,7,27,f,0,31);

 {nastavi na karte paletu sipky}
 s.MousePalShow;

 {inicializace pohybu}
 dx:=1000;
 dy:=0;
 x:=100;
 y:=200;

 {dokud nezareagujes, neco dela}
 while not keypressed and (mouseGetPress=0) do begin
   r:=sqrt(x*x+y*y)+1;                     {vygeneruje nejake souradnice}
   dx:=dx-r/100*x+random(100)-50;
   dy:=dy-r/100*y+random(100)-50;
   x:=x+dx/101;
   y:=y+dy/100;
   s.MouseHide;                            {skryje sipku}
   s.BtF2Box(b,s.Xres div 2+round(x),      {hodi bitmapku na obrazovku}
               s.Yres div 2+round(y));
   s.MouseShow;                            {zobrazi sipku}
   if not kPressed[kLShift]                {neni-li stisknut levy shift}
    then s.Sync;                           {ceka na paprsek a obslouzi mys}
   end;

 {uvolni bitmapku}
 {btw, zde neni nutne, po skonceni programu se pamet odalokuje automaticky}
 b^.Free;

 {nacte polohu mysi do promennych, ktere pote ulozi do INI}
 mx:=s.mouseX;
 my:=s.mouseY;

 {vrati puvodni (textovy) mod}
 s.Done;

 {zahodi font}
 {btw, zde neni nutne, po skonceni programu se pamet odalokuje automaticky}
 CFontLeave(f);

 {zapise promenne do ini}
 iniWrite('priklad.ini',0);

 {odpoji handler klavesnice}
 Int9Handler(false);

 {vyprazdni buffer klavesnice a skonci}
 FlushKey;
 writeln('Bye!');
End.
