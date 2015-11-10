{⁄ƒƒƒC.I.A.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒverze 1.00ƒƒƒø
 ≥S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi≥
 ≥v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.≥
 ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ}

Unit      Num;
Interface {$i define.inc}
Uses      Chyby, Stringy;
Function  Init:TError;
Procedure Done;

{Nasleduj°c°ch asi 40 funkc° slouz° pro prevody mezi c°selnymi soustavami.

 chemicke nazvoslovi:

 xxx2yyyN

 kde xxx, yyy je jedna z nasledujicich ciselnych soustav:
 Bin - dvojkova, zaklad je     ˛˛
 Oct - osmickova, zaklad je    ˛˛˛˛˛˛˛˛
 Dec - desitkova, zaklad je    ˛˛˛˛˛˛˛˛˛˛
 Hex - sestnactkova, zaklad je ˛˛˛˛˛˛˛˛˛˛˛˛˛˛˛˛
 Any - jakakoliv ciselna soustava
 Cislo N na konci nazvu rika, o kolikabajtovou konverzi jde.

 Pokud funkce vraci string, je vystup vzdy zleva doplnen nulami a ve
 velkych pismenech (if any). Tento format je vsak ocekavan i u vstupu.
 Pri chybnem vstupu (spatna delka stringu, cislice vetsi nez zaklad soustavy)
 klidne vrati zcestny vysledek a o nakou kontrolu se vubec nezajima.

 Any2Any podporuje az 255-ciferna cisla, soustavy 2-255 a v betaverzi
 kontroluje korektnost vstupu. Soustavy 2-36 jsou tvoreny klasicky
 z cifer a pismen (malych nebo velkych), soustavy 37-255 jsou ze znaku
 #0 az #254.
}
type
 string2=string[2];
 string3=string[3];
 string4=string[4];
 string6=string[6];
 string8=string[8];
 string11=string[11];
 string16=string[16];
 string32=string[32];

FUNCTION  Dec2Hex1(d:byte):string2;
FUNCTION  Dec2Hex2(d:word):string4;
FUNCTION  Dec2Hex4(d:longint):string8;
FUNCTION  Dec2Oct1(d:byte):string3;
FUNCTION  Dec2Oct2(d:word):string6;
FUNCTION  Dec2Oct4(d:longint):string11;
FUNCTION  Dec2Bin1(d:byte):string8;
FUNCTION  Dec2Bin2(d:word):string16;
FUNCTION  Dec2Bin4(d:longint):string32;
FUNCTION  Hex2Bin1(d:string2):string8;
FUNCTION  Hex2Bin2(d:string4):string16;
FUNCTION  Hex2Bin4(d:string8):string32;
FUNCTION  Oct2Bin1(d:string3):string8;
FUNCTION  Oct2Bin2(d:string6):string16;
FUNCTION  Oct2Bin4(d:string11):string32;
FUNCTION  Hex2Dec1(d:string2):byte;
FUNCTION  Hex2Dec2(d:string4):word;
FUNCTION  Hex2Dec4(d:string8):longint;
FUNCTION  Bin2Dec1(d:string8):byte;
FUNCTION  Bin2Dec2(d:string16):word;
FUNCTION  Bin2Dec4(d:string32):longint;
FUNCTION  Bin2Hex1(d:string8):string2;
FUNCTION  Bin2Hex2(d:string16):string4;
FUNCTION  Bin2Hex4(d:string32):string8;
FUNCTION  Bin2Oct1(d:string8):string3;
FUNCTION  Bin2Oct2(d:string16):string6;
FUNCTION  Bin2Oct4(d:string32):string11;
FUNCTION  Hex2Oct1(d:string2):string3;
FUNCTION  Hex2Oct2(d:string4):string6;
FUNCTION  Hex2Oct4(d:string8):string11;
FUNCTION  Oct2Dec1(d:string3):byte;
FUNCTION  Oct2Dec2(d:string6):word;
FUNCTION  Oct2Dec4(d:string11):longint;
FUNCTION  Oct2Hex1(d:string3):string2;
FUNCTION  Oct2Hex2(d:string6):string4;
FUNCTION  Oct2Hex4(d:string11):string8;
FUNCTION  Any2Any(number:string;inbase,outbase:byte):string;


{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
                          IMPLEMENTATION
{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}


{Budu vdecny tomu, kdo si da tu praci to vsechno otestovat.}

FUNCTION  Dec2Hex1(d:byte):string2; assembler;
asm   {Dec2Hex1}
 push es
 les  di,@result
 mov  al,2
 cld
 stosb
 mov  al,[d]
 shr  al,4
 call @ConvertHex
 mov  al,[d]
 and  al,0Fh
 call @ConvertHex
 jmp  @end
@ConvertHex:
 cmp  al,0Ah
 jb   @ConvertHex2
 add  al,7         {7=(ord('A')-$A) - ord('0')}
@ConvertHex2:
 add  al,'0'
 stosb
 ret
@end:
 pop  es
end;  {Dec2Hex1}

FUNCTION  Dec2Hex2(d:word):string4; assembler;
asm   {Dec2Hex2}
 push es
 les  di,@result
 mov  al,4
 cld
 stosb
 mov  al,byte ptr [d]+1
 shr  al,4
 call @ConvertHex
 mov  al,byte ptr [d]+1
 and  al,0Fh
 call @ConvertHex
 mov  al,byte ptr [d]
 shr  al,4
 call @ConvertHex
 mov  al,byte ptr [d]
 and  al,0Fh
 call @ConvertHex
 jmp  @end
@ConvertHex:
 cmp  al,0Ah
 jb   @ConvertHex2
 add  al,7         {7=(ord('A')-$A) - ord('0')}
@ConvertHex2:
 add  al,'0'
 stosb
 ret
@end:
 pop  es
end;  {Dec2Hex2}

FUNCTION  Dec2Hex4(d:LongInt):string8; assembler;
asm   {Dec2Hex4}
 push es
 les  di,@result
 mov  al,8
 cld
 stosb             {cpe do podprogramu LongInt po pulbajtech}
 mov  al,byte ptr [d]+3
 shr  al,4
 call @ConvertHex
 mov  al,byte ptr [d]+3
 and  al,0Fh
 call @ConvertHex
 mov  al,byte ptr [d]+2
 shr  al,4
 call @ConvertHex
 mov  al,byte ptr [d]+2
 and  al,0Fh
 call @ConvertHex
 mov  al,byte ptr [d]+1
 shr  al,4
 call @ConvertHex
 mov  al,byte ptr [d]+1
 and  al,0Fh
 call @ConvertHex
 mov  al,byte ptr [d]
 shr  al,4
 call @ConvertHex
 mov  al,byte ptr [d]
 and  al,0Fh
 call @ConvertHex
 jmp  @end
@ConvertHex:
 cmp  al,0Ah
 jb   @ConvertHex2
 add  al,7         {7=(ord('A')-$A) - ord('0')}
@ConvertHex2:
 add  al,'0'
 stosb
 ret
@end:
 pop  es
end;  {Dec2Hex4}

FUNCTION  Dec2Oct1(d:byte):string3; assembler;
asm   {Dec2Oct1}
 push es
 les  di,@result
 mov  al,3
 cld
 stosb
 mov  al,[d]
 shr  al,6
 add  al,'0'
 stosb
 mov  al,[d]
 shr  al,3
 and  al,7
 add  al,'0'
 stosb
 mov  al,[d]
 and  al,7
 add  al,'0'
 stosb
 pop  es
end;  {Dec2Oct1}

FUNCTION  Dec2Oct2(d:word):string6; assembler;
asm   {Dec2Oct2}
 push es
 les  di,@result
 mov  al,6
 cld
 stosb
 mov  al,byte ptr [d]+1
 shr  al,7
 add  al,'0'
 stosb
 mov  al,byte ptr [d]+1
 shr  al,4
 and  al,7
 add  al,'0'
 stosb
 mov  al,byte ptr [d]+1
 shr  al,1
 and  al,7
 add  al,'0'
 stosb
 mov  ax,[d]
 shr  ax,6
 and  al,7
 add  al,'0'
 stosb
 mov  al,byte ptr [d]
 shr  al,3
 and  al,7
 add  al,'0'
 stosb
 mov  al,byte ptr [d]
 and  al,7
 add  al,'0'
 stosb
 pop  es
end;  {Dec2Oct2}

FUNCTION  Dec2Oct4(d:LongInt):string11; assembler;
asm   {Dec2Oct4}
 push es
 les  di,@result
 mov  al,0Bh
 cld
 stosb
 mov  al,byte ptr [d]+3
 shr  al,6
 and  al,7
 add  al,'0'
 stosb
 mov  al,byte ptr [d]+3
 shr  al,3
 and  al,7
 add  al,'0'
 stosb
 mov  al,byte ptr [d]+3
 and  al,7
 add  al,'0'
 stosb
 mov  al,byte ptr [d]+2
 shr  al,5
 and  al,7
 add  al,'0'
 stosb
 mov  al,byte ptr [d]+2
 shr  al,2
 and  al,7
 add  al,'0'
 stosb
 mov  ax,word ptr [d]+1
 shr  ax,7
 and  al,7
 add  al,'0'
 stosb
 mov  al,byte ptr [d]+1
 shr  al,4
 and  al,7
 add  al,'0'
 stosb
 mov  al,byte ptr [d]+1
 shr  al,1
 and  al,7
 add  al,'0'
 stosb
 mov  ax,word ptr [d]
 shr  ax,6
 and  al,7
 add  al,'0'
 stosb
 mov  al,byte ptr [d]
 shr  al,3
 and  al,7
 add  al,'0'
 stosb
 mov  al,byte ptr [d]
 and  al,7
 add  al,'0'
 stosb
 pop  es
end;  {Dec2Oct4}

FUNCTION  Dec2Bin1(d:byte):string8; assembler;
asm   {Dec2Bin1}
 push es
 les  di,@result
 mov  al,8
 cld
 stosb
 mov  ah,[d]
 mov  cx,8
@ConvertBin:
 mov  bl,1
 dec  cx
 shl  bl,cl
 inc  cx
 mov  al,'0'
 and  bl,ah
 jz   @ConvertBin2
 inc  al
@ConvertBin2:
 stosb
 loop @ConvertBin
 pop  es
end;  {Dec2Bin1}

FUNCTION  Dec2Bin2(d:word):string16; assembler;
asm   {Dec2Bin2}
 push es
 les  di,@result
 mov  al,10h
 cld
 stosb
 mov  ah,byte ptr [d]+1
 call @ConvertBin
 mov  ah,byte ptr [d]
 call @ConvertBin
 jmp  @end
@ConvertBin:
 mov  cx,8
@ConvertBin1:
 mov  bl,1
 dec  cx
 shl  bl,cl
 inc  cx
 mov  al,'0'
 and  bl,ah
 jz   @ConvertBin2
 inc  al
@ConvertBin2:
 stosb
 loop @ConvertBin1
 ret
@end:
 pop  es
end;  {Dec2Bin2}

FUNCTION  Dec2Bin4(d:LongInt):string32; assembler;
asm   {Dec2Bin4}
 push es
 les  di,@result
 mov  al,20h
 cld
 stosb
 mov  ah,byte ptr [d]+3
 call @ConvertBin
 mov  ah,byte ptr [d]+2
 call @ConvertBin
 mov  ah,byte ptr [d]+1
 call @ConvertBin
 mov  ah,byte ptr [d]
 call @ConvertBin
 jmp  @end
@ConvertBin:
 mov  cx,8
@ConvertBin1:
 mov  bl,1
 dec  cx
 shl  bl,cl
 inc  cx
 mov  al,'0'
 and  bl,ah
 jz   @ConvertBin2
 inc  al
@ConvertBin2:
 stosb
 loop @ConvertBin1
 ret
@end:
 pop  es
end;  {Dec2Bin4}

PROCEDURE hextab; assembler;
asm   {hextab}
 db '0000','0001','0010','0011'
 db '0100','0111','0110','0111'
 db '1000','1001','1010','1011'
 db '1100','1111','1110','1111'
end;  {hextab}

FUNCTION  Hex2Bin1(d:string2):string8; assembler;
{Vysoce amaterska, neoptimalizovana, nedomyslena, neosetrena a patricne
 pras†ck† rutina pro prevod z hexadecimalni do binarni soustavy.
 Pozn.: Vstup musi byt upcasnut a doplnen nulami na zadany pocet mist.}
asm   {Hex2Bin1}
 push ds
 push es
 lds  si,d
 les  di,@result
 cld
 mov  al,8
 stosb
 lodsb
 mov  cx,2
@ForEachHex:
 lodsb
 call @zpracujhex
 loop @ForEachHex
 jmp  @end
@zpracujhex:
 push di
 cmp  al,'9'
 jbe  @dal
 sub  al,7             {7 proto, ze ord('A')-ord('0')-$A=7}
@dal:
 sub  al,'0'           {al=valu(b[2-cx])}
 shl  al,2             {chce ziskat al-te ctyrslovo z HexTab}
 xor  ah,ah
 push es
 push di
 lea  di,hextab
 add  di,ax            {a prictu ho k zacatku tabulky.}
 mov  ax,cs
 mov  es,ax
 db 66h;mov ax,es:[di] {Pak nactu prislusne ctyry byty do eax}
 pop  di
 pop  es
 db 66h;stosw          {a prekopiruju je do @resultu.}
 pop  di
 add  di,4
 ret
@end:
 pop  es
 pop  ds
end;  {Hex2Bin1}

FUNCTION  Hex2Bin2(d:string4):string16; assembler;
asm   {Hex2Bin2}
 push ds
 push es
 lds  si,d
 les  di,@result
 cld
 mov  al,16
 stosb
 lodsb
 mov  cx,4
@ForEachHex:
 lodsb
 call @zpracujhex
 loop @ForEachHex
 jmp  @end
@zpracujhex:
 push di
 cmp  al,'9'
 jbe  @dal
 sub  al,7             {7 proto, ze ord('A')-ord('0')-$A=7}
@dal:
 sub  al,'0'           {al=valu(b[2-cx])}
 shl  al,2             {chce ziskat offset z HexTab, tak vynasobim al ctyrmi}
 xor  ah,ah
 push es
 push di
 lea  di,hextab
 add  di,ax            {a prictu ho k zacatku tabulky.}
 mov  ax,cs
 mov  es,ax
 db 66h;mov ax,es:[di] {Pak nactu prislusne ctyry byty do eax}
 pop  di
 pop  es
 db 66h;stosw          {a prekopiruju je do @resultu.}
 pop  di
 add  di,4
 ret
@end:
 pop  es
 pop  ds
end;  {Hex2Bin2}

FUNCTION  Hex2Bin4(d:string8):string32; assembler;
asm   {Hex2Bin4}
 push ds
 push es
 lds  si,d
 les  di,@result
 cld
 mov  al,32
 stosb
 lodsb
 mov  cx,8
@ForEachHex:
 lodsb
 call @zpracujhex
 loop @ForEachHex
 jmp  @end
@zpracujhex:
 push di
 cmp  al,'9'
 jbe  @dal
 sub  al,7             {7 proto, ze ord('A')-ord('0')-$A=7}
@dal:
 sub  al,'0'           {al=valu(b[2-cx])}
 shl  al,2             {chce ziskat offset z HexTab, tak vynasobim al ctyrmi}
 xor  ah,ah
 push es
 push di
 lea  di,hextab
 add  di,ax            {a prictu ho k zacatku tabulky.}
 mov  ax,cs
 mov  es,ax
 db 66h;mov ax,es:[di] {Pak nactu prislusne ctyry byty do eax}
 pop  di
 pop  es
 db 66h;stosw          {a prekopiruju je do @resultu.}
 pop  di
 add  di,4
 ret
@end:
 pop  es
 pop  ds
end;  {Hex2Bin4}

PROCEDURE octtab; assembler;
asm   {octtab}
 db '000','001','010','011'
 db '100','101','110','111'
end;  {octtab}

FUNCTION  Oct2Bin1(d:string3):string8; assembler;
{Peclive neotestovano. Ignoruje prvni Most Significant Bit u prvniho bytu b.
 Vstup musi byt doplnen nulami.}
asm   {Oct2Bin1}
 push ds
 push es
 lds  si,d
 les  di,@result
 mov  al,8
 cld
 stosb
 inc  si
 lodsb
@PrvniOct:
 push di
 sub  al,'0'
 mov  ah,al
 shl  al,1
 add  al,ah
 xor  ah,ah
 push es
 push di
 lea  di,octtab
 add  di,ax
 mov  ax,cs
 mov  es,ax
 inc  di
 mov  ax,es:[di]
 pop  di
 pop  es
 stosw
 pop  di
 inc  di
 inc  di
 mov  cx,2
@1:
 lodsb
 call @zpracujOct
 loop @1
 jmp  @end
@zpracujOct:
 sub  al,'0'
 mov  ah,al
 shl  al,1
 add  al,ah
 xor  ah,ah
 push es
 push di
 lea  di,octtab
 add  di,ax
 mov  ax,cs
 mov  es,ax
 db 66h;mov ax,es:[di]
 pop  di
 pop  es
 db 66h;stosw
 dec  di
 ret
@end:
 pop  es
 pop  ds
end;  {Oct2Bin1}

FUNCTION  Oct2Bin2(d:string6):string16; assembler;
{Peclive neotestovano. Ignoruje prvni dva nejvyznamnejsi bity prvniho bytu b.
 Vstup musi byt doplnen nulami.}
asm   {Oct2Bin2}
 push ds
 push es
 lds  si,d
 les  di,@result
 mov  al,16
 cld
 stosb
 inc  si
 lodsb
@PrvniOct:
 push di
 sub  al,'0'
 mov  ah,al
 shl  al,1
 add  al,ah
 xor  ah,ah
 push es
 push di
 lea  di,octtab
 add  di,ax
 mov  ax,cs
 mov  es,ax
 inc  di
 inc  di
 mov  al,es:[di]
 pop  di
 pop  es
 stosb
 pop  di
 inc  di
 mov  cx,5
@1:
 lodsb
 call @zpracujOct
 loop @1
 jmp  @end
@zpracujOct:
 sub  al,'0'
 mov  ah,al
 shl  al,1
 add  al,ah
 xor  ah,ah
 push es
 push di
 lea  di,octtab
 add  di,ax
 mov  ax,cs
 mov  es,ax
 db 66h;mov ax,es:[di]
 pop  di
 pop  es
 db 66h;stosw
 dec  di
 ret
@end:
 pop  es
 pop  ds
end;  {Oct2Bin2}

FUNCTION  Oct2Bin4(d:string11):string32; assembler;
{Peclive neotestovano. Ignoruje prvni Most Significant Bit u prvniho bytu b.
 Vstup musi byt doplnen nulami.}
asm   {Oct2Bin4}
 push ds
 push es
 lds  si,d
 les  di,@result
 mov  al,32
 cld
 stosb
 inc  si
 lodsb
@PrvniOct:
 push di
 sub  al,'0'
 mov  ah,al
 shl  al,1
 add  al,ah
 xor  ah,ah
 push es
 push di
 lea  di,octtab
 add  di,ax
 mov  ax,cs
 mov  es,ax
 inc  di
 mov  ax,es:[di]
 pop  di
 pop  es
 stosw
 pop  di
 inc  di
 inc  di
 mov  cx,10
@1:
 lodsb
 call @zpracujOct
 loop @1
 jmp  @end
@zpracujOct:
 sub  al,'0'
 mov  ah,al
 shl  al,1
 add  al,ah
 xor  ah,ah
 push es
 push di
 lea  di,octtab
 add  di,ax
 mov  ax,cs
 mov  es,ax
 db 66h;mov ax,es:[di]
 pop  di
 pop  es
 db 66h;stosw
 dec  di
 ret
@end:
 pop  es
 pop  ds
end;  {Oct2Bin4}

FUNCTION  Hex2Dec1(d:string2):byte; assembler;
{Pozn.: vyzaduje mit vstup upcasnuty a doplneny nulama.}
asm   {Hex2Dec1}
 push ds
 lds  si,d
 cld
 lodsb
 lodsb
 cmp  al,'9'
 jbe  @1
 sub  al,7
@1:
 sub  al,'0'
 shl  al,4
 mov  ah,al
 lodsb
 cmp  al,'9'
 jbe  @2
 sub  al,7
@2:
 sub  al,'0'
 and  al,0Fh
 add  al,ah
 pop  ds
end;  {Hex2Dec1}

FUNCTION  Hex2Dec2(d:string4):word; assembler;
asm   {Hex2Dec2}
 push ds
 cld
 lds  si,d
 inc  si
 call @zpracujbyte
 mov  bh,al
 call @zpracujbyte
 xor  ah,ah
 xor  bl,bl
 add  ax,bx
 jmp  @end
@zpracujbyte:
 lodsb
 cmp  al,'9'
 jbe  @1
 sub  al,7
@1:
 sub  al,'0'
 shl  al,4
 mov  ah,al
 lodsb
 cmp  al,'9'
 jbe  @2
 sub  al,7
@2:
 sub  al,'0'
 and  al,0Fh
 add  al,ah
 ret
@end:
 pop  ds
end;  {Hex2Dec2}

FUNCTION  Hex2Dec4(d:string8):LongInt; assembler;
asm   {Hex2Dec4}
 push ds
 cld
 lds  si,d
 inc  si
 call @zpracujbyte
 mov  bh,al
 call @zpracujbyte
 mov  ah,bh
 mov  dx,ax
 call @zpracujbyte
 mov  bh,al
 call @zpracujbyte
 mov  ah,bh
 jmp  @end
@zpracujbyte:
 lodsb
 cmp  al,'9'
 jbe  @1
 sub  al,7
@1:
 sub  al,'0'
 shl  al,4
 mov  ah,al
 lodsb
 cmp  al,'9'
 jbe  @2
 sub  al,7
@2:
 sub  al,'0'
 and  al,0Fh
 add  al,ah
 ret
@end:
 pop  ds
end;  {Hex2Dec4}

FUNCTION  Bin2Dec1(d:string8):byte; assembler;
{Pozn.: vyzaduje regulerni vstup, doplneny nulama.}
asm   {Bin2Dec1}
 push ds
 cld
 lds  si,d
 inc  si
 mov  bx,08000h    {bh-samotny bit, bl-(mezi)vysledek}
 mov  cx,8
@cykl:
 lodsb
 test al,1
 jz   @dal
 add  bl,bh
@dal:
 shr  bh,1
 loop @cykl
 mov  al,bl
 pop  ds
end;  {Bin2Dec1}

FUNCTION  Bin2Dec2(d:string16):word; assembler;
asm   {Bin2Dec2}
 push ds
 cld
 lds  si,d
 inc  si
 call @zpracujbyte
 mov  ah,al
 call @zpracujbyte
 jmp  @end
@zpracujbyte:
 mov  bx,08000h    {bh-samotny bit, bl-(mezi)vysledek}
 mov  cx,8
@cykl:
 lodsb
 test al,1
 jz   @dal
 add  bl,bh
@dal:
 shr  bh,1
 loop @cykl
 mov  al,bl
 ret
@end:
 pop  ds
end;  {Bin2Dec2}

FUNCTION  Bin2Dec4(d:string32):LongInt; assembler;
asm   {Bin2Dec4}
 push ds
 cld
 lds  si,d
 inc  si
 call @zpracujbyte
 mov  dh,al
 call @zpracujbyte
 mov  dl,al
 call @zpracujbyte
 mov  ah,al
 call @zpracujbyte
 jmp  @end
@zpracujbyte:
 mov  bx,08000h    {bh-samotny bit, bl-(mezi)vysledek}
 mov  cx,8
@cykl:
 lodsb
 test al,1
 jz   @dal
 add  bl,bh
@dal:
 shr  bh,1
 loop @cykl
 mov  al,bl
 ret
@end:
 pop  ds
end;  {Bin2Dec4}

FUNCTION  Bin2Hex1(d:string8):string2; assembler;
{Pozn.: Vyzaduje regulerni vstup, doplneny nulami.}
asm   {Bin2Hex1}
 push ds
 push es
 les  di,@result
 mov  al,2
 cld
 stosb
 lds  si,d
 inc  si
 call @zpracujhex
 call @zpracujhex
 jmp  @end
@zpracujhex:
 mov  bx,0830h
 mov  cx,4
@cykl:
 lodsb
 cmp  al,'0'
 je   @dal
 add  bl,bh
@dal:
 shr  bh,1
 loop @cykl
 cmp  bl,'9'
 jbe  @done
 add  bl,7
@done:
 mov  al,bl
 stosb
 ret
@end:
 pop  es
 pop  ds
end;  {Bin2Hex1}

FUNCTION  Bin2Hex2(d:string16):string4; assembler;
asm   {Bin2Hex2}
 push ds
 push es
 les  di,@result
 mov  al,4
 cld
 stosb
 lds  si,d
 inc  si
 mov  cx,4
 rep  call @zpracujhex
 jmp  @end
@zpracujhex:
 mov  bx,0830h
 push cx
 mov  cx,4
@cykl:
 lodsb
 cmp  al,'0'
 je   @dal
 add  bl,bh
@dal:
 shr  bh,1
 loop @cykl
 pop  cx
 cmp  bl,'9'
 jbe  @done
 add  bl,7
@done:
 mov  al,bl
 stosb
 ret
@end:
 pop  es
 pop  ds
end;  {Bin2Hex2}

FUNCTION  Bin2Hex4(d:string32):string8; assembler;
asm   {Bin2Hex4}
 push ds
 push es
 les  di,@result
 mov  al,8
 cld
 stosb
 lds  si,d
 inc  si
 mov  cx,8
 rep  call @zpracujhex
 jmp  @end
@zpracujhex:
 mov  bx,0830h
 push cx
 mov  cx,4
@cykl:
 lodsb
 cmp  al,'0'
 je   @dal
 add  bl,bh
@dal:
 shr  bh,1
 loop @cykl
 pop  cx
 cmp  bl,'9'
 jbe  @done
 add  bl,7
@done:
 mov  al,bl
 stosb
 ret
@end:
 pop  es
 pop  ds
end;  {Bin2Hex4}

FUNCTION  Bin2Oct1(d:string8):string3; assembler;
{Pozn.: Vyzaduje regulerni vstup, doplneny nulami.}
asm   {Bin2Oct1}
 push ds
 push es
 les  di,@result
 mov  al,3
 cld
 stosb
 lds  si,d
 mov  byte ptr ds:[si],'0' {pouziju d[0] na doplneni dvou bitu jeden oct}
 mov  cx,3
 rep  call @zpracujoct
 jmp  @end
@zpracujoct:
 mov  bx,0430h
 push cx
 mov  cx,3
@cykl:
 lodsb
 cmp  al,'0'
 je   @dal
 add  bl,bh
@dal:
 shr  bh,1
 loop @cykl
 pop  cx
 mov  al,bl
 stosb
 ret
@end:
 pop  es
 pop  ds
end;  {Bin2Oct1}

FUNCTION  Bin2Oct2(d:string16):string6; assembler;
asm   {Bin2Oct2}
 push ds
 push es
 les  di,@result
 mov  al,6
 cld
 stosb
 mov  bl,'0'
 lds  si,d
 inc  si
 lodsb
 cmp  al,'0'
 je   @1
 inc  bl
@1:
 stosb
 mov  cx,5
 rep  call @zpracujoct
 jmp  @end
@zpracujoct:
 mov  bx,0430h
 push cx
 mov  cx,3
@cykl:
 lodsb
 cmp  al,'0'
 je   @dal
 add  bl,bh
@dal:
 shr  bh,1
 loop @cykl
 pop  cx
 mov  al,bl
 stosb
 ret
@end:
 pop  es
 pop  ds
end;  {Bin2Oct2}

FUNCTION  Bin2Oct4(d:string32):string11; assembler;
asm   {Bin2Oct4}
 push ds
 push es
 les  di,@result
 mov  al,11
 cld
 stosb
 lds  si,d
 mov  byte ptr ds:[si],'0' {pouziju d[0] na doplneni dvou bitu jeden oct}
 mov  cx,11
@proces:
 push cx
 call @zpracujoct
 pop  cx
 loop @proces
 jmp  @end
@zpracujoct:
 mov  bx,0430h
 mov  cx,3
@cykl:
 lodsb
 cmp  al,'0'
 je   @dal
 add  bl,bh
@dal:
 shr  bh,1
 loop @cykl
 mov  al,bl
 stosb
 ret
@end:
 pop  es
 pop  ds
end;  {Bin2Oct4}

FUNCTION  Hex2Oct1(d:string2):string3; assembler;
{Pozn.: vyzaduje mit vstup upcasnuty a doplneny nulama. Je relativne pomala
 a neoptimalizovana, protoze neprevadi primo, ale pres desitkovou soustavu.}
asm   {Hex2Oct1}
 push ds
 push es
 les  di,@result
 mov  al,3
 cld
 stosb
 lds  si,d
 inc  si
 lodsb
 cmp  al,'9'
 jbe  @1
 sub  al,7
@1:
 sub  al,'0'
 mov  ah,al
 shl  ah,4
 lodsb
 cmp  al,'9'
 jbe  @2
 sub  al,7
@2:
 sub  al,'0'
 add  al,ah
 mov  ah,al
 shr  al,6
 add  al,'0'
 stosb
 mov  al,ah
 shr  al,3
 and  al,7
 add  al,'0'
 stosb
 mov  al,ah
 and  al,7
 add  al,'0'
 stosb
 pop  es
 pop  ds
end;  {Hex2Oct1}

FUNCTION  Hex2Oct2(d:string4):string6; assembler;
{Pozn.: vyzaduje mit vstup upcasnuty a doplneny nulama. Je relativne pomala
 a neoptimalizovana, protoze neprevadi primo, ale pres desitkovou soustavu.}
asm   {Hex2Oct2}
 push ds
 push es
 les  di,@result
 mov  al,6
 cld
 stosb
 lds  si,d
 inc  si
 lodsb
 cmp  al,'9'
 jbe  @1
 sub  al,7
@1:
 sub  al,'0'
 mov  bh,al
 shl  bh,4
 lodsb
 cmp  al,'9'
 jbe  @2
 sub  al,7
@2:
 sub  al,'0'
 add  bh,al
 lodsb
 cmp  al,'9'
 jbe  @3
 sub  al,7
@3:
 sub  al,'0'
 mov  bl,al
 shl  bl,4
 lodsb
 cmp  al,'9'
 jbe  @4
 sub  al,7
@4:
 sub  al,'0'
 add  bl,al
 mov  al,'0'
 test bh,80h
 jz   @5
 inc  al
@5:
 stosb
 mov  al,bh
 shr  al,4
 and  al,7
 add  al,'0'
 stosb
 mov  al,bh
 shr  al,1
 and  al,7
 add  al,'0'
 stosb
 mov  ax,bx
 shr  ax,6
 and  al,7
 add  al,'0'
 stosb
 mov  al,bl
 shr  al,3
 and  al,7
 add  al,'0'
 stosb
 mov  al,bl
 and  al,7
 add  al,'0'
 stosb
 pop  es
 pop  ds
end;  {Hex2Oct2}

FUNCTION  Hex2Oct4(d:string8):string11; assembler;
{Pozn.: vyzaduje mit vstup upcasnuty a doplneny nulama. Je relativne pomala
 a neoptimalizovana, protoze neprevadi primo, ale pres desitkovou soustavu.}
asm   {Hex2Oct4}
 push ds
 push es
 les  di,@result
 mov  al,11
 cld
 stosb
 lds  si,d
 inc  si
 lodsb
 cmp  al,'9'
 jbe  @1
 sub  al,7
@1:
 sub  al,'0'
 mov  ah,al
 shl  ah,4
 lodsb
 cmp  al,'9'
 jbe  @2
 sub  al,7
@2:
 sub  al,'0'
 add  ah,al
 shr  al,6
 add  al,'0'
 stosb
 mov  al,ah
 shr  al,3
 and  al,7
 add  al,'0'
 stosb
 mov  al,ah
 and  al,7
 add  al,'0'
 stosb
 lodsb             {v dx bude 2. a 3. byte}
 cmp  al,'9'
 jbe  @3
 sub  al,7
@3:
 sub  al,'0'
 mov  dh,al
 shl  dh,4
 lodsb
 cmp  al,'9'
 jbe  @4
 sub  al,7
@4:
 sub  al,'0'
 add  dh,al
 lodsb
 cmp  al,'9'
 jbe  @5
 sub  al,7
@5:
 sub  al,'0'
 mov  dl,al
 shl  dl,4
 lodsb
 cmp  al,'9'
 jbe  @6
 sub  al,7
@6:
 sub  al,'0'
 add  dl,al
 dec  si
 dec  si
 lodsb             {v bx bude 3. a 4. byte}
 cmp  al,'9'
 jbe  @7
 sub  al,7
@7:
 sub  al,'0'
 mov  bh,al
 shl  bh,4
 lodsb
 cmp  al,'9'
 jbe  @8
 sub  al,7
@8:
 sub  al,'0'
 add  bh,al
 lodsb
 cmp  al,'9'
 jbe  @9
 sub  al,7
@9:
 sub  al,'0'
 mov  bl,al
 shl  bl,4
 lodsb
 cmp  al,'9'
 jbe  @10
 sub  al,7
@10:
 sub  al,'0'
 add  bl,al
 mov  al,dh
 shr  al,5
 add  al,'0'
 stosb
 mov  al,dh
 shr  al,2
 and  al,7
 add  al,'0'
 stosb
 mov  ax,dx
 shr  ax,7
 and  al,7
 add  al,'0'
 stosb
 mov  al,bh
 shr  al,4
 and  al,7
 add  al,'0'
 stosb
 mov  al,bh
 shr  al,1
 and  al,7
 add  al,'0'
 stosb
 mov  ax,bx
 shr  ax,6
 and  al,7
 add  al,'0'
 stosb
 mov  al,bl
 shr  al,3
 and  al,7
 add  al,'0'
 stosb
 mov  al,bl
 and  al,7
 add  al,'0'
 stosb
 pop  es
 pop  ds
end;  {Hex2Oct4}

FUNCTION  Oct2Dec1(d:string3):byte; assembler;
{Pozn.: Vyzaduje regulerni vstup, doplneny nulami.}
asm   {Oct2Dec1}
 push ds
 lds  si,d
 inc  si
 cld
 lodsb
 sub  al,'0'
 and  al,3         {ignoruje Most Significant Bit u nejvyssiho Octu}
 shl  al,6
 mov  ah,al
 lodsb
 sub  al,'0'
 shl  al,3
 add  ah,al
 lodsb
 sub  al,'0'
 add  ah,al
 mov  al,ah
 pop  ds
end;  {Oct2Dec1}

FUNCTION  Oct2Dec2(d:string6):word; assembler;
asm   {Oct2Dec2}
 push ds
 lds  si,d
 inc  si
 cld
 lodsb
 shl  ax,15
 mov  bx,ax
 lodsb
 sub  al,'0'
 shl  ax,12
 add  bx,ax
 lodsb
 sub  al,'0'
 xor  ah,ah
 shl  ax,9
 add  bx,ax
 lodsb
 sub  al,'0'
 xor  ah,ah
 shl  ax,6
 add  bx,ax
 lodsb
 sub  al,'0'
 xor  ah,ah
 shl  ax,3
 add  bx,ax
 lodsb
 sub  al,'0'
 xor  ah,ah
 add  ax,bx
 pop  ds
end;  {Oct2Dec2}

FUNCTION  Oct2Dec4(d:string11):LongInt; assembler;
asm   {Oct2Dec4}
 push ds
 lds  si,d
 inc  si
 cld
 lodsb
 sub  al,'0'
 and  al,3
 shl  al,6
 mov  dh,al
 lodsb
 sub  al,'0'
 shl  al,3
 add  dh,al
 lodsb
 sub  al,'0'
 add  dh,al
 lodsb
 sub  al,'0'
 shl  al,5
 mov  dl,al
 lodsb
 sub  al,'0'
 shl  al,2
 add  dl,al
 lodsb
 sub  al,'0'
 mov  ah,al
 shr  al,1
 add  dl,al
 shl  ah,7
 lodsb
 sub  al,'0'
 shl  al,4
 add  ah,al
 lodsb
 sub  al,'0'
 shl  al,1
 add  ah,al
 lodsb
 sub  al,'0'
 mov  bl,al
 shr  al,2
 add  ah,al
 shl  bl,6
 lodsb
 sub  al,'0'
 shl  al,3
 add  bl,al
 lodsb
 sub  al,'0'
 add  al,bl
 pop  ds
end;  {Oct2Dec4}

FUNCTION  Oct2Hex1(d:string3):string2; assembler;
{Pozn.: Vyzaduje regulerni vstup, doplneny nulami.}
asm   {Oct2Hex1}
 push ds
 push es
 les  di,@result
 mov  al,2
 cld
 stosb
 lds  si,d
 inc  si
 lodsb
 sub  al,'0'
 and  al,3
 shl  al,2
 mov  bh,al
 lodsb
 sub  al,'0'
 mov  ah,al
 shr  al,1
 add  bh,al
 cmp  bh,9
 jbe  @1
 add  bh,7
@1:
 add  bh,'0'
 and  ah,3
 shl  ah,3
 lodsb
 sub  al,'0'
 add  ah,al
 cmp  ah,9
 jbe  @2
 add  ah,7
@2:
 add  ah,'0'
 mov  al,bh
 stosb
 mov  es:[di],ah
 pop  es
 pop  ds
end;  {Oct2Hex1}

FUNCTION  Oct2Hex2(d:string6):string4; assembler;
asm   {Oct2Hex2}
 push ds
 push es
 les  di,@result
 mov  al,4
 cld
 stosb
 lds  si,d
 inc  si
 lodsb
 sub  al,'0'
 shl  al,3
 mov  ah,al
 lodsb
 sub  al,'0'
 add  ah,al
 call @ulozhex
 lodsb
 sub  al,'0'
 shl  al,1
 mov  ah,al
 lodsb
 sub  al,'0'
 mov  bl,al
 shr  al,2
 add  ah,al
 call @ulozhex
 mov  ah,bl
 and  ah,3
 shl  ah,2
 lodsb
 sub  al,'0'
 mov  bl,al
 shr  al,1
 add  ah,al
 call @ulozhex
 mov  ah,bl
 and  ah,1
 shl  ah,3
 lodsb
 sub  al,'0'
 add  ah,al
 call @ulozhex
 jmp  @end
@ulozhex:
 cmp  ah,9
 jbe  @1
 add  ah,7
@1:
 add  ah,'0'
 mov  al,ah
 stosb
 ret
@end:
 pop  es
 pop  ds
end;  {Oct2Hex2}

FUNCTION  Oct2Hex4(d:string11):string8; assembler;
asm   {Oct2Hex4}
 push ds
 push es
 les  di,@result
 mov  al,8
 cld
 stosb
 lds  si,d
 inc  si
 lodsb
 sub  al,'0'
 and  al,3
 shl  al,2
 mov  ah,al
 lodsb
 sub  al,'0'
 mov  bl,al
 shr  al,1
 add  ah,al
 call @ulozhex
 mov  ah,bl
 and  ah,1
 shl  ah,3
 lodsb
 sub  al,'0'
 add  ah,al
 call @ulozhex
 lodsb
 sub  al,'0'
 shl  al,1
 mov  ah,al
 lodsb
 sub  al,'0'
 mov  bl,al
 shr  al,2
 add  ah,al
 call @ulozhex
 mov  ah,bl
 and  ah,3
 shl  ah,2
 lodsb
 sub  al,'0'
 mov  bl,al
 shr  al,1
 add  ah,al
 call @ulozhex
 mov  ah,bl
 and  ah,1
 shl  ah,3
 lodsb
 sub  al,'0'
 add  ah,al
 call @ulozhex
 lodsb
 sub  al,'0'
 shl  al,1
 mov  ah,al
 lodsb
 sub  al,'0'
 mov  bl,al
 shr  al,2
 add  ah,al
 call @ulozhex
 mov  ah,bl
 and  ah,3
 shl  ah,2
 lodsb
 sub  al,'0'
 mov  bl,al
 shr  al,1
 add  ah,al
 call @ulozhex
 mov  ah,bl
 and  ah,1
 shl  ah,3
 lodsb
 sub  al,'0'
 add  ah,al
 call @ulozhex
 jmp  @end
@ulozhex:
 cmp  ah,9
 jbe  @1
 add  ah,7
@1:
 add  ah,'0'
 mov  al,ah
 stosb
 ret
@end:
 pop  es
 pop  ds
end;  {Oct2Hex4}

procedure digit2byte(var number:string);assembler;
asm
     les di,number
     mov cl,[es:di]
     @1:
     dec cl
     js @end
     inc di
     cmp byte ptr [es:di],'a'
     jae @small_letter
     cmp byte ptr [es:di],'A'
     jae @big_letter
    @digit:
     sub byte ptr [es:di],'0'
     jmp @1
    @big_letter:
     sub byte ptr [es:di],'A'-10
     jmp @1
    @small_letter:
     sub byte ptr [es:di],'a'-10
     jmp @1
    @end:
end;

procedure byte2digit(var number:string);assembler;
asm
     les di,number
     mov cl,[es:di]
     @1:
     dec cl
     js @end
     inc di
     cmp byte ptr [es:di],10
     jae @letter
    @digit:
     add byte ptr [es:di],'0'
     jmp @1
    @letter:
     add byte ptr [es:di],'A'-10
     jmp @1
     @end:
end;

function convert(number:string;inbase,outbase:byte):string;assembler;
asm
    PUSH DS
    lds si,number       {ds:si=vstup}
    mov cl,[si]         {cx=delka vstupu}
    mov ch,0
    les di,@result      {es:di=vystup}
    inc di
    xor bl,bl           {bl=delka vystupu}
    jcxz @done          {pri nulove delce vstupu skonci}
    @2:
    xor bh,bh           {bh<>0 indikuje ze vstup<>0}
    push si
    push cx
    mov al,0
    @1:
     mul inbase
     inc si
     add al,[si]        {nacte 1 cifru ze vstupu}
     adc ah,0
     div outbase
     mov [si],al        {prepise 1 cifru vstupu novym cislem vstup/outbase}
     or bh,al           {poznamena si zda je nove cislo nenula}
     shr ax,8
     loop @1
    pop cx
    pop si
    stosb               {posle na vystup 1 cifru}
    inc bl              {zvysi citac delky vystupu}
    or bh,bh            {pokud neni na vstupu 0, pokracuje dalsi iteraci}
    jnz @2
    @done:
    les di,@result      {es:di=vystup}
    mov byte ptr [es:di],bl
    POP DS
end;

function bad_digit(number:string;base:byte):boolean;assembler;
asm
    les di,number
    mov cl,[es:di]
    mov ch,0
    jcxz @ok
    mov al,base
    @1:
    inc di
    cmp byte ptr [es:di],al
    jae @bug
    loop @1
    @ok:
    mov al,0
    @bug:
end;

FUNCTION Any2Any(number:string;inbase,outbase:byte):string;
begin
 if inbase<=36 then digit2byte(number);
 {$ifdef beta}
 if (inbase in [0..1]) then ReportErr(_(_erBadBase)+' '+stri(inbase)+'.');
 if (outbase in [0..1]) then ReportErr(_(_erBadBase)+' '+stri(outbase)+'.');
 if bad_digit(number,inbase) then ReportErr(_(_erBadDigit));
 {$endif}
 any2any:=Reversed(convert(number,inbase,outbase));
 if outbase<=36 then asm
     db 66h;push word ptr @result
     call byte2digit
 end;
end;


{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

function Init:TError;
 begin
  Init:=erOk;
 end;

procedure Done;
 begin
 end;

END.