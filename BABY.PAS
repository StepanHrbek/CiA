{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      Baby;
Interface {$i define.inc}
Uses      VGA;

{
---------------------------------------------------------------------------
                            Grafika pro deti
---------------------------------------------------------------------------

Tato unita nabizi praci s grafikou co nejjednodussi a nejprehlednejsi formou.

Slovnicek

 memorymapa - Bitmapa v systemove pameti.
 screenmapa - Bitmapa tvorici obrazovku.
 mapa       - Jakakoliv z techto bitmap.
              Temer vsechny procedury pracuji s mapami, tj. se vsim.

 model      - Zpusob ulozeni pixelu, je ruzny napr. pro ruzne bitove hloubky.
              Pokud nevis, zadavej vzdy babyAuto.

 src,dst    - zdroj, cil
 x,y,w,h    - souradnice leveho horniho rohu, sirka a vyska

Unita neprovadi orezavani, souradnice ktere zadavas musi lezet uvnitr map.

}

const     babyAuto=65535;

procedure babySetMode(model,x,y:word);
function  babyScreen:PScreen;
procedure babyRestoreTextmode;

function  babyMapCreate(model,w,h:word):PBitmap;
function  babyMapLoad(picname:string):PBitmap;
procedure babyMapConvert(map:PBitmap;reference:PAbstractMap);
procedure babyMapDestroy(map:PBitmap);

function  babyColor(map:PAbstractMap;r,g,b:byte):longint;
procedure babyRGB(map:PAbstractMap;color:longint;var r,g,b:byte);

function  babyGetPixel(map:PAbstractMap;x,y:word):longint;
procedure babyPutPixel(map:PAbstractMap;x,y:word;color:longint);
procedure babyFill(map:PAbstractMap;x,y,w,h:word;color:longint);

procedure babyCopy(src:PAbstractMap;srcx,srcy,srcw,srch:word;dst:PAbstractMap;dstx,dsty:word);
procedure babyResize(src:PAbstractMap;srcx,srcy,srcw,srch:word;dst:PAbstractMap;dstx,dsty,dstw,dsth:word);

procedure babyWrite(map:PBitmap;x,y:word;color:longint;fontname,text:string);

{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
                          IMPLEMENTATION
{ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ}

Uses  Chyby,Cache,Fonty,
      Loadery,LdGif,LdX,LdPcx,LdTga,LdTxt;

var   s:TScreen;
const s_inited:boolean=false;

{nastavi zadany graficky nebo textovy mod}
{pri model=babyAuto vybere nejlepsi dostupny model}
{pokud nejde presne takove rozliseni, nastavi nejblizsi mozne}
procedure babySetMode(model,x,y:word);
begin
 if reslist.items=0 then InitReslist(true);
 if model=babyAuto then model:=model_gfx;
 if s_inited then begin
   s.silentDone:=true;
   s.Done;
   end;
 s_inited:=s.Init(model,x,y,0);
 if not s_inited then Halt(_erBadMode);
end;

{vrati screenmapu}
function  babyScreen:PScreen;
begin
 if not s_inited then Halt(_erNoScreen);
 babyScreen:=@s;
end;

{nastavi puvodni textovy mod}
procedure babyRestoreTextmode;
begin
 s.Done;
 s_inited:=false;
end;


{vytvori memorymapu}
{pri model=babyAuto pouzije stejny model/paletu jako obrazovka}
{pri nedostatku pameti muze vratit nil}
function  babyMapCreate(model,w,h:word):PBitmap;
var b:PBitmap;
begin
 if model=babyAuto then begin
   model:=babyScreen^.mapmodel;
   nextPal:=s.pal;
   end;
 new(b,Init(model,w,h));
 babyMapCreate:=b;
end;

{vytvori memorymapu se zadanym obrazkem (gif/x/pcx/tga/txt)}
{pri nedostatku pameti nebo neexistenci obrazku vraci nil}
{pokud uz je nastaven graficky mod, prevede obrazek do stejneho modelu}
function  babyMapLoad(picname:string):PBitmap;
var pic:PBitmap;
begin
 pic:=picLoad(picname);
 if s_inited then JoinMapTo(pic,@s,false);
 babyMapLoad:=pic;
end;

{prevede memorymapu na model/paletu referencni mapy}
procedure babyMapConvert(map:PBitmap;reference:PAbstractMap);
begin
 JoinMapTo(map,reference,false);
end;

{zrusi memorymapu}
procedure babyMapDestroy(map:PBitmap);
begin
 if map<>nil then map^.Free;
end;


{vrati barvu platnou pro danou mapu}
function  babyColor(map:PAbstractMap;r,g,b:byte):longint;
begin
 babyColor:=map^.Color(r,g,b,0);
end;

{vrati r,g,b odvozene z barvy platne pro danou mapu}
procedure babyRGB(map:PAbstractMap;color:longint;var r,g,b:byte);
begin
 map^.RGB(color,r,g,b);
end;


{vrati barvu pixelu}
function  babyGetPixel(map:PAbstractMap;x,y:word):longint;
begin
 babyGetPixel:=map^.GetPixel(x,y);
end;

{nastavi barvu pixelu}
procedure babyPutPixel(map:PAbstractMap;x,y:word;color:longint);
begin
 map^.PutPixel(x,y,color);
end;

{vyplni obdelnikovy vyrez mapy barvou}
procedure babyFill(map:PAbstractMap;x,y,w,h:word;color:longint);
begin
 map^.Col2Box(x,y,w,h,color);
end;


{kopiruje obdelnikovy vyrez mapy do jine mapy}
procedure babyCopy(src:PAbstractMap;srcx,srcy,srcw,srch:word;dst:PAbstractMap;dstx,dsty:word);
var tmp:PBitmap;
begin
 {obe mapy musi mit stejny model}
 if src^.mapModel<>dst^.mapModel then Halt(_erDiffModels);
 {kopirovani z memorymapy do mapy}
 if typeof(src^)=typeof(TBitmap) then dst^.BtB2Box(PBitmap(src),srcx,srcy,srcw,srch,dstx,dsty)
 else
 {kopirovani z mapy do memorymapy}
 if typeof(dst^)=typeof(TBitmap) then src^.Box2BtB(PBitmap(dst),srcx,srcy,srcw,srch,dstx,dsty)
 else
 {kopirovani z mapy do mapy}
 begin
  tmp:=src^.BoxCopy(srcx,srcy,srcw,srch);
  if tmp<>nil then begin
   dst^.BtF2Box(tmp,dstx,dsty);
   tmp^.Free;
   end;
 end;
end;

{kopiruje obdelnikovy vyrez mapy do jinak velkeho obdelniku jine mapy}
procedure babyResize(src:PAbstractMap;srcx,srcy,srcw,srch:word;dst:PAbstractMap;dstx,dsty,dstw,dsth:word);
var tmp:PBitmap;
begin
 {obe mapy musi mit stejny model}
 if src^.mapModel<>dst^.mapModel then Halt(_erDiffModels);
 {resizovani z memorymapy do mapy}
 if typeof(src^)=typeof(TBitmap) then dst^.ResizeBtB2Box(0,PBitmap(src),srcx,srcy,srcw,srch,dstx,dsty,dstw,dsth)
 else
 {resizovani z mapy do memorymapy}
 if typeof(dst^)=typeof(TBitmap) then src^.ResizeBox2BtB(0,PBitmap(dst),srcx,srcy,srcw,srch,dstx,dsty,dstw,dsth)
 else
 {resizovani z mapy do mapy}
 begin
  tmp:=src^.BoxCopy(srcx,srcy,srcw,srch);
  if tmp<>nil then begin
   dst^.ResizeBtF2Box(0,tmp,dstx,dsty,dstw,dsth);
   tmp^.Free;
   end;
 end;
end;


{pise zadanym fontem a barvou do memorymapy}
{x,y jsou souradnice zacatku linky na ktere pismena sedi}
procedure babyWrite(map:PBitmap;x,y:word;color:longint;fontname,text:string);
var font:PFont;
begin
 font:=cacheGetFont(fontname);
 OutStr(text,map,x,y,font,0,color);
 caLeave(font);
end;


END.