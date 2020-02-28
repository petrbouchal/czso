PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX dcat: <http://www.w3.org/ns/dcat#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT ?dataset_iri
?dataset_id
?title ?provider ?description
?spatial
?temporal
?modified
?page
?periodicity
?periodicity_abb
?start
?end
?keyword
WHERE {
  GRAPH ?g {
    ?dataset_iri a dcat:Dataset .
    ?dataset_iri dcterms:title ?title .
    ?dataset_iri dcterms:description ?description .
    ?dataset_iri dcterms:publisher ?publisher .
    OPTIONAL { ?dataset_iri dcterms:identifier ?dataset_id .}
    OPTIONAL { ?dataset_iri dcterms:spatial ?spatial .}
    OPTIONAL { ?dataset_iri foaf:page ?page.}
    OPTIONAL { ?dataset_iri dcterms:temporal ?temporal .}
    OPTIONAL { ?dataset_iri dcterms:modified ?modified .}
    OPTIONAL { ?dataset_iri dcat:keyword ?keyword .}
    OPTIONAL { ?dataset_iri dcterms:accrualPeriodicity ?periodicity .}
    OPTIONAL { ?dataset_iri <https://data.gov.cz/slovník/nkod/accrualPeriodicity> ?periodicity_abb .}

    ?publisher foaf:name ?provider .

    OPTIONAL { ?temporal schema:startDate ?start .}
    OPTIONAL { ?temporal schema:endDate ?end .}

    VALUES ?publisher {
      <https://data.gov.cz/zdroj/ovm/00025593> # IRI pro CZSO
      <https://data.gov.cz/zdroj/ovm/70890366> # IRI pro PlzKraj
    }

    FILTER(lang(?provider) = "cs")
    FILTER(lang(?keyword) = "cs")
    FILTER(lang(?title) = "cs")
  }
}
