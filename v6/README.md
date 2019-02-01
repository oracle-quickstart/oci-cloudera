# oci-cloudera-edh v6 
This module deploys a cluster of arbitrary size using Cloudera Enterprise Data Hub v6

|             | Worker Nodes   | Bastion Instance | Utility and Master Instances |
|-------------|----------------|------------------|------------------------------|
| Recommended | BM.DenseIO2.52 | VM.Standard2.4   | VM.Standard2.16              |

## Prerequisites
Installation has a dependency on Terraform being installed and configured for the user tenancy.   As such an "env-vars" file is included with this package that contains all the necessary environment variables.  This file should be updated with the appropriate values prior to installation.  To source this file prior to installation, either reference it in your .rc file for your shell's or run the following:

    source env-vars


## ALPHA NOTICE - This template is still in Alpha development, as such it's not completely functional ... yet


