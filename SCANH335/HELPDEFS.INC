{#Z+}

{.$define debug}

{$ifdef debug}
{$A+,B-,D+,E-,F-,G-,I+,L+,N-,O-,P-,Q+,R+,S+,T+,V+,X+,Y+}
{$M 20000,0,655360}

{$else}
{$A+,B-,D-,E-,F-,G-,I+,L+,N-,O-,P-,Q-,R-,S+,T+,V+,X+,Y+}
{$M 20000,0,655360}
{$endif}

{$define ta7}  { This is for version 7.01 of Turbo Analyst.  Undefine for
                 version 6.01, after applying patches to it. }

{#Z-}
