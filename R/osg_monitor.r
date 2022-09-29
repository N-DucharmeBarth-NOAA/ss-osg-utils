
#' This function monitors an Open Science Grid (OSG) job submission
#'
#' It is a wrapper around the \href{https://htcondor.readthedocs.io/en/latest/man-pages/condor_q.html}{condor_q} function
#'
#' @param session ssh connection created by \link{osg_connect}.
#' @param unix_name Character string giving OSG unix login name.
#' @param login_node Character string giving OSG login node (e.g., login05.osgconnect.net).
#' @param rsa_keyfile Path to private key file. Must be in OpenSSH format (see details). Default is NULL. See \link[ssh]{ssh_connect} for more details.
#' @param rsa_passphrase Either a string or a callback function for password prompt. Default is NULL. See \link[ssh]{ssh_connect} for more details.
#' @return Returns the output from executing the \href{https://htcondor.readthedocs.io/en/latest/man-pages/condor_q.html}{condor_q} command on the OSG.
#' @export
#' @importFrom ssh ssh_exec_internal
#' 

# Nicholas Ducharme-Barth
# August 20, 2022
# Copyright (C) 2022  Nicholas Ducharme-Barth
# You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.

osg_monitor = function(session = NULL,
					   unix_name,
					   login_node,
					   rsa_keyfile=NULL,
					   rsa_passphrase=NULL)
{
	# connect to osg
		if(is.null(session))
		{
			session = osg_connect(unix_name,login_node,rsa_keyfile,rsa_passphrase)
			osg_disconnect = TRUE
		} else {
			osg_disconnect = FALSE
		}

	# submit condor job
		status = strsplit(rawToChar(ssh::ssh_exec_internal(session,"condor_q")$stdout),"\\n")[[1]]
	
	return(status)
}

