{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 1.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

const
 selMaxFiles  =2048;
 selUpperDir  ='..          ';
 selMark      =1 shl 7;
 CharsInFile  :set of char=['!'..')','-','.','0'..'9','<'..'>','@'..'[',']'..#255]; {mozne znaky v souboru (kdyz tak uprav)}
 {konstanty pro funkci InputString; bity 0-7 urcuji, ktere znaky je mozno zadat}
 inpNumbers   =1 shl 0; {'0'..'9'}
 inpHILetters =1 shl 1; {'A'..'Z'}
 inpLOLetters =1 shl 2; {'a'..'z'}
 inp32_64     =1 shl 3; {#32..#64}
 inpSpecial   =1 shl 4; {#0..#7, #10..#12, #14..#31}
 inp91_127    =1 shl 5; {#91..#127}
 inpHIChars   =1 shl 6; {#128..#255}
 inpAllChars  =inpNumbers+inpHILetters+inpLOLetters+inp32_64+inpSpecial+inp91_127+inpHIChars;
 inpFileChars =1 shl 7; {CharsInFile + znaky ':\*?;'}
 inpStartCur  =1 shl 8; {pocatecni rezim kurzoru (1=prepisov n¡,0=vkl d n¡)}
 inpBlock     =1 shl 9; {da na zacatku cely text do bloku}
 inpShyBlock  =1 shl 10;{1=cokoli krome oznaceni bloku blok zrusi, 0=blok rusi jen CTRL/Shift-Delete}
 inpPasteCur  =1 shl 11;{po Shift-Ins presunout kurzor ZA vlozeny clipboard}
 stdinp:word  =inpFileChars+inpBlock+inpShyBlock;
 {navratove kody}
 retEsc       =1;
 retEnter     =2;
 retTab       =3;
 retErr       =4;
 {jake operace se soubory/adresari muze uzivatel ze selektoru delat}
 mngReadFiles =1;
 mngWriteFiles=2;
 mngReadDirs  =4;
 mngWriteDirs =8;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
type
 string12=string[12];
 TThisFile=
  record
   attr:byte;
   dirc:byte;
   time:longint;
   size:longint;
   name:string12;
  end;
 PThisFile=^TThisFile;
 Pselector=^Tselector;
 Tselector=
  object(TObject)
   c1,c1max :byte; {ukazatel do tabulky souboru}
   editw    :byte; {delka editovaciho radku}
   yedit    :byte; {kde bude editovaci radek}
   yqfind   :byte; {kde bude quick-find-string}
   ydetail  :byte; {kde bude tabulka s detailnimi udaji vybraneho souboru}
   ycurdir  :byte; {kde bude vypsany soucasny adresar}
   x0,y0    :byte; {zacatek tabulky souboru/adresaru (relativne k dialogu)}
   w        :byte; {pocet sloupcu tabulky (kolik souboru bude v jednom radku vedle sebe)}
   h        :byte; {pocet radku tabulky}
   ret      :byte; {navratovy kod}
   scrollbar:byte; {typ scrolluj¡c¡ li¨ky}
   item     :byte; {co se m  zobrazit u kazdeho souboru (adresare)}
   itemw    :byte; {¨¡©ka z znamu kazdeho souboru (adresare)}
   sorting  :byte; {podle ‡eho a jak ©adit soubory a adresare}
   clrFiles :byte; {barva tabulky souboru a adresaru}
   clrDirs  :byte; {barva adresaru v PathBrowseru}
   clrActive:byte; {barva vybrane polozky, na ktere je kurzor}
   clrActual:byte; {barva vybrane polozky, na ktere neni kurzor}
   clrScroll:byte; {barva scrolluj¡c¡ li¨ky}
   clrInf   :byte; {barva pro Quick-Find string nebo soucasny adresar}
   clrDetail:byte; {barva do detailoveho okna}
   clrBlock :byte; {barva textu v bloku}
   clrMarked:byte; {barva oznaceneho souboru/adresare}
   clrDir2  :byte; {barva souboru z neaktualniho adresare}
   clrEdit  :byte; {barva editovaci radky}
   clrCur   :byte; {barva kurzoru v editovaci radce pri rezimu prepisovani}
   clrCurIns:byte; {barva kurzoru v editovaci radce pri rezimu vkladani}
   dirCount :byte; {citac neaktualnich adresaru}
   god      :byte; {pro MousEvents}
   count    :word; {po‡et na‡ten˜ch soubor–}
   at       :word; {atributy, ktere maji mit vsechny nactene soubory}
   c2,c2max :word; {ukazatel do tabulky souboru}
   homedir  :word; {index aktualniho adresare (pouze PathBrowser)}
   manager  :word; {jak‚ operace se soubory/adresari jsou povoleny}
   flags    :word; {vlajky chovani selectoru}
   maska    :string;   {souborova maska; muze jich byt i vic,oddelenych strednikem}
   origdir  :PathStr;  {adresar, z nehoz byl selektor volan}
   event    :TEvent;   {ud lost kl vesnice nebo mysi}
   d        :PDialog;  {dialogov‚ okno selektoru}
   qfind    :string12; {pro rychl‚ vyhled v n¡ souboru/adres re}
   parent   :string12; {jm‚no soucasn‚ho adres re}
   postfix  :PathStr;  {pripona za vybranym adresarem}
   ikona    :string[18];
   sez      :array[0..selMaxFiles-1] of PThisFile; {seznam souboru}
   dirs     :TCollection;{adresare z masky}
   dirs_inited:boolean;  {je dirs inicializovano}
   Constructor Init;
   Destructor  Done;virtual;
   Function  FindDir(index:byte):DirStr;
   Procedure ClearList;
   Function  AddItem(filerec:SearchRec):boolean;
   Function  AdjustName(fn:FileStr; lowcase:boolean):string;
   Function  TimeSlice(time:longint; slice:byte):word;
   Function  InputString(s:string; x,y,c,l,width:byte; e:word):string;
   Function  NumSelected(what:byte):word;
   Function  GodWishes(n:byte):boolean;
   Procedure ReadFiles;
   Procedure ReadDirectories;
   Procedure SortFiles;
   Procedure SortDirectories;
   Procedure DrawScrollBar;
   Procedure DrawFileTab;
   Procedure HandleEvents;
   Procedure MouseEvents;
   Procedure Arrange;
   Procedure ReRead;
   Procedure ReGain;
   Procedure PreSelektni(fn:string12);
   Function  SelectFile(preselect:string):string;
   Function  SelectDirectory(preselect:string):string;
   Function  SelectDisk:boolean;
  end; {object Tselector}
 PDir=^TDir;
 TDir=
  object(TObject)
   dir         :DirStr;
   constructor Init(adir:DirStr);
  end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Constructor TDir.Init(adir:DirStr);
begin
 dir:=adir;
end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
PROCEDURE Xchg4(var a,b);assembler;
asm
 push ds
 les  di,a
 lds  si,b
 db 66h;mov ax,[si]
 db 66h;xchg ax,[es:di]
 db 66h;mov [si],ax
 pop ds
end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Constructor Tselector.Init;
var i:word;
begin {Tselector.Init}
 inherited Init;
 for i:=0 to selMaxFiles-1 do
  sez[i]:=nil;
 count:=0;dircount:=0;
 c1:=0;   c1max:=0;
 c2:=0;   c2max:=0;
 qfind    :='';
 sorting  :=stdsort;
 item     :=stditem;
 scrollbar:=stdbar;
 manager  :=0;
 clrFiles :=$3E;
 clrDirs  :=$30;
 clrActive:=$0F;
 clrScroll:=$78;
 clrInf   :=$3B;
 clrDetail:=$13;
 clrCur   :=$07;
 clrCurIns:=$0F;
 clrBlock :=$2F;
 clrMarked:=$3D;
 clrActual:=$3F;
 clrDir2  :=$3A;
 clrEdit  :=$1E;
 at       :=AnyFile-VolumeID-Directory;
 ikona    :=''#27#26'°±²þ[]';
 dirs_inited:=false;
end;  {Tselector.Init}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Destructor  Tselector.Done;
begin {Tselector.Done}
 if dirs_inited then dirs.Done;
 ClearList;
end;  {Tselector.Done}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Procedure Tselector.ClearList;
{Zrusi vsechny dynamicke promenne v seznamu.}
var
 p:pointer;
 i:word;
begin {Tselector.ClearList}
 for i:=0 to selMaxFiles-1 do
  if sez[i]<>nil then
   begin
    p:=sez[i];
    FreeMem(p,SizeOf(TThisFile));
    sez[i]:=nil;
   end;
 count:=0;
 dircount:=0;
end;  {Tselector.ClearList}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function  Tselector.InputString(s:string; x,y,c,l,width:byte; e:word):string;
{Necha uzivatele napsat retezec
 s-pocatecni string
 x,y-zacatek radku - ofsety vuci levemu hornimu rohu dialogoveho okna
 c-pocatecni pozice kurzoru
 l-maximalni delka zadavaneho stringu (muze byt i delsi nez vyrez)
 width-delka vyrezu stringu, ktery bude viden (kdyz bude text vetsi, zobrazi pred nej nebo za nej sipky)
 e-viz konstanty inpXXXX}
var
 zac,i:byte;
 block:word; {horni byte-zacatek bloku, dolni byte-delka bloku}
 ins:boolean;
 clipboard:string;
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
 procedure TypeChar(zn:char);
 var zn2:string[1];
 begin {TypeChar}
  zn2:=zn;
  if ins or (length(s)<l) then
   if ((e and inpNumbers  <>0) and (zn in ['0'..'9'])) or
      ((e and inpHILetters<>0) and (zn in ['A'..'Z'])) or
      ((e and inpLOLetters<>0) and (zn in ['a'..'z'])) or
      ((e and inp32_64    <>0) and (zn in [#32..#64])) or
      ((e and inpSpecial  <>0) and (zn in [#0..#7, #10..#12, #14..#31])) or
      ((e and inp91_127   <>0) and (zn in [#91..#127])) or
      ((e and inpHIChars  <>0) and (zn in [#128..#255])) or
      ((e and inpFileChars<>0) and (zn in (CharsInFile+[':','\','*','?',';']) )) then
    if lo(block)=0 then
     if ins then
      begin
       s[c+1]:=zn;
       c:=either(c<length(s),c+1,length(s));
      end
     else
      begin
       Insert(zn2,s,c+1);
       c:=either(c<length(s),c+1,length(s));
      end
    else
     if e and inpShyBlock<>0 then
      begin
       if ins then
        begin
         s[c+1]:=zn;
         c:=either(c<length(s),c+1,length(s));
         block:=0;
        end
       else
        begin
         Delete(s,hi(block)+1,lo(block)-hi(block)+1);
         c:=hi(block);
         block:=0;
         Insert(zn2,s,c+1);
         c:=either(c<length(s),c+1,length(s));
        end
      end
     else
      if ins then
       begin
        s[c+1]:=zn;
        c:=either(c<length(s),c+1,length(s));
       end
      else
       begin
        Insert(zn2,s,c+1);
        if c<hi(block) then block:=(hi(block)+1) shl 8+lo(block) else
        if c<hi(block)+lo(block) then block:=block and $FF00+lo(block)+1;
        c:=either(c<length(s),c+1,length(s));
       end;
 end;  {TypeChar}
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
 procedure JumpWord(ToTheRight:boolean);
 const
  PartOfWord:set of char=['0'..'9','A'..'Z','a'..'z',#128..#175,#224..#239];
 var oldc:byte;
 begin {JumpWord}
  oldc:=c;
  case ToTheRight of
  false:
   if c>0 then
    begin
     if not (s[c] in PartOfWord) then
      while (c>0) and not(s[c] in PartOfWord) do dec(c);
     while (c>0) and (s[c] in PartOfWord) do dec(c);
    end;
  true:
   if c<length(s) then
    begin
     while (c<=length(s)) and (s[c+1] in PartOfWord) do inc(c);
     while (c<=length(s)) and not(s[c+1] in PartOfWord) do inc(c);
    end;
  end;
  if (mem[Seg0040:$17] and 3=0)  and (e and inpShyBlock<>0) then
   begin
    block:=0;
    exit;
   end;
  if c=oldc then exit;
  if mem[Seg0040:$17] and 3<>0 then
   if ToTheRight then
    if oldc=hi(block)+lo(block) then block:=block and $FF00+c-hi(block) else
    if oldc=hi(block) then
     block:=either(c>=hi(block)+lo(block),(hi(block)+lo(block)) shl 8+c-hi(block)-lo(block),c shl 8+hi(block)+lo(block)-c)
    else block:=oldc shl 8+c-oldc
   else
    if oldc=hi(block)+lo(block) then block:=either(hi(block)<=c,block and $FF00+c-hi(block),c shl 8+hi(block)-c) else
    if oldc=hi(block) then block:=c shl 8+lo(block)+hi(block)-c
    else block:=c shl 8+oldc-c;
 end;  {JumpWord}
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
begin {Tselector.InputString}
 InputString:='';
 clipboard:='';
 if l>width then
  begin
   inc(x);
   dec(width,2);
  end;
 if (width<3) or (l<1) then exit;
 zac:=0;
 ins:=e and inpStartCur<>0;
 if length(s)>l then s[0]:=chr(l);
 if (e and inpBlock<>0) and (length(s)>0) then block:=length(s) else block:=0;
 repeat
  if c>length(s) then c:=length(s);
  if c<zac then zac:=c;
  if c>=zac+width then zac:=c-width+1;
  if hi(block)+lo(block)>length(s) then block:=either(hi(block)>=length(s),0,block and $FF00+length(s)-hi(block));
  if lo(block)=0 then block:=0;
  for i:=0 to width-1 do
   d^.wrixy(
    either(zac+i>length(s),clrEdit,
     either((lo(block)>0) and IsIn(zac+i,hi(block),hi(block)+lo(block)-1),
      either(zac+i=c,clrBlock shr 4 xor byte(ins) shl 3,clrBlock),
      either(zac+i=c,either(ins,clrCurIns,clrCur),clrEdit))),
    x+i,y,
    eitherS(zac+i<length(s),s[zac+i+1],' '));
  d^.wrixy(clrEdit and $F0+$A,x-1,y,eitherS(zac>0,ikona[7],' '));
  d^.wrixy(clrEdit and $F0+$A,x+width,y,eitherS(length(s)>zac+width,ikona[8],' '));
  d^.FreshFull;
  event:=d^.GetEvent;
  case code(event) of
  kLeft:
   if mem[Seg0040:$17] and 4<>0 then JumpWord(false) else
   if mem[Seg0040:$17] and 3<>0 then
    if c>0 then
     if (lo(block)>0) and (c=hi(block)+lo(block)) then
      begin
       dec(c);
       block:=block and $FF00+lo(block)-1;
      end else
     if (lo(block)>0) and (c=hi(block)) then
      begin
       dec(c);
       block:=(hi(block)-1) shl 8+lo(block)+1;
      end
     else
      begin
       dec(c);
       block:=c shl 8+1;
      end
    else
   else
    begin
     c:=either(c<1,0,c-1);
     if e and inpShyBlock<>0 then block:=0;
    end;
  kRight:
   if mem[Seg0040:$17] and 4<>0 then JumpWord(true) else
   if mem[Seg0040:$17] and 3<>0 then
    if c<length(s) then
     if (lo(block)>0) and (c=hi(block)+lo(block)) then
      begin
       inc(c);
       block:=block and $FF00+lo(block)+1;
      end else
     if (lo(block)>0) and (c=hi(block)) then
      begin
       inc(c);
       block:=(hi(block)+1) shl 8+lo(block)-1;
      end
     else
      begin
       block:=c shl 8+1;
       inc(c);
      end
    else
   else
    begin
     c:=either(c<length(s),c+1,length(s));
     if e and inpShyBlock<>0 then block:=0;
    end;
  kHome:
   if mem[Seg0040:$17] and 3<>0 then
    begin
     if c=hi(block) then block:=hi(block)+lo(block) else
     if c=hi(block)+lo(block) then block:=hi(block)
     else block:=c;
     c:=0;
    end
   else
    begin
     c:=0;
     if e and inpShyBlock<>0 then block:=0;
    end;
  kEnd:
   if mem[Seg0040:$17] and 3<>0 then
    begin
     if c=hi(block)+lo(block) then block:=block and $FF00+length(s)-hi(block) else
     if c=hi(block) then block:=(hi(block)+lo(block)) shl 8+length(s)-hi(block)-lo(block)
     else block:=c shl 8+length(s)-c;
     c:=length(s);
    end
   else
    begin
     c:=length(s);
     if e and inpShyBlock<>0 then block:=0;
    end;
  kDelete:
   if (mem[Seg0040:$17] and 7<>0) and (lo(block)<>0) then
    begin
     if mem[Seg0040:$17] and 3<>0 then clipboard:=Copy(s,hi(block),lo(block));
     Delete(s,hi(block)+1,lo(block));
     if lo(block)<>0 then c:=hi(block);
     block:=0;
    end
   else
    if e and inpShyBlock<>0 then
     begin
      if lo(block)<>0 then
       begin
        Delete(s,hi(block)+1,lo(block));
        c:=hi(block);
       end
      else Delete(s,c+1,1);
      block:=0;
     end
    else
     begin
      if c<hi(block) then block:=(hi(block)-1) shl 8+lo(block) else
      if c<hi(block)+lo(block) then block:=block and $FF00+lo(block)-1;
      Delete(s,c+1,1);
     end;
  kInsert:
   if (mem[Seg0040:$17] and 4<>0) and (lo(block)<>0) then
    clipboard:=Copy(s,hi(block)+1,lo(block)) else
   if mem[Seg0040:$17] and 3<>0 then
    begin
     if (lo(block)<>0) and (e and inpShyBlock<>0) then
      begin
       Delete(s,hi(block),lo(block));
       c:=hi(block);
      end;
     Insert(clipboard,s,c+1);
     block:=c shl 8+length(clipboard);
     if e and inpPasteCur<>0 then inc(c,length(s));
    end
   else ins:=not ins;
  kBackSpace:
   if c>0 then
    begin
     dec(c);
     Delete(s,c+1,1);
     if e and inpShyBlock<>0 then block:=0;
    end;
  kEsc,kEnter,kkEnter,kTab:
   begin
    InputString:=s;
    case code(event) of
    kEsc: ret:=retEsc;
    kEnter,kkEnter: ret:=retEnter;
    kTab: ret:=retTab;
    end;
    break;
   end;
  mcLeftHold:
   if (d^.press.y<>yedit) or not IsIn(d^.press.x,x-1,x+width) then
    begin
     InputString:=s;
     ret:=retTab;
     break;
    end
   else
    begin
     if d^.press.x=x-1 then zac:=either(zac>0,zac-1,0) else
     if d^.press.x=x+width then zac:=either(zac<length(s)-width+1,zac+1,length(s)-width+1) else
      c:=zac+d^.press.x-x;
     if e and inpShyBlock<>0 then block:=$FFFF;
    end;
  end;
  if char(event)<>#0 then TypeChar(char(event))
  else
   case extchar(event) of
   #30: TypeChar(dlgChar);
   end;
 until false;
 d^.wrixy(clrEdit,x-1,y,rep(' ',width+2));
end;  {Tselector.InputString}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function  TSelector.AdjustName(fn:FileStr; lowcase:boolean):string; assembler;
{Upravi string. Predpoklada se, ze fn je jmeno souboru. Upravi ho tak,
 ze doplni pripadne mezery, aby mel string delku dvanact znak– a aby tecka
 (pokud ma priponu) byla na 9. miste. Zaroven jmeno prevede do malych nebo
 velkych znaku. Tuhle funkci vyuziva akorat file-selector. Optimalizovano
 na rychlost. Jeslize prvni znak jmena je tecka, vyplni jmeno znakem #0
 (kvuli razeni, aby adresar ".." byl prvni).}
asm   {TSelector.AdjustName}
 push ds
 push es
 xor  ch,ch
 lds  si,fn
 lodsb
 mov  bh,al  {BH - puvodni delka stringu}
 or   bh,bh
 jz   @nic
 mov  ah,lowcase
 cmp  bh,12
 jae  @case
 mov  al,ds:[si]
 cmp  al,'.'
 je   @tecka
 les  di,fn
 inc  di
 mov  al,'.'
 mov  cl,bh
 repne scasb
 or   cl,cl
 jz   @nopoint
 mov  bl,cl
 neg  bl
 add  bl,bh  {BL - pozice tecky ve stringu}
 les  di,@result
 mov  al,12
 stosb
 mov  cl,bl
 dec  cl
 cmp  ah,true
 je   @3
@1:
 lodsb
 cmp  al,'a'
 jb   @2
 cmp  al,'z'
 ja   @2
 sub  al,'a'-'A'
@2:
 stosb
 loop @1
 jmp  @5
@3:
 lodsb
 cmp  al,'A'
 jb   @4
 cmp  al,'Z'
 ja   @4
 add  al,'a'-'A'
@4:
 stosb
 loop @3
@5:
 mov  al,' '
 mov  cl,9
 sub  cl,bl
 rep  stosb
 mov  cl,bh
 sub  cl,bl
 inc  cl
 cmp  ah,true
 je   @8
@6:
 lodsb
 cmp  al,'a'
 jb   @7
 cmp  al,'z'
 ja   @7
 sub  al,'a'-'A'
@7:
 stosb
 loop @6
 jmp  @10
@8:
 lodsb
 cmp  al,'A'
 jb   @9
 cmp  al,'Z'
 ja   @9
 add  al,'a'-'A'
@9:
 stosb
 loop @8
@10:
 mov  cl,3
 sub  cl,bh
 add  cl,bl
 or   cl,cl
 jz   @end
 mov  al,' '
 rep  stosb
 jmp  @end
@nic:
 les  di,@result
 mov  al,12
 stosb
 mov  al,' '
 mov  cl,8
 rep  stosb
 mov  al,'.'
 stosb
 mov  al,' '
 mov  cl,3
 rep  stosb
 jmp  @end
@tecka:
 les  di,@result
 mov  al,12
 stosb
 mov  cl,al
 xor  al,al
 rep  stosb
 jmp  @end
@case:
 les  di,@result
 mov  al,12
 stosb
 mov  cl,al
 cmp  ah,true
 je   @case4
@case2:
 lodsb
 cmp  al,'a'
 jb   @case3
 cmp  al,'z'
 ja   @case3
 sub  al,'a'-'A'
@case3:
 stosb
 loop @case2
 jmp  @end
@case4:
 lodsb
 cmp  al,'A'
 jb   @case5
 cmp  al,'Z'
 ja   @case5
 add  al,'a'-'A'
@case5:
 stosb
 loop @case4
 jmp  @end
@nopoint:
 les  di,@result
 mov  al,12
 stosb
 mov  cl,bh
 cmp  ah,true
 je   @nopoint4
@nopoint2:
 lodsb
 cmp  al,'a'
 jb   @nopoint3
 cmp  al,'z'
 ja   @nopoint3
 sub  al,'a'-'A'
@nopoint3:
 stosb
 loop @nopoint2
 jmp  @nopoint6
@nopoint4:
 lodsb
 cmp  al,'A'
 jb   @nopoint5
 cmp  al,'Z'
 ja   @nopoint5
 add  al,'a'-'A'
@nopoint5:
 stosb
 loop @nopoint4
@nopoint6:
 mov  al,' '
 mov  cl,12
 sub  cl,bh
 rep  stosb
 jmp  @end
@end:
 pop  es
 pop  ds
end;  {TSelector.AdjustName}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function  Tselector.TimeSlice(time:longint; slice:byte):word; assembler;
{Z promenne %time, ktera je ve formatu file-time, vrati cast casoveho
 udaje, ktery je v jejich bitech ulozen.}
asm   {Tselector.TimeSlice}
 xor  ah,ah
 mov  al,slice
 cmp  al,sortDate
 je   @SliceDate
 cmp  al,sortTime
 je   @SliceTime
 cmp  al,sortYear
 je   @SliceYear
 cmp  al,sortMonth
 je   @SliceMonth
 cmp  al,sortDay
 je   @SliceDay
 cmp  al,sortHour
 je   @SliceHour
 cmp  al,sortMinute
 je   @SliceMinute
 cmp  al,sortSecond
 je   @SliceSecond
 jmp  @end
@SliceDate:
 mov  ax,word ptr time+2
 jmp  @end
@SliceTime:
 mov  ax,word ptr time
 jmp  @end
@SliceYear:
 mov  al,byte ptr time+3
 shr  al,1
 add  ax,1980
 jmp  @end
@SliceMonth:
 mov  ax,word ptr time+2
 and  ah,1
 shr  ax,1
 shr  ax,1
 shr  ax,1
 shr  ax,1
 shr  ax,1
 jmp  @end
@SliceDay:
 mov  al,byte ptr time+2
 and  al,01Fh
 jmp  @end
@SliceHour:
 mov  al,byte ptr time+1
 shr  al,1
 shr  al,1
 shr  al,1
 and  al,01Fh
 jmp  @end
@SliceMinute:
 mov  ax,word ptr time
 and  ah,007h
 shr  ax,1
 shr  ax,1
 shr  ax,1
 shr  ax,1
 shr  ax,1
 jmp  @end
@SliceSecond:
 mov  al,byte ptr time
 and  al,01Fh
 shl  al,1
@end:
end;  {Tselector.TimeSlice}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function  Tselector.AddItem(filerec:SearchRec):boolean;
{Vytvori dynamickou promennou typu TThisFile a prida ji do seznamu souboru.}
var
 p:pointer;
 src:TThisFile;
begin {Tselector.AddItem}
 AddItem:=false;
 if count>=selMaxFiles then
  begin
   ret:=retErr;
   exit;
  end;
 GetMem(p,SizeOf(TThisFile));
 if p=nil then exit;
 with src do
 begin
  attr:=filerec.attr;
  dirc:=dircount;
  size:=filerec.size;
  time:=filerec.time;
  name:=AdjustName(filerec.name,attr and Directory=0);
 end;
 sez[count]:=p;
 move(src,sez[count]^,SizeOf(TThisFile));
 inc(count);
 AddItem:=true;
end;  {Tselector.AddItem}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function Tselector.FindDir(index:byte):DirStr;
begin {Tselector.finddir}
 finddir:=PDir(dirs.At(index))^.dir;
end;  {Tselector.finddir}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function  Tselector.GodWishes(n:byte):boolean;
begin
 god:=(god+1) mod n;
 GodWishes:=god=0;
end;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Procedure Tselector.ReadFiles;
{Nacte jmena souboru a/nebo adresaru do seznamu.}
var
 origmaska,wild,cur:string;
 di:SearchRec;
 oldcount,dirindex:integer;

 procedure SearchFor(mask:PathStr);
 begin
  FindFirst(mask,at and (AnyFile-Directory),di);
  while DosError=0 do
  begin
   if di.attr and Directory=0 then
    if not AddItem(di) then break;
   FindNext(di);
  end;
 end;

begin {Tselector.ReadFiles}
 if dirs_inited then dirs.Done;
 dirs.Init(10,20);
 dirs_inited:=true;
 ClearList;
 origmaska:=maska;
 if maska='' then maska:='*.*';
 cur:=maska;
 wild:='';
 dircount:=0;
 if flags and dlgDontLoadDirs=0 then
  begin
   dirs.Insert(New(PDir,Init('')));
   FindFirst(dirCur+'*.*',AnyFile,di);
   while (DosError=0) and (di.name='.') do FindNext(di);
   while DosError=0 do
    begin
     if di.attr and Directory<>0 then
      if not AddItem(di) then break;
     FindNext(di);
    end;
   inc(dircount);
  end;
 if flags and dlgDontLoadFiles=0 then
  while (wild<>'') or (cur<>'') do
   begin
    {ustrihne jeden kousek}
    if wild='' then wild:=CutString(cur,';');
    {je to pouze adresar?}
    if wild[length(wild)] in [':','\'] then
     begin
      dirs.Insert(New(PDir,Init(wild)));
      wild:='';
     end
    else
    {neni to pouze adresar, zacina tu serie masek}
     begin
      {je to pouze maska?}
      if pos(':',wild)+pos('\',wild)=0 then
       begin
        if (dircount>0) and (finddir(dircount-1)='') then dec(dircount)
         else dirs.Insert(New(PDir,Init('')));
       end
      else
      {je to adresar s maskou}
       begin
        dirs.Insert(New(PDir,Init(PathSlice(wild,psPath))));
        wild:=PathSlice(wild,psFile);
       end;
      {adresare ma nactene}
      {zpracovava a trha dalsi masky dokud neutrhne nemasku}
      oldcount:=dircount;
      repeat
       for dirindex:=oldcount to dirs.count-1 do
        begin
         dircount:=dirindex;{musime nastavit kvuli AddItem}
         SearchFor(finddir(dirindex)+wild);
        end;
       wild:=CutString(cur,';');
      until ((wild='') and (cur='')) or (pos(':',wild)+pos('\',wild)>0);
      dircount:=dirs.count;
     end;
   end;
 maska:=origmaska;
end;  {Tselector.ReadFiles}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Procedure Tselector.SortFiles;
{Seradi soubory a adresare podle promenne %sorting.}
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
 function noot(smer:boolean; n1,n2:byte):boolean; assembler;
 {if smer=true then noot:=n1<n2 else noot:=n1>n2;}
 asm   {noot}
  mov  al,n1
  mov  ah,smer
  cmp  ah,true
  je   @2
  cmp  al,n2
  ja   @je
  jmp  @neni
 @2:
  cmp  al,n2
  jae  @neni
 @je:
  mov  al,true
  jmp  @end
 @neni:
  mov  al,false
 @end:
 end;  {noot}
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
var
 a,b,minpos:word;
 FilesFirst:boolean;
begin {Tselector.SortFiles}
 case count of
 0: exit; {nen¡ co ©adit}
 1: begin
     if sez[0]^.name=Rep(#0,12) then sez[0]^.name:=selUpperDir;
     exit
    end
 end;
 if sorting and $3F=0
 then {nem  ©adit}
  for a:=0 to count-1 do
   if sez[a]^.name=Rep(#0,12) then
    begin
     sez[a]^.name:=selUpperDir;
     exit
    end;
 FilesFirst:=sorting and sortFilesFirst<>0;
 if FilesFirst then
  for a:=0 to count-1 do
   if sez[a]^.name=Rep(#0,12) then
    begin
     sez[a]^.name:=Rep(#255,12);
     break;
    end;
 case sorting and $3F of
 sortName: {podle jm‚na (v p©¡padˆ shody jmen rozhodne podle p©¡pony)}
    for a:=0 to count-2 do
     begin
      minpos:=a;
      for b:=a+1 to count-1 do
       if noot(FilesFirst,sez[b]^.attr and Directory,sez[minpos]^.attr and Directory) or
          ((sez[b]^.attr and Directory=sez[minpos]^.attr and Directory))
           and (sez[b]^.name<sez[minpos]^.name)
       then minpos:=b;
      if minpos>a then xchg4(sez[a],sez[minpos]);
     end;
 sortExt: {podle p©¡pony (v p©¡padˆ shody p©¡pon rozhodne podle jm‚na)}
    for a:=0 to count-2 do
     begin
      minpos:=a;
      for b:=a+1 to count-1 do
       if noot(FilesFirst,sez[b]^.attr and Directory,sez[minpos]^.attr and Directory) or
          ((sez[b]^.attr and Directory=sez[minpos]^.attr and Directory) and
           (Copy(sez[b]^.name,9,3)+Copy(sez[b]^.name,1,8)<Copy(sez[minpos]^.name,9,3)+Copy(sez[minpos]^.name,1,8)))
       then minpos:=b;
      if minpos>a then xchg4(sez[a],sez[minpos]);
     end;
 sortSize: {podle velikosti}
    for a:=0 to count-2 do
     begin
      minpos:=a;
      for b:=a+1 to count-1 do
       if noot(FilesFirst,sez[b]^.attr and Directory,sez[minpos]^.attr and Directory) or
          ((sez[b]^.attr and Directory=sez[minpos]^.attr and Directory))
           and (sez[b]^.size<sez[minpos]^.size)
       then minpos:=b;
      if minpos>a then xchg4(sez[a],sez[minpos]);
     end;
 sortDateAndTime: {podle datumu a ‡asu}
    for a:=0 to count-2 do
     begin
      minpos:=a;
      for b:=a+1 to count-1 do
       if noot(FilesFirst,sez[b]^.attr and Directory,sez[minpos]^.attr and Directory) or
          ((sez[b]^.attr and Directory=sez[minpos]^.attr and Directory))
           and (sez[b]^.time<sez[minpos]^.time)
       then minpos:=b;
      if minpos>a then xchg4(sez[a],sez[minpos]);
     end;
 sortDate,sortTime,sortYear,sortMonth,sortDay,sortHour,sortMinute,sortSecond:
    for a:=0 to count-2 do
     begin
      minpos:=a;
      for b:=a+1 to count-1 do
       if noot(FilesFirst,sez[b]^.attr and Directory,sez[minpos]^.attr and Directory) or
          ((sez[b]^.attr and Directory=sez[minpos]^.attr and Directory))
           and (TimeSlice(sez[b]^.time,sorting and $3F)<TimeSlice(sez[minpos]^.time,sorting and $3F))
       then minpos:=b;
      if minpos>a then xchg4(sez[a],sez[minpos]);
     end;
 sortAttr: {podle atributu}
    for a:=0 to count-2 do
     begin
      minpos:=a;
      for b:=a+1 to count-1 do
       if noot(FilesFirst,sez[b]^.attr and Directory,sez[minpos]^.attr and Directory) or
          ((sez[b]^.attr and Directory=sez[minpos]^.attr and Directory))
           and (byte(sez[b]^.attr and AnyFile)<byte(sez[minpos]^.attr and AnyFile))
       then minpos:=b;
      if minpos>a then xchg4(sez[a],sez[minpos]);
     end;
 sortSeparate: {oddˆl¡ adres ©e od soubor–}
    for a:=0 to count-2 do
     begin
      minpos:=a;
      for b:=a+1 to count-1 do
       if noot(FilesFirst,sez[b]^.attr and Directory,sez[minpos]^.attr and Directory)
       then minpos:=b;
      if minpos>a then xchg4(sez[a],sez[minpos]);
     end;
 end; {case}
 for a:=0 to count-1 do
  if (sez[a]^.name=Rep(#0,12)) or (sez[a]^.name=Rep(#255,12)) then
   begin
    sez[a]^.name:=selUpperDir; {Tohle nebylo zrovna profesion ln¡ :-(}
    break
   end;
 if sorting and sortFlipList<>0 then {kdy‘ je nastaveno ©azen¡ v sestupn‚m po©ad¡, obr t¡ seznam}
  for a:=0 to (count-1) shr 1 do
   xchg4(sez[a],sez[count-1-a]); {symetricky vymˆnuje pointery sez[a] a sez[posledni-a]}
end;  {Tselector.SortFiles}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Procedure Tselector.PreSelektni(fn:string12);
var j:word;
begin {Tselector.PreSelektni}
 c1:=0; c2:=0;
 fn:=AdjustName(fn,true);
 if (fn='') or (count<1) then exit;
 for j:=0 to count-1 do
  with sez[j]^ do
  if lcased(name)=fn then
   begin
    c1:=0;
    c2:=j;
    for j:=0 to w*h shr 1 do
     if (c2<=0) or (c1>=c1max) then break else
      begin
       dec(c2);
       inc(c1);
      end;
    while (c2>c2max) and (c1<=c1max) do
     begin
      dec(c2);
      inc(c1);
     end;
    break;
   end;
end;  {Tselector.PreSelektni}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Procedure Tselector.DrawScrollBar;
{Nakresli listu podle promenne scrollbar.}
var i,j:word;
begin {Tselector.DrawScrollBar}
 case scrollbar of
 barVertical:
  if (h>1) and (count>0) then
   repeat
    d^.wrixy(clrScroll,x0+w*(itemw+1)-1,y0,ikona[5]);
    d^.wrixy(clrScroll,x0+w*(itemw+1)-1,y0+h-1,ikona[6]);
    if h<3 then break;
    if count<2 then
     for i:=0 to h-3 do
      d^.wrixy(clrScroll,x0+w*(itemw+1)-1,y0+1+i,ikona[9])
    else
     begin
      j:=(h-3)*(c1+c2) div (count-1);
      for i:=0 to h-3 do
       d^.wrixy(clrScroll,x0+w*(itemw+1)-1,y0+1+i,eitherS(i<>j,ikona[10],ikona[12]));
     end;
   until true;
 barHorizontal:
  if editw-2>1 then
   if count<2 then
    d^.wrixy(clrScroll,x0,y0+h,ikona[7]+rep(ikona[9],editw-2)+ikona[8])
   else
    begin
     j:=(editw-3)*(c1+c2) div (count-1);
     d^.wrixy(clrScroll,x0,y0+h,ikona[7]+rep(ikona[10],j)+ikona[12]+rep(ikona[10],editw-3-j)+ikona[8])
    end;
 barArrows:
  begin
   d^.wrixy(either(c2>0,$3E,$38),x0-1,y0,ikona[1]);
   d^.wrixy(either(c2<c2max,$3E,$38),x0+editw,y0+h-1,ikona[2]);
  end;
 end;{case}
end;  {Tselector.DrawScrollBar}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Procedure Tselector.DrawFileTab;
{Vypise soubory a adresare v tabulce,editLn,quick-find string a DetailWindow}
var i:word;
begin {Tselector.DrawFileTab}
 if count>0 then
  for i:=0 to c1max do
   with sez[c2+i]^ do {vypsani vsech souboru videnych v tabulce}
   d^.wrixy(
    either(i<>c1,
     either(sez[c2+i]^.attr and selMark=0,either(dirc=0,clrFiles,clrDir2),clrFiles and $F0+clrMarked and $0F),
     either(sez[c2+i]^.attr and selMark=0,clrActive,clrActive and $F0+clrMarked and $0F))
   ,x0+(i div h)*(itemw+1),y0+i mod h,
    eitherS(item and itemName=0,'',Copy(name,1,8))+
    eitherS(item and itemExt =0,'',eitherS(flags and dlgHideExt<>0,'    ',Copy(name,9,4)))+
    eitherS(item and itemSize=0,'',eitherS(attr and Directory<>0,'<DIRECTORY>',Right(stri(size),11)))+
    eitherS(item and itemDate=0,'',' '+
     WithZeroes(TimeSlice(time,sortDay),2)+'.'+
     WithZeroes(TimeSlice(time,sortMonth),2)+'.'+
     Right(stri(TimeSlice(time,sortYear)),2)+
    eitherS(item and itemTime=0,'',' '+
     WithZeroes(TimeSlice(time,sortHour),2)+':'+
     WithZeroes(TimeSlice(time,sortMinute),2)))+
    eitherS(item and itemAttr=0,'',' '+
     eitherS(attr and Archive<>0,'-','a')+
     eitherS(attr and ReadOnly=0,'-','r')+
     eitherS(attr and Hidden  =0,'-','h')+
     eitherS(attr and SysFile =0,'-','s')));
 if flags and dlgShowQuickFindStr<>0 then
  d^.wrixy(clrInf,x0,yqfind,Left('['+qfind+']',editw));
 if (count>0) and (flags and dlgShowDetailTab<>0) and (editw>10) then
  with sez[c1+c2]^ do
  begin {detail window}
   d^.wrixy(clrDetail,x0,ydetail,Left(
    eitherS(attr and Directory=0,Right(stri(size),11),'<DIRECTORY>')+
    eitherS(editw<24,'',' '+name)
    ,editw));
   d^.wrixy(clrDetail,x0,ydetail+1,Left(
    WithZeroes(TimeSlice(time,sortDay),2)+'.'+
    WithZeroes(TimeSlice(time,sortMonth),2)+'.'+
    Right(stri(TimeSlice(time,sortYear)),2)+
    eitherS(editw<14,'',' '+
     WithZeroes(TimeSlice(time,sortHour),2)+':'+
     WithZeroes(TimeSlice(time,sortMinute),2))+
    eitherS(editw<19,'',' '+
     eitherS(attr and Archive<>0,'-','a')+
     eitherS(attr and ReadOnly=0,'-','r')+
     eitherS(attr and Hidden  =0,'-','h')+
     eitherS(attr and SysFile =0,'-','s'))+
    eitherS(editw<20+length(maska),' '+Left(maska,editw-21)+'',' '+maska)
    ,editw));
  end;
end;  {Tselector.DrawFileTab}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function  Tselector.NumSelected(what:byte):word;
var i,j:word;
begin {Tselector.NumSelected}
 j:=0;
 if count>0 then
  case what of
  1: for i:=0 to count-1 do
      with sez[i]^ do
      if (attr and (Directory+selMark)=Directory+selMark) then inc(j);
  2: for i:=0 to count-1 do
      with sez[i]^ do
      if (attr and (Directory+selMark)=selMark) then inc(j);
  3: for j:=0 to count-1 do
      with sez[i]^ do
      if attr and selMark<>0 then inc(j);
  end;
 NumSelected:=j;
end;  {Tselector.NumSelected}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Procedure Tselector.MouseEvents;
{Zpracuje udalosti mysi. Kurzor se nad soubory presouva pri drzeni leveho
 mysitka. Uvolnenim v tabulce soubor– vyberes aktualni soubor/adresar.
 Tabulka scrolluje i kdyz je stisknuto mimo ni. Li¨ty lze ovladat taky.}
var j:word;
begin {Tselector.MouseEvents}
 event:=d^.GetEvent;
 case code(event) of
 mcCenterHold: {emuluje scrollovani nahoru/dolu podle y-souradnice mysi}
  if d^.press.y<(2*y0+h-1) div 2 then
   if (count>0) and (c2>0)
    then dec(c2)
    else
   else
  if d^.press.y>(2*y0+h-1) div 2 then
   if (count>0) and (c2<c2max) then inc(c2);
 mcLeftHold:
  begin
   if IsIn(d^.press.x,x0,x0+editw-1) and {presune kurzor na soubor/adresar}
      IsIn(d^.press.y,y0,y0+h-1) and
      ((d^.press.x-x0) mod (itemw+1)<>itemw)
   then c1:=Bounded(((d^.press.x-x0) div (itemw+1))*h+d^.press.y-y0,0,c1max);
   if IsIn(d^.press.x,x0,x0+itemw-1) and (d^.press.y<y0) then
    if godWishes(3) then
     if (count>0) and not((c1=0) and (c2=0)) then {v prvnim sloupci nad tabulkou emuluje kUp}
      if c1=0 then
       if c2>0
       then dec(c2)
       else
      else dec(c1);
   if IsIn(d^.press.x-x0,(w-1)*(itemw+1),(w-1)*(itemw+1)+itemw-1) and (d^.press.y>=y0+h+byte(scrollbar=barHorizontal)) then
    if godWishes(3) then
     if (count>0) and not((c2=c2max) and (c1=c1max)) then {v poslednim sloupci pod tabulkou emuluje kDown}
      if c1=c1max then
       if c2<c2max
       then inc(c2)
       else
      else inc(c1);
   if IsIn(d^.press.y,y0,y0+h-1) and (d^.press.x<x0-1) then
    if godWishes(10) then
     if (count>0) and not((c1=0) and (c2=0)) then {nalevo od tabulky emuluje kLeft}
      if c1<h then
       if c2=0 then c1:=0 else
        if c2<h then c2:=0
        else c2:=c2-h
      else c1:=c1-h;
   if IsIn(d^.press.y,y0,y0+h-1) and (d^.press.x>x0+editw) then
    if godWishes(10) then
     if (count>0) and not((c2=c2max) and (c1=c1max)) then {napravo od tabulky emuluje kRight}
      if c1 div h=w-1 then
       if c2=c2max then c1:=c1max
       else c2:=either(c2+h>c2max,c2max,c2+h)
      else c1:=either(c1+h>c1max,c1max,c1+h);
   case scrollbar of
   barVertical:
    if d^.press.x=x0+editw then
     begin
      if d^.press.y=y0 then
       if godWishes(10) then
        if (count>0) and not((c1=0) and (c2=0)) then
         if c1=0 then
          if c2>0
          then dec(c2)
          else
         else dec(c1);
      if d^.press.y=y0+h-1 then
       if godWishes(10) then
        if (count>0) and not((c2=c2max) and (c1=c1max)) then
         if c1=c1max then
          if c2<c2max
          then inc(c2)
          else
         else inc(c1);
     end;
   barHorizontal:
    if d^.press.y=y0+h then
     begin
      if d^.press.x=x0 then
       if godWishes(10) then
        if (count>0) and not((c1=0) and (c2=0)) then
         if c1<h then
          if c2=0 then c1:=0 else
           if c2<h then c2:=0
           else c2:=c2-h
         else c1:=c1-h;
      if d^.press.x=x0+editw-1 then
       if godWishes(10) then
        if (count>0) and not((c2=c2max) and (c1=c1max)) then
         if c1 div h=w-1 then
          if c2=c2max then c1:=c1max
          else c2:=either(c2+h>c2max,c2max,c2+h)
         else c1:=either(c1+h>c1max,c1max,c1+h);
     end;
   barArrows:
    if (d^.press.x=x0-1) and (d^.press.y=y0) then
     if godWishes(10) then
      if (count>0) and not((c1=0) and (c2=0)) then
       if c1=0 then
        if c2>0
        then dec(c2)
        else
       else dec(c1);
    else if (d^.press.x=x0+editw) and (d^.press.y=y0+h-1) then
     if godWishes(10) then
      if (count>0) and not((c2=c2max) and (c1=c1max)) then
       if c1=c1max then
        if c2<c2max
        then inc(c2)
        else
       else inc(c1);
   end; {case scrollbar}
  end; {case barVertical}
 mcLeftPressed:
  begin
   if IsIn(d^.press.x,x0,x0+editw-1) and (d^.press.y=yedit)
   then event:=MakeEvent(kTab,#9,#0);
   if (d^.press.x<x0) and (d^.press.y<y0) then {v levym hornim rohu emuluje PgUp}
    if (count>0) and not((c1=0) and (c2=0)) then
     if c1<h then
      if c2=0 then c1:=0 else
       if c2<h then c2:=0
       else c2:=c2-h
     else c1:=c1-h;
   if (d^.press.x>x0+editw-1) and (d^.press.y>y0+h-1) then {v pravym dolnim rohu emuluje PgDn}
    if count>0 then
     if not((c2=c2max) and (c1=c1max)) then
      if c2=c2max then c1:=c1max
      else c2:=either(c2+h*w>c2max,c2max,c2+h*w);
   case scrollbar of
   barVertical:
    if d^.press.x=x0+editw then
     if IsIn(d^.press.y,y0+1,y0+h-2) and (count>1) then
      begin
       j:=(h-3)*(c1+c2) div (count-1);
       if d^.press.y<y0+1+j then
        if (count>0) and not((c1=0) and (c2=0)) then
         if c1<h then
          if c2=0 then c1:=0 else
           if c2<h then c2:=0
           else c2:=c2-h
         else c1:=c1-h;
       if d^.press.y>y0+1+j then
        if (count>0) and not((c2=c2max) and (c1=c1max)) then
         if c1 div h=w-1 then
          if c2=c2max then c1:=c1max
          else c2:=either(c2+h>c2max,c2max,c2+h)
         else c1:=either(c1+h>c1max,c1max,c1+h);
      end;
   barHorizontal:
    if d^.press.y=y0+h then
     if IsIn(d^.press.x,x0+1,x0+editw-2) and (count>1) then
      begin
       j:=(editw-3)*(c1+c2) div (count-1);
       if d^.press.x<x0+1+j then
        if (count>0) and not((c1=0) and (c2=0)) then
         if c2=0 then c1:=0 else
          if c2<h*w then c2:=0
          else c2:=c2-h*w;
       if d^.press.x>x0+1+j then
        if count>0 then
         if not((c2=c2max) and (c1=c1max)) then
          if c2=c2max then c1:=c1max
          else c2:=either(c2+h*w>c2max,c2max,c2+h*w);
      end;
   end; {case scrollbar}
  end; {case mcLeftPressed}
 mcLeftReleased:
  if IsIn(d^.press.x,x0,x0+editw-1) and
     IsIn(d^.press.y,y0,y0+h-1) and
     ((d^.press.x-x0) mod (itemw+1)<>itemw) then
   begin
    c1:=((d^.press.x-x0) div (itemw+1))*h+d^.press.y-y0;
    if c1>c1max then c1:=c1max else event:=MakeEvent(kEnter,#13,#0);
   end;
 end; {case}
end;  {Tselector.MouseEvents}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Procedure Tselector.HandleEvents;
var
 i:word;
begin {Tselector.HandleEvents}
 ret:=0;
 MouseEvents;
 if (extchar(event)=#0) and ((char(event) in CharsInFile) or (code(event)=kBackSpace))
 then else qfind[0]:=#0; {QuickFind string vynuluje stisk klavesy, ktera nemuze byt soucasti jmena souboru}
 case code(event) of
 kUp:
  if (count>0) and not((c1=0) and (c2=0)) then
   if c1=0 then
    if c2>0
    then dec(c2)
    else
   else dec(c1);
 kDown:
  if (count>0) and not((c2=c2max) and (c1=c1max)) then
   if c1=c1max then
    if c2<c2max
    then inc(c2)
    else
   else inc(c1);
 kPgUp:
  if extchar(event)='I' then
   if (count>0) and not((c1=0) and (c2=0)) then
    if c2=0 then c1:=0 else
     if c2<h*w then c2:=0
     else c2:=c2-h*w;
 kPgDwn:
  if extchar(event)='Q' then
   if count>0 then
    if not((c2=c2max) and (c1=c1max)) then
     if c2=c2max then c1:=c1max
     else c2:=either(c2+h*w>c2max,c2max,c2+h*w);
 kHome:
  if (count>0) and not((c1=0) and (c2=0)) then
   begin
    c1:=0;
    c2:=0;
   end;
 kEnd:
  if (count>0) and not((c2=c2max) and (c1=c1max)) then
   begin
    c2:=c2max;
    c1:=c1max;
   end;
 kEsc:
  ret:=retEsc;
 kBackSpace:
  begin {BackSpace:pro rychle vyhledavani}
   if qfind[0]>#0
   then dec(qfind[0]);
   qfind:=lcased(qfind);
   for i:=0 to count-1 do
    if lcased(Copy(WithoutChar(' ',sez[i]^.name),1,length(qfind)))=qfind then
     begin {nasel soubor zacinajici na qfind}
      c1:=0;
      c2:=i;
      for i:=1 to (w*h) shr 1 do {zmeni ukazatele tak,aby bylo jmeno souboru bylo zobrazeno pokud mozno uprostred tabulky}
       if (c2>0) and (c1<c1max)
       then begin dec(c2); inc(c1) end
       else break;
      while (c2>c2max) and (c1<=c1max) do
       begin
        dec(c2);
        inc(c1);
       end;
      i:=$FFFF;
      break
     end
  end; {case kBackSpace}
 else {case: rychle vyhlodavani}
  if (extchar(event)=#0) and (char(event) in CharsInFile) and (count>0) then
   begin
    if qfind[0]<#12
    then qfind:=qfind+char(event);
    qfind:=lcased(qfind);
    for i:=0 to count-1 do
     if lcased(Copy(WithoutChar(' ',
         sez[either(flags and dlgSearchFromCursor=0,i,(c2+i) mod count)]^.name),1,length(qfind)))=qfind then
      begin {nasel string zacinajici na qfind}
       c1:=0;
       c2:=i;
       for i:=1 to (w*h) shr 1 do
        if (c2>0) and (c1<c1max) then
         begin
          dec(c2);
          inc(c1)
         end
        else break;
       while (c2>c2max) and (c1<=c1max) do
        begin
         dec(c2);
         inc(c1);
        end;
       i:=$FFFF;
       break;
      end;
    if i<>$FFFF then dec(qfind[0]) {kdyz byl stisknut spatny znak, vymaze ho, aby qfind neukazoval na neexistujici jmeno}
   end
 end;
 case char(event) of
 #23: {CTRL-W}
  if (count>0) and (c2>0) then dec(c2);
 #24: {CTRL-X}
  if (count>0) and (c2<c2max) then inc(c2);
 'w': {CTRL-Home}
  c1:=0;
 'u': {CTRL-End}
  c1:=c1max;
 end;
end;  {Tselector.HandleEvents}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Procedure Tselector.ReRead;
begin {Tselector.ReRead}
 ReadFiles;
 Arrange;
 SortFiles;
end;  {Tselector.ReRead}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Procedure Tselector.Arrange;
var
 j:word;
 s:Tstopky;
 curdir:PathStr;
begin {Tselector.Arrange}
 for j:=0 to w*h-1 do
  d^.wrixy(clrFiles,x0+(j div h)*(itemw+1),y0+(j mod h),Rep(' ',itemw));
 c1:=0;
 c2:=0;
 qfind:='';
 if count>0 then
  if count>w*h then c1max:=w*h-1
  else c1max:=count-1
 else c1max:=0;
 if count>w*h then c2max:=count-w*h else c2max:=0;
 DrawScrollbar;
 if flags and dlgNoEditLine=0 then
  d^.wrixy(clrEdit,x0,yedit,rep(' ',editw));
 if (flags and dlgShowDirectory<>0) and (editw>7) then
  begin
   curdir:=PathSlice(dirCur,psPascalPath);
   if length(curdir)>editw
   then curdir:=Copy(curdir,1,3)+'..'+Right(curdir,editw-5)
   else curdir:=Left(curdir,editw);
   d^.wrixy(clrInf,x0,ycurdir,curdir);
  end;
 if ret=retErr then
  begin
   ret:=0;
   case h of
   1:    d^.wrixy(clrFiles,x0,y0,Left(_(_selPrilisMnoho)+' '+_(_selSouboru),itemw));
   else begin
         d^.wrixy(clrFiles,x0,y0,Left(_(_selPrilisMnoho),itemw));
         d^.wrixy(clrFiles,x0,y0+1,Left(_(_selSouboru),itemw));
        end;
   end;
   d^.FreshFull;
   s.Start;
   repeat until Keypressed or (s.LookAt>=1500);
  end;
 if count>300 then
  begin
   ret:=0;
   case h of
   1:    d^.wrixy(clrFiles,x0,y0,Left(_(_selRadim),itemw));
   2:   begin
         d^.wrixy(clrFiles,x0,y0,Left(_(_selCekejte),itemw));
         d^.wrixy(clrFiles,x0,y0+1,Left(_(_selRadim),itemw));
        end;
   else begin
         d^.wrixy(clrFiles,x0,y0,Left(_(_selCekejte),itemw));
         d^.wrixy(clrFiles,x0,y0+1,Left(_(_selProsim),itemw));
         d^.wrixy(clrFiles,x0,y0+2,Left(_(_selRadim),itemw));
        end;
   end;
   d^.FreshFull;
  end;
end;  {Tselector.ReRead}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function  Tselector.SelectFile(preselect:string):string;
{Nech  u‘ivatele vybrat si jeden ze soubor– (adres ©–).}
var
 i:word;
 res:string;
begin {Tselector.SelectFile}
 origdir:=dirCur;
 if PathSlice(preselect,psPath)<>'' then dirChange(PathSlice(preselect,psPath));
 parent:=PathSlice(PathSlice(dirCur,psPascalPath),psFile);
 ReRead;
 PreSelektni(preselect);
 repeat
  DrawFileTab;
  if (flags and dlgNoEditLine=0) then
   if sez[c1+c2]<>nil then
    begin
     res:=finddir(sez[c1+c2]^.dirc)+WithoutChar(' ',sez[c1+c2]^.name);
     if length(res)<editw then res:=Left(res,editw) else res:=Copy(res,1,editw);
     d^.wrixy(clrEdit,x0,yedit,res);
    end;
  DrawScrollbar;
  d^.FreshFull;
  HandleEvents;
  case code(event) of
  kLeft:
   if (count>0) and not((c1=0) and (c2=0)) then
    if c1<h then
     if c2=0 then c1:=0 else
      if c2<h then c2:=0
      else c2:=c2-h
    else c1:=c1-h;
  kRight:
   if (count>0) and not((c2=c2max) and (c1=c1max)) then
    if c1 div h=w-1 then
     if c2=c2max then c1:=c1max
     else c2:=either(c2+h>c2max,c2max,c2+h)
    else c1:=either(c1+h>c1max,c1max,c1+h);
  kPgUp:
   if extchar(event)='„' then {CTRL-PgUp}
    if length(dirCur)>3 then
     if dirChange('..') then
      begin
       ReRead;
       parent:=PathSlice(PathSlice(dirCur,psPascalPath),psFile);
      end;
  kPgDwn:
   if extchar(event)='v' then {CTRL-PgDn}
    if (sez[c1+c2]^.attr and Directory<>0) and dirChange(WithoutChar(' ',sez[c1+c2]^.name)) then
     if sez[c1+c2]^.name=selUpperDir then
      begin
       ReRead;
       PreSelektni(parent);
       parent:=PathSlice(PathSlice(dirCur,psPascalPath),psFile);
      end
     else
      begin
       parent:=PathSlice(PathSlice(dirCur,psPascalPath),psFile);
       ReRead;
      end;
  kEnter:
   if count>0 then
    if (char(event)=#10) and {CTRL-Enter}
       (sez[c1+c2]^.attr and Directory<>0) and
       (sez[c1+c2]^.name<>selUpperDir) and
       (flags and dlgDontLoadFiles<>0) and
       ((flags and dlgForbidNew=0) or DirExists(sez[c1+c2]^.name))
    then ret:=retEnter else
    if char(event)=#13 then  {Enter}
     if sez[c1+c2]^.attr and Directory<>0 then
      begin {zmˆna adres ©e}
       if (sez[c1+c2]^.name=selUpperDir) and dirChange('..') then {o £rove¤ n¡‘}
        begin
         ReRead;
         PreSelektni(parent);
         parent:=PathSlice(PathSlice(dirCur,psPascalPath),psFile);
        end else
       if dirChange(WithoutChar(' ',sez[c1+c2]^.name)) then {o £rove¤ v˜¨}
        begin
         parent:=WithoutChar(' ',sez[c1+c2]^.name);
         ReRead;
        end;
      end
     else {v˜bˆr souboru}
      begin
       res:=fExpand(finddir(sez[c1+c2]^.dirc))+WithoutChar(' ',sez[c1+c2]^.name);
       if ((flags and dlgForbidNew=0) or FileExists(res))
       then  ret:=retEnter;
      end;
  kInsert,kSpace:
   if (count>0) and (manager>0) then
    begin
     if (sez[c1+c2]^.name<>selUpperDir) then
      sez[c1+c2]^.attr:=sez[c1+c2]^.attr xor selMark;
     if (count>0) and not((c2=c2max) and (c1=c1max)) then
      if c1=c1max then
       if c2<c2max
       then inc(c2)
       else
      else inc(c1);
    end;
  kkPlus:
   if (count>0) and (manager>0) then
    for i:=0 to count-1 do
     if sez[i]^.name<>selUpperDir
     then sez[i]^.attr:=sez[i]^.attr or selMark
     else sez[i]^.attr:=sez[i]^.attr and AnyFile;
  kkMinus:
   if (count>0) and (manager>0) then
    for i:=0 to count-1 do
     sez[i]^.attr:=sez[i]^.attr and AnyFile;
  kDelete:
   if (count>0) then if (sez[c1+c2]^.name<>selUpperDir) and (manager>0) then
    begin
     if (manager and mngWriteFiles<>0) and (sez[c1+c2]^.attr and Directory=0) then
      if NumSelected(1)=0 then
       fileDelete(0,WithoutChar(' ',sez[c1+c2]^.name))
      else
       for i:=0 to count-1 do
        with sez[i]^ do
        if attr and Directory=0 then fileDelete(0,WithoutChar(' ',name));
     if (manager and mngWriteDirs<>0) and (sez[c1+c2]^.attr and Directory<>0) then
      if NumSelected(2)=0 then
       dirDelete(fileWithSubDirs,WithoutChar(' ',sez[c1+c2]^.name))
      else
       for i:=0 to count-1 do
        with sez[i]^ do
        if attr and Directory<>0 then dirDelete(0,WithoutChar(' ',name));
     ReRead;
    end;
  kTab:
   if flags and dlgNoEditLine=0 then
    repeat
     if sez[c1+c2]=nil then res:='' else
      res:=finddir(sez[c1+c2]^.dirc)+WithoutChar(' ',sez[c1+c2]^.name);
     res:=InputString(res
     ,x0,yedit,either(flags and dlgCursorToStart=0,$FF,0),sizeof(PathStr)-1,editw,stdinp);
     if ret<>retEnter then
      begin
       ret:=0;
       break;
      end;
     res:=ucased(getcore(res));
     if (res[0]+res[2]=#2':') then {napr: "A:"}
      begin
       ret:=0;
       if UpCase(res[1])=dskCur then break;
       if dskChange(res[1]) then
        begin
         ReRead;
         parent:=PathSlice(PathSlice(dirCur,psPascalPath),psFile);
        end
       else ReportErr(_(_selDrive)+' '+res[1]+': '+_(_selNotReady));
       break;
      end;
     if (Pos(';',res)=0) and (Pos('?',PathSlice(res,psFile))+Pos('*',PathSlice(res,psFile))>0) then
      begin {napr: "C:\PROGRAMY\*.pas"}
       ret:=0;
       dirChange(PathSlice(res,psPath));
       maska:=PathSlice(res,psFile);
       ReRead;
       break;
      end;
     if Pos(';',res)>0 then
      begin {napr: "*.pas;A:\*.exe"}
       maska:=res;
       ReRead;
       ret:=0;
       break;
      end else
     if dirExists(res) then
      begin
       ret:=0;
       if (flags and dlgDontLoadFiles<>0) and (flags and dlgDontLoadDirs=0) then
        begin {kdyz zobrazuje jen same adresare, bere to jako vysledek funkce}
         SelectFile:=dirCur+WithoutChar(' ',sez[c1+c2]^.name);
         exit;
        end
       else
        if dirChange(res) then ReRead;
       break;
      end;
     if (flags and dlgForbidNew<>0) and not(fileExists(res)) then
      begin
       ret:=0;
       break;
      end;
     SelectFile:=fExpand(res);
     exit;
    until true;
  end;
  case char(event) of
  #18: {CTRL-R}
   ReRead;
  end;
  if ret in [retEsc,retEnter,retErr] then break;
 until false;
 if ret=retEsc then
  if flags and dlgEscReturnsNothing<>0 then SelectFile:=''
   else SelectFile:=preselect
 else
  if sez[c1+c2]=nil then SelectFile:=''
   else SelectFile:=finddir(sez[c1+c2]^.dirc)+WithoutChar(' ',sez[c1+c2]^.name);
 if flags and dlgUpdateDir=0 then
  dirChange(origdir);
end;  {Tselector.SelectFile}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  dlgSelector(flagy:word;popisek,masc,preselect:string):string;
var
 f:Pselector;
 sloupcu,radek:byte;
 i:integer;
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
 procedure GetSize(var sir,vys:word;maxsir,maxvys:word);far;
 begin {GetSize}
  with f^ do
  begin
   itemw:=0;
   if item and itemName<>0 then inc(itemw,8);
   if item and itemExt <>0 then inc(itemw,4);
   if item and itemSize<>0 then inc(itemw,11);
   if item and itemDate<>0 then inc(itemw,9);
   if item and itemTime<>0 then inc(itemw,7);
   if item and itemAttr<>0 then inc(itemw,5);
   if (itemw=0) or (itemw+4>maxsir) then
    begin
     sir:=$FFFF;
     vys:=$FFFF;
     exit;
    end;
  end;
  if flagy and dlgRatherBig<>0 then
   begin
    vys:=maxvys*9 div 10;
    sloupcu:=(maxsir-3-byte(stdbar=barVertical)) div (f^.itemw+1);
    sir:=3+byte(stdbar=barVertical)+sloupcu*(f^.itemw+1);
   end
  else
   begin
    vys:=maxvys shr 1;
    sloupcu:=(maxsir*4 div 10) div f^.itemw;
    sir:=3+byte(stdbar=barVertical)+sloupcu*(f^.itemw+1);
    if sir>maxsir then sloupcu:=1;
   end
 end;  {GetSize}
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
begin {dlgSelector}
 dlgSelector:='';
 if stditem=0 then exit;
 New(f,Init);
 if NewDialog(f^.d,0,0,@GetSize) then
  with f^ do
  repeat
   d^.Frame;
   maska:=masc;
   flags:=flagy;
   radek:=byte(popisek<>'');
   if flags and dlgNoEditLine=0 then begin inc(radek); yedit:=radek; end;
   if flags and dlgShowQuickFindStr<>0 then begin inc(radek); yqfind:=radek; end;
   if flags and dlgShowDirectory<>0 then begin inc(radek); ycurdir:=radek; end;
   x0:=2;
   y0:=1+radek;
   w:=sloupcu;
   i:=d^.chrY-2-radek;
   if scrollbar=barHorizontal then dec(i);
   if flags and dlgShowDetailTab<>0 then begin dec(i,2); ydetail:=d^.chrY-3; end;
   if (i>0) and (sloupcu>0) then
    begin
     h:=i;
     editw:=w*itemw+w-1;
     if popisek<>'' then d^.wriXY($30,2,1,Left(popisek,editw));
     dlgSelector:=SelectFile(preselect);
    end
   else
    dlgSelector:='';
   d^.Free;
   Dispose(f,Done);
  until true;
end;  {dlgSelector}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Procedure Tselector.ReadDirectories;
var
 dir:PathStr;
 di:SearchRec;
 level,i:byte;
begin {Tselector.ReadDirectories}
 ClearList;
 dir:=ucased(dirCur);
 with di do
 begin
  name:='Disky:';
  size:=0;
  attr:=0;
 end;
 AddItem(di);
 level:=1;
 while dir<>'' do
  with di do
  begin
   name:=CutString(dir,'\');
   if name[0]+name[2]=#2':' then name:=name+'\';
   attr:=Directory;
   size:=level;
   homedir:=level;
   AddItem(di);
   inc(level);
  end;
 dir:=Copy(sez[1]^.name,1,2);
 for i:=2 to homedir do
  begin
   dir:=dir+'\'+WithoutChar(' ',sez[i]^.name);
   FindFirst(dir,Directory,di);
   if DosError=0 then sez[i]^.attr:=di.attr;
  end;
 FindFirst(maska,Directory,di);
 while (DosError=0) and (di.name[1]='.') do FindNext(di);
 repeat
  while (DosError=0) and (di.attr and Directory=0) do FindNext(di);
  if DosError=0 then
   begin
    di.size:=level;
    AddItem(di);
    FindNext(di);
   end
  else break;
 until false;
end;  {Tselector.ReadDirectories}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Procedure Tselector.SortDirectories;
var a,b,minpos:word;
begin {Tselector.SortDirectories}
 if (sorting and $3F=0) or (homedir+2>=count) then exit;
 case sorting and $3F of
 sortName:
  for a:=homedir+1 to count-2 do
   begin
    minpos:=a;
    for b:=a+1 to count-1 do
     if (sez[b]^.size<sez[minpos]^.size) or
        ((sez[b]^.size=sez[minpos]^.size) and (sez[b]^.name<sez[minpos]^.name))
     then minpos:=b;
    if minpos>a then xchg4(sez[a],sez[minpos]);
   end;
 sortExt:
  for a:=homedir+1 to count-2 do
   begin
    minpos:=a;
    for b:=a+1 to count-1 do
     if (sez[b]^.size<sez[minpos]^.size) or
        ((sez[b]^.size=sez[minpos]^.size) and
         (Copy(sez[b]^.name,9,3)+Copy(sez[b]^.name,1,8)<Copy(sez[minpos]^.name,9,3)+Copy(sez[minpos]^.name,1,8)))
     then minpos:=b;
    if minpos>a then xchg4(sez[a],sez[minpos]);
   end;
 sortDate,sortTime,sortYear,sortMonth,sortDay,sortHour,sortMinute,sortSecond:
    for a:=0 to count-2 do
     begin
      minpos:=a;
      for b:=a+1 to count-1 do
       if (sez[b]^.size<sez[minpos]^.size) or
          ((sez[b]^.attr and Directory=sez[minpos]^.attr and Directory))
           and (TimeSlice(sez[b]^.time,sorting and $3F)<TimeSlice(sez[minpos]^.time,sorting and $3F))
       then minpos:=b;
      if minpos>a then xchg4(sez[a],sez[minpos]);
     end;
 sortAttr:
  for a:=homedir+1 to count-2 do
   begin
    minpos:=a;
    for b:=a+1 to count-1 do
     if (sez[b]^.size<sez[minpos]^.size) or
        ((sez[b]^.size=sez[minpos]^.size) and
         (sez[b]^.attr<sez[minpos]^.attr))
     then minpos:=b;
    if minpos>a then xchg4(sez[a],sez[minpos]);
   end;
 end; {case}
 if sorting and sortFlipList<>0 then
  begin {kdy‘ je nastaveno ©azen¡ v sestupn‚m po©ad¡, obr t¡ seznam}
   for a:=0 to (count-1) shr 1 do
    xchg4(sez[a],sez[count-1-a]); {symetricky vymˆnuje pointery sez[a] a sez[posledni-a]}
   homedir:=count-homedir-1;
  end;
end;  {Tselector.SortDirectories}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Procedure Tselector.ReGain;
var
 i:byte;
begin {Tselector.ReGain}
 ReadDirectories;
 SortDirectories;
 c1:=0;
 c2:=homedir;
 for i:=0 to c1max*8 div 10 do
  if (c1<c1max) and (c2>0) then
   begin
    inc(c1);
    dec(c2);
   end;
 Arrange;
end;  {Tselector.ReGain}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function  Tselector.SelectDisk:boolean;
var
 _c1,_c1max:byte;
 _c2,_c2max,i:word;
 dsk:char;
 disky:string[ord('Z')-ord('A')];
begin {Tselector.SelectDisk}
 SelectDisk:=false;
 disky:=dskList;
 if length(disky)<2 then exit;
 _c1:=c1; _c1max:=c1max;
 _c2:=c2; _c2max:=c2max;
 c1:=0; c1max:=either(length(disky)+1>h,h-1,length(disky));
 c2:=0; c2max:=either(length(disky)+1>h,length(disky)+1-h,0);
 dsk:=dskCur;
 for i:=0 to length(disky)-1 do
  if disky[i+1]=dsk then
   begin
    c1:=0;
    c2:=i+1;
    for i:=0 to c1max do
     if (c2<=0) or (c1>=c1max) then
      begin
       i:=length(disky)-1;
       break;
      end
     else
      begin
       inc(c1);
       dec(c2);
      end;
   end;
 if flags and dlgNoEditLine=0 then d^.wrixy(clrEdit,x0,yedit,rep(' ',editw));
 for i:=c1max to h-1 do d^.wrixy(clrDirs,x0,y0+i,Rep(' ',editw));
 repeat
  DrawScrollbar;
  for i:=0 to c1max do
   d^.wrixy(either(i=c1,clrActive,either(disky[i]=dsk,clrActual,clrDirs))
   ,x0,y0+i
   ,Left(eitherS(i=0,_(_selDrives)+':',eitherS((c2=c2max) and (i=c1max),'À','Ã')+'Ä'+disky[c2+i]),editw));
  d^.FreshFull;
  HandleEvents;
  case code(event) of
  kLeft:
   if (count>0) and not((c1=0) and (c2=0)) then
    if c1<h then
     if c2=0 then c1:=0 else
      if c2<h then c2:=0
      else c2:=c2-h
    else c1:=c1-h;
  kRight:
   if (count>0) and not((c2=c2max) and (c1=c1max)) then
    if c1 div h=w-1 then
     if c2=c2max then c1:=c1max
     else c2:=either(c2+h>c2max,c2max,c2+h)
    else c1:=either(c1+h>c1max,c1max,c1+h);
  kEnter,kkEnter:
   if c1+c2<>0 then ret:=retEnter;
  end;
  if ret in [retEsc,retErr,retEnter] then break;
 until false;
 for i:=0 to h-1 do d^.wrixy(clrDirs,x0,y0+i,Rep(' ',editw));
 if (ret=retEnter) and (disky[c1+c2]<>dsk) then SelectDisk:=dskChange(disky[c1+c2]);
 c1:=_c1; c1max:=_c1max;
 c2:=_c2; c2max:=_c2max;
end;  {Tselector.SelectDisk}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Function  Tselector.SelectDirectory(preselect:string):string;
const
 dirw=60;
var
 res:string;
 zac:byte;
 i:word;
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
 procedure appoint;
 var j:word;
 begin {appoint}
  c1:=0;
  c2:=homedir;
  for j:=1 to homedir do
   if (c1<c1max) and (c2>0) then
    begin
     inc(c1);
     dec(c2);
    end
   else break;
  if flags and dlgNoEditLine=0 then
   begin
    res:=dirCur+postfix;
    if (length(res)>3) and (res[length(res)]='\') then dec(res[0]);
    if length(res)>editw
    then res:=Copy(res,1,3)+'..'+Right(res,editw-5)
    else res:=res+Rep(' ',editw-length(res));
    d^.wrixy(clrEdit,x0,yedit,res);
   end;
 end;  {appoint}
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
begin {Tselector.SelectDirectory}
 origdir:=dirCur;
 if PathSlice(preselect,psPath)<>'' then dirChange(PathSlice(preselect,psPath));
 parent:=PathSlice(PathSlice(dirCur,psPascalPath),psFile);
 zac:=1; itemw:=editw;
 ReGain;
 appoint;
 repeat
  DrawFileTab;
  DrawScrollbar;
  if count<>0 then
   for i:=0 to c1max do
    with sez[c2+i]^ do
    begin
     if c2+i=0 then res:=name else
      begin
       res:=Rep(' ',(size-1)*2)+'À';
       if sez[c2+i+1]<>nil then if sez[c2+i+1]^.size=size then res[length(res)]:='Ã';
       res:=res+'Ä'+
        eitherS(item and itemName=0,'',Copy(name,1,8))+
        eitherS(item and itemExt =0,'',eitherS(flags and dlgHideExt=0,' '+Copy(name,9,4),'    '))+
        eitherS(item and itemDate=0,'',' '+
         WithZeroes(TimeSlice(time,sortDay),2)+'.'+
         WithZeroes(TimeSlice(time,sortMonth),2)+'.'+
         Right(stri(TimeSlice(time,sortYear)),2)+
        eitherS(item and itemTime=0,'',' '+
         WithZeroes(TimeSlice(time,sortHour),2)+':'+
         WithZeroes(TimeSlice(time,sortMinute),2)))+
        eitherS(item and itemAttr=0,'',' '+
         eitherS(attr and Archive<>0,'-','a')+
         eitherS(attr and ReadOnly=0,'-','r')+
         eitherS(attr and Hidden  =0,'-','h')+
         eitherS(attr and SysFile =0,'-','s'));
      end;
     d^.wrixy(either(i=c1,clrActive,either(c2+i=homedir,clrActual,clrDirs)),x0,y0+i,Left(Copy(res,zac,editw),editw));
    end;
  d^.FreshFull;
  HandleEvents;
  case code(event) of
  kLeft:
   zac:=either(zac>1,zac-1,1);
  kRight:
   zac:=either(zac<dirw,zac+1,dirw);
  kEnter,kkEnter:
   repeat
    if c1+c2=0 then
     begin
      if SelectDisk then ReGain;
      appoint;
      ret:=0;
      break;
     end;
    if c1+c2=homedir then
     begin
      ret:=retEnter;
      break;
     end;
    if sez[c1+c2]^.size<sez[homedir]^.size then
     begin
      res:=Copy(sez[1]^.name,1,3);
      for i:=2 to c1+c2 do
       res:=res+WithoutChar(' ',sez[i]^.name)+'\';
     end
    else res:=WithoutChar(' ',sez[c1+c2]^.name);
    dirChange(res);
    ReGain;
    appoint;
   until true;
  kTab:
   if flags and dlgNoEditLine=0 then
    repeat
     repeat
      res:=InputString(PathSlice(dirCur,psPascalPath)
      ,x0,yedit,either(flags and dlgCursorToStart=0,$FF,0),sizeof(PathStr)-1,editw,stdinp);
      if ret<>retEnter then
       begin
        ret:=0;
        break;
       end;
      res:=ucased(getcore(res));
      if (res[0]+res[2]=#2':') then {napr: "A:"}
       begin
        ret:=0;
        if UpCase(res[1])=dskCur then break;
        if dskChange(res[1]) then
         begin
          ReGain;
          parent:=PathSlice(PathSlice(dirCur,psPascalPath),psFile);
         end;
        break;
       end;
      if (length(res)>2) and (res[2]=':') and (res[3]<>'\') then
       begin
        ret:=0;
        if Pos('*',res)+Pos('?',res)>0 then break;
        dskSelectFantom(res[1]);
        if dirExists(res) then
         begin
          if UpCase(res[1])<>dskCur then dskChange(res[1]);
          if dirChange(res) then ReRead;
          break;
         end;
        if ((flags and dlgForbidNew=0) or dirExists(sez[c1+c2]^.name)) then
         begin
          SelectDirectory:=fExpand(res+'\');
          exit;
         end;
       end;
      if (flags and dlgForbidNew<>0) and not(dirExists(res)) then
       begin
        ret:=0;
        break;
       end;
      if res[length(res)]<>'\' then res:=res+'\';
      SelectDirectory:=fExpand(res);
      exit;
     until true;
     appoint;
    until true;
  end; {/case}
  case char(event) of
  #18: {CTRL-R}
   begin
    ReGain;
    appoint;
   end;
  end;
  if ret in [retEsc,retEnter,retErr] then break;
 until false;
 if (ret=retEsc) then
  if (flags and dlgEscReturnsNothing<>0) then SelectDirectory:=''
   else SelectDirectory:=preselect
 else
  SelectDirectory:=dirCur+postfix+rep('\',ord(not (postfix[length(postfix)] in [#0,'\'])));
 if flags and dlgUpdateDir=0 then dirChange(origdir);
end;  {Tselector.SelectDirectory}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
FUNCTION  dlgPathBrowser(flagy:word;popisek,masc,preselect:string):string;
var
 f:Pselector;
 sloupcu,radek:byte;
 i:integer;
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
 procedure GetSize(var sir,vys:word;maxsir,maxvys:word);far;
 begin {GetSize}
  sloupcu:=1;
  sir:=MinW(40,maxsir)-2;
  if flagy and dlgRatherBig<>0
  then vys:=maxvys*9 div 10
  else vys:=maxvys*4 div 10;
  with f^ do itemw:=sir-4-byte(scrollbar=barVertical);
 end;  {GetSize}
{ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß ß }
begin {dlgPathBrowser}
 dlgPathBrowser:='';
 New(f,Init);
 if NewDialog(f^.d,0,0,@GetSize) then
  with f^ do begin
   if scrollbar=barHorizontal then scrollbar:=barVertical;
   postfix:=masc;
   masc:=CutString(postfix,' ');
   repeat
    d^.Frame;
    maska:=masc;
    flags:=flagy;
    radek:=byte(popisek<>'');
    if flags and dlgNoEditLine=0 then begin inc(radek); yedit:=radek; end;
    if flags and dlgShowQuickFindStr<>0 then begin inc(radek); yqfind:=radek; end;
    if flags and dlgShowDirectory<>0 then begin inc(radek); ycurdir:=radek; end;
    x0:=2;
    y0:=1+radek;
    w:=sloupcu;
    i:=d^.chrY-2-radek;
    if scrollbar=barHorizontal then dec(i);
    if flags and dlgShowDetailTab<>0 then begin dec(i,2); ydetail:=d^.chrY-3; end;
    if (i>0) and (sloupcu>0) then
     begin
      h:=i;
      editw:=w*itemw+w-1;
      if popisek<>'' then d^.wriXY($30,2,1,Left(popisek,editw));
      dlgPathBrowser:=SelectDirectory(preselect);
     end
    else
     dlgPathBrowser:='';
    d^.Free;
   until true;
   Dispose(f,Done);
  end;
end;  {dlgPathBrowser}
