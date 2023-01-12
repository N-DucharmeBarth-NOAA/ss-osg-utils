.onAttach <- function(libname, pkgname) {
  packageStartupMessage("###########################################################################################################")
  packageStartupMessage("Loading package ssgrid version ", packageVersion("ssgrid") )
  packageStartupMessage("Use of ssgrid implies adherence to the OSG Connect and OSPool acceptable use policy.")
  packageStartupMessage("OSG Connect may only be used for work relevant to research and/or education with an affiliated institution.")
  packageStartupMessage("Data with any  privacy concerns should not be computed in OSG.")
  packageStartupMessage("###########################################################################################################")
}