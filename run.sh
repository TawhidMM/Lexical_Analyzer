flex -o lex.yy.c 2005036.l
g++ lex.yy.c -lfl -o lexer
./lexer input.txt
