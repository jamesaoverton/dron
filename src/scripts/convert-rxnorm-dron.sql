-- Convert RxNorm tables to DrOn tables.

-- .echo on

PRAGMA foreign_keys = ON;
ATTACH 'tmp/chebi.db' AS chebi;
ATTACH 'tmp/rxnorm.db' AS rxnorm;

-- Add RXCUIs that we plan to use.
INSERT OR IGNORE INTO rxcui
SELECT
  RXCUI AS rxcui,
  NULL AS replaced_by
FROM rxnorm.RXNCONSO
WHERE SAB = 'RXNORM'
  AND TTY IN ('IN', 'SCDF', 'SCD', 'SBD');

-- Add ingredients not already in that table
-- if they match a ChEBI label.
INSERT OR IGNORE INTO ingredient
SELECT DISTINCT
    cl.curie AS curie,
    c.STR AS label,
    c.RXCUI AS rxcui
FROM rxnorm.RXNCONSO AS c
LEFT JOIN ingredient AS i
  ON c.RXCUI = i.rxcui
LEFT JOIN chebi.label AS cl
WHERE c.SAB = 'RXNORM'
  AND c.TTY = 'IN'
  AND i.curie IS NULL
  AND LOWER(c.STR) = cl.lower;

-- Add ingredients not already in that table.
INSERT OR IGNORE INTO ingredient
SELECT DISTINCT
    NULL AS curie,
    c.STR AS label,
    c.RXCUI AS rxcui
FROM rxnorm.RXNCONSO AS c
LEFT JOIN ingredient AS i
  ON c.RXCUI = i.rxcui
WHERE c.SAB = 'RXNORM'
  AND c.TTY = 'IN'
  AND i.curie IS NULL;

-- Add clinical drug forms not already in that table.
INSERT OR IGNORE INTO clinical_drug_form
SELECT DISTINCT
    NULL AS curie,
    c.STR AS label,
    c.RXCUI AS rxcui
FROM rxnorm.RXNCONSO AS c
LEFT JOIN clinical_drug_form AS cdf
  ON c.RXCUI = cdf.rxcui
WHERE c.SAB = 'RXNORM'
  AND c.TTY = 'SCDF'
  AND cdf.curie IS NULL;

-- Add clinical drugs not already in the 'dron' table.
-- We join the RXNREL table
-- where the relation is 'isa'
-- the RXCUI1 is the clinical drug form
-- and the RXCUI2 is the clinical drug.
INSERT OR IGNORE INTO clinical_drug
SELECT DISTINCT
    NULL AS curie,
    c.STR AS label,
    cdf.curie AS clinical_drug_form,
    c.RXCUI AS rxcui
FROM rxnorm.RXNCONSO AS c
LEFT JOIN rxnorm.RXNREL AS r
  ON c.RXCUI = r.RXCUI2
LEFT JOIN clinical_drug_form AS cdf
  ON r.RXCUI1 = cdf.rxcui
LEFT JOIN clinical_drug AS cd
  ON r.RXCUI2 = cd.rxcui
WHERE c.SAB = 'RXNORM'
  AND c.TTY = 'SCD'
  AND r.RELA = 'isa'
  AND cd.curie IS NULL;

-- Add branded drugs not already in that table.
-- We join the RXNREL table
-- where the relation is 'tradename_of'
-- the RXCUI1 is the clinical drug
-- and the RXCUI2 is the branded drug.
INSERT OR IGNORE INTO branded_drug
SELECT DISTINCT
    NULL AS curie,
    c.STR AS label,
    cd.curie AS clinical_drug,
    c.RXCUI AS rxcui
FROM rxnorm.RXNCONSO AS c
LEFT JOIN rxnorm.RXNREL AS r
  ON c.RXCUI = r.RXCUI2
LEFT JOIN clinical_drug AS cd
  ON r.RXCUI1 = cd.rxcui
LEFT JOIN branded_drug AS bd
  ON r.RXCUI2 = bd.rxcui
WHERE c.SAB = 'RXNORM'
  AND c.TTY = 'SBD'
  AND r.RELA = 'tradename_of'
  AND bd.curie IS NULL;

-- Add NDCs for branded drugs not already in that table.
INSERT OR IGNORE INTO ndc_branded_drug
SELECT DISTINCT
    NULL AS curie,
    s.ATV AS ndc,
    bd.curie AS drug
FROM rxnorm.RXNSAT AS s
LEFT JOIN branded_drug AS bd
LEFT JOIN ndc_branded_drug AS n
  ON s.ATV = n.ndc
WHERE s.RXCUI = bd.rxcui
  AND s.SAB = 'RXNORM'
  AND s.ATN = 'NDC'
  AND n.curie IS NULL;

-- Add NDCs for clinical drugs not already in that table.
INSERT OR IGNORE INTO ndc_clinical_drug
SELECT DISTINCT
    NULL AS curie,
    s.ATV AS ndc,
    cd.curie AS drug
FROM rxnorm.RXNSAT AS s
LEFT JOIN clinical_drug AS cd
LEFT JOIN ndc_clinical_drug AS n
  ON s.ATV = n.ndc
WHERE s.RXCUI = cd.rxcui
  AND s.SAB = 'RXNORM'
  AND s.ATN = 'NDC'
  AND n.curie IS NULL;

-- Link clinical drug forms to their ingredients.
-- We join the RXNREL table
-- where the relation is 'has_ingredient'
-- the RXCUI1 is the ingredient
-- and the RXCUI2 is the clinical drug form.
INSERT OR IGNORE INTO clinical_drug_form_ingredient
SELECT DISTINCT
    cdf.curie AS clinical_drug_form,
    i.curie AS ingredient
FROM clinical_drug_form AS cdf
LEFT JOIN ingredient AS i
LEFT JOIN rxnorm.RXNREL AS r
WHERE r.RELA = 'has_ingredient'
  AND i.rxcui = r.RXCUI1
  AND cdf.rxcui = r.RXCUI2;

-- Link clinical drugs to their ingredients and strengths.
-- Foreach clinical_drug, find its SCDC consituents.
-- Foreach constituent,
-- get its has_ingrediant relation,
-- and its RXN_STRENGTH attribute.
INSERT OR IGNORE INTO clinical_drug_strength
SELECT DISTINCT
  cd.curie AS clinical_drug,
  i.curie AS ingredient,
  s.ATV AS strength
FROM clinical_drug AS cd
LEFT JOIN ingredient AS i
LEFT JOIN rxnorm.RXNCONSO AS c
LEFT JOIN rxnorm.RXNREL AS r1
LEFT JOIN rxnorm.RXNREL AS r2
LEFT JOIN rxnorm.RXNSAT AS s
WHERE r1.RXCUI1 = cd.rxcui
  AND r1.RELA = 'constitutes'
  AND c.RXCUI = r1.RXCUI2
  AND c.SAB = 'RXNORM'
  AND c.TTY = 'SCDC'
  AND r2.RXCUI2 = c.RXCUI
  AND r2.RELA = 'has_ingredient'
  AND i.rxcui = r2.RXCUI1
  AND s.RXCUI = c.RXCUI
  AND s.SAB = 'RXNORM'
  AND s.ATN = 'RXN_STRENGTH';

-- Link branded drugs to their excipients.
-- Foreach 'has_inactive_ingredient' relation,
-- follow the RXAUI1 atom to an RXCUI for an ingredient
-- and the RXAUI2 atom to an RXCUI for a branded_drug.
INSERT OR IGNORE INTO branded_drug_excipient
SELECT DISTINCT
    bd.curie AS branded_drug,
    i.curie AS ingredient
FROM rxnorm.RXNREL AS r
LEFT JOIN branded_drug AS bd
LEFT JOIN ingredient AS i
LEFT JOIN rxnorm.RXNCONSO AS c1
LEFT JOIN rxnorm.RXNCONSO AS c2
WHERE r.RELA = 'has_inactive_ingredient'
  AND c1.RXAUI = r.RXAUI1
  AND c1.RXCUI = i.rxcui
  AND c2.RXAUI = r.RXAUI2
  AND c2.RXCUI = bd.rxcui;
