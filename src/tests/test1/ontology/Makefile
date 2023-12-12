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
	rm -rf $(TMPDIR)/rxnorm/
	cp -r ../rxnorm/ $(TMPDIR)/
	sqlite3 $@ < $<
	sqlite3 $@ < $(word 2,$^)

$(TMPDIR)/convert.db: $(TMPDIR)/chebi.db $(TMPDIR)/rxnorm.db $(SCRIPTSDIR)/create-dron-tables.sql $(SCRIPTSDIR)/convert-rxnorm-dron.sql $(SCRIPTSDIR)/load-dron-manual-tables.sql
	rm -f $@
	sqlite3 $@ < $(word 3,$^)
	sqlite3 $@ "UPDATE current_dron_id SET id = 90000001"
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
	diff -u $(TEMPLATESDIR)/ $<

$(TMPDIR)/ldtab.db: $(TMPDIR)/convert.db $(SCRIPTSDIR)/prefix.tsv $(SCRIPTSDIR)/create-statement-table.sql $(SCRIPTSDIR)/convert-dron-ldtab.sql
	rm -f $@
	ldtab init $@
	ldtab prefix $@ $(word 2,$^)
	sed 's/statement/dron_ingredient/' $(word 3,$^) | sqlite3 $@
	sed 's/statement/dron_rxnorm/' $(word 3,$^) | sqlite3 $@
	sed 's/statement/dron_ndc/' $(word 3,$^) | sqlite3 $@
	sqlite3 $@ < $(word 4,$^)

$(TMPDIR)/ldtab/:
	mkdir -p $@

$(TMPDIR)/ldtab/%.tsv: $(TMPDIR)/ldtab.db | $(TMPDIR)/ldtab/
	ldtab export $< $@ --table $*
	mv $@ $@.tmp
	head -n1 $@.tmp > $@
	tail -n+2 $@.tmp | sort >> $@
	rm $@.tmp

.PHONY: ldtab
ldtab: $(TMPDIR)/ldtab/dron_ingredient.tsv $(TMPDIR)/ldtab/dron_rxnorm.tsv $(TMPDIR)/ldtab/dron_ndc.tsv
	diff -u ../ldtab/ $(TMPDIR)/ldtab/

$(TMPDIR)/ldtab/%.ttl: $(TMPDIR)/ldtab.db | $(TMPDIR)/ldtab/
	ldtab export $< $@ --table $*

$(TMPDIR)/ldtab/%.owl: $(TMPDIR)/ldtab/%.ttl
	robot convert -i $< -o $@

.PHONY: owl
owl: $(TMPDIR)/ldtab/dron_ingredient.owl $(TMPDIR)/ldtab/dron_rxnorm.owl $(TMPDIR)/ldtab/dron_ndc.owl
