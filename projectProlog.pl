/* digit */
digit(Input):- atom_codes(Input, List_codes), controlDigit(List_codes), !,
               term_string(TermInput, Input), integer(TermInput).

controlDigit([X]):- X > 47, X < 58.
controlDigit([X | Xs]):- X > 47, X < 58, !, controlDigit(Xs).


digit255(Input):- atom_codes(Input, List_codes), controlDigit(List_codes), !,
                  term_string(TermInput, Input), integer(TermInput),
                  TermInput >= 0, TermInput < 256.

/* caratteri non validi per identificatore */
id(64). %@
id(47). %/
id(63). %?
id(35). %#
id(58). %:

identificatore(Input) :- atom_codes(Input, List_input), ide(List_input), !.

ide([L| _]):- id(L), ! , fail.
ide([_ | Ls]):- ide(Ls).
ide([_]).

/* caratteri non validi per identificatore_host */
idH(64). %@
idH(47). %/
idH(63). %?
idH(35). %#
idH(58). %:
idH(46). %.

identificatore_host(Input):- atom_codes(Input, List_input), ids(List_input), !.

ids([L| _]):- idH(L), ! , fail.
ids([_ | Ls]):- ids(Ls).
ids([_]).

/* elimina gli spazi */

elimina_spazi([], []).
elimina_spazi([255 | Tail], Tail ):- !.
elimina_spazi([Head | Tail], [Head, X]):-  elimina_spazi(Tail, X).

/* split_atom */
split_atom(Atom, Pos, SubAtom1 , SubAtom2):- P is Pos - 1,
                                        sub_atom(Atom, 0, P, After, SubAtom1),
                                        A is After - 1,
                                        sub_atom(Atom, Pos, A, _,SubAtom2).

/* posizione */
listPos([X|_], X, 1).
listPos([_|Tail], X, Pos):- listPos(Tail, X, P), Pos is P + 1.

/* scheme */
scheme(Input):- identificatore(Input), !.

/* host */
host(Input):- identificatore_host(Input), !.
host(Input):- atom_codes(Input, List_codes), point(List_codes), !.
host(Input):- indirizzo_ip(Input), !.


point(List_codes):- listPos(List_codes, 46, Pos),
                     atom_codes(Atom, List_codes),
                     P is Pos - 1,
                     sub_atom(Atom, 0, P, After, SubAtomIdH),
                     identificatore_host(SubAtomIdH),
                     A is After - 1,
                     sub_atom(Atom, Pos, A, _, SubAtomIdHost),
                     identificatore_host(SubAtomIdHost), !.

point(List_codes):- listPos(List_codes, 46, Pos),
                    atom_codes(Atom, List_codes),
                    P is Pos - 1,
                    sub_atom(Atom, 0, P, After, SubAtomIdH),
                    identificatore_host(SubAtomIdH),
                    A is After - 1,
                    sub_atom(Atom, Pos, A, _, SubAtomIdHost),
                    host(SubAtomIdHost), !.
/* userinfo */
userinfo(Input):- identificatore(Input), !.

/* port */
port(Input):- digit255(Input), !.

/* authority */
authority(Input) :- atom_codes(Input, List_input), c_aut(List_input).

c_aut([X, X | Y]) :- X == 47, member(64, Y), !, aut(Y), !.
c_aut([X, X | Y]) :- X == 47, member(58, Y), !, twopoints(Y), !.
c_aut([X, X | Y]) :- X == 47, atom_codes(Atom, Y), host(Atom), !.

aut(List_codes):-length(List_codes, Length_list),
            listPos(List_codes, 64, Pos),
            P is Pos - 1,
            atom_codes(Atom, List_codes),
            sub_atom(Atom, 0, P, After, SubAtomAt),
            A is After - 1,
            sub_atom(Atom, Pos, A, _ , SubAtomRest),
            atom_codes(SubAtomRest, List_SubAtomRest),
            twopoints(List_SubAtomRest).

aut(List_codes):- length(List_codes, Length_list),
            listPos(List_codes, 64, Pos),
            P is Pos - 1,
            atom_codes(Atom, List_codes),
            sub_atom(Atom, 0, P, After, SubAtomAt),
            A is After - 1,
            sub_atom(Atom, Pos, A, _ , SubAtomRest),
            atom_codes(SubAtomRest, List_SubAtomRest),
            host(SubAtomRest), !,
            userinfo(SubAtomAt).

twopoints(List_codes):- member(58, List_codes), !,
                        length(List_codes, Length),
                        listPos(List_codes, 58, Pos),
                        L is Length - Pos,
                        atom_codes(Atom, List_codes),
                        sub_atom(Atom, Pos, L, _, SubAtomPoints),
                        A is Length - L - 1,
                        sub_atom(Atom, 0,  A, _, SubAtomHost),
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
path(Input):- identificatore(Input), !.
path(Input):- atom_codes(Input, List_codes),
              member(47, List_codes),
              slash(List_codes), !.

slash(List_codes):- listPos(List_codes, 47, Pos),
                     atom_codes(Atom, List_codes),
                     P is Pos - 1,
                     sub_atom(Atom, 0, P, After, SubAtomId),
                     identificatore(SubAtomId),
                     A is After - 1,
                     sub_atom(Atom, Pos, A, _, SubAtomIde),
                     identificatore(SubAtomIde), !.

slash(List_codes):- listPos(List_codes, 47, Pos),
                    atom_codes(Atom, List_codes),
                    P is Pos - 1,
                    sub_atom(Atom, 0, P, After, SubAtomId),
                    identificatore(SubAtomId),
                    A is After - 1,
                    sub_atom(Atom, Pos, A, _, SubAtomIde),
                    path(SubAtomIde).
/* query */
query(Input):- atom_codes(Input, List_codes), member(35, List_codes), !, fail.
query(Input).

/* fragment */
fragment(Input).

/* scheme_syntax */
scheme_syntax(Input):- mailto(Input), !.
scheme_syntax(Input):- news(Input), !.
scheme_syntax(Input):- tel(Input), !.
scheme_syntax(Input):- fax(Input), !.
scheme_syntax(Input):- zos(Input), !.


/* mailto */
mailto(Input):- userinfo(Input), !.
mailto(Input):- string_codes(Input, List_codes),
                member(64, List_codes),
                at(List_codes), !.

at(List_codes):- listPos(List_codes, 64, Pos),
                 atom_codes(Atom, List_codes),
                 P is Pos - 1,
                 sub_atom(Atom, 0, P, After, SubAtomAt),
                 A is After - 1,
                 userinfo(SubAtomAt),
                 sub_atom(Atom, Pos, A, _, SubAtomRest),
                 host(SubAtomRest).

/* news */
news(Input):- host(Input), !.

/* tel e fax */
tel(Input):- userinfo(Input), !.
fax(Input):- userinfo(Input), !.

/* caratteri alfanumerici */
controlX([X]):- X > 47, X < 58.
controlX([X]):- X > 61, X < 91.
controlX([X]):- X > 96, X < 123.

controlX([X | Xs]):- X > 47, X < 58, !, controlX(Xs).
controlX([X | Xs]):- X > 64, X < 91, !, controlX(Xs).
controlX([X | Xs]):-  X > 96, X < 123, !, controlX(Xs).

controlX44([X]):- X > 45, X < 58.
controlX44([X]):- X > 61, X < 91.
controlX44([X]):- X > 96, X < 123.

controlX44([X | Xs]):- X > 45, X < 58, !, controlX44(Xs).
controlX44([X | Xs]):- X > 64, X < 91, !, controlX44(Xs).
controlX44([X | Xs]):- X > 96, X < 123, !, controlX44(Xs).

/* id44 da controllare */
id44(Input):- atom_codes(Input, List_codes),
              length(List_codes, Y),
              Y < 44, !,
              controlid44(List_codes), !.

controlid44([X | Xs]):- X > 45, X < 58, !, fail.
controlid44([X | Xs]):- last_element(46, [X | Xs]), !, fail.
controlid44(List_codes):- controlX44(List_codes).

last_element(X, [X]).
last_element(X, [_ | Xs]) :- last_element(X, Xs).

/* id8 */
id8(Input):- atom_codes(Input, List_codes),
             length(List_codes, Y),
             Y < 9, !,
             controlid8(List_codes).

controlid8([X | Xs]):- X > 45, X < 58, !, fail.
controlid8(List_codes):- controlX(List_codes).

/* ZOS */

zos(Input) :- id44(Input),
              Zos = Input, !.

zos(Input) :- atom_codes(Input, List_codes), member(28, List_codes),
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


/* URI */


uri_parse(Uri_string, Uri) :- string_codes(Uri_string, Uri_codes),
                            member(58, Uri_codes), !,
                            listPos(Uri_codes, 58, Pos),
                            atom_codes(Atom, Uri_codes),
                            split_atom(Atom, Pos, Scheme, Rest),
                            uri(Scheme, Rest), !.

uri(Scheme, Rest) :- atom_codes(Rest, Rest_codes),
                    nth0(0, Rest_codes, 47), !,
                    scheme(Scheme), !,
                    Identificatore = Scheme,
                    control_uri1(Rest_codes).

uri(Scheme, Rest):- control_uri2(Scheme, Rest).

%URI 1

/* CONTROLLO NUMERO DI slash */

control_uri1([X, X | Y]) :- X = 47, control_uriA([X, X | Y]).

%solo con REST Passo REST senza /
control_uri1([X | Xs]) :- uri1_rest(Xs).

%con tutto
control_uriA([X, X | Y]) :- member(47, Y), !,
                            listPos(Y, 47, Pos),
                            P is Pos + 2,
                          uri1_split([X, X | Y], P).

%solo con AUTHORITY
control_uriA(Codes) :- uri1A(Codes), !.



uri1_split(Codes, Pos) :- atom_codes(Atom, Codes),
                    split_atom(Atom, Pos, SubAtomAt, SubAtomRest),
                    authority(SubAtomAt), !,
                    Authority = SubAtomAt,
                    atom_codes(SubAtomRest, List_codes),
                    uri1_rest(List_codes), !.

uri1A(Codes) :- atom_codes(Atom, Codes),
                authority(Atom), !,
                Authority = Atom.

%REST senza path
uri1_rest([X | Xs]) :- X = 63 ; X = 35,
                      uri1_rsplit([X | Xs]),
                      Path = [].

%REST con path
uri1_rest(Codes) :- control_rest(Codes).

%con PATH query e fragment
control_rest([X | Xs]):- member(35, Xs),
                      member(63, Xs),
                      listPos([X | Xs], 63, Pos),
                      atom_codes(Atom, [X | Xs]),
                      split_atom(Atom, Pos, SubAtom1, SubAtom2),
                      path(SubAtom1), !,
                      Path = SubAtom1,
                      atom_codes(SubAtom2, Codes),
                      uri1_rsplit(Codes).


%COn path solo fragmetn o query
control_rest(Codes) :- atom_codes(Atom, Codes),
                    path(Atom), Path = Atom;
                    uri1_r(Codes).


%fragment e query
uri1_rsplit([X | Xs]) :- X = 63,
                     member(35, Xs), !,
                     listPos(Xs, 35 , Pos),
                     atom_codes(Atom, [X | Xs]),
                     split_atom(Atom, Pos, SubAtom1, SubAtom2),
                     query(SubAtom1),
                     fragment(SubAtom2),
                     Query = SubAtom1,
                     Fragment = SubAtom2.

%
uri1_rsplit([X | Xs]) :- X = 63,
                        atom_codes(Atom, [X | Xs]),
                        query(Atom), !,
                        Query = Atom.

uri1_rsplit(Codes) :- atom_codes(Atom, Codes),
                        fragment(Atom), !,
                        Fragment = Atom.


%QUERY
uri1_r(Codes) :- member(63, Codes),
                listPos(Codes, 63, Pos),
                atom_codes(Atom, Codes),
                split_atom(Atom, Pos, SubAtom1, SubAtom2),
                path(SubAtom1), !,
                Path = SubAtom1,
                query(SubAtom2), !,
                Query = SubAtom2.

%FRAGMENT
uri1_r(Codes) :- member(35, Codes), !,
                listPos(Codes, 35, Pos),
                atom_codes(Atom, Codes),
                split_atom(Atom, Pos, SubAtom1, SubAtom2),
                path(SubAtom1), !,
                Path = SubAtom1,
                fragment(SubAtom2), !,
                Fragment = SubAtom2.
                
/* uri2 */
control_uri2(Scheme, Rest):- Scheme == 'mailto', !, mailto(Rest).
control_uri2(Scheme, Rest):- Scheme == 'tel', !, tel(Rest).
control_uri2(Scheme, Rest):- Scheme == 'fax', !, fax(Rest).
control_uri2(Scheme, Rest):- Scheme == 'zos', !, zos(Rest).           
