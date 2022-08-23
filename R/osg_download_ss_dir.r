
#' This function downloads a directory of model runs to a local directory.
#'
#' Options exist for cleaning the local and remote directory after download
#'
#' @param unix_name
#' @param login_node
#' @param rsa_keyfile
#' @param rsa_passphrase
#' @param remote_dir_stem
#' @param remote_dirs
#' @param local_dir_stem
#' @param files_to_download
#' @param untar_local
#' @param clean_remote
#' @param delete_remote
#' @param verbose
#' @return
#' @export
#' @importFrom ssh ssh_exec_wait
#' @importFrom ssh scp_download
#' 

# Nicholas Ducharme-Barth
# August 20, 2022
# Copyright (C) 2022  Nicholas Ducharme-Barth
# You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.

osg_download_ss_dir = function(session = NULL,
					   unix_name,
					   login_node,
					   rsa_keyfile=NULL,
					   rsa_passphrase=NULL,
					   remote_dir_stem,
					   remote_dirs,
					   local_dir_stem,
					   files_to_download=c("End.tar.gz"),
					   untar_local=TRUE,
					   clean_remote=TRUE,
					   delete_remote=FALSE,
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
		remote_dir_stem = gsub("\\","/",remote_dir_stem,fixed=TRUE)
		remote_dirs = gsub("\\","/",remote_dirs,fixed=TRUE)
		for(i in 1:length(remote_dirs))
		{
			# sanitize
				if(substr(remote_dirs[i], nchar(remote_dirs[i]), nchar(remote_dirs[i]))!="/")
				{
					remote_dirs[i] = paste0(remote_dirs[i],"/")
				}
		}

	# sanitize local_dir_stem
		local_dir_stem = gsub("\\","/",local_dir_stem,fixed=TRUE)
		if(substr(local_dir_stem, nchar(local_dir_stem), nchar(local_dir_stem))!="/")
		{
			local_dir_stem = paste0(local_dir_stem,"/")
		}

	# prepare local directories to receive downloads
	if(!dir.exists(local_dir_stem))
	{
		dir.create(local_dir_stem,recursive=TRUE)
	}

	# iterate over directories
	for(i in 1:length(remote_dirs))
	{
		# create local directory if needed
		if(!dir.exists(paste0(local_dir_stem,remote_dirs[i])))
		{
			dir.create(paste0(local_dir_stem,remote_dirs[i]),recursive=TRUE)
		}

		# download
		ssh::scp_download(session, files=paste0(remote_dir_stem,remote_dirs[i],files_to_download), to = paste0(local_dir_stem,remote_dirs[i]), verbose = verbose)

		# un-tar
		if(untar_local)
		{
			tar_files = files_to_download[grep("tar.gz",files_to_download,fixed=TRUE)]
			for(j in 1:length(tar_files))
			{
				shell(paste0("powershell cd ",paste0(local_dir_stem,remote_dirs[i]),";tar -xzf ",tar_files[j]))
				file.remove(paste0(local_dir_stem,remote_dirs[i],tar_files[j]))
			}
		}

		# clean
		if(clean_remote&!delete_remote)
		{
			osg_clean(session = session,
					   unix_name=unix_name,
					   login_node=login_node,
					   remote_dirs=paste0(remote_dir_stem,remote_dirs[i]),
					   verbose=verbose)
		} else if(!clean_remote&delete_remote){
			ssh::ssh_exec_wait(session,paste0("rm -r ",paste0(remote_dir_stem,remote_dirs[i])))
		} else if(clean_remote&delete_remote){
			ssh::ssh_exec_wait(session,paste0("rm -r ",paste0(remote_dir_stem,remote_dirs[i])))
		}

	}
	B = proc.time()

	if(verbose)
	{
		# print actions
			time = round((B-A)[3]/60,digits=2)
			print(paste0(length(remote_dirs)," directories downloaded in ",time," minutes."))
	}
	return(0)
}
