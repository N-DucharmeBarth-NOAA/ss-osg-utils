
<!-- README.md is generated from README.Rmd. Please edit that file -->

<!-- badges: start -->

[![R-CMD-check](https://github.com/N-DucharmeBarth-NOAA/ssgrid/workflows/R-CMD-check/badge.svg)](https://github.com/N-DucharmeBarth-NOAA/ssgrid/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

<!-- <br> -->

## ssgrid: Stock Sythesis - OpenScienceGrid - utilities

> ***Warning:*** Package is in active development. Code base may change
> without warning prior to first stable release.

Utility functions for running [Stock
Synthesis](https://github.com/nmfs-stock-synthesis/stock-synthesis) (SS)
models on the [OpenScienceGrid](https://osg-htc.org/) (OSG)
[HTCondor](https://htcondor.org/) network.

This package facilitates running Stock Synthesis models and the
following advanced diagnostics on the OSG:

  - retrospective
  - R0 likelihood profile
  - age-structured production model (ASPM)
  - deterministic recruitment model

The *ssgrid* contains functions for:

  - connecting to the OSG
  - uploading files to OSG
  - writing files to automatically set-up the execution of the HTcondor
    job
      - creating the HTcondor *condor\_submit* script
      - creating the bash shell script executed by the *condor\_submit*
        script
      - creating R scripts needed to manipulate SS files using
        [r4ss](https://github.com/r4ss/r4ss) functions in order to run
        advanced diagnostics.
  - submiting the HTcondor job
  - downloading completed model runs
  - cleaning up directories on OSG

## Installation

*ssgrid* is not currently supported on CRAN. You can install the
development version of *ssgrid* from
[GitHub](https://github.com/N-DucharmeBarth-NOAA/ssgrid) with:

``` r
# install.packages("remotes")
remotes::install_github("N-DucharmeBarth-NOAA/ssgrid")
```

## Help & Documentation

Please see the *ssgrid*
[webpage](https://n-ducharmebarth-noaa.github.io/ssgrid/) for more
information, along with the following articles to get you started:

  - [1. Setting up your OSG environment to work with
    *ssgrid*](https://n-ducharmebarth-noaa.github.io/ssgrid/articles/01_setup_osg.html)
  - [2. Set-up a job array to run on
    OSG.](https://n-ducharmebarth-noaa.github.io/ssgrid/articles/02_model_ensemble.html)
    This article also shows how to combine models in an ensemble using
    the [*ss3diags*](https://github.com/PIFSCstockassessments/ss3diags)
    package.
  - [3. Run diagnostics for a Stock Synthesis model using
    OSG](https://n-ducharmebarth-noaa.github.io/ssgrid/articles/03_run_diags.html)

### Base functionality development list

  - [x] base code: `osg_connect()`
  - [x] base code: `osg_multi_copy()`
  - [x] base code: `osg_upload_ss_dir()`
  - [x] base code: `osg_wrapper_create()`
  - [x] base code: `osg_condor_submit_create()`
  - [x] base code: `osg_r_script_create()`
  - [x] base code: `osg_execute()`
  - [x] base code: `osg_monitor()`
  - [x] base code: `osg_clean()` (option to just remove logs)
  - [x] base code: `osg_download_ss_dir()` (download end.tar.gz,
    optionally download logs, and optionally remove files from osg via
    osg\_clean after downloading)
  - [x] `osg_upload_ss_dir()`: create target directory text file
  - [ ] add more flexibility to input/output args
  - [ ] `osg_wrapper_create()`: option to suppress log files
  - [ ] `osg_wrapper_create()`: add options for running diagnostics
    (ASPM, retrospectives, R0 profile, jitter) via R scripts
  - [ ] `osg_r_script_create()`: add options for user to pass their own
    R script
  - [x] Documentation (roxygen2)
  - [x] Make package: description, license, git-hub actions,
    github-pages, NOAA template
  - [x] Add vignettes: setting up OSG environment
  - [x] Add vignettes: launching/retrieving a job array
  - [x] Add vignettes: running diagnostics across a job array
  - [x] Add vignettes: model ensemble example (extracting quantities and
    combining with MVLN)
  - [ ] Add vignettes: run with custom submit script, r script, and
    wrapper script

<!-- Do not edit below. This adds the Disclaimer and NMFS footer. -->

-----

## Disclaimer

The United States Department of Commerce (DOC) GitHub project code is
provided on an ‘as is’ basis and the user assumes responsibility for its
use. DOC has relinquished control of the information and no longer has
responsibility to protect the integrity, confidentiality, or
availability of the information. Any claims against the Department of
Commerce stemming from the use of its GitHub project will be governed by
all applicable Federal law. Any reference to specific commercial
products, processes, or services by service mark, trademark,
manufacturer, or otherwise, does not constitute or imply their
endorsement, recommendation or favoring by the Department of Commerce.
The Department of Commerce seal and logo, or the seal and logo of a DOC
bureau, shall not be used in any manner to imply endorsement of any
commercial product or activity by DOC or the United States Government.”

-----

<img src="https://raw.githubusercontent.com/nmfs-general-modeling-tools/nmfspalette/main/man/figures/noaa-fisheries-rgb-2line-horizontal-small.png" width="200" style="height: 75px !important;"  alt="NOAA Fisheries">

[U.S. Department of Commerce](https://www.commerce.gov/) | [National
Oceanographic and Atmospheric Administration](https://www.noaa.gov) |
[NOAA Fisheries](https://www.fisheries.noaa.gov/)
