 {$define beta}                   {-kompilovat jako betaverzi (vcetne ladicich informaci apod)}
 {$define _debuginit}             {-pro ladeni init/done casti unit}
 {$define _testvga}               {-pro ladeni na divnych vga kartach}
 {$define autoinit}               {-automaticky init unit}
 {$define autodone}               {-automaticky done unit}
 {$define dosmem}                 {-pouzivat dosovou pamet...nutno}
 {$define _timer}                 {-podporovat praci s timerem, pri usestimer doopravdy, bez usestimer ji jen simulovat}
 {$define _safestack}             {-pouzit vlastni stack v timerhandleru, vyzaduje rucni upravu v scrol.userinit}
 {$define _dement}                {-soukrome veci}

 {$ifdef timer}
  {$define usestimer}             {-pouzit unitu timer}
 {$endif}

 {$G+,I-,X+}                      {-nezbytne nastaveni}
 {$T+,V+}                         {-doporucene nastaveni}

 {$ifdef beta}
  {$D+,L+,Q+,R+,S+,Y+}            {-v betaverzi provadet kontroly}
 {$else}
  {$D-,L-,Q-,R-,S-,Y-}            {-v ostre verzi ne}
 {$endif}

 {zbyle, zde nedefinovane switche: A,B,E,F,M,N,O,P}

{
  Vyber pametoveho modelu.
  Mezi realem a protektem se prepina automaticky, podle toho jak si nastavis
  kompilator. Mezi realpas a realdos prepinas rucne tak, ze o par radek nize
  zneskodnis nechteny nazev podtrzitkem a preferovany nechas bez podtrzitka.
  Vysvetleni rozdilu mezi modely je v unite Memo.
}

 {$ifdef dpmi}
  {$define protpas}
 {$else}
  {$define realpas_}
  {$define realdos}
 {$endif}

