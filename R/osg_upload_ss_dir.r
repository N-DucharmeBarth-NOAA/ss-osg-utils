
#' This function uploads a directory of Stock Synthesis model runs to the OSG.
#'
#' Please see ?help for osg_connect and ssh::ssh_connect for more information.
#' 
#' @param session
#' @param unix_name
#' @param login_node
#' @param rsa_keyfile
#' @param rsa_passphrase 
#' @param local_dir_path
#' @param local_dir_names
#' @param remote_dir_path
#' @param files_to_upload
#' @param verbose
#' @export
#' @importFrom ssh ssh_exec_wait
#' @importFrom ssh scp_upload
#' @importFrom ssh ssh_disconnect
#' 

# Nicholas Ducharme-Barth
# August 19, 2022
# Copyright (C) 2022  Nicholas Ducharme-Barth
# You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.

osg_upload_ss_dir = function(session=NULL,unix_name,login_node,rsa_keyfile=NULL,rsa_passphrase=NULL,local_dir_path,local_dir_names=NULL,remote_dir_path,files_to_upload,verbose=TRUE)
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
	for(i in 1:length(local_dir_names))
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
