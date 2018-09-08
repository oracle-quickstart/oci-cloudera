## Cloudera Data Science Workbench on OCI

# ALPHA NOTICE
This template is in ALPHA state and is not fully functional - requires some updates to support DNS pre-requisite for CDSW. 

# Templates Supported
This automation template can be added onto the following templates:
  1. Production
  2. N-Node
  3. AD-Spanning

Copy the contents here over the existing deployment files and run the terraform deployment.

# DNS Domain Configuraiton Required
Note that the DNS records required for CDSW need to be adjusted.  This requires modification of the following files:
  1. cdsw_dns.tf
  2. scripts/cdsw.sh

The script includes a variable at the top for ease of configuration.  The TF template requires modification of the following:

	name           = "cdh-primary.oci-dns"

# Java Required
This installation also requires Java 1.8 RPM.  This is not distributed as part of this automation, you will need to donwload manually and put in the java/ directory prior to deployment.
