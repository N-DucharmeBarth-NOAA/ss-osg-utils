
#' This function writes a bash shell wrapper script to be executed within each specified directory 
#'
#' This function saves a copy of locally, uploads a copy to osg, and modifies permissions so that it can be executed remotely 
#' 
#' @param session
#' @param unix_name
#' @param login_node
#' @param rsa_keyfile
#' @param rsa_passphrase 
#' @param local_shell_path
#' @param remote_shell_path
#' @param file_name
#' @param wrapper_actions
#' @param overwrite
#' @param verbose
#' @export
#' @importFrom ssh ssh_exec_wait
#' @importFrom ssh ssh_exec_internal
#' @importFrom ssh ssh_disconnect
#' 

# Nicholas Ducharme-Barth
# August 22, 2022
# Copyright (C) 2022  Nicholas Ducharme-Barth
# You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.

osg_wrapper_create = function(session=NULL,
							unix_name,
							login_node,
							rsa_keyfile=NULL,
							rsa_passphrase=NULL,
							local_shell_path = NULL,
							remote_shell_path = "scripts/bash/",
							file_name = "wrapper.sh",
							wrapper_actions = NULL,
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
		# define shell script
			script_vec = c('#!/bin/bash',
							'',
							'pwd',
							'ls -l',
							'echo $PATH',
							'mkdir -p working/',
							'',
							'# Move files',
							'mv Start.tar.gz working/',
							'',
							'if [ -f "R-packages.tar.gz" ]',
							'then',
							'  mv R-packages.tar.gz working/',
							'  # set TMPDIR variable',
							'  mkdir rtmp',
							'  export TMPDIR=$_CONDOR_SCRATCH_DIR/rtmp',
							'fi',
							'',
							'rcount=`ls -1 *.r 2>/dev/null | wc -l`',
							'if [ $rcount != 0 ]',
							'then',
							'  mv *.r working/',
							'fi',
							'',
							'# if ss executable exists, set permissions',
							'if [ -f "ss_linux" ]',
							'then',
							'  mv ss_linux working/',
							'  chmod 777 working/ss_linux',
							'fi',
							'',
							'cd working/',
							'',	
							'# Upack everything from initial tar file',
							'tar -xzf Start.tar.gz',
							'',
							'# Upack everything from the R-packages.tar.gz file if it exists',
							'if [ -f "R-packages.tar.gz" ]',
							'then',
							'  tar -xzf R-packages.tar.gz',
							'  export R_LIBS="$PWD/R-packages"',
							'fi',
							'',
							'start=`date +%s`',
							'end=`date +%s`',
							'runtime=$((end-start))',
							'echo $runtime',
							'',
							'if [ -f "runtime.txt" ]',
							'then',
							'  touch runtime.txt',
							'  echo $runtime >> runtime.txt',
							'else',
							'  echo $runtime > runtime.txt',
							'fi',
							'',
							'# Clean-up',
							'if [ -f "R-packages.tar.gz" ]',
							'then',
							'  rm R-packages.tar.gz',
							'  rm -r R-packages',
							'fi',
							'',
							'if [ -f "ss_linux" ]',
							'then',
							'  rm ss_linux',
							'fi',
							'rm Start.tar.gz',
							'',		
							'# Create empty file so that it does not mess up when repacking tar',
							'touch End.tar.gz',
							"tar -czf End.tar.gz --exclude='End.tar.gz' --exclude='*.log' --exclude='*.r' --exclude='rtmp/' .",
							'cd ..',
							'mv working/End.tar.gz .',
							'')
							# "tar -czf End.tar.gz --exclude='End.tar.gz' --exclude='Start.tar.gz' --exclude='*.log' --exclude='.*' --exclude='condor*' --exclude='_condor*' --exclude='local-tmp/' --exclude='.gwms.d/' --exclude='.gwms_aux/' --exclude='.condor_creds/' .",

		# add wrapper_actions
			if(is.null(wrapper_actions))
			{
				wrapper_actions = c("00_run_ss")
			}

			# sanitize wrapper actions
				valid_actions = c("00_run_ss","01_run_retro","02_run_R0profile","03_run_aspm")

				if(length(wrapper_actions[which(is.na(match(wrapper_actions,valid_actions)))])>0)
				{
					print("Invalid actions included in wrapper actions:")
					print(paste0(wrapper_actions[which(is.na(match(wrapper_actions,valid_actions)))],collapse=", "))
					print("These have been removed.")
					wrapper_actions = wrapper_actions[which(!is.na(match(wrapper_actions,valid_actions)))]
				}
				if(length(wrapper_actions)==0){
					print("All actions are invalid. These are the only valid actions: ")
					print(paste0(valid_actions,collapse=", "))
					stop("Please redefine wrapper_actions to include valid actions.")
				}

				wrapper_actions = sort(unique(wrapper_actions))
				for(i in seq_along(wrapper_actions))
				{
					if(wrapper_actions[i] == "00_run_ss")
					{
						pointer = grep("end=`date +%s`",script_vec,fixed=TRUE)
						script_vec = c(script_vec[1:(pointer-1)],
									 "./ss_linux",
									 script_vec[pointer:length(script_vec)])
					} else {
						pointer = grep("end=`date +%s`",script_vec,fixed=TRUE)
						script_vec = c(script_vec[1:(pointer-1)],
									 paste0("Rscript ",wrapper_actions[i],".r"),
									 script_vec[pointer:length(script_vec)])
					}
				}

				wrapper_actions = c(paste0(file_name," has the following actions: "),wrapper_actions)

		# check if shell script exists, if not then sink
			if(!file.exists(paste0(local_shell_path,file_name)))
			{
				writeLines(script_vec,con=paste0(local_shell_path,file_name))
				local_action_time = Sys.time()
				local_action = c(paste0(file_name," did not exist at local location: "),
								local_shell_path,
								paste0(file_name," was written at local location at : "),
								as.character(local_action_time))
			} else if(file.exists(paste0(local_shell_path,file_name)) && overwrite) {
				writeLines(script_vec,con=paste0(local_shell_path,file_name))
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
			print(wrapper_actions)
			print(local_action)
			print(remote_action)
			time = round((B-A)[3]/60,digits=2)
			print(paste0(" Actions taken in ",time," minutes."))
	}
	return(0)
}