.PHONY: test lint clean help

THEMIS_COMMIT :=
VIMLINT_COMMIT :=
VIMLPARSER_COMMIT :=

LINT_DIRS := autoload plugin test

help:
	@echo "Available targets:"
	@echo "  test  - Run tests with vim-themis"
	@echo "  lint  - Run vim-vimlint"
	@echo "  clean - Clean up dependencies and temporary files"

test: vim-themis
	./vim-themis/bin/themis test

lint: vim-vimlint vim-vimlparser
	./vim-vimlint/bin/vimlint.sh -l ./vim-vimlint -p ./vim-vimlparser -e EVL102.l:_=1 -v $(LINT_DIRS)

vim-themis:
	git clone https://github.com/thinca/vim-themis.git
ifeq ($(THEMIS_COMMIT),)
	@echo "Using latest vim-themis"
else
	cd vim-themis && git checkout $(THEMIS_COMMIT)
endif

vim-vimlint:
	git clone https://github.com/syngan/vim-vimlint.git
ifeq ($(VIMLINT_COMMIT),)
	@echo "Using latest vim-vimlint"
else
	cd vim-vimlint && git checkout $(VIMLINT_COMMIT)
endif

vim-vimlparser:
	git clone https://github.com/ynkdir/vim-vimlparser.git
ifeq ($(VIMLPARSER_COMMIT),)
	@echo "Using latest vim-vimlparser"
else
	cd vim-vimlparser && git checkout $(VIMLPARSER_COMMIT)
endif

clean:
	rm -rf vim-themis vim-vimlint vim-vimlparser tmp/*
