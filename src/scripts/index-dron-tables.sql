-- Create the DrOn tables.

DROP INDEX IF EXISTS idx_ingredient_curie;
CREATE INDEX idx_ingredient_curie ON ingredient(curie);

DROP INDEX IF EXISTS idx_ingredient_rxcui;
CREATE INDEX idx_ingredient_rxcui ON ingredient(rxcui);

DROP INDEX IF EXISTS idx_clinical_drug_form_curie;
CREATE INDEX idx_clinical_drug_form_curie ON clinical_drug_form(curie);

DROP INDEX IF EXISTS idx_clinical_drug_form_rxcui;
CREATE INDEX idx_clinical_drug_form_rxcui ON clinical_drug_form(rxcui);

DROP INDEX IF EXISTS idx_clinical_drug_curie;
CREATE INDEX idx_clinical_drug_curie ON clinical_drug(curie);

DROP INDEX IF EXISTS idx_clinical_drug_rxcui;
CREATE INDEX idx_clinical_drug_rxcui ON clinical_drug(rxcui);

DROP INDEX IF EXISTS idx_branded_drug_curie;
CREATE INDEX idx_branded_drug_curie ON branded_drug(curie);

DROP INDEX IF EXISTS idx_branded_drug_rxcui;
CREATE INDEX idx_branded_drug_rxcui ON branded_drug(rxcui);
