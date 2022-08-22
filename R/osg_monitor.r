
#' This function monitors an Open Science Grid job submission
#'
#' It is a wrapper around the condor_q function
#'
#' @param unix_name
#' @param login_node
#' @param rsa_keyfile
#' @param rsa_passphrase
#' @return
#' @export
#' @importFrom ssh ssh_connect
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

