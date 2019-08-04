DESTDIR?=	$(CURDIR)/destdir
PREFIX?=	/usr

.PHONY: help
help:
	@echo Available targets:
	@echo - install PREFIX=... DESTDIR=...

.PHONY: install
install:
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	install -m0755 bin/va11halla_extract $(DESTDIR)$(PREFIX)/bin
	install -m0755 bin/va11halla_reader $(DESTDIR)$(PREFIX)/bin
