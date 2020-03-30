Pro CZSO

Poptávka do open dat
- národní účty: ideální by bylo zveřejňovat přesné zrcadlo databáze národních účtů; teď je v open datech jen výběr; alternativou by bylo odhalit a zdokumentovat existující kvazi-API databáze národních a regionálních účtů
  - aktuální počty obyvatel MČ - 2019 visí na https://www.czso.cz/csu/xa/pohyb-obyvatelstva-v-hl-m-praze-v-1-pololeti-2019 ale ve VDB jsou starší; obecně je v nich trochu nepořádek, protože někdy jsou ke konci období, někdy k začátku následujícího; jednou "střední stav, 1.7.", podruhé 2Q, 30. 6.
  - časové řady trhu práce - tady jsem si
  - u národních a regionálních účtů není jasné, o jakou metodu jde (dokumentace datové sady používá trochu jiné názvosloví než databáze národních účtů; databáze regionálních účtů je v tomto bohužel dost nejasná - tady by se hodilo napřímo napsat jak u open dat tak u databáze RÚ, že jde o výrobní metodu a alokace do krajů se děje pracovištní metodou - tyto dva parametry mi trvalo hodně dlouho najít a přinejmenším ten druhý se objeví v téměř každé diskusi o spolehlivosti odhadů regionálního HDP.)
- jemnější detail platů a mezd (průměr a decily podle krajů, pohlaví a stupně vzdělání)
- oprava tohoto https://www.czso.cz/csu/czso/prumerna-hruba-mesicni-mzda-a-median-mezd-v-krajich

Obecně
- chybí reálné mzdy
- obecněji: v textových výstupech (analýzy, rychlé informace) často jsou čísla, která pak nejde najít v přiložených datech (někdy mediány, někdy necily, někdy reálné hodnoty tj. upravené o inflaci)
- mzdy ve VDB - obecně průšvih
- chybí mediánové mzdy podle krajů - například v https://www.czso.cz/csu/czso/cri/prumerne-mzdy-2-ctvrtleti-2019#_ftn1 je medián zmíněn, ale není v datech. Plus jsou tam odkazy na "strukturální výdělkové statistiky", což je nešikovný název. (Ad medián vím, že je v open datech i ve výstupech ze struktury mezd https://www.czso.cz/csu/czso/struktura-mezd-zamestnancu-2018 - ale i tam příliš hrubě)

Ke kvaziAPI OD CZSO
- robots.txt
- vysvětlit jak to dělám
- dá se nějak dostat na webku datasetu např. https://www.czso.cz/csu/czso/prumerna-hruba-mesicni-mzda-a-median-mezd-v-krajich je OK, ale https://www.czso.cz/csu/czso/konjunkturalni-pruzkumy-070013-17 je něco jiného než https://www.czso.cz/csu/czso/konjunkturalni-pruzkumy a podlední dvojčíslí na konci URL nejde dovodit 
