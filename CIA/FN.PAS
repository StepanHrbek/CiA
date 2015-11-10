{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

{
  FN.EXE - commandlinovy konvertor bitmapovych fontu
}

{$ifndef dpmi}
 kompiluj pro protected mode, v realu by nebylo dost pameti pro velke fonty
{$endif}

{$m 30000,100000,100000}
{$i define.inc}
uses Memo,Chyby,Dos,Sys,Fajly,Fonty,FnExpand,Stringy,Vga,Lang2;

var prop             :boolean;   {udelat font proporcionalnim?}
    noprop           :boolean;   {udelat font neproporcionalnim?}
    nopropwidth      :byte;      {konstantni sirka pro noprop, 0=detect}
    rename           :boolean;   {renejmnout?}
    rename2          :string;    {renejmnout na co?}
    info             :boolean;   {vypsat info?}
    konv             :byte;      {konverze kodovani?}
    superscript      :integer;   {posun do superscriptu?}
    vsechny          :boolean;   {projit ve FON vsechny rezy?}
    forcewidth       :byte;      {sirka znaku ve FNT v pixelech}
    onlyrepack       :boolean;   {pouze prepakovat, nic vic nedelat}

    gfirstchar       :char;      {prvni definovany znak}
    glastchar        :char;      {posledni definovany znak}

    srcMask          :PathStr;
    srcFile          :PathStr;
    srcPtr           :PLine;
    srcSize          :longint;
    srcFree          :longint;

    destMask         :PathStr;
    destFile         :PathStr;
    fnPtr            :pointer;
    fnSize           :longint;
    fnName           :string;

    fnt              :TExpandedFont;

const copyright      :string[10]='(c)';
      Carlos         :string[30]='€…‰‹¥•›†¦—’ ‡ƒˆ‚¡¤¢©¨Ÿ–£˜‘';{znaky 128..157 v carlosovych fontech}

PROCEDURE Usage;
begin
 BiosWriteln('');
 BiosWriteln('FN 3.01 - just another sexy program by Dement.');
 BiosWriteln('');
 BiosWriteln(_(_fnHelp1));
 BiosWriteln(_(_fnHelp2));
 BiosWriteln(_(_fnHelp3));
 BiosWriteln(_(_fnHelp4));
 BiosWriteln(_(_fnHelp5));
 BiosWriteln(_(_fnHelp6));
 BiosWriteln(_(_fnHelp7));
 BiosWriteln(_(_fnHelp8));
 BiosWriteln(_(_fnHelp9));
 BiosWriteln(_(_fnHelp10));
 BiosWriteln(_(_fnHelp11));
 BiosWriteln(_(_fnHelp12));
 BiosWriteln(_(_fnHelp13));
 BiosWriteln(_(_fnHelp14));
 BiosWriteln(_(_fnHelp15));
 BiosWriteln(_(_fnHelp16));
 BiosWriteln(_(_fnHelp17));
 Halt(_erWritten);
end;

PROCEDURE Formaty;
begin
 BiosWriteln(_(_fnForm1));
 BiosWriteln(_(_fnForm2));
 BiosWriteln(_(_fnForm3));
 BiosWriteln(_(_fnForm4));
 BiosWriteln(_(_fnForm5));
 BiosWriteln(_(_fnForm6));
 BiosWriteln(_(_fnForm7));
 BiosWriteln(_(_fnForm8));
 BiosWriteln(_(_fnForm9));
 Halt(_erWritten);
end;

{----------------------------------------------------------------------------
 Podle cmdlajny naplni:
  - srcFile
  - destFile
  - prop
  - firstchar
  - lastchar
 ----------------------------------------------------------------------------}
PROCEDURE ReadParams;
var   st:string;
      i:integer;
const s255:string[1]=#255;
      s32:string[1]=#32;
begin
 srcMask    :='';
 destMask   :='';
 prop       :=false;
 noprop     :=false;
 nopropwidth:=0;
 rename     :=false;
 rename2    :='';
 info       :=false;
 konv       :=0;
 vsechny    :=false;
 gfirstchar :=#0;
 glastchar  :=#255;
 forcewidth :=8;
 onlyrepack :=true;
 for i:=1 to paramcount do
  if not paramUsed[i] then begin
   st:=paramstr(i);
   if st[1]<>'-' then begin
     if srcMask='' then srcMask:=st else
     if destMask='' then destMask:=st else
      erMsg(_(_fnMocParams));
     end
   else begin
     onlyrepack:=false;
     delete(st,1,1);
     if st='f' then Formaty else
     if st='i' then info:=true else
     if st='v' then vsechny:=true else
     if st='k' then konv:=1 else
     if st='p' then prop:=true else
     if copy(st,1,1)='r' then begin rename:=true;rename2:=xlated(copy(st,2,255),pstring(@s255),pstring(@s32));end else
     if copy(st,1,1)='n' then begin noprop:=true;nopropwidth:=valu(copy(st,2,255));end else
     if copy(st,1,1)='w' then forcewidth:=valu(copy(st,2,255)) else
     if copy(st,1,1)='c' then copyright:=copy(st,2,255) else
     if copy(st,1,1)='s' then superscript:=cutnum(st) else begin
       gfirstchar:=chr(valu(cutstring(st,'-')));
       glastchar:=chr(valu(st));
       if (st='') or (glastchar<gfirstchar) then ReportErr(_(_erNeznamParam)+' "'+paramstr(i)+'".');
       end;
     end;
   end;
 if destMask='' then onlyrepack:=false;
end;


PROCEDURE FixDolars(var st:openstring);
var size,j:integer;
begin
 j:=pos('$$',st);
 if j>0 then begin
   size:=fnt.sizeUnder+fnt.sizeOver;
   st[j]:=chr(48+size div 10);
   st[j+1]:=chr(48+size mod 10);
   end;
end;

const fFn =1;
      fFnt=2;
      fFnp=3;
      fRif=4;
      fFon=5;


var   rezu      :word;   {kolik je k dispozici rezu}
      rez       :word;   {kolikaty rez pouzijeme}
      projit_vsechny_rezy:boolean;{projit vsechny rezy?}

PROCEDURE Load;
var   maxsir    :byte;      {maximalni sirka znaku}
      maxvys    :byte;      {maximalni vyska znaku}
      firstchar :char;
      lastchar  :char;
      sizeOver  :byte;
      sizeUnder :byte;
      addspace  :byte;
      future    :byte;
      tablo     :TFontTable; {tabulka informaci o definovanych znacich}

      chars     :word;
      tablobytes:word;
      headlen   :word;
      c         :char;
      a,b,aa,bb :^byte;
      form      :byte;
      i,j,k     :integer;

      {jen pro FON}
      rezsize   :longint;{kolik ma celej rez}
      rezdata   :longint;{kolik maj bitmapy v jednom rezu}
      rezdataofs:longint;{na jakym offsetu zacinaj bitmapy rezu}
      p         :TPtr;
      pp        :pointer;

      {carlos}
      crstablo  :TFontTable;
      crsmap    :PBitmap;
label eexit;
begin
 fnt.Init;

 if PathSlice(srcFile,psExt)='FN' then begin
   erCheck(fnt.LoadFromDisk(srcFile));
   goto eexit;
   end;

 if PathSlice(srcFile,psExt)='FNT' then form:=fFnt else
 if PathSlice(srcFile,psExt)='FNP' then form:=fFnp else
 if PathSlice(srcFile,psExt)='RIF' then form:=fRif else
 if PathSlice(srcFile,psExt)='FON' then form:=fFon else
  erMsg(srcFile+': '+_(_fnNeznamyFormat));

 srcPtr    :=nil;
 srcSize   :=0;
 srcFree   :=0;
 if not fileLoad(srcFile,nil,pointer(srcPtr),srcSize,srcFree) then Halt(_erWritten);
 a         :=pointer(srcPtr);
 future    :=0;
 projit_vsechny_rezy:=false;

 if form=fFon then begin
   projit_vsechny_rezy:=vsechny;
   {zjiti kolik je rezu}
   p.Init(srcPtr);
   p.GotoStr(#7'FONTDIR');
   for i:=1 to 11{minimalne 11, mozna i vic} do p.GotoEos;
   p.AlignUp(16);
   rezu:=p.ReadWord;
   p.Add(2);
   if (rezu<1) or (rezu>30) then erMsg(_(_fnChaos1));
   {zjisti ktery rez chceme pouzit}
   if not projit_vsechny_rezy then begin
     BiosWrite(_(_fnFontu)+' '+stri(rezu)+'. ');
     rez:=1;
     if rezu>1 then
      repeat
       BiosWrite(_(_fnPouzitFont)+' ');
       readln(rez);
      until (rez>0) and (rez<=rezu);
     end
   else begin
     inc(rez);
     BiosWrite(_(_fnFont)+' '+stri(rez)+'. ');
     end;
   {doleze na zacatek rezu}
   for i:=1 to rezu+rez do begin p.GotoStr(copyright);p.Add(1);end;
   p.AlignDown(16);
   {nacte header rezu}
   pp:=p.p;
   if p.ReadWord<>$200 then erMsg(_(_fnChaos2));
   rezsize   :=p.ReadLong;
   p.GotoEop;
   p.Add(1);
   p.AlignUp(4);
   p.Add(20);
   maxvys    :=p.ReadByte;
   BiosWrite(_(_Vyska)+'='+stri(maxvys)+'. ');
   p.Add(6);
   firstchar :=p.ReadChar;
   lastchar  :=p.ReadChar;
   p.Add(16);
   rezdataofs:=p.ReadWord;
   p.Add(3);
   if projit_vsechny_rezy then
    destfile:=PathSlice(destfile,psPath)+copy(PathSlice(destfile,psName),1,6)+
     rep('0',2-length(stri(maxvys)))+stri(maxvys)+PathSlice(destfile,psPoint+psExt);
   {stdinit}
   chars     :=ord(lastchar)-ord(firstchar)+1;
   maxsir    :=64;
   rezdata   :=0;
   end else
 if form=fRif then begin
   inc(a,2);
   while a^<>0 do inc(a);
   inc(a);
   maxsir    :=16;
   maxvys    :=a^;
   inc(a,2);
   firstchar :=' ';
   lastchar  :=chr(a^);
   inc(a,2);
   chars     :=ord(lastchar)-ord(firstchar)+1;
   end
 else begin
   firstchar :=gfirstchar;
   lastchar  :=glastchar;
   chars     :=ord(lastchar)-ord(firstchar)+1;
   maxsir    :=8*Bi2By(forcewidth);
   maxvys    :=(srcSize div chars) div Bi2By(forcewidth);
   if form=fFnp then dec(maxvys);
   if (srcSize mod (chars*Bi2By(forcewidth)))>0 then erMsg(_2(_fnVelNeniNasobkem,srcFile,
     stri(chars)+'*'+stri(Bi2By(forcewidth))));
   end;

 sizeOver  :=0;       {prozatim ulozi znaky tak, ze zacinaji pod radkou}
 sizeUnder :=maxvys;
 if not prop then addspace:=0 else addspace:=1;
 tablobytes:=sizeof(Tcharinfo)*chars;
 headlen   :=fnmagiclen+length(fnName)+1+4+1+1+tablobytes;
 fnSize    :=headlen;
 for c:=firstchar to lastchar do with tablo[c] do begin
   relx  :=0;
   rely  :=0;
   case form of
     fFnt:begin
          ofsb:=(ord(c)-ord(firstchar))*Bi2By(maxsir)*maxvys+headlen;
          sirb:=maxsir;
          end;
     fFnp:begin
          ofsb:=(ord(c)-ord(firstchar))*Bi2By(maxsir)*maxvys+headlen;
          sirb:=srcPtr^[(ord(c)-ord(firstchar))*(maxvys+1)];
          if sirb=0 then inc(fnSize,maxvys);{aby zkopcil i prazdny znak}
          end;
     fRif:begin
          ofsb:=a^;inc(a);ofsb:=MakeWord(a^,ofsb);inc(a);
          sirb:=a^;inc(a,2);
          end;
     fFon:begin
          sirb:=p.ReadWord;
          ofsb:=p.ReadWord-rezdataofs+headlen;
          inc(rezdata,Bi2By(sirb)*maxvys);
          end;
     end;
   vysb  :=maxvys;
   shift :=sirb;
   inc(fnSize,Bi2By(sirb)*vysb);
   end;

 {naalokuje pamet pro generovany fn}
 if fnSize>65520 then erMsg(_(_fnPrilisVelky));
 if not GetMem(fnPtr,fnSize) then Halt(erLowMem);

 {vygeneruje fn do bloku pameti}
 b:=fnPtr;
 move(fnmagic^,b^,fnmagiclen);          inc(b,fnmagiclen);
 move(fnName[1],b^,length(fnName));     inc(b,length(fnName));
 b^:=0;                                 inc(b);
 b^:=ord(firstchar);                    inc(b);
 b^:=ord(lastchar);                     inc(b);
 b^:=sizeOver;                          inc(b);
 b^:=sizeUnder;                         inc(b);
 b^:=addspace;                          inc(b);
 b^:=future;                            inc(b);
 bb:=b;
 aa:=a;
 move(tablo[firstchar],b^,tablobytes);  inc(b,tablobytes);
 case form of
   fFnt:begin
        move(a^,b^,srcSize);            inc(b,srcSize);
        end;
   fFnp:begin
        for c:=firstchar to lastchar do begin
          move(srcPtr^[(ord(c)-ord(firstchar))*(maxvys+1)+1],b^,maxvys);
                                        inc(b,maxvys);
                                        end;
        end;
   fRif:begin
        for c:=firstchar to lastchar do begin
          PtrRec(a).Ofs:=PtrRec(aa).Ofs+tablo[c].ofsb;
          k:=Bi2By(tablo[c].sirb);{k=kolik sloupcu konverti do radek}
          tablo[c].ofsb:=PtrRec(b).Ofs-PtrRec(fnPtr).Ofs;
          for j:=1 to maxvys do begin{maxvys=pocet radek}
            for i:=1 to k do begin
              b^:=a^;                   inc(b);
              inc(a,maxvys);
              end;
            dec(a,maxvys*k-1);
            end;
          end;
        move(tablo[firstchar],bb^,tablobytes);
        end;
   fFon:begin
        for c:=firstchar to lastchar do begin
          p.p:=pp;
          p.Add(tablo[c].ofsb+rezdataofs-headlen);
          k:=Bi2By(tablo[c].sirb);{k=kolik sloupcu konverti do radek}
          for j:=0 to tablo[c].vysb-1 do begin
            for i:=1 to k do begin
              b^:=p.GetByte;            inc(b);
              p.Add(tablo[c].vysb);
              end;
            p.Add(-tablo[c].vysb*k+1);
            end;
          end;
        end;
   end;

 if word(b)-word(fnPtr)<>fnSize then erMsg(_(_fnInterni));

 {uvolni pamet do ktery font nahral z disku}
 FreeMem(pointer(srcPtr),srcSize+srcFree);

 {loadne fn do objektu}
 erCheck(fnt.LoadFromMem(fnPtr,fnSize));

 {zkomprimuje}
 if not fnt.Expand(0,0) then erMsg(_(_fnExpandFailed));

 {* ) rotation
 with fnt.fontmap^ do
  for j:=0 to 19 do
   for i:=0 to 39 div 2 do xchgB(tab^[41]^[j*40+i],tab^[41]^[j*40+39-i]);}


 {* carlos cs chars conversion
 crstablo:=fnt.tablo2;
 crsmap:=fnt.fontmap^.FulCopy;
 fillchar(fnt.tablo2[#128],sizeof(fnt.tablo2) div 2,0);
 for i:=1 to 30 do begin
   fnt.lastchar:=char(MaxW(byte(fnt.lastchar),byte(carlos[i])));
   fnt.tablo2[carlos[i]]:=crstablo[chr(127+i)];
   fnt.fontmap^.BtB2Box(crsmap,0,127+i,crsmap^.sizeX,1,0,ord(carlos[i]));
   end;
 KillObj(crsmap);
 fnt.chars:=ord(fnt.lastchar)+1-ord(fnt.firstchar);{}

 FixDolars(fnt.fontname2);

 fnt.DetectSize;
{ fnt.Edit;{*}
 if not fnt.Shrink then erMsg(_(_fnShrinkFailed));

 {uvolni pamet do ktery vygeneroval fn}
 FreeMem(fnPtr,fnSize);

eexit:
 FixDolars(rename2);
 FixDolars(destFile);
end;


PROCEDURE Save;
begin
 if PathSlice(destFile,psExt)='FN' then begin
   erCheck(fnt.Save(destFile));
   exit;
   end;

 if PathSlice(destFile,psExt)='FNT' then begin
   erCheck(fnt.SaveFnt(destFile));
   exit;
   end;

 erMsg(_(_msgZapisDoForm)+PathSlice(destFile,psExt)+' '+_(_msgNeniPodporovan));
end;


PROCEDURE Work(st:PathStr);
 function Expand(src,dest:PathStr):PathStr;
 var i:word;
     res:PathStr;
 begin
  res:='';
  for i:=1 to length(dest) do
    case dest[i] of
      '?':res:=res+copy(src,length(res)+1,1);
      '*':res:=res+copy(src,length(res)+1,255);
      else res:=res+dest[i];
      end;
  Expand:=res;
 end;
var   c:char;
      i,j:integer;
      srccode,destcode:PString;
      srcallsize,saved:longint;
type      string40=string[40];
const     Kamenici :string40 = 'ˆ¨‡©‘˜ ¡‚£–Ÿ¤ƒ¢„Œ“ª'+{nas standard}
                               '‰›€’‹—¦†¥…•œŠ§«';
          Win1250  :string40 = 'ìšèøıáíéúùòïóä¾åôà'+{win in win}
                               'ÌŠÈØİÁÍÉÚÙÒÏÓÄ¼ÅôÀ';
begin
 {zjisti srcFile}
 st:=PathSlice(srcMask,psPath)+st;
 srcFile:=st;
 {zjisti destFile}
 destFile:=PathSlice(destMask,psPath)+Expand(PathSlice(srcFile,psName),PathSlice(destMask,psName));
 if destfile<>'' then destfile:=destfile+'.'+Expand(PathSlice(srcFile,psExt),PathSlice(destMask,psExt));
 {zjisti implicitni nazev fontu}
 fnName:=PathSlice(srcFile,psFile);
 {loadne}
 BiosWrite(_i(_fnLoad,srcFile)+' ');
 Load;
 {veci ktere jdou pouze v expandovanem fontu}
 if (konv>0) or rename or onlyrepack then begin
   if not fnt.Expand(0,0) then erMsg(_(_fnExpandFailed));
   {konverze}
   if konv>0 then begin
     BiosWrite('CE->KAM. ');
     srccode:=PString(@Win1250);
     destcode:=PString(@Kamenici);
     for i:=1 to length(Kamenici) do begin
       fnt.charcopy(srccode^[i],destcode^[i]);
       {if srccode^[i]<>destcode^[i] then fnt.charclear(srccode^[i]);}
       end;
     end;
   {vymeni nazev}
   if rename or projit_vsechny_rezy then begin
     if not projit_vsechny_rezy or (rez=1) then
      if not rename then rename2:=fnt.fontname2 else
       if rename2='' then begin
        BiosWrite(_(_fnRename));
        readln(rename2);
        end;
     fnt.fontname2:=rename2;
     if projit_vsechny_rezy then fnt.fontname2:=rename2+' '+stri(fnt.maxvys);
     end;
   srcallsize:=fnt.allsize;
   if not fnt.Shrink then erMsg(_(_fnShrinkFailed));
   {pri onlurepack se chlubi svymi uspechy}
   if (PathSlice(srcFile,psExt)='FN') and (PathSlice(destFile,psExt)='FN') and onlyrepack then begin
     saved:=srcallsize-fnt.allsize;
     if saved>0 then BiosWrite(stri(saved)+' bytes gained. ') else
     if saved<0 then BiosWrite('Oooops, '+stri(-saved)+' bytes lost. ');
     end;
   end;
 {make proporc}
 if prop then begin
   BiosWrite(_(_fnProporc)+' ');
   fnt.MakeProporc;
   end;
 {make noproporc}
 if noprop then begin
   BiosWrite(_(_fnNoproporc)+' ');
   fnt.MakeNoprop(nopropwidth);
   end;

 {* zuzeni d~ t~}
{ for c:=fnt.firstchar to fnt.lastchar do dec(fnt.tablo^[c].shift,5);
 { dec(fnt.tablo^['ƒ'].shift,2);
{ dec(fnt.tablo^['Ÿ'].shift);}

 {make superscript}
 if superscript<>0 then begin
   BiosWrite(_(_fnSuperscript)+' ');
   for c:=fnt.firstchar to fnt.lastchar do dec(fnt.tablo^[c].relY,superscript);
   inc(fnt.sizeOver,superscript);
   dec(fnt.sizeUnder,superscript);
   end;
 {nastavi}
 if not info and (destFile='') then begin
   BiosWrite(_(_fnShow)+' ');
   erCheck(fnt.SetFnt);
   end;
 {sejvne}
 if not info and (destFile<>'') then begin
   BiosWrite(_(_fnSave)+' '+destFile+'. ');
   Save;
   end;
 {vypise info}
 if info then
  BiosWrite('sizeOver='+stri(fnt.sizeOver)+
   ' sizeUnder='+stri(fnt.sizeUnder)+' maxOver='+stri(-fnt.maxNad)+' maxUnder='+stri(fnt.maxPod)+'. ');
 {uvolni z pameti}
 fnt.Done;
 BiosWriteln('OK');
end;




var t:SearchRec;

BEGIN
 ReadParams;
 FindFirst(srcMask,0,t);
 if DosError<>0 then Usage;
 while DosError=0 do begin
   rez:=0;
   repeat
     Work(t.name);
   until (not projit_vsechny_rezy) or (rez=rezu);
   FindNext(t);
   end;
END.