{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

{
---------------------------------------------------------------------------
                                Loader
---------------------------------------------------------------------------

K praci s formatem Xxxx staci Uses Loadery,LdXxxx;
a dal pracovat s funkcemi z unity Loadery.

Ze zdejsi interface je prazdny neni chyba, loader se automaticky zaregistruje
a unita loadery o nem vi.

}

Unit      LdTga;
Interface {$i define.inc}
Implementation
Uses      Chyby, Objects, Vga,Fajly,Loadery;

type TTga=record
       idlen  :byte; {delka identifikatoru za headerem}
       palette:byte; {0=bez palety, 1=ma paletu}
       maptype:byte; {1=indexed,2=rgb,3=b/w...}
       first  :word; {prvni barva v palete}
       colors :word; {barev v palete}
       bypc8  :byte; {bitu na barvu vcetne alfy}
       originx:integer;
       originy:integer;
       width  :word; {sirka v pixelech}
       height :word; {vyska v pixelech}
       bypp8  :byte; {bitu na pixel vcetne alfy}
       flags  :byte; {0000xxxx=alfa, 00x00000=radky nejsou pozpatku, xx000000=interleaving}
      end;

var tga:TTga;

function GetModel(bypp8:byte):word;
begin
 case bypp8 of
   16:GetModel:=model_bgr15;
   24:GetModel:=model_bgr24;
   32:GetModel:=model_bgra32;
   else GetModel:=0;
   end;
end;

function GetInfo(s:PStream;var model,x,y:word):TError;far;
begin
 GetInfo:=erOk;
 s^.Read(tga,sizeof(tga));
 x:=tga.width;
 y:=tga.height;
 case tga.maptype of
   1:begin
     model:=model_packed;
     if tga.palette=0 then GetInfo:=ldMissPalette;
     end;
   2:begin
     model:=GetModel(tga.bypp8);
     if tga.palette<>0 then GetInfo:=ldUnexpPalette;
     if model=0 then GetInfo:=ldColorDepthNotSup;
     end;
   3:model:=model_packed;
     {GetInfo:=ldGrayscaleNotSup;}
   else GetInfo:=ldComprTypeNotSup;
   end;
end;

function Decompress(s:PStream;map:PBitmap):TError;far;
var y:word;
    c:byte;
    model:word;
    pixel:longint;
    tmp:byte;
begin
 Decompress:=erOk;
 if map^.pal<>nil then
  with map^.pal^ do
   if tga.palette>0 then begin
     Setup(tga.first,tga.first+tga.colors-1,pifUsed);
     model:=GetModel(tga.bypc8);
     if model=0 then begin Decompress:=ldColorDepthNotSup;exit;end;
     for c:=tga.first to tga.first+tga.colors-1 do
      with pal[c] do begin
        s^.Read(pixel,tga.bypc8 shr 3);
        _RGBA(model,nil,pixel,r,g,b,tmp);
        r:=r shr 2;
        g:=g shr 2;
        b:=b shr 2;
        end;
     end
   else begin
     Setup(0,255,pifUsed);
     for c:=0 to 255 do
      with pal[c] do begin
        r:=c shr 2;
        g:=c shr 2;
        b:=c shr 2;
        {do a nastavuje nejakou alfu, a=pifUsed}
        end;
     end;
 if (tga.flags and 32)>0
  then for y:=0 to map^.sizeY-1     do s^.Read(map^.tab^[y]^,map^.sizeXb)
  else for y:=map^.sizeY-1 downto 0 do s^.Read(map^.tab^[y]^,map^.sizeXb);
 map^.transparent:=false;
end;

function Compress(s:PStream;map:PBitmap):TError;far;
var col:TCol;
    c:byte;
    y:word;
begin
 tga.idlen   :=0;
 tga.palette :=ord(map^.pal<>nil);
 tga.maptype :=1+ord(map^.MapModel in models_direct);
 tga.first   :=0;if map^.pal<>nil then tga.first  :=map^.pal^.first;
 tga.colors  :=0;if map^.pal<>nil then tga.colors :=map^.pal^.last+1-map^.pal^.first;
 tga.bypc8   :=0;if map^.pal<>nil then tga.bypc8  :=24;
 tga.originx :=0;
 tga.originy :=0;
 tga.width   :=map^.sizeX;
 tga.height  :=map^.sizeY;
 tga.bypp8   :=map^.bypp*8;
 tga.flags   :=tga.bypp8-map^.bipp+$20;
 s^.Write(tga,sizeof(tga));
 if map^.pal<>nil then
  with map^.pal^ do
   for c:=first to last do begin
     col.b:=pal[c].r shl 2+pal[c].r shr 4;
     col.g:=pal[c].g shl 2+pal[c].g shr 4;
     col.r:=pal[c].b shl 2+pal[c].b shr 4;
     s^.Write(col,3);
     end;
 for y:=0 to map^.sizeY-1 do s^.Write(map^.tab^[y]^,map^.sizeXb);
 Compress:=erOk;
end;

begin
 picRegister('TGA',isLoadable+isGraphics+isFixedSize,GetInfo,Decompress,Compress,
  chr(model_packed)+chr(model_bgr15)+chr(model_bgr24)+chr(model_bgra32));
end.