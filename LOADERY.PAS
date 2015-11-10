{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 1.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      Loadery;
Interface {$i define.inc}
Uses      Chyby,Memo, Objects,Dos, Stringy,Fajly,Vga;
Function  Init:TError;
Procedure Done;

{
 ---------------------------------------------------------------------------
                                Koncepce
 ---------------------------------------------------------------------------

 Zde v unite loadery je interface pro praci s obrazky.
 Dalsi unity, nazvane LdXXX a obsahujici podporu formatu XXX,
 nemaji interface. Jak se k te podpore tedy dostat? Staci dat unitu LdXXX
 do uses hlavniho programu. To je vse, od te chvile bude unita loadery
 plne podporovat format XXX.
 Unity LdXXX maji totiz inicializacni cast, ktera format 'zaregistruje'.

 V soucasne dobe obsahuje CiA pouze podporu TGA a TXT.
 Ale po napsani loaderu pro dalsi formaty bude stacit pridat je do uses
 hlavniho programu, dalsi upravy nebudou nutne.
 Pokud jde v nejake situaci vhod vice loaderu, bude pouzit nejdrive
 zaregistrovany, tedy prvni podle poradi v Uses. Vice loaderu tedy serad
 treba podle kvality komprese.
 Pokud pro jeden format zaregistrujes vic loaderu, plati ten posledni.

 Flags... kazdy format si pri registraci stanovi sve atributy.
 - zda je nahratelny do bitmapy, animovany, spustitelny, skalovatelny
 a tak dale a tak dale, viz seznam konstant isXXXX v unite Fajly.

 Funkce picWrite(bitmap,name) se snazi obrazek ulozit. Neni-li zadano
 v jakem formatu, vybere nejvhodnejsi (s podporou ukladani v danem nebo
 co nejblizsim modelu, a v pripade shody podle poradi registrace). Kdyz je
 zvolen format nepodporujici model bitmapy, provede se konverze.
 Konvertovat nejde pouze mezi textem a grafikou.

 Informace pro autory loaderu:
  fce GetInfo muze predpokladat, ze pointer je na zacatku streamu.
   naplni tyto promenne: model,x,y. pokud je obrazek v nejakem modu, ktery
   loader nepodporuje, GetInfo ma naplnit model,x,y, ale vratit chybovy kod.
  fce Decompress muze predpokladat, ze je volana po uspesnem GetInfo
   a ze dostane za parametr spravne velkou bitmapu ve spravnem modelu.
   obrazek nahraje ze streamu do bitmapy.
  fce Compress muze predpokladat, ze bitmapa je v nekterem z ji
   podporovanych modelu. obrazek z bitmapy zapise do streamu.
}


{---------------------------------------------------------------------------
 Interface pro autora loaderu: registrace, trochu pripravene pameti
 ---------------------------------------------------------------------------}
Type      TGetInfo=Function(s:PStream;var model,x,y:word):TError;
          TDecompress=Function(s:PStream;map:PBitmap):TError;
          TCompress=Function(s:PStream;map:PBitmap):TError;
          String10=string[10];

Var       picSeg1:word;                {64KB segment k dispozici loaderum}
          picSeg2:word;                {64KB segment k dispozici loaderum}

Procedure picRegister(aext:ExtStr;aflags:word;agetinfo:TGetInfo;
           adecompress:TDecompress;acompress:TCompress;awrmodels:string10);

{---------------------------------------------------------------------------
 Interface pro uzivatele loaderu: cteni a psani obrazku...
 ---------------------------------------------------------------------------}

Function  picGetInfo(name:PathStr;var model,x,y:word):boolean;
Function  picLoad(name:PathStr):PBitmap;
Function  picLoadTo(name:PathStr;map:PBitmap):boolean;
Function  picWrite(map:PBitmap;name:PathStr):boolean;


{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
                          IMPLEMENTATION
{ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ}

Type  PLoaderItem=^TLoaderItem;
      TLoaderItem=object(TFormatItem)
               GetInfo     :TGetInfo;   {informator, zjisti rozmery a model}
               Decompress  :TDecompress;{dekompresor=loader}
               Compress    :TCompress;  {kompresor=writer}
               wrmodels    :string10;   {seznam writerem podporovanych modelu}
              end;

{---------------------------------------------------------------------------
 Najde loader pro zadany soubor.
 ---------------------------------------------------------------------------}
Function GetLoader(name:PathStr):PLoaderItem;
var p:PFormatItem;
begin
 p:=fileGetFormat(name);
 if (p<>nil) and (typeof(p^)=typeof(TLoaderItem))
  then GetLoader:=PLoaderItem(p)
  else GetLoader:=nil;
end;

{---------------------------------------------------------------------------
 Zaregistruje loader.
 ---------------------------------------------------------------------------}
Procedure picRegister(aext:ExtStr;aflags:word;agetinfo:TGetInfo;
           adecompress:TDecompress;acompress:TCompress;awrmodels:string10);
var p:PLoaderItem;
begin
 if GetLoader('a.'+aext)<>nil then Formats.Delete(GetLoader('a.'+aext));
 New(p,Init);
 p^.ext         :=UpCased(aext);
 p^.flags       :=aflags;
 p^.GetInfo     :=agetinfo;
 p^.Decompress  :=adecompress;
 p^.Compress    :=acompress;
 p^.wrmodels    :=awrmodels;
 Formats.Insert(p);
end;

{---------------------------------------------------------------------------
 Volitelne bud jen vraci info o obrazku nebo ho i nahraje.
 ---------------------------------------------------------------------------}
Function HandlePicture(name:PathStr;load:boolean;var model,x,y:word;var map:PBitmap):boolean;
var e:TError;
    myLoader:PLoaderItem;
    s:PStream;
    killmap:boolean;
begin
 if debugPal then SetHwCol(0,63,0,0);
 e:=erOk;
 myLoader:=GetLoader(name);
 if (myLoader=nil) or (@myLoader^.getinfo=nil) or (load and (@myLoader^.decompress=nil))
  then e:=ldNoLoaderFound else begin
   s:=fileReadStream(name);
   if s=nil then e:=errFileNotFound else begin
     e:=myLoader^.GetInfo(s,model,x,y);
     if e=erOk then
      if load then begin
        killmap:=map=nil;
        if map=nil then New(map,Init(model,x,y));
        if map=nil then e:=erLowMem else begin
          e:=myLoader^.Decompress(s,map);
          if (e<>erOk) and killmap then KillObj(map);
          end;
        end;
     KillObj(s);
     end;
   end;
 if e<>erOk then ReportErr(name+': '+_(e));
 HandlePicture:=e=erOk;
 if debugPal then SetHwCol(0,0,0,0);
end;

{---------------------------------------------------------------------------
 Vraci parametry obrazku a uspesnost.
 ---------------------------------------------------------------------------}
FUNCTION picGetInfo(name:PathStr;var model,x,y:word):boolean;
var   map:PBitmap;
begin
 picGetInfo:=HandlePicture(name,false,model,x,y,map);
end;

{---------------------------------------------------------------------------
 Nahraje obrazek do nove vytvorene bitmapy.
 ---------------------------------------------------------------------------}
Function picLoad(name:PathStr):PBitmap;
var   m,x,y:word;
      map:PBitmap;
begin
 map:=nil;
 HandlePicture(name,true,m,x,y,map);
 picLoad:=map;
end;

{---------------------------------------------------------------------------
 Nahraje obrazek do zadane bitmapy.
 ---------------------------------------------------------------------------}
Function  picLoadTo(name:PathStr;map:PBitmap):boolean;
var   m,x,y:word;
begin
 picLoadTo:=HandlePicture(name,true,m,x,y,map);
end;

{---------------------------------------------------------------------------
 Ulozi obrazek v zadanem nebo nejvhodnejsim formatu a vraci uspesnost.
 ---------------------------------------------------------------------------}
Function picWrite(map:PBitmap;name:PathStr):boolean;

  const empty=30000;

  function AIsMoreThanBNearToC(a,b,c:word):boolean;
  begin
   AIsMoreThanBNearToC:=
     Convertable(a,c) and
     ((b=empty) or ((a>b)and(b<c)) or ((a<b)and(a>=c)));
  end;

  function FindBestModel(models:string10):word;
  var i:word;
      bestmodel:word;
  begin
   bestmodel:=empty;
   for i:=1 to length(models) do
    if AIsMoreThanBNearToC(ord(models[i]),bestmodel,map^.MapModel)
     then bestmodel:=ord(models[i]);
   FindBestModel:=bestmodel;
  end;

  var myLoader:PLoaderItem;
      myLoader_bestmodel:word;
  procedure Try(p:PLoaderItem);far;
  var p_bestmodel:word;
  begin
   if typeof(p^)<>typeof(TLoaderItem) then exit;
   p_bestmodel:=FindBestModel(p^.wrmodels);
   if p_bestmodel=empty then exit;
   if (myLoader=nil)
    or AIsMoreThanBNearToC(p_bestmodel,myLoader_bestmodel,map^.MapModel)
    then begin
      myLoader:=p;
      myLoader_bestmodel:=p_bestmodel;
      end;
  end;

var e:TError;
    s:PStream;
    bestmodel:word;
begin
 e:=erOk;
 {urci jaky format pouzit... bud uz je zadany nebo vybere nejvhodnejsi}
 if PathSlice(name,psExt)<>''
  then myLoader:=GetLoader(name)
  else begin
       myLoader:=nil;
       Formats.ForEach(@Try);
       if myLoader<>nil then name:=PathSlice(name,psPath+psName+psPoint)+myLoader^.ext;
       end;
 {uspel nejaky loader?}
 if myLoader=nil
  then e:=ldNoWriterFound else begin
   {vybere nejvhodnejsi model}
   bestmodel:=FindBestModel(myLoader^.wrmodels);
   {zmeni model}
   ChangeMapTo(map,bestmodel);
   if map=nil then e:=erLowMem else begin
     s:=fileCreateStream(name);
     if s=nil then e:=erFileCreate else begin
       e:=myLoader^.Compress(s,map);
       KillObj(s);
       end;
     end;
   end;
 if e<>erOk then ReportErr(name+': '+_(e));
 picWrite:=e=erOk;
end;


{°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°INIT/DONE°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°}

const unita='loadery';
var result:TError;

procedure UserInit;
 var p:pointer;
 begin
  if not GetMem(p,65536) then begin result:=erLowMem;exit;end;
  picSeg1     :=freeseg;
  picSeg2     :=PtrRec(p).Seg;
 end;

procedure UserDone;
 var p:pointer;
 begin
  p:=ptr(picSeg2,0);
  FreeMem(p,65536);
 end;

{$i initdone.inc}
{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.