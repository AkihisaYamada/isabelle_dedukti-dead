KOCHECK ?= kocheck

%.dko:
	@echo $<

%.koo:
	$(MAKE) --silent -f deps.mk -f kontroli.mk $*.dko | xargs cat | $(KOCHECK) $(KOFLAGS) -