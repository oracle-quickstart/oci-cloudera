# Sandbox
This sets up an instance running the Cloudera VM Docker image.  This is a self contained environment.   Access to the Sandbox is done via post deployment URLs.  SSH access is also possible, but because this is running inside docker, shell commands to the container require attaching to the Docker container first:

    ssh -i ~/.ssh/id_rsa opc@<sandbox_public_ip>
    sudo docker ps

Output will show a CONTAINER ID - use that in the following command

    sudo docker exec -it <container_id> bash

All post deployment for the Sandbox instance is done in remote-exec as part of the Terraform apply process.  You will see output on the screen as part of this process.  Once complete, URLs for access to the Sandbox will be displayed.
