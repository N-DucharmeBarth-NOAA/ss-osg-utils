
#' This function submits a job array to the Open Science Grid (OSG)
#'
#' It is a wrapper around the \href{https://htcondor.readthedocs.io/en/latest/man-pages/condor_submit.html}{condor_submit} function
#' 
#' @param session ssh connection created by \link{osg_connect}.
#' @param unix_name Character string giving OSG unix login name.
#' @param login_node Character string giving OSG login node (e.g., login05.osgconnect.net).
#' @param rsa_keyfile Path to private key file. Must be in OpenSSH format (see details). Default is NULL. See \link[ssh]{ssh_connect} for more details.
#' @param rsa_passphrase Either a string or a callback function for password prompt. Default is NULL. See \link[ssh]{ssh_connect} for more details.
#' @param remote_submit_path Path to directory on OSG login node where condor_submit script is written.
#' @param condor_submit_name Name given to the condor_submit script.
#' @return Returns the output from executing the \href{https://htcondor.readthedocs.io/en/latest/man-pages/condor_submit.html}{condor_submit} command on the OSG.
#' @export
#' @importFrom ssh ssh_exec_internal
#' 

# Nicholas Ducharme-Barth
# August 20, 2022
# Copyright (C) 2022  Nicholas Ducharme-Barth
# You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.

osg_execute = function(session = NULL,
					   unix_name,
					   login_node,
					   rsa_keyfile=NULL,
					   rsa_passphrase=NULL,
					   remote_submit_path="scripts/condor_submit/",
					   condor_submit_name="condor.sub")
{
	# connect to osg
		if(is.null(session))
		{
			session = osg_connect(unix_name,login_node,rsa_keyfile,rsa_passphrase)
			osg_disconnect = TRUE
		} else {
			osg_disconnect = FALSE
		}

	# sanitize remote_submit_path
		remote_submit_path = gsub("\\","/",remote_submit_path,fixed=TRUE)
		if(substr(remote_submit_path, nchar(remote_submit_path), nchar(remote_submit_path))!="/")
		{
			remote_submit_path = paste0(remote_submit_path,"/")
		}

	# submit condor job
		status = strsplit(rawToChar(ssh::ssh_exec_internal(session,paste0("condor_submit ",remote_submit_path,condor_submit_name))$stdout),"\\n")[[1]]
	
	return(status)
}

