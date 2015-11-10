{⁄ƒƒƒC.I.A.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒverze 2.00ƒƒƒø
 ≥S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi≥
 ≥v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.≥
 ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ}

Unit      Ini;
Interface {$i define.inc}
Uses      Chyby,Memo, Dos,Objects, Stringy,Fajly,Texty,Sys;
Function  Init:TError;
Procedure Done;

{
---------------------------------------------------------------------------
                       Uvod k INI souborum
---------------------------------------------------------------------------

 INI soubory jsou textove soubory pro ukladani konfiguracnich udaju
 a komentaru tak, aby je uzivatel mohl menit i rucne.

 Priklad INI souboru:
   [sekce1]
    promenna1=10 ;komentar
    promenna2=5,3,7,4,0,-1,-1,9,9 ;komentar
   [sekce2]
    promenna1=yes ;komentar
    rozliseni=640x480/32

 O maximalne efektivni parsovani/generovani obsahu INI souboru se stara unita.

 Veskere chyby zjistene pri parsovani jsou standardnim zpusobem reportovany
 uzivatelsky definovatelnou procedurou ReportErr.

 Procedurou iniRead nactes hodnoty promennych z INI souboru.
 Procedurou iniWrite zapises promenne do existujiciho souboru.

 K tomu potrebujes nejprve
 - mit seznam promennych, ktere chces ukladat do ini souboru
   (priklad takoveho seznamu je v souboru priklad.pas)
   (vsechny promenne musi lezet v datasegmentu)
   (jsou podporovany vybrane typy (promennych), dalsi si muzes doplnit)
 - predat tento seznam procedure iniSetup

 Pokrocilejsi programatori si mohou navic vytvorit vlastni SecSelector
 pro presnejsi praci se sekcemi INI souboru (bez nej jsou vsechny promenne
 dostupne na stejne urovni, jako by sekce nebyly).

 Poznamky: tato unita pouziva freeseg (viz memo.pas),
  diky tomu nemusi alokovat zadnou pamet.
 Velikost INI souboru je omezena zhruba na 20K.
 V INI souboru lze kdeco, zatim ale pozor na:
  -tabelatory jsou povazovany za normalni znaky jako treba X
  -komentar nesmi byt za nazvem sekce (na stejne radce)
 Pri nacitani cisel z INI se nehlida prekroceni mezi, v betaverzi to hodi
  runtime error, v ostre se cislo orizne.

---------------------------------------------------------------------------
 SecSelector.
---------------------------------------------------------------------------

 V pripade vetsich naroku na INI si muzes napsat vlastni SecSelektor.
 Tady je deklarace a par nezbytnych konstant:
 }
 type  TSecSelector=function(var sekce:openstring;var varstab:pointer):PathStr;

 const iniModeR     =#255;{what sections to Read?}
       iniModeW     =#254;{what sections to Write modified?}
       iniModeA     =#253;{what sections to Add (from ext.file) when writing?}
       iniModeU     =#252;{what sections to Upgrade?}
       iniModeC     =#251;{what sections to Copy (from old version) when upgrading?}
       iniModeD     =#250;{what sections to Dopy..he?}
 {
 Promenna sekce neobsahuje hranate zavorky, pouze nazev sekce.
 Promennou varstab muzes pokazde nastavit stejne, mas-li jen jeden
  seznam promennych, nebo ruzne, mas-li jich vic.
 Hlavnim ukolem SecSelectoru je rozdelit sekce na dobre a spatne.
  U spatnych predej result='', u dobrych result<>''.

 Toto schema popisuje chovani selektoru:

   sekce=iniMode* -> prejde do modu * a skonci

   mod=R          -> if souhlasis se ctenim udaju ze sekce
                       then nastav varstab;result:='x'
                       else result:=''

   mod=W          -> if souhlasis se zmenou udaju v sekci
                       then nastav varstab;result:='x'
                       else result:=''

   mod=U          -> if souhlasis s upgradnutim sekce (nastaveni hodnot podle stejne nazvane sekce ve starem ini)
                       then result:='x'
                       else result:=''

   mod=A          -> chces-li do prave zapisovaneho ini pridat nejakou sekci
                       then nastav varstab, sekce, result=externi ini soubor obsahujici vkladanou sekci
                       else result:=''

   mod=C          -> chces-li sekci pri upgradu ze stareho ini prenest do noveho
                     beze zmen (a vis ze v novem stejna sekce jeste neni!)
                       then result:='x'
                       else result:=''

   mod=D          -> chces-li sekci pri upgradu ze stareho ini prenest do noveho,
                     nalayoutovanou podle externiho.souboru
                     (a vis ze v novem stejna sekce jeste neni!)
                       then result:=externi ini soubor
                       else result:=''
}



{---------------------------------------------------------------------------
 Typy promennych, dalsi az do 255 lze snadno doplnit.
 ---------------------------------------------------------------------------}
const i_bool =0;   {boolean   (Ano=true,Ne=false)}
      i_fuzz =1;   {fuzzy     (Ano=Okay,Ne=Bad,<nic>=Unsure)}
      i_byte =2;   {byte}
      i_word =3;   {word}
      i_hexw =4;   {hexa word}
      i_intg =5;   {integer}
      i_long =6;   {longint}
      i_stri =7;   {string}
      i_lost =8;   {lostring  (po nacteni ho automaticky locasne)}
      i_upst =9;   {upstring  (po nacteni ho automaticky upcasne)}
      i_9sho =10;  {pole deviti shortintu}
      i_2wor =11;  {dva wordy ve tvaru 640x480}
      i_mode =12;  {tri wordy ve tvaru 640x480/16}

{---------------------------------------------------------------------------
 Priznaky jednotlivych promennych.
 ---------------------------------------------------------------------------}
      i_use1 =1;   {Zda se ma pri sejvu ulozit aktualni hodnota nebo nechat}
      i_use2 =2;   {puvodni. Pri ukladani zadas param treba i_use1+i_use3 a}
      i_use3 =4;   {ulozi se pouze promenne oznacene nekterym z techto flagu.}
      i_use4 =8;
      i_use5 =16;
      i_renz =32;  {REad Nothing as Zero}
                   {Normalne kdyz neni zadano nic, promennou nemodifikuje.}
                   {S flagem i_renz ale interpretuje <nic> jako 0,'',false,unsure.}
      i_dwrf =64;  {Dont WRite FFFF}
                   {Pri hodnotach 255/65535/-1 nezapisuje nic.}
      i_neup =128; {Neupgradovat hodnotu pri iniUpgrade.}


{---------------------------------------------------------------------------
 Cteni, psani, upgrade INI souboru.
 ---------------------------------------------------------------------------}
PROCEDURE iniSetup(selektor:TSecSelector;varstab:pointer);
FUNCTION  iniRead(Ini:PathStr):boolean;
FUNCTION  iniWrite(Ini:PathStr;flags:byte):boolean;
FUNCTION  iniUpgrade(OldIni,VzorIni,NewIni:PathStr):boolean;




{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
                          IMPLEMENTATION
{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}

type  string80            =string[80];{1 radek ini souboru}
var   SelectSec           :TSecSelector;{aktualni selektor dobrych sekci}
      {$ifdef beta}
      SelectSecPtr        :pointer absolute SelectSec;
      {$endif}
      olda,vzor,news,extr :TText2;{pomocne virtualni textfajly ve freesegu}
      vars                :pointer;{pointer na tabulku tvych promennych}
      typprom             :byte;{typ posledne hledane promenne}
      promflags           :byte;{flagy posledne hledane promenne}
      ofsprom             :word;{offset na posledne hledanou promennou v DS}



{---------------------------------------------------------------------------
 Minimalizovany nahradni selektor, vyuzivan iniSetupem.
 ---------------------------------------------------------------------------}
var iniMode:char;
    minivars:pointer;

function miniSecSelector(var sekce:openstring;var varstab:pointer):PathStr;far;
begin
 {nastavi tabulku promennych}
 varstab:=minivars;

 case Str2Char(sekce) of
   {zpracovani signalu pro zmenu modu}
   iniModeR,iniModeW,iniModeU,iniModeA,iniModeC,iniModeD:iniMode:=sekce[1];
   else
    {hlavni cinnost, vetveni podle modu}
    case iniMode of
      iniModeR:miniSecSelector:='x';{cte vsechny sekce}
      iniModeW:miniSecSelector:='x';{pise vsechny sekce}
      iniModeA:miniSecSelector:=''; {zadne nove sekce nepridava}
      iniModeU:miniSecSelector:='x';{upgraduje vsechny sekce}
      iniModeC:miniSecSelector:=''; {nezname sekce ignoruje}
      iniModeD:miniSecSelector:=''; {nezname sekce ignoruje}
      end;
   end;

end;




{---------------------------------------------------------------------------
 Timto initem predas ostatnim ini proceduram nektere parametry.
 Pravdepodobne je budes mit pro vsechny stejne, takze staci provest
 init jednou. V opacnem pripade budes init volat vickrat, muzes za
 sebou bez nutnosti Done.

 Nejjednodussi varianta je zadat nil,nil,@seznam_promennych.

 Selektor je v uvodnim komentari popsana specialni funkce.
 Zadas-li nil, bude pouzit nahradni minimalizovany selektor.

 Vars je vyuzito jen pri selektor=nil, jindy nema vyznam.
 ---------------------------------------------------------------------------}
PROCEDURE iniSetup(selektor:TSecSelector;varstab:pointer);
var   selektorPtr:pointer absolute selektor;
begin
 {$ifdef beta}
 if (selektorPtr=nil) and (varstab=nil) then erBetaMsg('iniInit1');
 {$endif}
 if selektorPtr=nil then begin
   SelectSec:=miniSecSelector;
   minivars:=varstab;
   end
  else
   SelectSec:=selektor;
end;



{---------------------------------------------------------------------------
 Hleda zadanou promennou ve tvem seznamu promennych.
 Pri uspechu nastavi globalni promenny typprom, promflags, ofsprom.
 ---------------------------------------------------------------------------}
FUNCTION FindVariable(name:string80):boolean;assembler;
 asm
     {
      ES:SI - vars list
      FS:DI - name[i]
      FS:DX - name[0]
     }
     {$ifdef beta}
     db 66h;cmp word ptr vars,0;jnz @ok
      push cs
      push offset @msg1
      call chyby.erBetaMsg
      @msg1:
      db 13,'ini: vars=nil'
     @ok:
     {$endif}
     les dx,name
     push es;{pop fs}db 0fh,0a1h
     mov di,dx
     les si,vars
     @nextstring:
     mov ah,255{dylka stringu}
     mov bl,0{zatim neni zadny rozdil}
     @nextbyte:
     inc ah
     seges lodsb;cmp al,30;jc @endofstr
     inc di;db 64h{fs};cmp al,[di];jz @stejny;mov bl,1;@stejny:
     jmp @nextbyte
     @endofstr:
     add si,4{preskoci flags}
     {v ES narazil na konec stringu}
      {neni uz konec seznamu vars ?}
      cmp ah,0;jz @badkonec
      {shodny dylky ?}
      mov di,dx;db 64h{fs};cmp ah,[di];jnz @nextstring
      {zadny rozdily ?}
      or bl,bl;jnz @nextstring
     {byla nalezena shoda}
     mov ax,[es:si-4]
     mov typprom,ah{typ promenny}
     mov promflags,al{flagy promenny}
     mov ax,[es:si-2]
     mov ofsprom,ax{adresa promenny}
     mov ah,1
     @badkonec:
     mov al,ah
    {kvuli NTckum FS=0}
     push 0;db 0fh,0a1h
 end;

{---------------------------------------------------------------------------
 Proleze cely soubor t. Nechava si ohodnotit nazvy sekci selektorem.
 Ve spatnych sekcich provadi akci bad, v dobrych na radkach s dobrou
 promennou provadi akci goodvars, jinak goodstaff.
 (dobra sekce je ta, kterou SelGoodSec oznaci za dobrou,
  dobra promenna je ta, kterou SelGoodVar oznaci za dobrou)
 Je-li initSelSec<>#0, provadi se jim na zacatku inicializace selektoru.
 Chyby hlasi pres report.
 ---------------------------------------------------------------------------}
type  TVarSelector    =function(name:string80):boolean;

var   pass_sekce,
      pass_name,
      pass_result     :string80;

PROCEDURE PassThruIni(t:PText2;SelSec:TSecSelector;initSelSec:char;SelVar:TVarSelector;bad,goodstaff,goodvars:TReporter);
var   dobrasekce      :boolean;
      st,core         :string80;
      oldpos          :pchar;

label bug,notvar;
begin
 {nastavi spravny mod selektoru}
 if initSelSec<>#0 then begin
   pass_sekce:=initSelSec;
   selsec(pass_sekce,vars);
   end;
 dobrasekce:=false;
 {cte po radkach od zacatku az do konce}
 oldpos:=t^.pos;{zabrani zmene t^.pos protoze muze byt vic parseru vnorenych parsujic stejny soubor}
 t^.Reset;
 while not t^.eof do begin
   st:=t^.nlRead;                     {st=" var = value ; comment "}
   core:=GetCore(GetString(st,';',1));{st= "var = value"}
   {je na radku neco zajimaveho ?}
   if core='' then goto notvar;
   {je to [sekce] ?}
   if core[1]='[' then begin
     if core[length(core)]<>']' then goto bug;
     pass_sekce:=LoCased(GetCore(copy(core,2,length(core)-2)));
     pass_result:=SelSec(pass_sekce,vars);
     dobrasekce:=pass_result<>'';
     goto notvar;
     end;
   {je to spatna sekce ?}
   if not dobrasekce then goto notvar;
   {je to var=data ?}
   if pos('=',core)=0 then goto bug;
   pass_name:=LoCased(GetCore(GetString(st,'=',1)));
   {je to good var ?}
   if SelVar(pass_name) then goodvars(st) else goodstaff(st);
   continue;
  bug:
   ReportErr(_(_msgChybnaSyntaxIni)+' '+st);
  notvar:
   if dobrasekce then goodstaff(st) else bad(st);
   end;
 t^.pos:=oldpos;
end;



{---------------------------------------------------------------------------
 Ruzne utilitky pro PassThru a dalsi.
 ---------------------------------------------------------------------------}

  {loadne text z disku}
  function LoadText(st:PathStr;txt:PText2):boolean;
  var   datasize,freesize:longint;
        loaded:TError;
  begin
   txt^.Rewrite;
   datasize:=txt^.maxkonec-txt^.start;
   freesize:=0;
   if not fileLoad(st,nil,pointer(txt^.pos),datasize,freesize)
    then
     LoadText:=false
    else begin
     txt^.konec:=txt^.start+datasize;
     txt^.EndPtr^:=#0;{EndNewline;}
     LoadText:=true;
     end;
  end;

  {ulozi text na disk}
  function SaveText(st:PathStr;txt:PText2):boolean;
  var   written:TError;
  begin
   SaveText:=fileSave(fileOverwrite,st,txt^.startPtr,txt^.FileSize);
  end;

  {v radce st ("var=value;comment") zmeni value na newvalue}
  procedure ChangeValue(var st:openstring;NewValue:string);
  var i,j:word;
  begin
   j:=pos(';',st);
   if j=0 then j:=length(st)+1; {j=pozice ;}
   i:=pos('=',copy(st,1,j-1));  {i=pozice =}
   if i>0 then begin
     {dokud muze, prepisuje stary udaj novym}
     while (i+1<j) and (NewValue<>'') do begin
       inc(i);
       st[i]:=NewValue[1];
       delete(NewValue,1,1);
       end;
     {kdyz se nevesel, zbytek insertne}
     if NewValue<>'' then Insert(NewValue,st,i+1) else
      {kdyz zbylo misto pred komentarem, vyplni ho mezerama}
      if length(st)>=j then fillchar(st[i+1],j-i-1,32) else
       {kdyz neni komentar, string zkrati}
       st[0]:=chr(i);
     end;
  end;

  {sec!selektor: goodsec je vsechno}
  function  SelAllSec(var sekce:openstring;var varstab:pointer):PathStr;far;
  begin
   SelAllSec:='x';
  end;

  {sec!selektor: goodsec je jen usersec}
  var UserSec:string80;
  function  SelUserSec(var sekce:openstring;var varstab:pointer):PathStr;far;
  begin
   if sekce=UserSec
    then SelUserSec:='x'
    else SelUserSec:='';
  end;

  {var!selektor: goodvar je vsechno}
  function  SelAllVar(st:string80):boolean;far;
  begin
   SelAllVar:=true;
  end;

  {var!selektor: goodvar je jen uservar}
  var UserVar:string80;
  function  SelUserVar(st:string80):boolean;far;
  begin
   SelUserVar:=st=UserVar;
  end;

  {var!selektor: goodvar je jen promenna bez zakazaneho upgradu}
  function  SelUpgrVar(st:string80):boolean;far;
  begin
   SelUpgrVar:=not (FindVariable(st) and ((promflags and i_neup)>0));
  end;

  {var!selektor: goodvar je jen promenna bez zakazaneho upgradu}
  var UserFlag:byte;
  function  SelUserFlagyVar(st:string80):boolean;far;
  begin
   SelUserFlagyVar:=FindVariable(st) and
     (((promflags and UserFlag)>0) or (UserFlag=0));
  end;

  {reporter: radek vynecha}
  procedure Skip(st:string);far;
  begin
  end;

  {reporter: radek zapise beze zmeny}
  procedure WriteUnmodified(st:string);far;
  begin
   news.Writeln(st);
  end;

  {reporter: radek zapise beze zmeny, jen nazvy sekci zmeni na RenamedSec}
  var RenamedSec:string80;
  procedure RenameSec(st:string);far;
  begin
   if copy(GetCore(st),1,1)='[' then st:=RenamedSec;
   news.Writeln(st);
  end;

  {reporter: radek vynecha, ale ulozi si ho do goodvalue}
  var GoodValue:string80;
  procedure SkipAndRemember(st:string);far;
  var i:word;
  begin
   i:=pos('=',st);
   if i>0 then GoodValue:=GetCore(GetString(copy(st,i+1,255),';',1));
  end;

  {reporter: radek nahradi stejnym ze stejne sekce oldy}
  procedure Replace(st:string);far;
  begin
   UserSec:=pass_sekce;
   UserVar:=pass_name;
   GoodValue:=#0;
   PassThruIni(@olda,selUserSec,#0,SelUserVar,skip,skip,skipAndRemember);
   if GoodValue<>#0 then ChangeValue(st,GoodValue);
   news.Writeln(st);
   {obnovi puvodni hodnoty ktere PassThruIni rozhodil}
   pass_sekce:=UserSec;
   pass_name:=UserVar;
  end;

  {reporter: prida sekci pass_result}
  procedure AddSec(st:string);far;
  var i:word;
  begin
   {*bug: odsud vola Replace, Replace by si pak mel do UserSec nastavit to co
          JE TED v pass_sekce, ne co tam BUDE az se Replace zavola
   oprava by byla narocna, chyba ale neni nijak fatalni, jen trochu meni
     chovani upgradu, tak ji toleruju}
   if pass_result<>'' then begin
     if LoadText(pass_result,@extr)
      then PassThruIni(@extr,SelAllSec,#0,SelAllVar,Skip,WriteUnmodified,Replace);
     pass_result:='';
     end;
  end;

  {reporter: radek vynecha, obsah nacte do promenne}
  procedure ReadToMem(st:string);far;
  var i,code          :word;
      name,udaj       :string80;
      somebool        :boolean;
      somefuzz        :fuzzy;
      somebyte        :byte;
      someword        :word;
      someintg        :integer;
      somelong        :longint;
      somepstring     :^string;

   function DecodeNumber(was,min,max:longint):longint;
   var decoded:longint;
   begin
    if udaj='' then begin
      DecodeNumber:=0;
      exit;
      end;
    val(udaj,decoded,code);
    if code>0 then begin
      DecodeNumber:=was;
      ReportErr(_(_msgChybneCisloVIni)+#13#10+st);
      exit;
      end;
    if (decoded<min) or (decoded>max) then ReportErr(_2(_msgMimoRozsahVIni,stri(min),stri(max))+#13#10+st);
    DecodeNumber:=Bounded(decoded,min,max);
   end;

  label bug;
  begin
   st:=GetString(st,';',1);{odstrani komentar}
   i:=pos('=',st);
   if i=0 then goto bug;
   name:=GetCore(LoCased(copy(st,1,i-1)));
   udaj:=GetCore(LoCased(copy(st,i+1,255)));
   if FindVariable(name) then
    if (udaj<>'') or ((promflags and i_renz)>0) or (typprom=i_fuzz) then
     case typprom of
              i_bool:begin
                       if udaj='' then somebool:=false else
                        if udaj='no' then somebool:=false else
                         if udaj='yes' then somebool:=true else
                          goto bug;
                       mem[dseg:ofsprom]:=byte(somebool);
                     end;
              i_fuzz:begin
                       if udaj='' then somefuzz:=dunno else
                        if udaj='no' then somefuzz:=no else
                         if udaj='yes' then somefuzz:=yes else
                          goto bug;
                       mem[dseg:ofsprom]:=byte(somefuzz);
                     end;
              i_byte:mem [dseg:ofsprom]:=DecodeNumber(mem [dseg:ofsprom],minByte,maxByte);
              i_word:memw[dseg:ofsprom]:=DecodeNumber(memw[dseg:ofsprom],minWord,maxWord);
              i_intg:integer(memw[dseg:ofsprom]):=DecodeNumber(integer(memw[dseg:ofsprom]),minInt,maxInt);
              i_long:meml[dseg:ofsprom]:=DecodeNumber(meml[dseg:ofsprom],minLong,maxLong);
              i_hexw:begin
                       somelong:=Dehexed(udaj);
                       if (somelong=-1) or (somelong>65535)
                        then ReportErr(_(_msgChybneHexaVIni)+#13#10+st)
                        else memw[dseg:ofsprom]:=somelong;
                     end;
              i_stri,
              i_lost,
              i_upst:begin
                       somepstring:=ptr(dseg,ofsprom);
                       case typprom of i_upst:upcasni(udaj);{stringy prevede na upcase}
                                       i_stri:udaj:=GetCore(copy(st,i+1,255));{nacte puvodni zneni stringu}
                                       end;
                       {somepstring^:=udaj;}
                       move(udaj,somepstring^,length(udaj)+1);
                     end;
              i_9sho:for i:=1 to 9 do
                      if udaj<>''
                       then shortint(mem[dseg:ofsprom+i-1]):=CutNum(udaj);
              i_2wor:for i:=1 to 2 do
                       memw[dseg:ofsprom+2*(i-1)]:=CutNum(udaj);
              i_mode:for i:=1 to 3 do
                       memw[dseg:ofsprom+2*(i-1)]:=CutNum(udaj);
              else ReportErr(_(_msgInterniChybaIni));
              end;
   exit;
  bug:
   ReportErr(_(_msgChybnaSyntaxIni)+' '+st);
  end;

  {reporter: radek updatne podle stavu promenne v pameti a zapise}
  procedure WriteFromMem(st:string);far;
  var i,code          :word;
      name,udaj       :string80;
      somebool        :boolean;
      somefuzz        :fuzzy;
      somebyte        :byte;
      someword        :word;
      someintg        :integer;
      somelong        :longint;
      somepstring     :^string;
  label bug;
  begin
   i:=pos('=',st);
   if i=0 then goto bug;
   name:=copy(st,1,i-1);
   if FindVariable(LoCased(GetCore(name))) then begin
     case typprom of
              i_bool:begin
                       somebool:=boolean(mem[dseg:ofsprom]);
                       case somebool of false:udaj:='no';
                                        true:udaj:='yes';
                                        end;
                     end;
              i_fuzz:begin
                       somefuzz:=fuzzy(mem[dseg:ofsprom]);
                       case somefuzz of no:udaj:='no';
                                     dunno:udaj:='';
                                       yes:udaj:='yes';
                                     end;
                     end;
              i_byte:begin
                       somebyte:=mem[dseg:ofsprom];
                       if (somebyte=255) and ((promflags and i_dwrf)>0)
                        then udaj:=''
                        else str(somebyte,udaj);
                     end;
              i_word:begin
                       someword:=memw[dseg:ofsprom];
                       if (someword=65535) and ((promflags and i_dwrf)>0)
                        then udaj:=''
                        else str(someword,udaj);
                     end;
              i_hexw:begin
                       someword:=memw[dseg:ofsprom];
                       if (someword=65535) and ((promflags and i_dwrf)>0)
                        then udaj:=''
                        else udaj:=Hexed(someword);
                     end;
              i_intg:begin
                       someintg:=integer(memw[dseg:ofsprom]);
                       if (someintg=-1) and ((promflags and i_dwrf)>0)
                        then udaj:=''
                        else str(someintg,udaj);
                     end;
              i_long:begin
                       somelong:=meml[dseg:ofsprom];
                       if (somelong=-1) and ((promflags and i_dwrf)>0)
                        then udaj:=''
                        else str(somelong,udaj);
                     end;
              i_stri,
              i_lost,
              i_upst:begin
                       somepstring:=ptr(dseg,ofsprom);
                       udaj:=somepstring^;
                     end;
              i_9sho:begin
                       udaj:='';
                       for i:=1 to 9 do begin
                         if i>1 then udaj:=udaj+',';
                         udaj:=udaj+Stri(shortint(mem[dseg:ofsprom+i-1]));
                         end;
                     end;
              i_2wor:begin
                       udaj:=Stri(memw[dseg:ofsprom])+'x'+Stri(memw[dseg:ofsprom+2]);
                     end;
              i_mode:begin
                       if memw[dseg:ofsprom+4]=0 then udaj:='' else
                        udaj:=Stri(memw[dseg:ofsprom])+'x'+Stri(memw[dseg:ofsprom+2])+'/'+Stri(memw[dseg:ofsprom+4]);
                     end;
              else ReportErr(_(_msgInterniChybaIni));
              end;
     ChangeValue(st,udaj);
     end;
   news.Writeln(st);
   exit;
  bug:
   ReportErr(_(_msgChybnaSyntaxIni)+' '+st);
  end;


{---------------------------------------------------------------------------
 Nacte INI soubor, vraci uspesnost.
 ---------------------------------------------------------------------------}
FUNCTION  iniRead(Ini:PathStr):boolean;
begin
 {$ifdef beta}
 if SelectSecPtr=nil then erBetaMsg('iniRead before iniSetup');
 {$endif}
 iniRead:=false;
 news.Rewrite;
 {precte ini}
 if not LoadText(Ini,@olda) then exit;
 {projde ho a vybrane sekce nacte}
 PassThruIni(@olda,SelectSec,iniModeR,SelAllVar,Skip,Skip,ReadToMem);
 {hotovo}
 iniRead:=true;
end;

{---------------------------------------------------------------------------
 Zapise INI soubor, vraci uspesnost.
 Zapisuje jen promenne s nastavenym zadanym flagem. Pri flags=0 vsechny.
 ---------------------------------------------------------------------------}
FUNCTION iniWrite(Ini:PathStr;flags:byte):boolean;
var   st,sekce:string80;
begin
 {$ifdef beta}
 if SelectSecPtr=nil then erBetaMsg('iniWrite before iniSetup');
 {$endif}
 iniWrite:=false;
 {v readonly modu ini nezapise}
 if ReadOnlyMod then begin
   ReportErr(_(_msgReadOnlyVynech)+' '+Ini+'.');
   exit;
   end;
 {rewritne vystup}
 news.Rewrite;
 {precte ini}
 if not LoadText(Ini,@olda) then exit;
 {projde ho a zapise do news, ve vybranych sekcich opravi vybrane hodnoty}
 UserFlag:=flags;
 PassThruIni(@olda,SelectSec,iniModeW,SelUserFlagyVar,WriteUnmodified,WriteUnmodified,WriteFromMem);
 {na pozadani prida nove sekce z externich souboru}
 sekce:=iniModeA;
 SelectSec(sekce,vars);
 repeat
  sekce:='';
  st:=SelectSec(sekce,vars);
  if st='' then break;
  if LoadText(st,@extr) then begin
    RenamedSec:='['+sekce+']';
    PassThruIni(@extr,SelAllSec,#0,SelAllVar,WriteUnmodified,RenameSec,WriteFromMem);
    end;
 until false;
 {zapise news}
 iniWrite:=SaveText(Ini,@news);
end;

{---------------------------------------------------------------------------
 Nastavi udaje v NewIni podle hodnot v OldIni.
 ---------------------------------------------------------------------------}
FUNCTION iniUpgrade(OldIni,VzorIni,NewIni:PathStr):boolean;
var   dobrasekce      :boolean;
      udaju           :byte;
      i,j             :word;
      st              :string;
      sekce,name,udaj :string80;
Begin
 {$ifdef beta}
 if SelectSecPtr=nil then erBetaMsg('iniUpgrade before iniSetup');
 {$endif}
 iniUpgrade:=false;
 {v readonly modu ini nezapise}
 if ReadOnlyMod then begin
   ReportErr(_(_msgReadOnlyVynech)+' '+NewIni+'.');
   exit;
   end;
 {rewritne vystup}
 news.Rewrite;
 {precte ini}
 if not LoadText(OldIni,@olda) then exit;
 if not LoadText(VzorIni,@vzor) then exit;
 {projde vzor a upgradne ho do news (layout=vzor,data=olda,dest=news)}
 {nemeni promenne z nevybranych sekci a promenne s flagem 'neupgradovat'}
 PassThruIni(@vzor,SelectSec,iniModeU,SelUpgrVar,WriteUnmodified,WriteUnmodified,Replace);
 {projde oldu a vybrany sekce zkopci cely do news, ostatni vynecha}
 {urceno pro sekce, jejichz nejsi autorem a neznas jejich strukturu}
 PassThruIni(@olda,SelectSec,iniModeC,SelAllVar,Skip,WriteUnmodified,WriteUnmodified);
 {projde oldu a vybrany sekce upgradne do news (layout=extr,data=olda,dest=news)}
 {urceno pro sekce, jejichz jsi autorem, ale v ini nejsou napevno ([svga:???])}
 PassThruIni(@olda,SelectSec,iniModeD,SelAllVar,Skip,AddSec,Skip);
 {zapise news}
 iniUpgrade:=SaveText(NewIni,@news);
End;


{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

const unita='ini';
var result:TError;

procedure UserInit;
 const a=freesize div 4;
 begin
  SelectSec:=nil;
  olda.InitEmpty(ptr(freeseg,0*a),a);olda.static:=true;
  vzor.InitEmpty(ptr(freeseg,1*a),a);vzor.static:=true;
  news.InitEmpty(ptr(freeseg,2*a),a);news.static:=true;
  extr.InitEmpty(ptr(freeseg,3*a),a);extr.static:=true;
 end;

procedure UserDone;
 begin
  olda.Done;
  vzor.Done;
  news.Done;
  extr.Done;
 end;

{$i initdone.inc}
{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.