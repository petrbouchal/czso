PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX dcat: <http://www.w3.org/ns/dcat#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT ?polozka ?label
WHERE {
  GRAPH ?g {

    ?polozka skos:inScheme <http://publications.europa.eu/resource/authority/frequency> .
    ?polozka skos:prefLabel ?label
    FILTER(lang(?label) = "cs")

  }
}
