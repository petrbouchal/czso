PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX dcterms: <http://purl.org/dc/terms/>
  PREFIX dcat: <http://www.w3.org/ns/dcat#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT DISTINCT ?title ?publisher WHERE {
  GRAPH ?g {
    ?d a dcat:Dataset
    ?d dcterms:publisher ?publisher .
    ?d dcterms:title ?title

    FILTER(lang(?poskytovatel) = "cs")
    VALUES ?publisher {
      <https://data.gov.cz/zdroj/ovm/00025593>
      <https://data.gov.cz/zdroj/ovm/70890366>
    }
  }

}
