TMPDIR := tmp
SRC := ../../..
SCRIPTSDIR := $(SRC)/scripts
TEMPLATESDIR := ../templates

.PHONY: clean
clean:
	rm -rf $(TMPDIR)

$(TMPDIR)/:
	mkdir -p $(TMPDIR)

$(TMPDIR)/chebi.db: $(SRC)/ontology/tmp/chebi.db | $(TMPDIR)/
	cp $< $@

$(TMPDIR)/dron.db: $(SCRIPTSDIR)/create-dron-tables.sql $(SCRIPTSDIR)/load-dron-tables.sql | $(TMPDIR)/
	rm -f $@
	sqlite3 $@ < $<
	sqlite3 $@ < $(word 2,$^)

$(TMPDIR)/rxnorm.db: $(SCRIPTSDIR)/create-rxnorm-tables.sql $(SCRIPTSDIR)/load-rxnorm-tables.sql | $(TMPDIR)/
	rm -f $@
	sqlite3 $@ < $<
	sqlite3 $@ < $(word 2,$^)

$(TMPDIR)/convert.db: $(TMPDIR)/chebi.db $(TMPDIR)/rxnorm.db $(SCRIPTSDIR)/create-dron-tables.sql $(SCRIPTSDIR)/convert-rxnorm-dron.sql $(SCRIPTSDIR)/load-dron-manual-tables.sql
	rm -f $@
	sqlite3 $@ < $(word 3,$^)
	sqlite3 $@ "UPDATE current_dron_id SET id = 90000000"
	sqlite3 $@ < $(word 4,$^)
	sqlite3 $@ < $(word 5,$^)

$(TMPDIR)/convert/: $(TMPDIR)/convert.db $(SCRIPTSDIR)/save-dron-tables.sql
	rm -rf $@
	mkdir -p $@
	cd $(TMPDIR)/convert/ && sqlite3 ../convert.db < ../../$(word 2,$^)
	# Create empty tables for comparison.
	echo "curie	ndc	clinical_drug" > $@/ndc_clinical_drug.tsv
	
.PHONY: convert
convert: $(TMPDIR)/convert/
	diff $(TEMPLATESDIR)/ $<
