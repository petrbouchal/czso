## R CMD check results

0 errors | 0 warnings | 0 notes

No WARNINGs or consistently occurring NOTEs were issued by any of the systems I used to check tha package:
- r-hub
- win-builder devel and release
- local MacOS Intel

* 0.3.6 was a patch release resolving a test failure that occurred on CRAN due to the inaccessibility of a remote resource
* 0.3.7 additionally removes an unused dependency which caused a check NOTE
