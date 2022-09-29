
#' This function writes a \href{https://htcondor.readthedocs.io/en/latest/man-pages/condor_submit.html}{condor_submit} script to be executed on the Open Science Grid (OSG). 
#'
#' This function saves a copy of locally, uploads a copy to osg, and modifies permissions so that it can be executed remotely 
#' 
#' @param session ssh connection created by \link{osg_connect}.
#' @param unix_name Character string giving OSG unix login name.
#' @param login_node Character string giving OSG login node (e.g., login05.osgconnect.net).
#' @param rsa_keyfile Path to private key file. Must be in OpenSSH format (see details). Default is NULL. See \link[ssh]{ssh_connect} for more details.
#' @param rsa_passphrase Either a string or a callback function for password prompt. Default is NULL. See \link[ssh]{ssh_connect} for more details.
#' @param local_shell_path Path to directory where condor_submit script is written. Defaults to \link[base]{tempdir}.
#' @param remote_shell_path Path to directory on OSG login node where condor_submit script is written.
#' @param file_name Name given to the condor_submit script.
#' @param c_executable Name of executable or bash script to be executed by the condor_submit script.
#' @param c_input_files Character vector of input files to be passed to condor job.
#' @param c_output_files Character vector of output files to be returned from condor job.
#' @param c_project OSG project to submit this job under.
#' @param c_memory Requested RAM for condor job (e.g., 200MB or 2GB)
#' @param c_disk Requested disk storage for condor job (e.g., 200MB or 2GB)
#' @param c_target_dir_path Path on OSG login node with text file giving each directory to execute the condor job in.
#' @param c_singularity Character string specifiying the R version to use. Defaults to NULL.
#' \describe{
#'		\item{\emph{r:3.5.0}}{R version 3.5.0}
#'      \item{\emph{r:4.0.2}}{R version 4.0.2}
#' }
#' @param overwrite If the file given by \emph{file_name} exists in \emph{local_shell_path} or \emph{remote_shell_path} overwrite if TRUE.
#' @param verbose Boolean denoting if function details should be printed.
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

osg_condor_submit_create = function(session=NULL,
							unix_name,
							login_node,
							rsa_keyfile=NULL,
							rsa_passphrase=NULL,
							local_shell_path = NULL,
							remote_shell_path = "scripts/condor_submit/",
							file_name = "condor.sub",
							c_executable="scripts/bash/wrapper.sh",
							c_input_files=c("Start.tar.gz"),
							c_output_files=c("End.tar.gz"),
							c_project=NULL,
							c_memory="2GB",
							c_disk="2GB",
							c_target_dir_path=NULL,
							c_singularity=NULL,
							overwrite = TRUE,
							verbose = TRUE)
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
			if(is.null(c_singularity))
			{
				c_singularity = ""
			} else {
				valid_singularity = c('r:3.5.0','r:4.0.2')

				if(length(c_singularity[which(is.na(match(c_singularity,valid_singularity)))])>0)
				{
					stop(paste0("c_singularity not a valid choice. Redefine as one of the following: ",paste0(valid_singularity,collapse=", ")))
				} else {
					c_singularity = paste0('+SingularityImage = "/cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-',c_singularity,'"')
				}
			}
			if(is.null(c_project))
			{
				stop("OSG project must be defined.")
			}
			if(is.null(c_target_dir_path))
			{
				stop("target_dir_path must be defined.")
			} else {
				c_target_dir_path = gsub("\\","/",c_target_dir_path,fixed=TRUE)
			}

		# define submit script
		# should add 'max_idle = 2000' at some point			
			submit_vec = c("universe = vanilla",
						  	"",
						  	"# Define initial directory",
						  	"initial_dir = $(target_dir)",
							"# Define executable",
							paste0("executable = ",c_executable),
							"",
							"# Error logging",
							"log = job_$(Cluster)_$(Process).log",
							"error = job_$(Cluster)_$(Process).err",
							"output = job_$(Cluster)_$(Process).out",
							"",
							"# Define singularity",
							c_singularity,
							"",
							"# Define resources",
							"request_cpus = 1",
							paste0("request_memory = ",c_memory),
							paste0("request_disk = ",c_disk),
							"",
							"# Define project",
							paste0('+ProjectName = "',c_project,'"'),
							"",
							"# Define input files",
							"should_transfer_files = YES",
							paste0("transfer_input_files = ",paste0(c_input_files,collapse = ", ")),
							"",
							"# Define output files",
							"when_to_transfer_output = ON_EXIT_OR_EVICT",
							paste0("transfer_output_files = ",paste0(c_output_files,collapse = ", ")),
							"",
							"# Define queue",
							paste0("queue target_dir from ",c_target_dir_path))
							
		# check if shell script exists, if not then sink
			if(!file.exists(paste0(local_shell_path,file_name)))
			{
				writeLines(submit_vec,con=paste0(local_shell_path,file_name))
				local_action_time = Sys.time()
				local_action = c(paste0(file_name," did not exist at local location: "),
								local_shell_path,
								paste0(file_name," was written at local location at : "),
								as.character(local_action_time))
			} else if(file.exists(paste0(local_shell_path,file_name)) && overwrite) {
				writeLines(submit_vec,con=paste0(local_shell_path,file_name))
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
			print(paste0("condor_submit script created in ",time," minutes."))
	}
	return(0)	
}