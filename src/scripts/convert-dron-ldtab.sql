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

-- Assert rdfs:subClassOf BFO:0000016 'diposition'
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
