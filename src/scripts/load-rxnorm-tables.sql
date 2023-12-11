-- Load RxNorm RRF tables into SQLite.

PRAGMA foreign_keys = ON;

.mode csv
.separator |

.import ../rxnorm/RXNCONSO.RRF RXNCONSO
.import ../rxnorm/RXNSAT.RRF RXNSAT
.import ../rxnorm/RXNREL.RRF RXNREL
