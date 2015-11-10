{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      FnExpand;
Interface {$i define.inc}
Uses      Chyby,Memo,Sys,Stringy,Vga,Fonty,Mys;

{
  Objekt pro podporu editoru a konvertoru .FN fontu, umoznuje
   - expandovat prekryvajici se znaky do samostatnych velkych bitmap
   - spakovat znaky s vyuzitim prekryvani do co nejmensiho prostoru
}

Type      TExpandedFont = object(TFont)
                     fontname2 :string;    {nazev fontu}
                     tablo2    :TFontTable;{tabulku informaci o vsech znacich}
                     chars     :word;
                     maxsir    :byte;      {maximalni sirka znaku; maxza-maxpred}
                     maxvys    :byte;      {maximalni vyska znaku; maxpod-maxnad}
                     fontmap   :PBitmap;   {mapa fontu, 1pixel=1byte}
                     function  Expand(fontsir,fontvys:byte):boolean;
                     procedure ScanBounds;
                     procedure CharCopy(src,dest:char);
                     procedure CharClear(c:char);
                     procedure Edit;
                     function  Shrink:boolean;
                     procedure MakeProporc;
                     procedure MakeNoprop(width:byte);
                     procedure DetectSize;
                   end;



{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
                          IMPLEMENTATION
{ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ}


{---------------------------------------------------------------------------
 Roztahne font z minimalniho objemu pameti do pohodlnych velkych struktur
 vhodnych k editaci fontu. Nejdulezitejsi vyhodou je prechod na konstantne
 velke bitmapy pismen. Velikost bitmap lze bud pevne zadat nebo
 pri vstupu 0 nechat nejmensi mozne (bez rezerv na okrajich).
 Pri prevodu snizi relX,Y vsech znaku v tablu2 o maxpred,nad.
 Vraci uspesnost.
 ---------------------------------------------------------------------------}
function  TExpandedFont.Expand(fontsir,fontvys:byte):boolean;
var   c       :char;
      i,j,k   :integer;
      b       :^byte;
      srcbyte :byte;
      destadr :word;
      sir8:byte;
begin
 expand   :=false;
 {stanovi jaka bude maximalni velikost bitmap}
 maxsir:=maxza-maxpred;
 maxvys:=maxpod-maxnad;
 if fontsir>maxsir then maxsir:=fontsir;
 if fontvys>maxvys then maxvys:=fontvys;
 {zkopci name}
 fontname2:=Pc2Str(fontname);
 {nastavi chars}
 chars    :=ord(lastchar)-ord(firstchar)+1;
 {zkopci tablo}
 fillchar(tablo2,sizeof(tablo2),0);
 move(tablo^[firstchar],tablo2[firstchar],sizeof(Tcharinfo)*chars);
 {opravi tablo tak aby nebyla zaporna relX,Y}
 for c:=firstchar to lastchar do
  with tablo2[c] do begin
    dec(relX,maxpred);
    dec(relY,maxnad);
    end;

 {naalokuje pamet pro fontmapu plne velikosti}
 new(FontMap,Init(model_packed,maxsir*maxvys,256));
 if FontMap=nil then exit;

 {vynuluje pamet}
 FontMap^.Clr2Ful;

 {zkopci data z levyho horniho rohu all na spravny misto ve fontmap}
 for c:=firstchar to lastchar do
  with tablo2[c] do begin
    sir8:=(sirb+7) shr 3;
    for j:=0 to vysb-1 do
     for i:=0 to sirb-1 do
      FontMap^.Tab^[ord(c)]^[(j+rely)*maxsir+(i+relx)]
       :=mem[seg(all^):tablo2[c].ofsb+(j*sir8+i shr 3)] shr (7-(i and 7)) and 1;
    end;

 {najde hranice bitmap}
 ScanBounds;

 {hotovo}
 expand   :=true;
end;


{---------------------------------------------------------------------------
 Projde expandovanou bitmapu fontu a nastavi okraje pismen.
 ---------------------------------------------------------------------------}
Procedure TExpandedFont.ScanBounds;
var   c:char;
      x,y,minx,miny,maxx,maxy    :integer;
label 1,2,3,4;
begin
 for c:=firstchar to lastchar do with tablo2[c] do begin

   {zameri vrsek bitmapy}
   for miny:=0 to maxvys-1 do
    for x:=0 to maxsir-1 do
     if FontMap^.Tab^[ord(c)]^[maxsir*miny+x]<>0 then goto 1;
   {nasel prazdnou bitmapu}
   relx  :=0;
   rely  :=0;
   sirb  :=0;
   vysb  :=0;
   continue;{jde na dalsi char}
   1:

   {zameri spodek bitmapy}
   for maxy:=maxvys-1 downto 0 do
    for x:=0 to maxsir-1 do
     if FontMap^.Tab^[ord(c)]^[maxsir*maxy+x]<>0 then goto 2;
   2:

   {zameri levej kraj bitmapy}
   for minx:=0 to maxsir-1 do
    for y:=miny to maxy do
     if FontMap^.Tab^[ord(c)]^[maxsir*y+minx]<>0 then goto 3;
   3:

   {zameri pravej kraj bitmapy}
   for maxx:=maxsir-1 downto 0 do
    for y:=miny to maxy do
     if FontMap^.Tab^[ord(c)]^[maxsir*y+maxx]<>0 then goto 4;
   4:

   {nastavi charinfo parametry jako relx,rely..}
   relx  :=minx;
   rely  :=miny;
   sirb  :=1+maxx-minx;
   vysb  :=1+maxy-miny;

   end;
end;

procedure TExpandedFont.CharCopy(src,dest:char);
begin
 tablo2[dest]:=tablo2[src];
 move(FontMap^.Tab^[ord(src)]^,FontMap^.Tab^[ord(dest)]^,maxsir*maxvys);
end;

procedure TExpandedFont.CharClear(c:char);
begin
 fillchar(tablo2[c],sizeof(tablo2[c]),0);
 fillchar(FontMap^.Tab^[ord(c)]^,maxsir*maxvys,0);
end;

{---------------------------------------------------------------------------
 Srazi font do minimalniho objemu pameti. Ve vyslednem stavu je snadno
 citelny(pouzitelny), ale nelze editovat. Metoda nemeni shifty, predpoklada
 ze pri editaci znaku nastavis i jeho sirku.
 Pri prevodu zvysi relX,Y vsech znaku o maxpred,nad.
 Vraci uspesnost.
 ---------------------------------------------------------------------------}
function  TExpandedFont.Shrink:boolean;

  procedure MyWrite(st:string);
  begin
   {BiosWrite(st);}
  end;

  type Tinfo = record
                vrsekf  :boolean; {je vrsek znaku nezanoren do jineho?}
                spodekf :boolean; {je spodek znaku nezanoren do jineho?}
                inchar  :char;    {vrsek je zanoren uvnitr znaku chara}
                inY     :byte;    {konkretne od teto souradnice Y}
                uvnitr  :byte;    {je v jinem znaku zanoren 0=vubec,1=castecne,2=zcela,3=prazdnyznak/done}
              end;
      Tinfoarr = array[#0..#255] of Tinfo;
  var info                       :^Tinfoarr;
      c,d,e,f,g                  :char;
      x,y                        :integer;
      line,line0                 :word;
      tablobytes                 :word;
      sir8                       :byte;
      b                          :^byte;
      srcadr,destadr             :word;
      srcbyte                    :byte;
      buf                        :Pline;
      buflen                     :longint;
      p1,p2                      :pointer;

  procedure VnorDo(c:char);
  var d:char;
  begin
   info^[c].uvnitr:=3;
   for d:=firstchar to lastchar do with info^[d] do
    if (uvnitr=2) and (inchar=c) then begin
      tablo2[d].ofsb:=tablo2[c].ofsb+inY*sir8;
      MyWrite(d);
      VnorDo(d);
      end;
  end;

label 11,uzjeinside;
begin
 shrink   :=false;

 {odalokuje puvodni spakovny data}
 Done;

 {zdetekuje firstchar,lastchar}
 {*}
 tablobytes:=sizeof(Tcharinfo)*chars;


 {naalokuje pomocnej databuffer velikosti 256 znaku}
 buflen:=longint(maxsir*maxvys)*256;
 if buflen>65520 then buflen:=65520;
 if not GetMem(pointer(buf),buflen) then exit;
 fillchar(buf^,buflen,0);

 {najde hranice bitmap}
 ScanBounds;


 {naalokuje infoarray pro stesnavani bitmap do sebe}
 if not GetMem(pointer(info),sizeof(info^)) then exit;

 {napakuje bitmapy do co nejmensiho prostoru:}
 {oznaci si okraje bitmap za kterymi muze byt cokoliv (jina bitmapa)}
 for c:=firstchar to lastchar do
  with info^[c] do begin
   inchar     :=#0;{pro jistotu}
   inY        :=0; {pro jistotu}
   if tablo2[c].vysb=0 then begin
     vrsekf   :=false;
     spodekf  :=false;
     uvnitr   :=3; {prazdne znaky oznacim za nezajimave}
     end
    else begin
     vrsekf   :=true;
     spodekf  :=true;
     uvnitr   :=0;{ostatni znaky oznacim za dosud nezanorene}
     end;
   end;

 {hleda mista kde je jeden znak cely uvnitr jineho znaku}
 for c:=firstchar to lastchar do begin
   with info^[c] do
    if vrsekf and spodekf then{c je maly znak uvnitr}
     for d:=firstchar to lastchar do
      if (info^[d].uvnitr<2){d neni plne vnorenej ani prazdnej}
      and (d<>c) and (tablo2[c].sirb=tablo2[d].sirb){c,d ruzny stejne siroky znaky}
      and (tablo2[d].vysb>=tablo2[c].vysb){d je vyssi nez c}
      and (((tablo2[d].sirb+7) shr 3)=((tablo2[c].sirb+7) shr 3)){maji stejne linebytes}
      then{d je velky znak kolem}
       for line0:=0 to tablo2[d].vysb-tablo2[c].vysb do begin
        with tablo2[c] do p1:=@FontMap^.Tab^[ord(c)]^[maxsir*rely+relx];
        with tablo2[d] do p2:=@FontMap^.Tab^[ord(d)]^[maxsir*(rely+line0)+relx];
        if CmpBlock({c[0]}p1,
                    {d[line0]}p2,
                    {sizeof(c)}tablo2[c].vysb*maxsir) then
         begin
         {kraje c oznaci za zablokovane, protoze za nimi musi lezet d}
         vrsekf  :=false;
         spodekf :=false;
         {zapamatuje si ze c je uvnitr d}
         inchar  :=d;
         inY     :=line0;
         uvnitr  :=2;
         goto uzjeinside;
         end;
        end;
   uzjeinside:
   end;
 {hleda mista kde se konec jednoho znaku rovna zacatku jineho znaku}
 {*}


 {spocita velikost headeru vcetne tabla}
 allsize:=fnmagiclen+length(fontname2)+1+4+1+1+tablobytes;

 {smestna do nej data}
 MyWrite('compress_log(');
 destadr:=0;
 for c:=firstchar to lastchar do
  with tablo2[c] do
   with info^[c] do
    if uvnitr<2 then begin
      ofsb:=allsize+destadr;
      sir8:=(sirb+7) shr 3;
      for y:=0 to vysb-1 do begin
        for x:=0 to sirb-1 do
         if FontMap^.Tab^[ord(c)]^[maxsir*(y+rely)+(x+relx)]>0 then
          buf^[destadr+x shr 3]:=buf^[destadr+x shr 3] or (128 shr (x and 7));
        inc(destadr,sir8);
        end;
      VnorDo(c);
{
      info^[c].uvnitr:=3;
      for d:=firstchar to lastchar do with info^[d] do
       if (uvnitr=2) and (inchar=c) then begin
         tablo2[d].ofsb:=tablo2[c].ofsb+inY*sir8;
         uvnitr:=3;
         MyWrite(d);
         for e:=firstchar to lastchar do with info^[e] do
          if (uvnitr=2) and (inchar=d) then begin
            tablo2[e].ofsb:=tablo2[d].ofsb+inY*sir8;
            uvnitr:=3;
            MyWrite(' <'+e+'> ');
            for f:=firstchar to lastchar do with info^[f] do
             if (uvnitr=2) and (inchar=e) then begin
               tablo2[f].ofsb:=tablo2[e].ofsb+inY*sir8;
               uvnitr:=3;
               MyWrite(' <<'+f+'>> ');
               for g:=firstchar to lastchar do with info^[g] do
                if (uvnitr=2) and (inchar=f) then erMsg('Moc vnoreni pri optimalizaci.');
               end;
            end;
         end;}
      end;
 MyWrite(') ');

 {zpetne opravi tablo tak aby v nem zase byla zaporna relX,Y}
 for c:=firstchar to lastchar do
  with tablo2[c] do begin
    inc(relX,maxpred);
    inc(relY,maxnad);
    end;

 {odalokuje infoarray}
 FreeMem(pointer(info),sizeof(info^));

 {odalokuje fontmap}
 dispose(FontMap,Done);
 FontMap:=nil;


 {naalokuje definitivni all}
 inc(allsize,destadr);
 if not GetMem(pointer(all),allsize) then exit;


 {zapise do all vsechno: hlavicku, tablo, data}
 pointer(b):=all;
 move(fnmagic^,b^,fnmagiclen);          inc(b,fnmagiclen);
 move(fontname2[1],b^,length(fontname2));inc(b,length(fontname2));
 b^:=0;                                 inc(b);
 b^:=ord(firstchar);                    inc(b);
 b^:=ord(lastchar);                     inc(b);
 b^:=byte(sizeOver);                    inc(b);
 b^:=byte(sizeUnder);                   inc(b);
 b^:=addspace;                          inc(b);
 b^:=future;                            inc(b);
 move(tablo2[firstchar],b^,tablobytes); pointer(tablo):=b;
                                        dec(word(tablo),sizeof(TCharInfo)*ord(firstchar));
                                        inc(b,tablobytes);
 move(buf^,b^,destadr);                 inc(b,destadr);


 {uvolni pomocnej databuffer}
 FreeMem(pointer(buf),buflen);

 {hotovo}
 shrink   :=true;
end;
{*zabranit cyklickejm navaznostem (udrzet linearni poradi prekrytejch znaku)}



{---------------------------------------------------------------------------
 Editor expandovanych fontu.
 ---------------------------------------------------------------------------}
procedure TExpandedFont.Edit;
var   s:PScreen;

procedure show(c:char);
var   i,j:integer;
begin
 s^.Col2Ful($700+176);
 with tablo2[c] do begin
  for j:=relY to relY+vysb-1 do begin
   s^.gotoxy(20+relX,j);
   for i:=relX to relX+sirb-1 do
    write(chr(32+(fontmap^.tab^[ord(c)]^[j*maxsir+i]*(177-32))));
   end;
  end;
end;

procedure chg(c:char;i,j:integer);
var   b:byte;
begin
 inc(i,tablo2[c].relX);
 inc(j,tablo2[c].relY);
 FontMap^.Tab^[ord(c)]^[j*maxsir+i]:=1-FontMap^.Tab^[ord(c)]^[j*maxsir+i];
end;

var   c,r:char;
      i,j,k,l:integer;
      x,y:integer;
      z:word;
Begin
 New(s,Init(model_text,132,60,0));
 if s<>nil then begin
   c:='a';
   repeat
    show(c);
    with tablo2[c] do begin
      while not keypressed do begin
        {asm mov ax,1;int 33h;end;}
        s^.refresh(5);
        {asm mov ax,2;int 33h;end;}
        mouseGet(x,y,z);
        i:=x;
        j:=y;
        if i>=sirb then i:=sirb-1;
        if j>=vysb then j:=vysb-1;
        if z>0 then begin
          chg(c,i,j);
          show(c);
          end;
        end;
      end;
    r:=readkey;
    case r of #0:;
              ' ':chg(c,i,j);
              else c:=r;
              end;
   until r=#27;
   s^.Done;
   end;
End;


{---------------------------------------------------------------------------
 Ucini font proporcionalnim (v tablu zmeni relX a shift).
 Pozor: proste oreze prazdne okraje, nutne rucni doladeni nekterych znaku.
 Metoda je zamyslena jen pro pomoc pri tvorbe proporc.fontu.
 Volat pred expandem nebo po shrinku.
 ---------------------------------------------------------------------------}
procedure TExpandedFont.MakeProporc;
var   c:char;
      sumsir:word;
      znaku:word;
begin
 {spocita beznou sirku pismene = sirku mezery}
 sumsir:=0;
 znaku:=0;
 for c:=firstchar to lastchar do with tablo^[c] do
  if sirb>0 then begin
    inc(sumsir,sirb);
    inc(znaku);
    end;
 if znaku=0 then sumsir:=0 else sumsir:=sumsir div znaku;
 {nastavi posuny kurzoru}
 for c:=firstchar to lastchar do with tablo^[c] do begin
   relX:=0;
   if sirb>0 then shift:=sirb
             else shift:=sumsir;
   end;
end;

{---------------------------------------------------------------------------
 Ucini font neproporcionalnim (v tablu zkonstantni shift).
 Pozor: na sechno kasle, nutne rucni doladeni nekterych znaku.
 Metoda je zamyslena jen pro pomoc pri tvorbe neproporc.fontu.
 Volat pred expandem nebo po shrinku.
 ---------------------------------------------------------------------------}
procedure TExpandedFont.MakeNoprop(width:byte);
var   c:char;
begin
 {spocita beznou sirku pismene}
 if width=0 then begin
   width:=maxza+1;
   end;
 {nastavi posuny kurzoru}
 for c:=firstchar to lastchar do with tablo^[c] do begin
   shift:=width;
   end;
 addspace:=0;
end;



{---------------------------------------------------------------------------
 Odhadne velikost fontu = o kolik pixelu niz by mela byt druha radka
 textu, aby se to dalo cist.
 Vse potrebne podle toho nastavi.
 Primitivni detekce, mozno vylepsit.
 ---------------------------------------------------------------------------}
procedure TExpandedFont.DetectSize;
var   i:integer;
begin
 {pracuje jen pokud je velikost dosud neznama}
 if sizeOver=0 then begin

   {kolikata linka je hledana cara?}
   if (firstchar<='a') and ('a'<=lastchar) then i:=tablo2['a'].relY+tablo2['a'].vysB
                                           else i:=maxvys*3 div 4;
   {snizi maxnad o toto cislo}
   dec(maxnad,i);
   dec(maxpod,i);

   {nastavi size}
   sizeOver:=i;
   dec(sizeUnder,i);
   end;
end;



END.