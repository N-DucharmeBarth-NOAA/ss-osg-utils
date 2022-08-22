
#' This function submits a job array to the Open Science Grid
#'
#' It is a wrapper around the condor_submit function
#' 
#' @param unix_name
#' @param login_node
#' @param rsa_keyfile
#' @param rsa_passphrase
#' @param remote_submit_path
#' @param condor_submit_name 
#' @return
#' @export
#' @importFrom ssh ssh_connect
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

