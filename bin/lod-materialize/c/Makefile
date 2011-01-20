# CFLAGS	= -O3 -Wall -pedantic -std=c99
CFLAGS	= -g -Wall -pedantic -std=c99
# CFLAGS	= -g -ggdb -pg -Wall -pedantic -std=c99
CC		= gcc $(CFLAGS)
INC		= -I/usr/local/include -I/usr/local/include/rasqal -I/usr/include/rasqal
LIBS	= -lraptor -lrdf -lpcre
OBJS	= avl.o

all: lod-materialize

lod-materialize: lod-materialize.c avl.o
	$(CC) $(INC) $(LIBS) $(OBJS) -o lod-materialize lod-materialize.c

avl.o: avl.h avl.c
	$(CC) -c avl.c
