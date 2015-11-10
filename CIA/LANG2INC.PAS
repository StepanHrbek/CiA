{
  Tento programek konvertuje textove soubory 'lang.*'
  na zdrojaky v pascalu 'lang?.inc'.
}

var   f,g:text;
      st:string;
      i:integer;
      L:longint;
      EXT:string[3];
      NUM:char;
      hlasek:word;
      ofs:array[0..1000] of word;

const langs=2;
      langext:array[1..langs] of string[3]=('cz','eng');

begin
 for L:=1 to 2 do begin
  EXT:=langext[L];
  NUM:=chr(48+L);
  assign(f,'lang.'+EXT);
  reset(f);
  assign(g,'lang'+NUM+'.inc');
  rewrite(g);
  writeln(g,'{tento soubor je vygenerovan z lang.'+EXT+' programem lang2inc}');
  writeln(g,'const lang'+NUM+'str='''+EXT+''';');
  writeln(g,'{$ifdef lang_in_DS}');
  writeln(g,'const hlasky'+NUM+'DS:array[erOk..__] of pchar=(');
  hlasek:=0;
  ofs[0]:=0;
  while not eof(f) do begin
    readln(f,st);
    ofs[hlasek+1]:=ofs[hlasek]+length(st);
    for i:=length(st) downto 1 do
     if st[i]='''' then insert('''',st,i);
    writeln(g,''''+st+''',');
    inc(hlasek);
    end;
  writeln(g,''''');');
  writeln(g);
  writeln(g,'{$else}');
  writeln(g);
  reset(f);
  writeln(g,'procedure hlasky'+NUM+'CS;assembler;asm');
  for i:=0 to hlasek do begin
    if i mod 12=0 then write(g,' dw ') else write(g,',');
    write(g,ofs[i]+2*hlasek+2);
    if (i mod 12=11) or (i=hlasek) then writeln(g);
    end;
  while not eof(f) do begin
    readln(f,st);
    for i:=length(st) downto 1 do
     if st[i]='''' then insert('''',st,i);
    if st<>'' then writeln(g,' db '''+st+'''');
    end;
  writeln(g,'end;');
  writeln(g);
  writeln(g,'{$endif}');
  close(f);
  close(g);
  end;
end.


