## ss-osg-utils: Stock Sythesis - OpenScienceGrid - utilities 

Utility functions for running [Stock Synthesis](https://github.com/nmfs-stock-synthesis/stock-synthesis) (SS) models on the [OpenScienceGrid](https://osg-htc.org/) [HTCondor](https://htcondor.org/) network.

### Warning

Package is in active development. Code base may change without warning prior to first stable release.

### Base functionality development list
- [x] base code: osg_connect
- [x] base code: osg_multi-copy
- [x] base code: osg_upload_ss_dir
- [x] base code: osg_wrapper_create
- [x] base code: osg_condor_submit_create
- [x] base code: osg_r_script_create
- [x] base code: osg_execute
- [x] base code: osg_monitor
- [x] base code: osg_clean (option to just remove logs)
- [x] base code: osg_download_ss_dir (download end.tar.gz, optionally download logs, and optionally remove files from osg via osg_clean after downloading)
- [x] osg_upload_ss_dir: create target directory text file
- [ ] add more flexibility to input/output args
- [ ] osg_wrapper_create: option to suppress log files
- [ ] osg_wrapper_create: add options for running diagnostics (ASPM, retrospectives, R0 profile, jitter) via R scripts
- [ ] osg_r_script_create: add options for user to pass their own R script
- [ ] Documentation (roxygen2)
- [ ] Make package: description, license, git-hub actions, github-pages, NOAA template
- [ ] Add vignettes: setting up OSG environment
- [ ] Add vignettes: launching/retrieving a job array
- [ ] Add vignettes: running diagnostics across a job array
- [ ] Add vignettes: model ensemble example (extracting quantities and combining with MVLN)
- [ ] Add vignettes: run with custom submit script, r script, and wrapper script