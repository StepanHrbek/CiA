{ÚÄÄÄC.I.A.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄverze 0.10ÄÄÄ¿
 ³S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi³
 ³v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

 {$define beta}                 {-kompilovat jako betaverzi?}
 {$define autoinit}             {-automaticky init unit?}
 {define timer}                 {-pouzivat unitu Timer?}
 {define midas}                 {-pouzivat unitu Midas?}
 {define memory_cache}          {-mas unitu memory rozsirenou o cache?}
 {define dement}                {-soukromy kod ktery z unit ZATIM nemuzu
                                  odstranit, ale nekdy na nej urcite dojde}

 {$G+,I-,X+}                    {-nezbytne nastaveni}
 {$T+,V+}                       {-doporucene nastaveni}

 {$ifdef beta}
  {$D+,L+,Q+,R+,S+,Y+}          {-v betaverzi provadet kontroly}
 {$else}
  {$D-,L-,Q-,R-,S-,Y-}          {-v ostre verzi ne}
 {$endif}

 {zbyle, zde nedefinovane switche: A,B,E,F,M,N,O,P}

{
  Vyber pametoveho modelu.
  Mezi realem a protektem se prepina automaticky, podle toho jak si nastavis
  kompilator. Mezi realpas a realdos prepinas rucne tak, ze o par radek nize
  zneskodnis define nechteneho nazvu a nechas preferovany.
  Vysvetleni rozdilu mezi modely je v unite Memo.
}

 {$ifdef dpmi}
  {$define protpas}
 {$else}
  {define realpas}
  {$define realdos}
 {$endif}
