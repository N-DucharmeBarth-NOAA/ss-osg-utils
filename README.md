## ss-osg-utils: Stock Sythesis - OpenScienceGrid - utilities 

Utility functions for running [Stock Synthesis](https://github.com/nmfs-stock-synthesis/stock-synthesis) (SS) models on the [OpenScienceGrid](https://osg-htc.org/) [HTCondor](https://htcondor.org/) network.

### Base functionality development list
- [x] base code: osg_connect
- [x] base code: osg_multi-copy
- [x] base code: osg_upload_ss_dir
- [x] base code: osg_wrapper_create
- [x] base code: osg_condor_submit_create
- [ ] base code: osg_r_script_create
- [ ] base code: osg_execute
- [ ] base code: osg_clean (option to just remove logs)
- [ ] base code: osg_download (download end.tar.gz, optionally download logs, and optionally remove files from osg via osg_clean after downloading)
- [ ] osg_upload_ss_dir: create target directory text file
- [ ] osg_wrapper_create: option to suppress log files
- [ ] Documentation (roxygen2)
- [ ] Make package: description, license, git-hub actions, github-pages, NOAA template