DESTDIR?=	$(CURDIR)/destdir
PREFIX?=	/usr

RDOC?=		rdoc
RDOC_DIR=	rdoc

.PHONY: help
help:
	@echo Available targets:
	@echo - install PREFIX=... DESTDIR=...
	@echo - docs
	@echo - clean-docs

.PHONY: install
install:
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	install -m0755 bin/va11halla_extract $(DESTDIR)$(PREFIX)/bin
	install -m0755 bin/va11halla_reader $(DESTDIR)$(PREFIX)/bin

.PHONY: docs
docs:
	$(RDOC) -o $(RDOC_DIR) --visibility=private

.PHONY: clean-docs
clean-docs:
	rm -rf $(RDOC_DIR)
