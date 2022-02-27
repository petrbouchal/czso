## R CMD check results

0 errors | 0 warnings | 0 notes

No WARNINGs or consistently occurring NOTEs were issued by any of the systems I used to check tha package:
- r-hub
- win-builder devel and release
- local MacOS (M1) Monterey 12.2 and 12.3 beta

* 0.3.8 handles an unfortunate issue where R on early MacOS Monterey systems cannot access the server of the data provider whose data sources this package wraps (the Czech Statistical Office). This is a system-level bug which also affects `curl` in the command line when trying to reach this server. See https://stat.ethz.ch/pipermail/r-sig-mac/2022-January/014299.html and ensuing discussion. On the relevant systems, the relevant functions fail with an informative error, instructing the user on how to bypass the issue via setting an environment variable. This should not cause any failures on CRAN systems and was checked as above, plus manually on the relevant MacOS versions to check that the workaround works and the error message is returned as appropriate.
