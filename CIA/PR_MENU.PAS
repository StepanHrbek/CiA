{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 2.00ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

 Priklad: menu

}

{$m 10000,0,90000}

Uses
 Dos,Stringy,Dialogy,Vga,Lang1,Fajly,Key,Sys,Objects;

{ukazka 1 - kolikatou polozku si uzivatel vybral?}
Procedure Menu1;
var
 c:TMenuCollection;
 res:longint;
begin
 c.Init(false{=polozky abecedne NEtridit});
 c.InsertSt('Jsem samuraj.');
 c.InsertSt('Jsem nind‘a.');
 c.InsertSt('Jsem americk‚ commando.');
 res:=dlgMenuNdx('Kdo jsi? [test menu]',@c,2{implicitni=2.polozka});
 c.Done;
 writeln('Vybral sis ',res,'. polozku menu.');
 DelayS(0.3);{pockej 0.3s}
end;

{ukazka 2 - polozku s jakym kodem si uzivatel vybral?}
Procedure Menu2;
var
 c:TMenuCollection;
 res:longint;
begin
 c.Init(false);
 c.InsertStr('Udelat 5 kliku',5);
 c.InsertStr('Udelat 50 kliku',50);
 c.InsertStr('Udelat 100000 kliku',100000);
 res:=dlgMenuKod('Nejlepsi dieta-cviceni!',@c,50{implicitni=polozka s kodem 50});
 c.Done;
 writeln('Udelal jsi ',res,' kliku, zhubl jsi o ',res/10:0:0,'kg!');
 DelayS(0.3);
end;

{ukazka 3 - hotkeys}
Procedure Menu3;
var
 c:TMenuCollection;
 res:longint;
begin
 c.Init(false);
 c.InsertStr('Save   (F2)',kF2);
 c.InsertStr('Load   (F3)',kF3);
 c.InsertStr('Delete (F8)',kF8);
 dlgHotkeys:=true;
 res:=dlgMenuKod('K vyberu muzes pouzit hotkey...',@c,kF3{implicitni=polozka s kodem kF3});
 dlgHotkeys:=false;
 c.Done;
 writeln('Stiskl jsi klavesu s kodem ',res,'.');
 DelayS(1.5);
end;

Var
 s:TScreen;

procedure myUserFont(var name:PathStr;var p:pointer;var vyska:byte);far;
begin
 {tato uzivatelska funkce je velice hloupa, ackoliv bude tazana na
  font priblizne vysky 'vyska', nabidne vzdy tentyz}
 name:='moder_np.fn';
 {uvedeny soubor by pochopitelne mel existovat}
end;

Begin
 {volitelne: tato procedura bude v textmodu vybirat font}
 {pokud ji nenastavime, zustane nam romfont bez cestiny}
 UserFont:=myUserFont;

 { Nastavi mod. Muzes samozrejme nastavit libovolny, treba
   s.init(model_gfx,640,480,0); }
 s.init(model_text,80,25,0);

 { Nabidne postupne tri menu. }
 Menu1;
 Menu2;
 Menu3;

 { Ukonci praci s modem. }
 s.Done;
End.