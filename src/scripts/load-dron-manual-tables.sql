-- Load the DrOn tables that are manually created,
-- i.e. not converted from RxNorm.
-- These are all the tables for dispositions.

PRAGMA foreign_keys = ON;

.headers on
.mode tabs

.import --skip 1 ../templates/disposition.tsv disposition
.import --skip 1 ../templates/ingredient_disposition.tsv ingredient_disposition
.import --skip 1 ../templates/clinical_drug_form_disposition.tsv clinical_drug_form_disposition
