
#' This function writes an R script which can be executed within the wrapper.sh to set-up and run diagnostics using existing r4ss code. 
#'
#' This function saves a copy locally, uploads a copy to Open Science Grid (OSG), and modifies permissions so that it can be executed remotely 
#' 
#' @param session ssh connection created by \link[ssgrid]{osg_connect}.
#' @param unix_name Character string giving OSG unix login name.
#' @param login_node Character string giving OSG login node (e.g., login05.osgconnect.net).
#' @param rsa_keyfile Path to private key file. Must be in OpenSSH format (see details). Default is NULL. See \link[ssh]{ssh_connect} for more details.
#' @param rsa_passphrase Either a string or a callback function for password prompt. Default is NULL. See \link[ssh]{ssh_connect} for more details. 
#' @param local_shell_path Path to directory where condor_submit script is written. Defaults to \link[base]{tempdir}.
#' @param remote_shell_path Path to directory on OSG login node where condor_submit script is written.
#' @param diagnostic_type A character string specifying which diagnostic to run.
#' \describe{
#'		\item{\emph{"01_run_retro"}}{Conduct a retrospective analysis of length \emph{retro_n_years}.}
#'      \item{\emph{"02_run_R0profile"}}{Conduct a likelihood profile on R0 where the profile extends +/- \emph{r0_maxdiff} from the log(R0) maximum likelihood estimate at an interval specified by \emph{r0_step}.}
#' 		\item{\emph{"03_run_aspm"}}{Conduct age structured production (ASPM) and deterministic recruitment runs of the model. \emph{Warning: for the ASPM there are some hard coded settings that may not be appropriate for your model.}}
#' }
#' @param overwrite If the file given by \emph{file_name} exists in \emph{local_shell_path} or \emph{remote_shell_path} overwrite if TRUE.
#' @param verbose Boolean denoting if function details should be printed.
#' @param retro_n_years The number of years for the retrospective analysis.
#' @param r0_maxdiff The maximum distance from the log(R0) maximum likelihood estimate that the profile will extend.
#' @param r0_step The step size used in profiling (on a log scale).
#' @return Returns 0 on exit.
#' @export
#' @importFrom ssh ssh_exec_wait
#' @importFrom ssh ssh_exec_internal
#' @importFrom ssh ssh_disconnect
#' @importFrom ssh scp_upload
#' 

# Nicholas Ducharme-Barth
# August 22, 2022
# Copyright (C) 2022  Nicholas Ducharme-Barth
# You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.

osg_r_create = function(session=NULL,
							unix_name,
							login_node,
							rsa_keyfile=NULL,
							rsa_passphrase=NULL,
							local_shell_path = NULL,
							remote_shell_path = "scripts/r/",
							diagnostic_type = NULL,
							overwrite = TRUE,
							verbose = TRUE,
							retro_n_years = NULL,
							r0_maxdiff = NULL,
							r0_step = NULL)
{
	A = proc.time()
	# connect to osg
	if(is.null(session))
	{
		session = osg_connect(unix_name,login_node,rsa_keyfile,rsa_passphrase)
		osg_disconnect = TRUE
	} else {
		osg_disconnect = FALSE
	}
	
	# sink shell script locally
		# check if local_shell_path is defined, otherwise define local_shell_path as tempdir()
			if(is.null(local_shell_path))
			{
				local_shell_path = tempdir()
				clean_local = TRUE
			} else {
				clean_local = FALSE
			}

			# sanitize local_shell_path
				local_shell_path = gsub("\\","/",local_shell_path,fixed=TRUE)
				if(substr(local_shell_path, nchar(local_shell_path), nchar(local_shell_path))!="/")
				{
					local_shell_path = paste0(local_shell_path,"/")
				}
			# sanitize remote_shell_path
				remote_shell_path = gsub("\\","/",remote_shell_path,fixed=TRUE)
				if(substr(remote_shell_path, nchar(remote_shell_path), nchar(remote_shell_path))!="/")
				{
					remote_shell_path = paste0(remote_shell_path,"/")
				}

		# check if local_shell_path exists, otherwise create local_shell_path
			if(!dir.exists(local_shell_path))
			{
				dir.create(local_shell_path,recursive=TRUE)
			}

		# check submit script args
			if(is.null(diagnostic_type))
			{
				stop("Please specify which diagnostic_type you wish to create an R script for.")
			}

		# sanitize script arguments
			if(is.null(retro_n_years))
			{
				retro_n_years = 5
			}
			if(is.null(r0_step))
			{
				r0_step = 0.01
			}
			if(is.null(r0_maxdiff))
			{
				r0_maxdiff = 1
			}

		# define r script
			if(diagnostic_type == "01_run_retro")
			{
				file_name = paste0(diagnostic_type,".r")
				r_vec = c('dir_here = getwd()',
					      'print(dir_here)',
					      'library(r4ss)',
					      paste0('run_retro = retro(dir = dir_here,years=0:-',retro_n_years,',exe = "ss_linux")'))
			}
			if(diagnostic_type == "02_run_R0profile")
			{
				file_name = paste0(diagnostic_type,".r")
 				r_vec = c('dir_here = getwd()',
                               'print(dir_here)',
                               'library(r4ss)',
                               'dir_run_R0prof_up = paste0(dir_here,"/up/")',
                               'dir.create(dir_run_R0prof_up,recursive=TRUE,showWarnings=FALSE)',
                               'dir_run_R0prof_down = paste0(dir_here,"/down/")',
                               'dir.create(dir_run_R0prof_down,recursive=TRUE,showWarnings=FALSE)',
                               'tmp_starter = SS_readstarter(file = "starter.ss", verbose = FALSE)',
                               'orig_starter_ctlfile = tmp_starter$ctlfile',
							   'orig_starter_prior_like = tmp_starter$prior_like',
							   'orig_starter_init_values_src = tmp_starter$init_values_src',
							   'tmp_starter$ctlfile = "control_modified.ss"',
                               'tmp_starter$prior_like = 1',
                               'tmp_starter$init_values_src = 1',
                               'SS_writestarter(tmp_starter, dir = dir_here, file = "starter.ss", overwrite = TRUE, verbose = FALSE, warn = FALSE)',
                               'rm(list=c("tmp_starter"))',
                               'FileList=list.files()',
							   'FileList=setdiff(FileList,c("R-packages.tar.gz","Start.tar.gz"))',
                               'file.copy(paste0(dir_here,"/",FileList),dir_run_R0prof_up,overwrite=TRUE)',
                               'file.copy(paste0(dir_here,"/",FileList),dir_run_R0prof_down,overwrite=TRUE)',
                               'tmp_par = SS_readpar_3.30(parfile=paste0(dir_here,"/ss.par"), datsource=paste0(dir_here,"/data.dat"), ctlsource=paste0(dir_here,"/control.ss"), verbose = FALSE)',
                               'r0_original = tmp_par$SR_parms$ESTIM[1]',
                               paste0('r0_up_vec = seq(from=r0_original,to=r0_original+',r0_maxdiff,',by=',r0_step,')'),
                               paste0('r0_down_vec = seq(from=r0_original,to=r0_original-',r0_maxdiff,',by=-',r0_step,')'),
                               'rm(list=c("tmp_par"))',
                               'profile_up = profile(dir_run_R0prof_up,oldctlfile = "control.ss",newctlfile = "control_modified.ss",string = "SR_LN(R0)",profilevec = r0_up_vec,usepar = TRUE,globalpar = FALSE,parstring = "# SR_parm[1]:",saveoutput = FALSE,overwrite = TRUE,exe = "ss_linux",verbose = FALSE)',
                               'write.csv(profile_up,file="profile_up.csv")',
                               'profile_down = profile(dir_run_R0prof_down,oldctlfile = "control.ss",newctlfile = "control_modified.ss",string = "SR_LN(R0)",profilevec = r0_down_vec,usepar = TRUE,globalpar = FALSE,parstring = "# SR_parm[1]:",saveoutput = FALSE,overwrite = TRUE,exe = "ss_linux",verbose = FALSE)',
                               'write.csv(profile_down,file="profile_down.csv")',
                               'unlink(dir_run_R0prof_up, recursive=TRUE)',
                               'unlink(dir_run_R0prof_down, recursive=TRUE)',
							   'tmp_starter = SS_readstarter(file = "starter.ss", verbose = FALSE)',
							   'tmp_starter$ctlfile = orig_starter_ctlfile',
							   'tmp_starter$prior_like = orig_starter_prior_like',
							   'tmp_starter$init_values_src = orig_starter_init_values_src',
							   'SS_writestarter(tmp_starter, dir = dir_here, file = "starter.ss", overwrite = TRUE, verbose = FALSE, warn = FALSE)',
							   'rm(list=c("tmp_starter"))')
			}
			if(diagnostic_type == "03_run_aspm")
			{
				file_name = paste0(diagnostic_type,".r")
				r_vec = c('dir_here = getwd()',
								'print(dir_here)',
								'library(r4ss)',
								'FileList=list.files()',
								'FileList=setdiff(FileList,c("R-packages.tar.gz","Start.tar.gz"))',
								'dir_run_detrec = paste0(dir_here,"/det_rec/")',
								'dir.create(dir_run_detrec,recursive=TRUE,showWarnings=FALSE)',
								'file.copy(paste0(dir_here,"/",FileList),dir_run_detrec,overwrite=TRUE)',
								'tmp_ctl = SS_readctl(file=paste0(dir_run_detrec,"control.ss_new"),datlist = paste0(dir_run_detrec,"data.dat"))',
								'tmp_ctl$do_recdev = 0',
								'tmp_ctl$recdev_adv = 0',
								'SS_writectl(ctllist=tmp_ctl,outfile=paste0(dir_run_detrec,"control.ss"),overwrite = TRUE)',
								'rm(list=c("tmp_ctl"))',
								'run(dir = dir_run_detrec,exe = "ss_linux",verbose=FALSE,skipfinished=FALSE)', 
								'dir_run_aspm = paste0(dir_here,"/aspm/")',
								'dir.create(dir_run_aspm,recursive=TRUE,showWarnings=FALSE)',
								'file.copy(paste0(dir_here,"/",FileList),dir_run_aspm,overwrite=TRUE)',
								'# 1) change control to fix selex par',
								'      tmp_ctl = SS_readctl(file=paste0(dir_run_aspm,"control.ss_new"),use_datlist = TRUE,datlist = paste0(dir_run_aspm,"data.dat"))',
								'      tmp_ctl$size_selex_parms$PHASE = -abs(tmp_ctl$size_selex_parms$PHASE)',
								'      tmp_ctl$size_selex_parms$dev_link = 0',
								'      tmp_ctl$age_selex_parms$PHASE = -abs(tmp_ctl$age_selex_parms$PHASE)',
								'      tmp_ctl$age_selex_parms$dev_link = 0',
								'# 2) change control to turn-off length comp in likelihood',
								'      pointer = which(tmp_ctl$lambdas$like_comp == 4)',
								'      tmp_ctl$lambdas$value[pointer] = 0',
								'      rm(list=c("pointer"))',
								'# 3) change control to fix rec devs at 0',
								'      tmp_ctl$do_recdev = 0',
								'      tmp_ctl$recdev_adv = 0',
								'# 4) turn-off MG parms',
								'      tmp_ctl$MG_parms$PHASE = -abs(tmp_ctl$MG_parms$PHASE)',
								'SS_writectl(tmp_ctl,paste0(dir_run_aspm,"control.ss"), version = "3.30", overwrite = TRUE)',
								'rm(list="tmp_ctl")',
								'run(dir = dir_run_aspm,exe = "ss_linux",verbose=FALSE,skipfinished=FALSE)') 
			}
			
		# check if shell script exists, if not then sink
			if(!file.exists(paste0(local_shell_path,file_name)))
			{
				writeLines(r_vec,con=paste0(local_shell_path,file_name))
				local_action_time = Sys.time()
				local_action = c(paste0(file_name," did not exist at local location: "),
								local_shell_path,
								paste0(file_name," was written at local location at : "),
								as.character(local_action_time))
			} else if(file.exists(paste0(local_shell_path,file_name)) && overwrite) {
				writeLines(r_vec,con=paste0(local_shell_path,file_name))
				local_action_time = Sys.time()
				local_action = c(paste0(file_name," already exists at local location: "),
								local_shell_path,
								paste0("However, overwrite == TRUE so ",file_name," was overwritten at : "),
								as.character(local_action_time))
			} else {
				local_action = c(paste0(file_name," already exists at local location: "),
								local_shell_path,
								"No actions taken locally.")
			}

	# upload shell script to osg
		# check if remote_shell_path exists, otherwise create remote_shell_path
			dir_status = strsplit(rawToChar(ssh::ssh_exec_internal(session,paste0('[ -d "',remote_shell_path,'" ]&&echo "exists"||echo "not exists"'))$stdout),"\\n")[[1]]
			if(dir_status!="exists")
			{
				ssh::ssh_exec_wait(session,paste0("mkdir -p ",remote_shell_path))
			}
		# check if shell script exists remotely, if not then upload
			list_remote = ssh::ssh_exec_internal(session,paste0("ls -lh ",remote_shell_path))
			list_remote = strsplit(rawToChar(list_remote$stdout),"\\n")[[1]]
			remote_exist = grep(paste0("\\b",file_name,"\\b"),list_remote) 

			if(length(remote_exist)==0)
			{
		       	ssh::scp_upload(session,files=paste0(local_shell_path,file_name),to=paste0("/home/",unix_name,"/",remote_shell_path))
				remote_action_time = Sys.time()
				remote_action = c(paste0(file_name," did not exist at remote location: "),
								remote_shell_path,
								paste0(file_name," was written at remote location at : "),
								as.character(remote_action_time))
			} else if(length(remote_exist)!=0 && overwrite) {
		       	ssh::scp_upload(session,files=paste0(local_shell_path,file_name),to=paste0("/home/",unix_name,"/",remote_shell_path))
				remote_action_time = Sys.time()
				remote_action = c(paste0(file_name," already exists at remote location: "),
								remote_shell_path,
								paste0("However, overwrite == TRUE so ",file_name," was overwritten at : "),
								as.character(remote_action_time))
			} else {
				remote_action = c(paste0(file_name," already exists at remote location: "),
								remote_shell_path,
								"No actions taken remotely.")
			}

	# change line endings (dos2unix) and change permissions (chmod 777) 
			ssh::ssh_exec_wait(session,command=paste0('dos2unix ',paste0(remote_shell_path,file_name)))
			ssh::ssh_exec_wait(session,command=paste0('chmod 777 ',paste0(remote_shell_path,file_name)))

	# clean-up locally
		if(clean_local)
		{
			file.remove(paste0(local_shell_path,file_name))
		}

	# close session
	if(osg_disconnect)
	{
		ssh::ssh_disconnect(session)
	}

	B = proc.time()
	if(verbose)
	{
		# print actions
			print(local_action)
			print(remote_action)
			time = round((B-A)[3]/60,digits=2)
			print(paste0(file_name," script created in ",time," minutes."))
	}
	return(0)	
}