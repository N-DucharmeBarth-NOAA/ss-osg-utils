
#' This function cleans directories of given files and sub-directories
#'
#' @param unix_name
#' @param login_node
#' @param rsa_keyfile
#' @param rsa_passphrase
#' @param remote_dirs
#' @param clean_files
#' @param clean_subdirs
#' @param verbose
#' @return
#' @export
#' @importFrom ssh ssh_exec_wait
#' @importFrom ssh ssh_exec_internal
#' 

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
			osg_disconnect = TRUE
		} else {
			osg_disconnect = FALSE
		}

	A = proc.time()
	# sanitize remote_dirs
		remote_dirs = gsub("\\","/",remote_dirs,fixed=TRUE)
		for(i in 1:length(remote_dirs))
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
	for(i in 1:length(remote_dirs))
	{
		# delete files
			if(is.null(clean_files))
			{
				dir_contents = strsplit(rawToChar(ssh::ssh_exec_internal(session,paste0("cd ",remote_dirs[i],"; ls -lh"))$stdout),"\\n")[[1]][-1]
				rm_files = setdiff(unname(sapply(dir_contents,function(x)tail(strsplit(x,"\\s+")[[1]],n=1))),"End.tar.gz")
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
