{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 0.32ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

{---------------------------------------------------------------------------
 Nahraje soubor z disku do pameti.

 p<>nil
 ------
  P je pointer na blok pameti delky datasize+freesize.

 p=nil
 -----
  Datasize musi byt 0.
  Do p se naalokuje blok pameti delky souboru + freesize.

 vystupy
 -------
  Do p^ se nahraje soubor filename.
  Promenne datasize a freesize se upravi tak, ze datasize=delka nahranych dat,
  freesize=volna pamet za daty.
  Vraci kod chyby, 0=ok.

 P je pointer na pripraveny blok pameti, datasize + freesize jeho velikost.
 Je-li p=nil, naalokuje se pamet velikosti souboru + freesize.
 Datasize uvadi maximalni velikost souboru. Je-li soubor delsi, bude
  prebytek ignorovan a nahrano pouze datasize. V datasize se pote vraci
  delka nahrane casti souboru. Pokud se alokovala pamet, velikost bufferu
  zjistis souctem datasize + freesize.
 Onlyfull rika, ze se ma soubor nahravat jen pokud se do limitu datasize
  vejde cely.
 Pri neuspechu (soubor nejde cist/neexistuje/neni pamet) zachova p
  i datasize nezmenene.
 ---------------------------------------------------------------------------}

FUNCTION {$ifdef dm}LoadDMFile{$else}LoadDosFile{$endif}
 (filename:PathStr;var p:pointer;var datasize,freesize:longint):TError;

var   f               :file;
      fsize           :longint;{velikost souboru}
      toload          :longint;{kolik bajtu jeste zbyva naloadovat}
      temptoload      :word;
      temploaded      :word;
      tempp           :^byte;
      wasnil          :boolean;
      result          :TError;
label clous,passres;
begin
  wasnil:=p=nil;

 {otevre soubor}
  if filename='' then begin
    result:=errFileNotFound;
    goto passres;
    end;
  {$ifdef dm}
  if not OpenDMFile(filename)
  {$else}
  assign(f,filename);
  reset(f,1);
  if ioresult<>0
  {$endif}
   then begin
    result:=errFileOpen;
    goto passres;
    end;

 {zjisti velikost}
  fsize:=
   {$ifdef dm}
   lastopenLength;
   {$else}
   FileSize(f);
   {$endif}

 {p=nil: naalokuje pamet}
 if p=nil then begin
   {$ifdef beta}
   if datasize<>0 then erBetaMsg('loadfile datasize<>0');
   {$endif}
   datasize:=fsize;
   if not GetMem(p,datasize+freesize) then begin
     result:=erLowMem;
     goto clous;
     end;
   end
 {p<>nil: zkontroluje ze je dost pameti}
 else begin
   if fsize>datasize then begin
     result:=erFileTooBig;
     goto clous;
     end;
   inc(freesize,datasize-fsize);
   datasize:=fsize;
   end;

 {nacte soubor}
 toload    :=fsize;
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
     (temploaded<>temptoload) then begin
       result:=errFileRead;
       if wasnil then FreeMem(p,datasize+freesize);
       goto clous;
       end;

   dec(toload,temptoload);
   inc(tempp,temptoload);
   if PtrRec(tempp).Ofs=0 then inc(PtrRec(tempp).Seg,selectorInc);
   end;

 {skoncil uspechem}
 result:=erOk;

 {zavre soubor}
 clous:
  {$ifdef dm}
  CloseDMFile;
  {$else}
  close(f);
  {$endif}

 {preda vysledek}
 passres:
  {$ifdef dm}
  LoadDMFile:=result;
  {$else}
  LoadDosFile:=result;
  {$endif}
end;
