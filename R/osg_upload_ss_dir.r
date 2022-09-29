
#' This function uploads a directory structure to the Open Science Grid (OSG).
#' 
#' @param session ssh connection created by \link[ssgrid]{osg_connect}.
#' @param unix_name Character string giving OSG unix login name.
#' @param login_node Character string giving OSG login node (e.g., login05.osgconnect.net).
#' @param rsa_keyfile Path to private key file. Must be in OpenSSH format (see details). Default is NULL. See \link[ssh]{ssh_connect} for more details.
#' @param rsa_passphrase Either a string or a callback function for password prompt. Default is NULL. See \link[ssh]{ssh_connect} for more details. 
#' @param local_dir_path Path to directory on local machine to upload to OSG.
#' @param local_dir_names Character vector of sub-directories within \emph{local_dir_path} to upload to OSG.
#' @param remote_dir_path Path on OSG login node to upload \emph{local_dir_names} into.
#' @param files_to_upload Character vector giving file names to upload to OSG.
#' @param target_dir_path Path on OSG login node with text file giving each directory to execute condor jobs in.
#' @param target_dir_txt_name File name given to text file containing path of each directory to execute condor jobs in.
#' @param verbose Boolean denoting if function details should be printed.
#' @return Returns 0 on exit.
#' @export
#' @importFrom ssh ssh_exec_wait
#' @importFrom ssh scp_upload
#' @importFrom ssh ssh_disconnect
#' 

# Nicholas Ducharme-Barth
# August 19, 2022
# Copyright (C) 2022  Nicholas Ducharme-Barth
# You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.

osg_upload_ss_dir = function(session=NULL,
	unix_name,
	login_node,
	rsa_keyfile=NULL,
	rsa_passphrase=NULL,
	local_dir_path,
	local_dir_names=NULL,
	remote_dir_path,
	files_to_upload,
	target_dir_path, 
	target_dir_txt_name,
	verbose=TRUE)
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
	
	# make remote directory
		ssh::ssh_exec_wait(session,paste0("mkdir -p ",remote_dir_path))

	# if local_dir_names is NULL then define default
	if(is.null(local_dir_names))
	{
		stop("Please define 'local_dir_names'")
	}

	# iterate over local directories
	for(i in seq_along(local_dir_names))
	{
		# check if files to upload are in the directory
			if(mean(files_to_upload %in% list.files(paste0(local_dir_path,local_dir_names[i])))!=1)
			{
				print("The following file(s): ")
				print(files_to_upload[files_to_upload %in% list.files(paste0(local_dir_path,local_dir_names[i])) == FALSE])
				print("are not in the following directory: ")
				print(paste0(local_dir_path,local_dir_names[i]))
				stop("Please correct files_to_upload or remove directory from local_dir_names.")
			}
		# make tar with the necessary files
			shell(paste0("powershell cd ",paste0(local_dir_path,local_dir_names[i]),";tar -czf Start.tar.gz ",paste(files_to_upload,collapse=' ')))
		# make remote dir
			ssh::ssh_exec_wait(session,paste0("mkdir -p ",remote_dir_path,local_dir_names[i]))			
		# send all files to the launch machine
	       	ssh::scp_upload(session,files=paste0(local_dir_path,local_dir_names[i],"/",c("Start.tar.gz")),to=paste0("/home/",unix_name,"/",remote_dir_path,local_dir_names[i],"/"))
		# clean-up local
			shell(paste0("powershell cd ",paste0(local_dir_path,local_dir_names[i]),"; rm Start.tar.gz"))		
	}

	# add txt file with dir information
		# sanitize target_dir_path
			target_dir_path = gsub("\\","/",target_dir_path,fixed=TRUE)
			if(substr(target_dir_path, nchar(target_dir_path), nchar(target_dir_path))!="/")
			{
				target_dir_path = paste0(target_dir_path,"/")
			}

			dir_status = strsplit(rawToChar(ssh::ssh_exec_internal(session,paste0('[ -d "',target_dir_path,'" ]&&echo "exists"||echo "not exists"'))$stdout),"\\n")[[1]]
			if(dir_status!="exists")
			{
				ssh::ssh_exec_wait(session,paste0("mkdir -p ",target_dir_path))
			}

			local_shell_path = tempdir()
			local_shell_path = gsub("\\","/",local_shell_path,fixed=TRUE)
			if(substr(local_shell_path, nchar(local_shell_path), nchar(local_shell_path))!="/")
			{
				local_shell_path = paste0(local_shell_path,"/")
			}

			sink_target = paste0(remote_dir_path,local_dir_names)
			for(i in seq_along(sink_target))
			{
				if(substr(sink_target[i], nchar(sink_target[i]), nchar(sink_target[i]))!="/")
				{
					sink_target[i] = paste0(sink_target[i],"/")
				}
			}
			sink_target = gsub("\\","/",sink_target,fixed=TRUE)
			writeLines(sink_target,con=paste0(local_shell_path,target_dir_txt_name))
		    ssh::scp_upload(session,files=paste0(local_shell_path,target_dir_txt_name),to=paste0("/home/",unix_name,"/",target_dir_path))

			ssh::ssh_exec_wait(session,command=paste0('dos2unix ',paste0(target_dir_path,target_dir_txt_name)))
			ssh::ssh_exec_wait(session,command=paste0('chmod 777 ',paste0(target_dir_path,target_dir_txt_name)))

			file.remove(paste0(local_shell_path,target_dir_txt_name))

	# close session
	if(osg_disconnect)
	{
		ssh::ssh_disconnect(session)
	}

	B = proc.time()
	if(verbose)
	{
		time = round((B-A)[3]/60,digits=2)
		print(paste0(length(files_to_upload)," files uploaded to ",length(local_dir_names)," directories in ",time," minutes."))
	}
	return(0)
}
