{
  Tento programek konvertuje textovy soubor 'lang.cz'
  na zdrojak v pascalu 'lang1.inc'.
}

var f,g:text;
    st:string;
    i:integer;

begin
 assign(f,'lang.cz');
 reset(f);
 assign(g,'lang1.inc');
 rewrite(g);
 writeln(g,'{tento soubor je vygenerovan z lang.cz programem lang1inc}');
 writeln(g,'const hlasky:array[erOk..__] of pchar=(');
 while not eof(f) do begin
   readln(f,st);
   for i:=length(st) downto 1 do
    if st[i]='''' then insert('''',st,i);
   writeln(g,''''+st+''',');
   end;
 writeln(g,''''');');
 close(f);
 close(g);
end.


