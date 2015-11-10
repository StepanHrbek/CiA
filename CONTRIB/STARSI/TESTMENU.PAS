{$i define.inc}
{$m 20000,60000,200000}
uses Chyby,Memo,Objects,Strings,Sys,Ini,Vga,Cache,Dialogy,Key,Lang1;
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
Var s      :TScreen;{obrazovka}
    event  :TEvent;
    pos    :TPoint;
    i      :integer;
begin {main}
 {zavesi handler klavesnice}
 {v teto ukazce pouze kvuli cteni leveho shiftu}
 kSetHandler(true);
 {nastavi nejblizsi graficky mod, vyzkousej si ruzna rozliseni a modely}
 if not s.Init(model_gfx,640,400,0) then Halt(_erBadMode);
 {kdybys chtel nastavit konkretni mod a zadny jiny, volej init treba takto:
  if not s.Init(model_packed,0,0,P640x480) then Halt(erBadMode);
  viz seznam modelu a modu na zacatku vga.pas}
 {rozsviti paletu}
 s.Fade(+0);
 {btw, kdyz GetEvent skonci uspechem, mas udalost ulozenou v event a pos}

{ while not s.GetEvent(event,pos) do
  begin
   if kPressed[kM] then}
    i:=dlgRolMenu;
    {dlgSelector(0,'','','');}
{   if kPressed[kEsc] then exit;
  end;}

 {vrati puvodni (textovy) mod}
 s.Done;
 {odpoji handler klavesnice}
 {btw, neni nutne, odpojeni je v autodone}
 kSetHandler(false);
 {rozlouci se}
 writeln('Bye! i=',i);
end.  {main}
