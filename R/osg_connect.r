
#' This function opens an ssh connection to the OSG.
#'
#' If you have a passphrase associated with your rsa private key please enter it in the 'password' section of the dialogue box that opens.
#' This is function is a wrapper for ssh::ssh_connect to connect to the OSG login node via ssh
#'
#' Please use ?ssh::ssh_connect for more information.
#' 
#' @param unix_name
#' @param login_node
#' @param rsa_keyfile
#' @param rsa_passphrase 
#' @return 
#' @export
#' @importFrom ssh ssh_connect
#' 

# Nicholas Ducharme-Barth
# August 20, 2022
# Copyright (C) 2022  Nicholas Ducharme-Barth
# You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.

osg_connect = function(unix_name,login_node,rsa_keyfile=NULL,rsa_passphrase=NULL)
{
	# connect to osg
	if(is.null(rsa_passphrase)&is.null(rsa_keyfile))
	{
		# use password prompt
			session = ssh::ssh_connect(host=paste0(unix_name,"@",login_node))
	} else if (!is.null(rsa_passphrase)&is.null(rsa_keyfile)){
		# use passphrase as function argument
			session = ssh::ssh_connect(host=paste0(unix_name,"@",login_node),passwd=as.character(rsa_passphrase))
	} else if (is.null(rsa_passphrase)&!is.null(rsa_keyfile)){
		# use keyfile
			session = ssh::ssh_connect(host=paste0(unix_name,"@",login_node),keyfile=rsa_keyfile)
	} else {
		stop("Please specify either rsa_keyfile or rsa_passphrase. Not both.")
	}

	return(session)
}
	
	