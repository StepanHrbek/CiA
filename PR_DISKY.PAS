{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

 Priklad: vypis disku a jejich typu

 pozn: zde je videt jedina znama chyba CiA, detekuje cd-rom jako sitovy disk
}

{$m 10000,0,20000}

Uses Fajly;

Var  i:integer;
     list:string;

Begin
 {zjisti seznam disku}
 list:=dskList;
 {pro kazdy z nich...}
 for i:=1 to length(list) do begin
   {...vypise jeho typ}
   write(list[i],': je ');
   case dskId(list[i]) of
     dskFloppy:writeln('flopac');
     dskHard  :writeln('harddisk');
     dskNet   :writeln('sitovy disk');
     dskCdrom :writeln('CD-ROM');
     else      writeln('?');
     end;
   end;
End.