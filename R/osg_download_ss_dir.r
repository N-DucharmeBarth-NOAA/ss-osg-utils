
#' This function downloads a directory of model runs to a local directory from the Open Science Grid (OSG).
#'
#' Options exist for cleaning the local and remote directory after download
#'
#' @param session ssh connection created by \link{osg_connect}.
#' @param unix_name Character string giving OSG unix login name.
#' @param login_node Character string giving OSG login node (e.g., login05.osgconnect.net).
#' @param rsa_keyfile Path to private key file. Must be in OpenSSH format (see details). Default is NULL. See \link[ssh]{ssh_connect} for more details.
#' @param rsa_passphrase Either a string or a callback function for password prompt. Default is NULL. See \link[ssh]{ssh_connect} for more details.
#' @param remote_dir_stem Path on OSG login node to directory to download.
#' @param remote_dirs Character vector of sub-directories to download from \emph{remote_dir_stem}.
#' @param download_dir_stem Path to directory on local machin to download into.
#' @param files_to_download Files to download from each directory given by \emph{remote_dirs}.
#' @param untar_local Boolean denoting whether or not to untar all downloaded \emph{*tar.gz} files.
#' @param clean_remote Boolean denoting whether or not to clean \emph{remote_dirs} using \link{osg_clean}.
#' @param delete_remote Boolean denoting whether or not to delete \emph{remote_dirs}.
#' @param verbose Boolean denoting if function details should be printed.
#' @return Returns 0 on exit.
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
					   download_dir_stem,
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

	# sanitize download_dir_stem
		download_dir_stem = gsub("\\","/",download_dir_stem,fixed=TRUE)
		if(substr(download_dir_stem, nchar(download_dir_stem), nchar(download_dir_stem))!="/")
		{
			download_dir_stem = paste0(download_dir_stem,"/")
		}

	# prepare local directories to receive downloads
	if(!dir.exists(download_dir_stem))
	{
		dir.create(download_dir_stem,recursive=TRUE)
	}

	# iterate over directories
	for(i in 1:length(remote_dirs))
	{
		# create local directory if needed
		if(!dir.exists(paste0(download_dir_stem,remote_dirs[i])))
		{
			dir.create(paste0(download_dir_stem,remote_dirs[i]),recursive=TRUE)
		}

		# download
		for(j in 1:length(files_to_download))
		{
			tmp_dirfiles = strsplit(rawToChar(ssh::ssh_exec_internal(session,paste0("ls ",remote_dir_stem,remote_dirs[i]))$stdout),"\\n")[[1]]
			tmp_file = tmp_dirfiles[grep(files_to_download[j],tmp_dirfiles)]
			ssh::scp_download(session, files=paste0(remote_dir_stem,remote_dirs[i],tmp_file), to = paste0(download_dir_stem,remote_dirs[i]), verbose = verbose)
			rm(list=c("tmp_dirfiles","tmp_file"))
		}

		# un-tar
		if(untar_local)
		{
			tar_files = files_to_download[grep("tar.gz",files_to_download,fixed=TRUE)]
			for(j in 1:length(tar_files))
			{
				shell(paste0("powershell cd ",paste0(download_dir_stem,remote_dirs[i]),";tar -xzf ",tar_files[j]))
				file.remove(paste0(download_dir_stem,remote_dirs[i],tar_files[j]))
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
