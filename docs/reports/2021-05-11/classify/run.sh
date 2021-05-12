#! /bin/bash
#
# This is an example of how to run the script.  This assumes you have all of the
# necessary R packages installed already.  It also assumes you have the output
# table directory stored in `../tables`.

cd $(dirname $0)
Rscript run.R ../tables

