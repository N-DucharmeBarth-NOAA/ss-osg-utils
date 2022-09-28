
#' This function cleans directories of given files and sub-directories on the Open Science Grid (OSG).
#'
#' @param session ssh connection created by \link[ssgrid]{osg_connect}.
#' @param unix_name Character string giving OSG unix login name.
#' @param login_node Character string giving OSG login node (e.g., login05.osgconnect.net).
#' @param rsa_keyfile Path to private key file. Must be in OpenSSH format (see details). Default is NULL. See \link[ssh]{ssh_connect} for more details.
#' @param rsa_passphrase Either a string or a callback function for password prompt. Default is NULL. See \link[ssh]{ssh_connect} for more details.
#' @param remote_dirs Character vector giving path of directories to clean on OSG login node.
#' @param clean_files Character vector giving files to remove from remote_dirs. Defaults to all files except for End.tar.gz.
#' @param clean_subdirs Character vector giving path of directories to delete on OSG login node.
#' @param verbose Boolean denoting if function details should be printed.
#' @return Returns 0 on exit.
#' @export
#' @importFrom ssh ssh_exec_wait
#' @importFrom ssh ssh_exec_internal
#' @importFrom utils tail

# Nicholas Ducharme-Barth
# August 20, 2022
# Copyright (C) 2022  Nicholas Ducharme-Barth
# You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.

osg_clean = function(session = NULL,
					   unix_name,
					   login_node,
					   rsa_keyfile=NULL,
					   rsa_passphrase=NULL,
					   remote_dirs,
					   clean_files=NULL,
					   clean_subdirs=NULL,
					   verbose=TRUE)
{
	# connect to osg
		if(is.null(session))
		{
			session = osg_connect(unix_name,login_node,rsa_keyfile,rsa_passphrase)
		} 

	A = proc.time()
	# sanitize remote_dirs
		remote_dirs = gsub("\\","/",remote_dirs,fixed=TRUE)
		for(i in seq_along(remote_dirs))
		{
			# sanitize
				if(substr(remote_dirs[i], nchar(remote_dirs[i]), nchar(remote_dirs[i]))!="/")
				{
					remote_dirs[i] = paste0(remote_dirs[i],"/")
				}
		}

	# sanitize clean_subdirs
		if(!is.null(clean_subdirs))
		{
			clean_subdirs = gsub("\\","/",clean_subdirs,fixed=TRUE)
			if(substr(clean_subdirs, nchar(clean_subdirs), nchar(clean_subdirs))!="/")
			{
				clean_subdirs = paste0(clean_subdirs,"/")
			}		
		}


	# iterate over dirs
	for(i in seq_along(remote_dirs))
	{
		# delete files
			if(is.null(clean_files))
			{
				dir_contents = strsplit(rawToChar(ssh::ssh_exec_internal(session,paste0("cd ",remote_dirs[i],"; ls -lh"))$stdout),"\\n")[[1]][-1]
				rm_files = setdiff(unname(sapply(dir_contents,function(x)utils::tail(strsplit(x,"\\s+")[[1]],n=1))),"End.tar.gz")
			} else {
				rm_files = clean_files
			}
			ssh::ssh_exec_wait(session,paste0("cd ",remote_dirs[i],"; rm ",paste0(rm_files,collapse=" ")))
			if(verbose)
			{
				print(paste0("cd ",remote_dirs[i],"; rm ",paste0(rm_files,collapse=" ")))
			}

		# delete subdirectories
			if(!is.null(clean_subdirs))
			{
				ssh::ssh_exec_wait(session,paste0("cd ",remote_dirs[i],"; rm -r ",clean_subdirs,collapse=" "))
			}
	}
	B = proc.time()

	if(verbose)
	{
		# print actions
			time = round((B-A)[3]/60,digits=2)
			print(paste0(length(remote_dirs)," directories cleaned in ",time," minutes."))
	}
	return(0)
}
