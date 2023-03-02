PREFIX ?= /usr
LIBDIR ?= lib
SHAREDIR ?= share/libsh

SRC = $(shell git ls-tree --name-only HEAD *.sh)
DOCS = README.md

.PHONY: all
all:
	@echo Do 'make install'

.PHONY: install
install:
	install -t $(PREFIX)/$(LIBDIR) $(SRC) 
	install -t $(PREFIX)/$(SHAREDIR) $(DOCS)

.PHONY: getoptions
getoptions:
	./gengetoptions library > getoptlib.sh

