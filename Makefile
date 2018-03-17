SHELL := /bin/bash
CWD := $(shell cd -P -- '$(shell dirname -- "$0")' && pwd -P)

all:
	crystal build --release src/crysh.cr

run:
	crystal src/crysh.cr

install:
	ln -sf $(CWD)/crysh /usr/local/bin/crysh
