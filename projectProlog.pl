/* digit */
digit(Input) :- term_string(TermInput, Input), integer(TermInput), !.
digit255(Input) :- term_string(TermInput, Input), integer(TermInput),
                   TermInput >= 0, TermInput < 256.

/* caratteri non validi per identificatore */
id(64). %@
id(47). %/
id(63). %?
id(35). %#
id(58). %:

identificatore(Input) :- atom_codes(Input, List_input), ide(List_input), !.

ide([L| _]) :- id(L), ! , fail.
ide([_ | Ls]) :- ide(Ls).
ide([_]).

/* caratteri non validi per identificatore_host */
idH(64). %@
idH(47). %/
idH(63). %?
idH(35). %#
idH(58). %:
idH(46). %.

identificatore_host(Input) :- atom_codes(Input, List_input), ids(List_input), !.

ids([L| _]) :- idH(L), ! , fail.
ids([_ | Ls]) :- ids(Ls).
ids([_]).

/* elimina gli spazi */

elimina_spazi([], []).
elimina_spazi([255 | Tail], Tail ) :- !.
elimina_spazi([Head | Tail], [Head, X]) :-  elimina_spazi(Tail, X).

/* posizione */
listPos([X|_], X, 1).
listPos([_|Tail], X, Pos) :- listPos(Tail, X, P), Pos is P + 1.

/* scheme */
scheme(Input) :- identificatore(Input), !.

/* host */
host(Input) :- identificatore_host(Input), !.
host(Input) :- atom_codes(Input, List_codes), point(List_codes), !.
host(Input) :- indirizzo_ip(Input), !.

point(List_codes) :- listPos(List_codes, 46, Pos),
                     atom_codes(Atom, List_codes),
                     P is Pos - 1,
                     sub_atom(Atom, 0, P, After, SubAtomIdH),
                     identificatore_host(SubAtomIdH),
                     A is After - 1,
                     sub_atom(Atom, Pos, A, _, SubAtomIdHost),
                     identificatore_host(SubAtomIdHost).

/* userinfo */
userinfo(Input) :- identificatore(Input), !.

/* port */
port(Input) :- digit255(Input), !.

/* authority */
authority(Input) :- atom_codes(Input, List_input), c_aut(List_input).

c_aut([X, X | Y]) :- X == 47, member(64, Y), !, aut(Y), !.
c_aut([X, X | Y]) :- X == 47, member(58, Y), !, twopoints(Y), !.
c_aut([X, X | Y]) :- X == 47, atom_codes(Atom, Y), host(Atom), !.

aut(List_codes):-length(List_codes, Length_list),
            listPos(List_codes, 64, Pos),
            P is Pos - 1,
            atom_codes(Atom, List_codes),
            sub_atom(Atom, 0, P, After, SubAtomAt), %stringa fino a PRIMA di @
            A is After - 1, 
            sub_atom(Atom, Pos, A, _ , SubAtomRest), % da @ in poi quindi vado a richiamare twopoints per vedere se ho anche present i due punti 
            atom_codes(SubAtomRest, List_SubAtomRest),
            twopoints(List_SubAtomRest).

aut(List_codes):- length(List_codes, Length_list),
            listPos(List_codes, 64, Pos),
            P is Pos - 1,
            atom_codes(Atom, List_codes),
            sub_atom(Atom, 0, P, After, SubAtomAt), %stringa fino a PRIMA di @
            A is After - 1, 
            sub_atom(Atom, Pos, A, _ , SubAtomRest), % da @ in poi quindi vado a richiamare twopoints per vedere se ho anche present i due punti 
            atom_codes(SubAtomRest, List_SubAtomRest),
            host(SubAtomRest), !, 
            userinfo(SubAtomAt).

twopoints(List_codes):- member(58, List_codes), !,
                        length(List_codes, Length),
                        listPos(List_codes, 58, Pos), 
                        L is Length - Pos,
                        atom_codes(Atom, List_codes),
                        sub_atom(Atom, Pos, L, _, SubAtomPoints), % prende stringa dopo due punti
                        A is Length - L - 1,
                        sub_atom(Atom, 0,  A, _, SubAtomHost), %prende stringa host
                        host(SubAtomHost), !,
                        port(SubAtomPoints).

/* indirizzo_ip */
indirizzo_ip(Input):- atom_codes(Input, List_input),
                      length(List_input, 15), !,
                      validate_point(List_input).

validate_point(L):- nth1(12, L, 46), nth1(8, L, 46), nth1(4, L, 46),
                    atom_codes(String, L),
                    split_string(String, ".", "", List_string),
                    length(List_string, 4),
                    validate_number(List_string).

validate_number([L | Ls]):- digit(L), validate_number(Ls), !.
validate_number([]).

/* path */
path(Input) :- identificatore(Input), !.
path(Input) :- atom_codes(Input, List_codes),
               member(47, List_codes),
               slash(List_codes), !.

slash(List_codes) :- listPos(List_codes, 47, Pos),
                     atom_codes(Atom, List_codes),
                     P is Pos - 1,
                     sub_atom(Atom, 0, P, After, SubAtomId),
                     identificatore(SubAtomId),
                     A is After - 1,
                     sub_atom(Atom, Pos, A, _, SubAtomIde),
                     identificatore(SubAtomIde).

/* query */
query(Input) :- atom_codes(Input, List_codes), member(35, List_codes), !, fail.
query(Input).

/* fragment */
fragment(Input).

/* scheme_syntax */
scheme_syntax(Input) :- mailto(Input), !.
scheme_syntax(Input) :- news(Input), !.
scheme_syntax(Input) :- telfax(Input), !.

/* mailto */
mailto(Input) :- userinfo(Input), !.
mailto(Input) :- string_codes(Input, List_codes),
                 member(64, List_codes),
                 at(List_codes), !.

at(List_codes) :- listPos(List_codes, 64, Pos),
                  atom_codes(Atom, List_codes),
                  P is Pos - 1,
                  sub_atom(Atom, 0, P, After, SubAtomAt),
                  A is After - 1,
                  userinfo(SubAtomAt),
                  sub_atom(Atom, Pos, A, _, SubAtomRest),
                  host(SubAtomRest).

/* news */
news(Input) :- host(Input), !.

/* tel e fax */
telfax(Input) :- userinfo(Input), !.

/* caratteri alfanumerici */
controlX(List_codes) :- member(X, List_codes), X > 47, X < 58, !.
controlX(List_codes) :- member(X, List_codes), X > 64, X < 91, !.
controlX(List_codes) :- member(X, List_codes), X > 96, X < 123, !.

/* id8 */
id8(Input) :- atom_codes(Input, List_codes), length(List_codes, Y), Y > 8, !, fail.
id8(Input) :- atom_codes(Input, List_codes), controlX(List_codes), !.

/* id44 da controllare */
id44(Input) :- atom_codes(Input, List_codes),
               length(List_codes, Y),
               Y is 1,
               member(46, List_codes), !.
id44(Input) :- atom_codes(Input, List_codes), length(List_codes, Y), Y > 44, !, fail.
id44(Input) :- atom_codes(Input, List_codes), controlX(List_codes), !.


/*ZOS*/

zos(Input):- id44(Input), 
             Zos = Input, !.

zos(Input):- atom_codes(Input, List_codes), member(28, List_codes), 
            member(29, List_codes), !,
            listPos(List_codes, 28, X), length(List_codes, Length),
            atom_codes(Atom, List_codes),
            L is Length - X;
            sub_atom(Atom, 0, L, After, SubAtom),
            id44(SubAtom), !, 
            A is After - 2,
            sub_atom(Atom, X, A, _,SubAtom2),
            id8(SubAtom2), !,
            atom_concat(SubAtom + SubAtom2, Zos).


%----------URI

uri_parse(Uri_string, Uri) :- string_codes(Uri_string, Uri_codes), 
                            member(58, Uri_codes), !,
                            listPos(Uri_codes, 58, Pos),
                            atom_codes(Atom, Uri_codes),
                            P is Pos - 1,
                            sub_atom(Atom, 0, P, After, Scheme),
                            A is After - 1,
                            sub_atom(Atom, Pos, A, _, Rest),
                            uri(Scheme, Rest).

uri(Scheme, Rest) :- atom_codes(Rest, Rest_codes), 
                    nth0(0, Rest_codes, 47), !,
                    Identificatore = Scheme,
                    uri1(Rest).

%URI 1
uri1(Input) :- authority(Input),
             Path= [], 
             Query = [],
             Fragment = [].

uri1(Input) :- atom_codes(Atom, [X | Xs]), 
              X = 47, !,
              uri1_rest(Xs).

%PATH
uri1_rest(Input) :- atom_codes(Atom, [X | Xs]),
                    path(Input)
                    Path = Input.
%QUERY 
uri1_rest(X | Xs) :- X = 63, !,
                    atom_codes(Atom, [X | Xs]),
                    query(Atom), 
                    Query = Atom,
%FRAGMENT
uri1_rest(X | Xs) :- X = 35, !,
                    atom_codes(Atom, [X | Xs]),
                    fragment(Xs),
                    Fragment = Xs.

%Rest
uri1_rest(Input) :- member(63, Input), !, 
                    listPos(Uri_codes, 63, Pos),
                    atom_codes(Uri_Atom, Uri_codes),
                    P is Pos - 1,
                    sub_atom(Uri_Atom, 0, P, After, Path),
                    A is After - 1, Ps is Pos + 1,
                    sub_atom(Uri_Atom, Ps, A, _, Rest),
                    path(Path), 
                    Path = Path.
                    uri1_rest(Rest).

uri1_rest(Input):- member()

               





