-- Convert the old DrOn tables with too many _ids
-- to the new DrOn tables using CURIEs.

-- PRAGMA foreign_keys = ON;
ATTACH DATABASE '../../dron.db' AS source;

INSERT OR IGNORE INTO rxcui
SELECT
    label AS rxcui,
    replaced_by
FROM source.rxcui;

INSERT OR IGNORE INTO disposition
SELECT
    REPLACE(REPLACE(uri, 'http://purl.obolibrary.org/obo/', ''), '_', ':') AS curie,
    label
FROM source.disposition;

INSERT OR IGNORE INTO ingredient
SELECT
    REPLACE(REPLACE(i.uri, 'http://purl.obolibrary.org/obo/', ''), '_', ':') AS curie,
    i.label,
    x.label AS rxcui
FROM source.ingredient AS i
LEFT JOIN source.rxcui AS x
  ON i.ingredient_rxcui_id = x.rxcui_id;

INSERT OR IGNORE INTO ingredient_disposition
SELECT
    REPLACE(REPLACE(i.uri, 'http://purl.obolibrary.org/obo/', ''), '_', ':') AS ingredient,
    REPLACE(REPLACE(d.uri, 'http://purl.obolibrary.org/obo/', ''), '_', ':') AS disposition
FROM source.ingredient_disposition AS id
LEFT JOIN source.ingredient AS i
  ON id.ingredient_id = i.ingredient_id
LEFT JOIN source.disposition AS d
  ON id.disposition_id = d.disposition_id;

INSERT OR IGNORE INTO clinical_drug_form
SELECT
    REPLACE(REPLACE(cdf.uri, 'http://purl.obolibrary.org/obo/', ''), '_', ':') AS curie,
    cdf.label,
    x.label AS rxcui
FROM source.clinical_drug_form AS cdf
LEFT JOIN source.rxcui AS x
  ON cdf.clinical_drug_form_rxcui_id = x.rxcui_id;

INSERT OR IGNORE INTO clinical_drug_form_ingredient
SELECT
    REPLACE(REPLACE(cdf.uri, 'http://purl.obolibrary.org/obo/', ''), '_', ':') AS clinical_drug_form,
    REPLACE(REPLACE(i.uri, 'http://purl.obolibrary.org/obo/', ''), '_', ':') AS ingredient
FROM source.clinical_drug_form_ingredient AS cdfi
LEFT JOIN source.clinical_drug_form AS cdf
  ON cdfi.clinical_drug_form_id = cdf.clinical_drug_form_id
LEFT JOIN source.ingredient AS i
  ON cdfi.ingredient_id = i.ingredient_id;

INSERT OR IGNORE INTO clinical_drug_form_disposition
SELECT
    REPLACE(REPLACE(cdf.uri, 'http://purl.obolibrary.org/obo/', ''), '_', ':') AS clinical_drug_form,
    REPLACE(REPLACE(i.uri, 'http://purl.obolibrary.org/obo/', ''), '_', ':') AS disposition
FROM source.clinical_drug_form_disposition AS cdfi
LEFT JOIN source.clinical_drug_form AS cdf
  ON cdfi.clinical_drug_form_id = cdf.clinical_drug_form_id
LEFT JOIN source.disposition AS i
  ON cdfi.disposition_id = i.disposition_id;

INSERT OR IGNORE INTO clinical_drug
SELECT
    REPLACE(REPLACE(cd.uri, 'http://purl.obolibrary.org/obo/', ''), '_', ':') AS curie,
    cd.label,
    REPLACE(REPLACE(cdf.uri, 'http://purl.obolibrary.org/obo/', ''), '_', ':') AS clinical_drug_form,
    x.label AS rxcui
FROM source.clinical_drug AS cd
LEFT JOIN source.clinical_drug_form AS cdf
  ON cd.clinical_drug_form_id = cdf.clinical_drug_form_id
LEFT JOIN source.rxcui AS x
  ON cd.clinical_drug_rxcui_id = x.rxcui_id;

INSERT OR IGNORE INTO clinical_drug_strength
SELECT
    REPLACE(REPLACE(cdf.uri, 'http://purl.obolibrary.org/obo/', ''), '_', ':') AS clinical_drug,
    REPLACE(REPLACE(i.uri, 'http://purl.obolibrary.org/obo/', ''), '_', ':') AS ingredient,
    strength
FROM source.clinical_drug_strength AS cds
LEFT JOIN source.clinical_drug AS cdf
  ON cds.clinical_drug_id = cdf.clinical_drug_id
LEFT JOIN source.clinical_drug_form_ingredient AS cdfi
  ON cds.clinical_drug_form_ingredient_id = cdfi.clinical_drug_form_ingredient_id
LEFT JOIN source.ingredient AS i
  ON cdfi.ingredient_id = i.ingredient_id;

INSERT OR IGNORE INTO branded_drug
SELECT
    REPLACE(REPLACE(bd.uri, 'http://purl.obolibrary.org/obo/', ''), '_', ':') AS curie,
    bd.label,
    REPLACE(REPLACE(cd.uri, 'http://purl.obolibrary.org/obo/', ''), '_', ':') AS clinical_drug,
    x.label AS rxcui
FROM source.branded_drug AS bd
LEFT JOIN source.clinical_drug AS cd
  ON bd.clinical_drug_id = cd.clinical_drug_id
LEFT JOIN source.rxcui AS x
  ON bd.rxcui_id = x.rxcui_id;

INSERT OR IGNORE INTO branded_drug_excipient
SELECT
    REPLACE(REPLACE(bd.uri, 'http://purl.obolibrary.org/obo/', ''), '_', ':') AS branded_drug,
    REPLACE(REPLACE(i.uri, 'http://purl.obolibrary.org/obo/', ''), '_', ':') AS ingredient
FROM source.branded_drug_excipient AS bde
LEFT JOIN source.branded_drug AS bd
  ON bde.branded_drug_id = bd.branded_drug_id
LEFT JOIN source.ingredient AS i
  ON bde.ingredient_id = i.ingredient_id;

INSERT OR IGNORE INTO ndc_branded_drug
SELECT
    REPLACE(REPLACE(n.uri, 'http://purl.obolibrary.org/obo/', ''), '_', ':') AS curie,
    n.label AS ndc,
    REPLACE(REPLACE(bd.uri, 'http://purl.obolibrary.org/obo/', ''), '_', ':') AS branded_drug
FROM source.branded_drug_ndc AS bdn
LEFT JOIN source.branded_drug AS bd
  ON bdn.branded_drug_id = bd.branded_drug_id
LEFT JOIN source.ndc AS n
  ON bdn.ndc_id = n.ndc_id;

INSERT OR IGNORE INTO ndc_clinical_drug
SELECT
    REPLACE(REPLACE(n.uri, 'http://purl.obolibrary.org/obo/', ''), '_', ':') AS curie,
    n.label AS ndc,
    REPLACE(REPLACE(cd.uri, 'http://purl.obolibrary.org/obo/', ''), '_', ':') AS clinical_drug
FROM source.clinical_drug_ndc AS cdn
LEFT JOIN source.clinical_drug AS cd
  ON cdn.clinical_drug_id = cd.clinical_drug_id
LEFT JOIN source.ndc AS n
  ON cdn.ndc_id = n.ndc_id;
