ATTACH DATABASE 'tmp/convert.db' AS dron;

-- ### Ingredients

-- Assert rdf:type is owl:Class
-- for all ingredient and disposition rows.
INSERT INTO dron_ingredient(subject, predicate, object)
SELECT
    curie AS subject,
    'rdf:type' AS predicate,
    'owl:Class' AS object
FROM (
    SELECT curie FROM dron.ingredient
    UNION
    SELECT curie FROM dron.disposition
);

-- Assert rdfs:label annotation
-- for all ingredient and disposition rows.
INSERT INTO dron_ingredient(subject, predicate, object, datatype)
SELECT
    curie AS subject,
    'rdfs:label' AS predicate,
    label AS object,
    'xsd:string' AS datatype
FROM (
    SELECT curie, label FROM dron.ingredient
    UNION
    SELECT curie, label FROM dron.disposition
);

-- Assert DRON:00010000 'has_RxCUI' annotation.
-- for all ingredient rows.
INSERT INTO dron_ingredient(subject, predicate, object, datatype)
SELECT
    curie AS subject,
    'DRON:00010000' AS predicate,
    rxcui AS object,
    'xsd:string' AS datatype
FROM dron.ingredient;

-- Assert rdfs:subClassOf BFO:0000016 'disposition'
-- for all disposition rows.
INSERT INTO dron_ingredient(subject, predicate, object)
SELECT
    curie AS subject,
    'rdfs:subClassOf' AS predicate,
    'BFO:0000016' AS object
FROM dron.disposition;

-- Assert rdfs:subClassOf OBI:0000047 'processed material'
-- for all ingredient rows with DRON IDs.
INSERT INTO dron_ingredient(subject, predicate, object)
SELECT
    curie AS subject,
    'rdfs:subClassOf' AS predicate,
    'OBI:0000047' AS object
FROM dron.ingredient
WHERE curie LIKE 'DRON:%';

-- Assert rdfs:subClassOf "'has disposition' some DISPOSITION"
-- for all ingredient_disposition rows.
INSERT INTO dron_ingredient(subject, predicate, object, datatype)
SELECT
    ingredient AS subject,
    'rdfs:subClassOf' AS predicate,
    REPLACE(
        '{"owl:onProperty":[{"datatype":"_IRI","object":"BFO:0000053"}],"owl:someValuesFrom":[{"datatype":"_IRI","object":"DISPOSITION"}],"rdf:type":[{"datatype":"_IRI","object":"owl:Restriction"}]}',
        'DISPOSITION',
        disposition
    ) AS object,
    '_JSON' AS datatype
FROM dron.ingredient_disposition;

-- ### RxNorm Drugs

-- Assert rdf:type is owl:Class
-- for all clinical drug form, clinical drug, and branded drug
-- and dispositions in clinical_dru_form_disposition rows.
INSERT INTO dron_rxnorm(subject, predicate, object)
SELECT
    curie AS subject,
    'rdf:type' AS predicate,
    'owl:Class' AS object
FROM (
    SELECT curie FROM dron.clinical_drug_form
    UNION
    SELECT curie FROM dron.clinical_drug
    UNION
    SELECT curie FROM dron.branded_drug
    UNION
    SELECT disposition AS curie FROM dron.clinical_drug_form_disposition
);

-- Assert rdfs:label annotation
-- for all clinical drug form, clinical drug, and branded drug
-- and dispositions in clinical_dru_form_disposition rows.
INSERT INTO dron_rxnorm(subject, predicate, object, datatype)
SELECT
    curie AS subject,
    'rdfs:label' AS predicate,
    label AS object,
    'xsd:string' AS datatype
FROM (
    SELECT curie, label FROM dron.clinical_drug_form
    UNION
    SELECT curie, label FROM dron.clinical_drug
    UNION
    SELECT curie, label FROM dron.branded_drug
    UNION
    SELECT d.curie, d.label
    FROM dron.clinical_drug_form_disposition AS cdfd
    LEFT JOIN dron.disposition AS d
    WHERE cdfd.disposition = d.curie
);

-- Assert DRON:00010000 'has_RxCUI' annotation.
-- for all clinical drug form, clinical drug, and branded drug rows.
INSERT INTO dron_rxnorm(subject, predicate, object, datatype)
SELECT
    curie AS subject,
    'DRON:00010000' AS predicate,
    rxcui AS object,
    'xsd:string' AS datatype
FROM (
    SELECT curie, rxcui FROM dron.clinical_drug_form
    UNION
    SELECT curie, rxcui FROM dron.clinical_drug
    UNION
    SELECT curie, rxcui FROM dron.branded_drug
);

-- TODO: parents for clinical drug forms

-- Assert rdfs:subClassOf parent drug class
-- for all clinical drug and branded drug rows
INSERT INTO dron_rxnorm(subject, predicate, object)
SELECT
    curie AS subject,
    'rdfs:subClassOf' AS predicate,
    parent AS object
FROM (
    SELECT curie, clinical_drug_form AS parent FROM dron.clinical_drug
    UNION
    SELECT curie, clinical_drug AS parent FROM dron.branded_drug
);

-- Assert rdfs:subClassOf DRON:00000032 'drug product therapeutic function'
-- for all dispositions in clinical_drug_form_disposition rows.
INSERT INTO dron_rxnorm(subject, predicate, object)
SELECT
    disposition AS subject,
    'rdfs:subClassOf' AS predicate,
    'DRON:00000032' AS object
FROM dron.clinical_drug_form_disposition;

-- Assert rdfs:subClassOf "'has disposition' some DISPOSITION"
-- for all clinical_drug_form_disposition rows.
INSERT INTO dron_rxnorm(subject, predicate, object, datatype)
SELECT
    clinical_drug_form AS subject,
    'rdfs:subClassOf' AS predicate,
    REPLACE(
        '{"owl:onProperty":[{"datatype":"_IRI","object":"BFO:0000053"}],"owl:someValuesFrom":[{"datatype":"_IRI","object":"DISPOSITION"}],"rdf:type":[{"datatype":"_IRI","object":"owl:Restriction"}]}',
        'DISPOSITION',
        disposition
    ) AS object,
    '_JSON' AS datatype
FROM dron.clinical_drug_form_disposition;

-- ### NDCs

-- Assert rdf:type is owl:Class
-- for all NDCs: branded drug and clinical drug.
INSERT INTO dron_ndc(subject, predicate, object)
SELECT
    curie AS subject,
    'rdf:type' AS predicate,
    'owl:Class' AS object
FROM (
    SELECT curie FROM dron.ndc_branded_drug
    UNION
    SELECT curie FROM dron.ndc_clinical_drug
);

-- Assert rdfs:label annotation
-- for all NDCs: branded drug and clinical drug.
INSERT INTO dron_ndc(subject, predicate, object, datatype)
SELECT
    curie AS subject,
    'rdfs:label' AS predicate,
    ndc AS object,
    'xsd:string' AS datatype
FROM (
    SELECT curie, ndc FROM dron.ndc_branded_drug
    UNION
    SELECT curie, ndc FROM dron.ndc_clinical_drug
);

-- Assert rdfs:subClassOf DRON:00000027 'packaged drug product'
-- for all NDCs: branded drug and clinical drug.
INSERT INTO dron_ndc(subject, predicate, object)
SELECT
    curie AS subject,
    'rdfs:subClassOf' AS predicate,
    'DRON:00000027' AS object
FROM (
    SELECT curie FROM dron.ndc_branded_drug
    UNION
    SELECT curie FROM dron.ndc_clinical_drug
);

-- Assert rdfs:subClassOf "'has proper part' some DRUG"
-- for all NDCs: branded drug and clinical drug.
INSERT INTO dron_ndc(subject, predicate, object, datatype)
SELECT
    curie AS subject,
    'rdfs:subClassOf' AS predicate,
    REPLACE(
        '{"owl:onProperty":[{"datatype":"_IRI","object":"<http://www.obofoundry.org/ro/ro.owl#has_proper_part>"}],"owl:someValuesFrom":[{"datatype":"_IRI","object":"DRUG"}],"rdf:type":[{"datatype":"_IRI","object":"owl:Restriction"}]}',
        'DRUG',
        drug
    ) AS object,
    '_JSON' AS datatype
FROM (
    SELECT curie, branded_drug AS drug FROM dron.ndc_branded_drug
    UNION
    SELECT curie, clinical_drug AS drug FROM dron.ndc_clinical_drug
);
