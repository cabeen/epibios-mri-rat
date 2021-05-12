# EPIBIOS Classification Analysis

This directory provides code for running a classification analysis for the
EPIBIO rodent MRI project.  The script `run.sh` is an example of how to run
things, and the `results` directory contains the output.   This expects a
collection of data tables to be found in `../tables`, but you can update this
if you have the data elsewhere.

This is implemented in R using glmnet and a few other data-wrangling libraries.
The analysis performs classification of TBI vs PTE using elastic net regression
with leave-one-out-cross-validation (LOOCV).
