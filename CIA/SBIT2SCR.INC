{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

{$ifndef clr}
 {$ifndef smer1}
  {$define smer2}
 {$endif}
{$endif}

{---------------------------------------------------------------------------
 BitBlt pro TScrolScreen (pocita se splitem, doublebufferingem apod).
 ---------------------------------------------------------------------------}
{$ifdef clr}
Procedure TScrolScreen.Col2Box(destX,destY,Sirka,Vyska:word;pixel:longint);
var vramX:word absolute destX;
    vramY:word absolute destY;
    mapX :word absolute destX;
    mapY :word absolute destY;
{$else}
{$ifdef smer1}
Procedure TScrolScreen.BtB2Box(p:PBitmap;srcX,srcY,Sirka,Vyska,destX,destY:word);
var vramX:word absolute destX;
    vramY:word absolute destY;
    mapX :word absolute srcX;
    mapY :word absolute srcY;
{$else}
Procedure TScrolScreen.Box2BtB(p:PBitmap;srcX,srcY,Sirka,Vyska,destX,destY:word);
var vramX:word absolute srcX;
    vramY:word absolute srcY;
    mapX :word absolute destX;
    mapY :word absolute destY;
{$endif}
{$endif}

 procedure CallInherited(mapX,mapY,Sirka,Vyska,vramX,vramY:word);
 begin
  {$ifdef clr}
   TScreen.Col2Box(vramX,vramY,Sirka,Vyska,pixel);
   {$else}
   {$ifdef smer1}
   TScreen.BtB2Box(p,mapX,mapY,Sirka,Vyska,vramX,vramY);
   {$else}
   TScreen.Box2BtB(p,vramX,vramY,Sirka,Vyska,mapX,mapY);
   {$endif}
  {$endif}
 end;

 procedure CallSelf(mapX,mapY,Sirka,Vyska,vramX,vramY:word);
 begin
  {$ifdef clr}
   Col2Box(vramX,vramY,Sirka,Vyska,pixel);
   {$else}
   {$ifdef smer1}
   BtB2Box(p,mapX,mapY,Sirka,Vyska,vramX,vramY);
   {$else}
   Box2BtB(p,vramX,vramY,Sirka,Vyska,mapX,mapY);
   {$endif}
  {$endif}
 end;

var   Y,ted,prebytek:integer;
      oldpen:byte;
label 1,vram;
begin

 case pen of

   PEN_VRAM:
     vram:
     CallInherited(mapX,mapY,Sirka,Vyska,vramX,vramY);

   PEN_SCREEN:
     begin
     {$ifdef beta}
      if (vramX>=Xres) or (vramX+Sirka>Xres) or (vramY>=Yres) or (vramY+Vyska>Yres)
       then erBetaMsg('scrol.bitblt out of range');
     {$endif}
     if scrolMethod=movsd then goto vram;
     oldpen:=pen;
     ted:=vramY+Vyska-topYres;
     {dolni lista}
     if ted>0 then begin
       if ted>Vyska then ted:=Vyska;
       pen:=PEN_VRAM;
       CallSelf(mapX,mapY+Vyska-ted,Sirka,ted,vramX,vramY-topYres+Vyska-ted);
       dec(Vyska,ted);
       end;
     {horni scrol}
     if Vyska>0 then begin
       pen:=PEN_VIRTUAL;
       CallSelf(mapX,mapY,Sirka,Vyska,vramX+posNow.X div charXres,vramY+posNow.Y div charYres);
       end;
     pen:=oldpen;
     end;

   PEN_VIRT_AREA:
     begin
     {$ifdef smer2}
      map^.Box2BtB(p,srcX,srcY,Sirka,Vyska,destX,destY);
     {$else}
      inc(vramX,freePred);
      inc(vramY,freeNad);
      goto 1;
     {$endif}
     end;

   PEN_VIRTUAL:
     begin
     1:
     Y:=vramY mod buflines+buflineFirst;

     case scrolMethod of

       MOVSD:
         CallInherited(mapX,mapY,Sirka,Vyska,vramX-posNow.X div charXres,vramY-posNow.Y div charYres);

       WRAPPIN:
         CallInherited(mapX,mapY,Sirka,Vyska,vramX,vramY);

       SPLITTIN:
         begin
         prebytek:=Y+vyska-(buflineFirst+buflines);
         if prebytek<=0 then
          CallInherited(mapX,mapY,Sirka,Vyska,vramX,Y)
          else begin
           ted:=vyska-prebytek;
           CallInherited(mapX,mapY,Sirka,ted,vramX,Y);
           {$ifndef clr}
           inc(srcY,ted);
           {$endif}
           inc(destY,ted);
           dec(vyska,ted);
           goto 1;
           end;
         end;

       DOUBLEBUFFERIN:
         begin
         if Y<buflineFirst+topYres then begin
           ted:=minI(buflineFirst+topYres-Y,vyska);
           {$ifdef clr}
            TScreen.Col2Box(destX,Y,Sirka,ted,pixel);
            if destY>=buflines then TScreen.Col2Box(destX,Y+buflines,Sirka,ted,pixel);
           {$else}
            {$ifdef smer1}
             {na zacatek bufferu pise jen kdyz nejde o spodek stranky}
             {*if destY+ted<map^.sizeY-topYres then{} TScreen.BtB2Box(p,srcX,srcY,Sirka,ted,destX,Y);
             {*pri teto podmince vubec nepise do horni casti posledni obrazovky}
             {za hranici bufferu pise jen kdyz nejde o vrsek stranky}
             if destY>=buflines then TScreen.BtB2Box(p,srcX,srcY,Sirka,ted,destX,Y+buflines);
            {$else}
             CallInherited(mapX,mapY,Sirka,ted,vramX,Y);
            {$endif}
           {$endif}
           if vyska>ted then begin
             {$ifndef clr}
             inc(srcY,ted);
             {$endif}
             inc(destY,ted);
             dec(vyska,ted);
             goto 1;
             end;
           end
         else
         {*if Y<(buflineFirst+buflines) then} begin
           ted:=minI((buflineFirst+buflines)-Y,vyska);
           {kresli do prostredku bufferu, tam to staci jednou}
           CallInherited(mapX,mapY,Sirka,ted,vramX,Y);
           if vyska>ted then begin
             {$ifndef clr}
             inc(srcY,ted);
             {$endif}
             inc(destY,ted);
             dec(vyska,ted);
             goto 1;
             end;
           end;
         end;
       end;
     end;
   end;
end;

{$undef smer2}
