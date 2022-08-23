
#' This function writes an R script which can be executed within the wrapper.sh to set-up and run diagnostics using existing r4ss code. 
#'
#' This function saves a copy locally, uploads a copy to osg, and modifies permissions so that it can be executed remotely 
#' 
#' @param session
#' @param unix_name
#' @param login_node
#' @param rsa_keyfile
#' @param rsa_passphrase 
#' @param local_shell_path
#' @param remote_shell_path
#' @param diagnostic_type
#' @param overwrite
#' @param verbose
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
			if(is.null(diagnostic_type))
			{
				stop("Please specify which diagnostic_type you wish to create an R script for.")
			} 
		# define r script
			@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
			if(diagnostic_type == "01_run_retro")
			{
				file_name = paste0(diagnostic_type,".r")
				r_vec
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
			} else if(file.exists(paste0(local_shell_path,file_name)) & overwrite) {
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
			} else if(length(remote_exist)!=0 & overwrite) {
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