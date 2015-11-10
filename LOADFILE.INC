{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 0.10ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

{---------------------------------------------------------------------------
 Nahraje soubor z disku do pameti.
 P je pointer na pripraveny blok pameti. Je-li nil, naalokuje se pamet
  velikosti souboru + freesize (pokud chces mit za koncem souboru
  kus volneho mista).
 Maxsize uvadi maximalni velikost souboru. Je-li soubor delsi, bude
  prebytek ignorovan a nahrano pouze maxsize. V maxsize se pote vraci
  delka nahrane casti souboru. Pokud se alokovala pamet, velikost bufferu
  zjistis souctem maxsize + freesize.
 Onlyfull rika, ze se ma soubor nahravat jen pokud se do limitu maxsize
  vejde cely.
 Pri neuspechu (soubor nejde cist/neexistuje/neni pamet) zachova p
  i maxsize nezmenene.
 ---------------------------------------------------------------------------}

FUNCTION {$ifdef dm}LoadDMFile{$else}LoadDosFile{$endif}
(filename:pathStr;var p:pointer;onlyfull:boolean;var maxsize:longint;freesize:longint):TLoadFileRes;

var   f               :file;
      fsize           :longint;{velikost souboru}
      toloadtotal     :longint;{kolik bajtu loadovat celkem}
      toload          :longint;{kolik bajtu jeste zbyva naloadovat}
      temptoload      :word;
      temploaded      :word;
      tempp           :^byte;
      wasnil          :boolean;
      result          :TLoadFileRes;
label free,clous,passres;
begin

 {init}
  result    :=none;
  wasnil    :=p=nil;

 {otevre soubor}
  if filename='' then goto passres;
  {$ifdef dm}
  if not OpenDMFile(filename)
  {$else}
  assign(f,filename);
  reset(f,1);
  if ioresult<>0
  {$endif}
   then goto passres;

 {zjisti velikost}
  fsize:=
   {$ifdef dm}
   lastopenLength;
   {$else}
   FileSize(f);
   {$endif}

 {vyridi parametr onlyfull}
 if fsize<=maxsize then toloadtotal:=fsize else
  if onlyfull then goto clous else toloadtotal:=maxsize;
 {naalokuje pamet}
 if p=nil then
  if not GetMem(p,toloadtotal+freesize) then goto clous;
 {nacte soubor}
 toload    :=toloadtotal;
 tempp     :=p;
 while toload>0 do begin
   if PtrRec(tempp).Ofs=0 then temptoload:=65536-512
                          else temptoload:=65536-PtrRec(tempp).Ofs;
   if temptoload>toload then temptoload:=toload;

   {nacte kus souboru}
    {$ifdef dm}
    temploaded:=ReadFile(tempp,temptoload);
    if
    {$else}
    BlockRead(f,tempp^,temptoload,temploaded);
    if (ioresult<>0) or
    {$endif}
     (temploaded<>temptoload) then goto free;

   dec(toload,temptoload);
   inc(tempp,temptoload);
   if PtrRec(tempp).Ofs=0 then inc(PtrRec(tempp).Seg,selectorInc);
   end;

 {skoncil uspechem}
 if fsize>maxsize then result:=part else result:=full;
 maxsize   :=toloadtotal;
 goto clous;

 {skoncil neuspechem}
 free:
 if wasnil then begin
   FreeMem(p,toload+freesize);
   p:=nil;
   end;

 {zavre soubor}
 clous:
  {$ifdef dm}
  CloseDMFile;
  {$else}
  close(f);
  {$endif}

 {zavre soubor}
 passres:
  {$ifdef dm}
  LoadDMFile:=result;
  {$else}
  LoadDosFile:=result;
  {$endif}
end;
