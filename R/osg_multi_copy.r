
#' This function copies files to all specified directories on the OSG
#'
#' Please see ?help for osg_connect and ssh::ssh_connect for more information.
#' 
#' @param session
#' @param unix_name
#' @param login_node
#' @param rsa_keyfile
#' @param rsa_passphrase 
#' @param remote_source_path
#' @param files_to_copy
#' @param remote_paste_path
#' @param verbose
#' @export
#' @importFrom ssh ssh_exec_wait
#' @importFrom ssh ssh_exec_internal
#' @importFrom ssh ssh_disconnect
#' 

# Nicholas Ducharme-Barth
# August 19, 2022
# Copyright (C) 2022  Nicholas Ducharme-Barth
# You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.

osg_multi_copy = function(session=NULL,unix_name,login_node,rsa_keyfile=NULL,rsa_passphrase=NULL,remote_source_path,files_to_copy,remote_paste_path,verbose=TRUE)
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
	
	# iterate over target directories
	for(i in 1:length(remote_paste_path))
	{
		# check if target directory exists
			dir_status = strsplit(rawToChar(ssh::ssh_exec_internal(session,paste0('[ -d "',remote_paste_path[i],'" ]&&echo "exists"||echo "not exists"'))$stdout),"\\n")[[1]]
			if(dir_status == "exists")
			{
				ssh::ssh_exec_wait(session,command=paste0('cp ',paste0(remote_source_path,files_to_copy,collapse=" ")," ",remote_paste_path[i],"/"))
			} else{
				print("You attempted to copy files into the following directory, which does not exist: ")
				print(paste0(remote_paste_path[i]))
				stop("Please correct remote_paste_path to only include directories that have already been created using osg_upload_ss_dir().")
			}
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
		print(paste0(length(files_to_copy)," files uploaded to ",length(remote_paste_path)," directories in ",time," minutes."))
	}
	return(0)
}
