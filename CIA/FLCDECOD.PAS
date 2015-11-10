{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

Unit      FlcDecod;

{
---------------------------------------------------------------------------
                             FLI/FLC dekoder
---------------------------------------------------------------------------

Zde jsou pouze dve low-level rutiny fyzicky dekodujici FLI/FLC data.
Ve svem programu budes pravdepodobne pouzivat pouze objekty vyssi urovne,
playery, ktere najdes v FLCplay.pas.

Tento dekoder napsal Jan Patera.
}

Interface {$i define.inc}

const 	  flcData_Size  = 36;	{velikost dat potrebnych prehravacem}

{ Nastavi celkem sp_pocet barev, pocinaje indexem sp_prvni.
  sp_data ukazuje na sp_pocet trojic RGB, kazda hodnota v rozsahu 0 az 63.
  Muze byt volana behem kazdeho volani flcDecodeFrame, a to i opakovane. }
type      TFLCSetPalProc   = procedure(sp_prvni, sp_pocet: Word; var sp_data);

{ Nastavi zadanou banku, predpokladana granularita je 64KB. }
          TFLCSetBankFunc  = function(sb_banka: Word):Word;

{ Nacte celkem sp_bajtu na adresu sp_kam z aktualni pozice v souboru. }
          TFLCReadDataProc = procedure(sp_bajtu: Word; var sp_kam);


function  flcInit(
            Header:pointer;
            LineOffset:word;
            StartX,StartY:word;
            SetPalProc:TFLCSetPalProc;
            SetBankFunc:TFLCSetBankFunc;
            ReadDataProc:TFLCReadDataProc;
            DataSeg:Word
            ):pchar;

function  flcDecodeFrame(
            Frame:pointer;
            DataSeg:Word
            ):pchar;

type TFLCHeader=record
{0}       size    :longint;
{4}       magic   :word;        {AF12}
{6}       frames  :word;
{8}       width   :word;
{10}      height  :word;
{12}      depth   :word;
{14}      flags   :word;
{16}      speed   :longint;	{speed in miliseconds}
{20}      res1a   :byte;
{21}      res1b   :byte;
{22}	  created :longint;
{26}	  creator :longint;
{30}      updated :longint;
{34} 	  updater :longint;
{38}	  aspectx :word;
{40}      aspecty :word;
{42}      res2    :array[0..37] of byte;
{80}      oframe1 :longint;     {offset of the 1st frame in the file}
{84}      oframe2 :longint;     {offset of the 2nd frame in the file}
{88}      res3    :array[0..39] of byte;
       end;

     TFLIHeader=record
       size   :longint;
       magic  :word;            {AF11}
       frames :word;
       width  :word;
       height :word;
       depth  :word;
       flags  :word;
       speed  :word;
       expand :array[1..110] of byte;
      end;

     TFrameHeader=record
       size   :longint;
       magic  :word;
       chunks :word;
       expand :array[1..8] of byte;
      end;

     TFullFrame=record
       header :TFrameHeader;
       data   :byte;
      end;

implementation

function flcInit(
           Header:pointer;
           LineOffset:word;
           StartX,StartY:word;
           SetPalProc:TFLCSetPalProc;
           SetBankFunc:TFLCSetBankFunc;
           ReadDataProc:TFLCReadDataProc;
           DataSeg:Word
           ):pchar;
	   external;

function flcDecodeFrame(
           Frame:pointer;
           DataSeg:Word
           ):pchar;
	   external;

{$L flcdecod.obj}

end.