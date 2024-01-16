## Customize Makefile settings for dron
## 
## If you need to customize your Makefile, make
## changes here rather than in the main Makefile

##################################
#### Custom release artefacts ####
##################################

define swap_chebi
    $(ROBOT) rename -i $(1) --mappings mappings/dron-chebi-mapping.csv --allow-missing-entities true --allow-duplicates true convert -f ofn -o $(1)
endef

# The following describes the definition of the dron-lite release. 
# In essence we merge rxnorm, dron-ingredient, all imports and the edit file
# (no NDC) and the run a regular full release.

LITE_ARTEFACTS=$(COMPONENTSDIR)/dron-rxnorm.owl $(COMPONENTSDIR)/dron-ingredient.owl $(IMPORT_OWL_FILES)
$(TMPDIR)/dron-edit_lite.owl: $(SRC) $(LITE_ARTEFACTS)
	$(ROBOT) remove --input $(SRC) --select imports \
	merge $(patsubst %, -i %, $(LITE_ARTEFACTS)) --output $@.tmp.owl && mv $@.tmp.owl $@

dron-lite.owl: $(TMPDIR)/dron-edit_lite.owl
	$(ROBOT) merge --input $< \
		reason --reasoner ELK --equivalent-classes-allowed all --exclude-tautologies structural \
		relax \
		reduce -r ELK \
		annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) --output $@.tmp.owl && mv $@.tmp.owl $@


# export: $(TMPDIR)/export_dron-hand.tsv
# 
# $(TMPDIR)/export_dron-%.tsv: $(COMPONENTSDIR)/dron-%.owl | $(TMPDIR)
# 	$(ROBOT) export --input $< \
#   --header "ID|Type|LABEL|has_obo_namespace|SubClass Of|definition|hasDbXref|comment|hasExactSynonym|has_narrow_synonym|hasRelatedSynonym|created_by|creation_date|in_subset|has_alternative_id" \
#   --include "classes properties" \
#   --export $@
# reports/dron-%.tsv: $(COMPONENTSDIR)/dron-%.owl
# 	$(ROBOT) query -i $< --query ../sparql/dron-$*.sparql $@
# 	cat $@ | sed 's|http://purl.obolibrary.org/obo/DRON_|DRON:|g' | sed 's|http://purl.obolibrary.org/obo/CHEBI_|CHEBI:|g' | sed 's|http://purl.obolibrary.org/obo/OBI_|OBI:|g' | sed 's|http://www.w3.org/2002/07/owl#|owl:|g' | sed 's/[<>]//g' > $@.tmp && mv $@.tmp $@
# 
# reports/template-dron-ingredient.tsv: reports/dron-ingredient.tsv
# 	sed -i '1d' reports/dron-ingredient.tsv > $@
# 	echo "ID	LABEL	TYPE	PARENT	RXCUI	p1_bfo53	p1_bfo71	p1_genus	BEARER\nID	LABEL	TYPE	SC %	A DRON:00010000			SC 'is bearer of' some % SPLIT=|" | cat - reports/dron-ingredient.tsv > $@.tmp && mv $@.tmp $@
# 	echo "BFO:0000053	is bearer of	owl:ObjectProperty			" >> $@
# 
# reports/template-dron-ndc.tsv: reports/dron-ndc.tsv
# 	sed -i '1d' reports/dron-ndc.tsv > $@
# 	echo "ID	LABEL	TYPE	PARENT	BEARER\nID	LABEL	TYPE	SC %	SC 'has_proper_part' some % SPLIT=|" | cat - reports/dron-ndc.tsv > $@.tmp && mv $@.tmp $@
# 	echo "http://www.obofoundry.org/ro/ro.owl#has_proper_part	has_proper_part	owl:ObjectProperty			" >> $@
# 
# reports/template-dron-rxnorm.tsv: reports/dron-rxnorm.tsv
# 	sed -i '1d' reports/dron-rxnorm.tsv > $@
# 	echo "ID	LABEL	TYPE	PARENT	RXCUI	BEARER\nID	LABEL	TYPE	SC %	A DRON:00010000	SC 'is bearer of' some % SPLIT=|" | cat - reports/dron-rxnorm.tsv > $@.tmp && mv $@.tmp $@
# 	echo "BFO:0000053	is bearer of	owl:ObjectProperty			" >> $@
# 
# reports/template-%.owl: reports/template-%.tsv
# 	$(ROBOT) template --template $< \
#   --ontology-iri "$(ONTBASE)/$@" \
#   --output $@
# 
# tables: reports/dron-rxnorm.tsv reports/dron-ingredient.tsv reports/dron-ndc.tsv
# 
# tmp/unmerge-%.owl: $(COMPONENTSDIR)/dron-%.owl reports/template-dron-%.owl
# 	$(ROBOT) merge -i $< unmerge -i reports/template-dron-$*.owl convert -f ofn -o $@
# 
# tmp/unmerge-%.ttl: tmp/unmerge-%.owl
# 	$(ROBOT) convert -i $< -f ttl -o $@
# 
# tmp/unmerge-ingredient.owl:
# 	echo "skipped"
# 
# unmerge: tmp/unmerge-ingredient.owl tmp/unmerge-ingredient.ttl
# unmerge: tmp/unmerge-ndc.owl tmp/unmerge-ndc.owl tmp/unmerge-rxnorm.owl
# 
# tmp/rename-%.owl: tmp/%.owl
# 	$(ROBOT) rename -i $< --mappings config/rename.tsv -o $@
# 
# ALL_PATTERNS=$(patsubst ../patterns/dosdp-patterns/%.yaml,%,$(wildcard ../patterns/dosdp-patterns/[a-z]*.yaml))
# 
# .PHONY: matches	
# matches:
# 	dosdp-tools query --ontology=tmp/rename-unmerge-ingredient.owl --catalog=catalog-v001.xml --reasoner=elk --obo-prefixes=true --batch-patterns="$(ALL_PATTERNS)" --template="../patterns/dosdp-patterns" --outfile="../patterns/data/matches/"

DRON_RELEASE_LOCATION=https://drugontology.s3.amazonaws.com
DRON_NDC_RELEASE=$(DRON_RELEASE_LOCATION)/dron-ndc.owl
DRON_RXNORM_RELEASE=$(DRON_RELEASE_LOCATION)/dron-rxnorm.owl
DRON_INGREDIENTS_RELEASE=$(DRON_RELEASE_LOCATION)/dron-ingredient.owl

download_components:
	echo "Resetting components to the last release. This is usually only necessary when the project is cloned on a new machine."
	mkdir -p $(COMPONENTSDIR)
	wget $(DRON_NDC_RELEASE) -O $(COMPONENTSDIR)/dron-ndc.owl
	$(call swap_chebi,$(COMPONENTSDIR)/dron-ndc.owl)
	wget $(DRON_RXNORM_RELEASE) -O $(COMPONENTSDIR)/dron-rxnorm.owl
	$(call swap_chebi,$(COMPONENTSDIR)/dron-rxnorm.owl)
	wget $(DRON_INGREDIENTS_RELEASE) -O $(COMPONENTSDIR)/dron-ingredient.owl
	$(call swap_chebi,$(COMPONENTSDIR)/dron-ingredient.owl)
	grep -v "SubClassOf.*CHEBI_.*/OBI_0000047" components/dron-ingredient.owl > components/dron-ingredient-remediated.owl
	mv components/dron-ingredient.owl components/dron-ingredient-initial.owl
	mv components/dron-ingredient-remediated.owl components/dron-ingredient.owl 

################################
## From March 2021 Migration ###
################################

# tmp/dron-edit-external.ofn: $(SRC)
# 	$(ROBOT) filter --input $< \
#   --select "DRON:*" \
# 	--select complement \
#   --preserve-structure false \
#   --output $@
# 
# 
# unmerge_src:
# 	$(ROBOT) merge -i $(SRC) --collapse-import-closure false unmerge -i tmp/dron-edit-external.ofn convert -f ofn -o $(SRC)
# 
# 
# merge_release:
# 	$(ROBOT) merge -i $(SRC) -i $(COMPONENTSDIR)/dron-hand.owl  -i $(COMPONENTSDIR)/dron-upper.owl --collapse-import-closure false -o $(SRC).ofn

##### Diff #####

tmp/$(ONT)-build.owl:
	cp ../../$(ONT).owl $@
	
tmp/$(ONT)-merged.owl: $(SRC)
	$(ROBOT) merge -i $< -o $@

tmp/$(ONT)-release.owl:
	$(ROBOT) merge -I http://purl.obolibrary.org/obo/$(ONT).owl -o $@

reports/release-diff-%.md: tmp/$(ONT)-release.owl tmp/$(ONT)-%.owl
	$(ROBOT) diff --left $< --right tmp/$(ONT)-$*.owl -f markdown -o $@

reports/release-diff-%.txt: tmp/$(ONT)-release.owl tmp/$(ONT)-%.owl
	$(ROBOT) diff --left $< --right tmp/$(ONT)-$*.owl -o $@
	
reports/dron-release-diff-%.txt: reports/release-diff-%.txt
	grep DRON_ $< > $@

release_diff: reports/release-diff-build.md reports/release-diff-build.txt
release_diff: reports/release-diff-merged.md reports/release-diff-merged.txt
release_diff: reports/dron-release-diff-build.txt
release_diff: reports/dron-release-diff-merged.txt

.PHONY: unsat
unsat: tmp/dron_unsat.ofn
	
tmp/dron_unsat.ofn: $(SRC)
	robot merge --input $< explain --reasoner ELK \
  -M unsatisfiability --unsatisfiable all --explanation $@.md \
    annotate --ontology-iri "$(ONTBASE)/$@" \
    --output $@

.PHONY: swap_chebi_in_edit
swap_chebi_in_edit:
	 $(call swap_chebi,$(SRC))


############################
## From 2023 Refactoring ###
############################

# Use ROBOT to extract IDs and labels from chebi.owl.
# $(TMPDIR)/chebi.tsv: $(MIRRORDIR)/chebi.owl
# 	robot export --input $< \
# 	--include "classes" \
# 	--header "ID|LABEL" \
# 	--export $@

# Load ChEBI IDs and labels into SQLite.
$(TMPDIR)/chebi.db: $(TMPDIR)/chebi.tsv
	rm -f $@
	sqlite3 $@ ".mode tabs" ".import '$<' temp"
	sqlite3 $@ "CREATE TABLE label ( curie TEXT PRIMARY KEY, label TEXT UNIQUE, lower TEXT UNIQUE );"
	sqlite3 $@ "INSERT OR IGNORE INTO label SELECT ID AS curie, LABEL, LOWER(LABEL) AS lower FROM temp"
	sqlite3 $@ "CREATE INDEX idx_label_lower ON label(lower)"
	sqlite3 $@ "DROP TABLE temp"

# Create a SQLite database for DrOn and load tables from ../templates/*.tsv.
$(TMPDIR)/dron.db: $(SCRIPTSDIR)/create-dron-tables.sql $(SCRIPTSDIR)/load-dron-tables.sql
	rm -f $@
	sqlite3 $@ < $<
	sqlite3 $@ < $(word 2,$^)

# Create a SQLite database for RxNorm and load data from tmp/rxnorm/*.RRF.
$(TMPDIR)/rxnorm.db: $(SCRIPTSDIR)/create-rxnorm-tables.sql $(SCRIPTSDIR)/load-rxnorm-tables.sql $(SCRIPTSDIR)/index-rxnorm-tables.sql | $(TMPDIR)/
	rm -f $@
	sqlite3 $@ < $<
	sqlite3 $@ < $(word 2,$^) 2> /dev/null
	sqlite3 $@ < $(word 3,$^)

# Convert RxNorm to DrOn tables.
$(TMPDIR)/convert.db: $(TMPDIR)/chebi.db $(TMPDIR)/rxnorm.db $(SCRIPTSDIR)/create-dron-tables.sql $(SCRIPTSDIR)/index-dron-tables.sql $(SCRIPTSDIR)/convert-rxnorm-dron.sql $(SCRIPTSDIR)/load-dron-manual-tables.sql
	rm -f $@
	sqlite3 $@ < $(word 3,$^)
	sqlite3 $@ "UPDATE current_dron_id SET id = 10000000"
	sqlite3 $@ < $(word 4,$^)
	sqlite3 $@ < $(word 5,$^)
	sqlite3 $@ < $(word 6,$^)

# Save results of RxNorm to DrOn conversion to DrOn tables.
$(TMPDIR)/convert/: $(TMPDIR)/convert.db $(SCRIPTSDIR)/save-dron-tables.sql
	rm -rf $@
	mkdir -p $@
	cd $(TMPDIR)/convert/ && sqlite3 ../convert.db < ../../$(word 2,$^)
	# Create empty tables for comparison.
	echo "curie	ndc	clinical_drug" > $@/ndc_clinical_drug.tsv
	
# Compare DrOn templates to conversion results.
.PHONY: convert
convert: $(TMPDIR)/convert/
	diff -u $(TEMPLATEDIR)/ $<

# Convert DrOn tables to LDTab format.
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

# Export an LDTab table to a TSV file.
$(TMPDIR)/ldtab/%.tsv: $(TMPDI/ldtab.db | $(TMPDIR)/ldtab/
	ldtab export $< $@ --table $*
	mv $@ $@.tmp
	head -n1 $@.tmp > $@
	tail -n+2 $@.tmp | sort >> $@
	rm $@.tmp

# Compare LDTab tables to expected.
.PHONY: ldtab
ldtab: $(TMPDIR)/ldtab/dron_ingredient.tsv $(TMPDIR)/ldtab/dron_rxnorm.tsv $(TMPDIR)/ldtab/dron_ndc.tsv
	diff -u ../ldtab/ $(TMPDIR)/ldtab/

# Export an LDTab table to a file in Turtle format.
$(TMPDIR)/ldtab/%.ttl: $(TMPDIR)/ldtab.db | $(TMPDIR)/ldtab/
	ldtab export $< $@ --table $*

# Convert a Turtle file to an OWL file in RDFXML format.
$(TMPDIR)/ldtab/%.owl: $(TMPDIR)/ldtab/%.ttl
	robot convert -i $< -o $@

.PHONY: owl
owl: $(TMPDIR)/ldtab/dron_ingredient.owl $(TMPDIR)/ldtab/dron_rxnorm.owl $(TMPDIR)/ldtab/dron_ndc.owl
