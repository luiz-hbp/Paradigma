main :-
    open('in.txt', read, Stream),
    leitura(Stream,Texto), %Faz a leitura do arquivo e armazena caracteres em uma lista
    close(Stream),
    ms(Texto, Ordenado), %Ordena caracteres da lista
    caracteres_unicos(Ordenado,Caracteres,Frequencias), %Conta cada caracter da lista e suas respectivas frequencias
    unifica_lista(Caracteres, Frequencias, CaracteresEFrequencias), %Cria lista de duplas dos caracteres no texto e suas frequencias
    sort(CaracteresEFrequencias, OrdenadoPorFrequencia), %Ordena lista de duplas por frequencia
    gera_arvore(OrdenadoPorFrequencia, Arvore), %Cria arvore de huffman
    gera_tabela(Arvore, [], Tabela), %Cria tabela de caracteres e seus respectivos códigos
    codifica(Tabela, Texto, Codificado), %Codifica texto do arquivo baseado na tabela criada
    lista_para_string(Codificado, String), %Transforma lista codificada em string
    open('out.txt', write, Stream2, [encoding(utf8)]),
    write(Stream2, String), %Escreve texto codificado no arquivo out.txt
    close(Stream2),
    open('out.txt', read, Stream3),
    leitura(Stream3,TextoCodificado), %Faz a leitura do arquivo codificado
    close(Stream3),
    decodificar(TextoCodificado,Arvore,Arvore,[]). %Faz a decodificação do texto

%Caso base para leitura: quando o final do arquivo é atingido
leitura(Stream,[]) :- 
at_end_of_stream(Stream).

%Realiza a leitura do arquivo caracter por caracter e adiciona na lista resultante
leitura(Stream,[X|L]) :-
\+ at_end_of_stream(Stream),
get_char(Stream,X),
leitura(Stream,L).


%Merge Sort para ordenar a lista de caracteres
ms([],[]).
ms([A],[A]).
ms(L,R) :- split(L,L1,L2), ms(L1,R1), ms(L2,R2), interc(R1,R2,R).

interc(L,[],L).
interc([],L,L).
interc([A|As],[B|Bs],[A|Xs]) :-
A @=< B,
interc(As,[B|Bs],Xs).
interc([A|As],[B|Bs],[B|Xs]) :-
interc([A|As],Bs,Xs).

split([],[],[]).
split([A],[A],[]).
split([A,B|X],[A|As],[B|Bs]) :- split(X,As,Bs).

%Deleta todas as aparições do elemento na lista
delall(_, [], []).
delall(A, [A|X], Z) :- delall(A,X,Z).
delall(A, [B|X], [B|Z]) :- delall(A, X, Z).

%Calcula frequencia do caracter na lista
n_elemento(_, [], 0).
n_elemento(A, [A|X], N1):- n_elemento(A,X,N),N1 is N + 1.
n_elemento(A, [B|X], N):- n_elemento(A,X,N).

%Elimina repetições na lista e calcula número de repetições na lista
caracteres_unicos([],[],[]).
caracteres_unicos([A|X],[A|L],[F|Z]):-
n_elemento(A, [A|X], F),
delall(A, X, R),
caracteres_unicos(R,L,Z).

%Produz lista de Duplas para armazenar caracteres e sua frequencia
unifica_lista([],[],[]).
unifica_lista([C|X], [F|Y], [[F,C]|Z]):- unifica_lista(X,Y,Z).

%Cria árvore de huffman iniciando pelos nós de menor frequencia
gera_arvore([[Frequencia1|Caracter1], [Frequencia2|Caracter2]|Calda], Arvore) :-
SomaFrequencias is Frequencia1 + Frequencia2,
NovoNo = [SomaFrequencias, [Frequencia1|Caracter1], [Frequencia2|Caracter2]],
(Calda = [] -> 
Arvore = NovoNo; 
sort([NovoNo|Calda], NovaCalda), 
gera_arvore(NovaCalda, Arvore)).

%Gera tabela de codificações baseada na árvore
gera_tabela([_, [Frequencia1|Resto1], [Frequencia2|Resto2]], Caminho, Tabela) :-
gera_tabela([Frequencia1|Resto1], [0|Caminho], TabelaEsquerda),
gera_tabela([Frequencia2|Resto2], [1|Caminho], TabelaDireita),
append(TabelaEsquerda, TabelaDireita, Tabela).

gera_tabela([_, Caracter], Caminho, [[Caracter, Codigo]]) :-
reverse(Caminho, Codigo).

membro(A, [A|X]).
membro(A, [B|X]) :- membro(A,X).

%Codifica Texto usando a Tabela de Huffman
codifica(_, [], []).
codifica(Tabela, [Caracter|Resto], Codificado):-
membro([Caracter, Codigo], Tabela),
codifica(Tabela, Resto, RestoCodificado),
append(Codigo, RestoCodificado, Codificado).

%Transforma Lista de Caracteres em String
lista_para_string([], '').
lista_para_string([A|X], String) :-
lista_para_string(X, StringResto),
string_concat(A, StringResto, String).

%Decodifica a mensagem percorrendo a árvore
decodificar([], [_, Char], _, Decodifica) :-
append(Decodifica, [Char], Deci), 
lista_para_string(Deci, MensagemDecodificada),
open('novoIn.txt', write, Stream, [encoding(utf8)]), %Escreve texto codificado em novo arquivo
write(Stream, MensagemDecodificada),
close(Stream).

decodificar(['1' | Resto], [_, Item2, Item3 | X], Arvore, Decodifica) :- %Caso 1 segue pelo lado esquerdo da árvore
decodificar(Resto, Item3, Arvore, Decodifica).

decodificar(['0' | Resto], [_, Item2, Item3 | X], Arvore, Decodifica) :- %Caso 0 segue pelo lado direito da árvore
decodificar(Resto, Item2, Arvore, Decodifica).

decodificar(Resto, [_, Char], Arvore, Decodifica) :- 
append(Decodifica, [Char], Deci),
decodificar(Resto, Arvore, Arvore, Deci).
