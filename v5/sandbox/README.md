# sandbox
This sets up an instance running the Cloudera VM Docker image.  Once complete, Terraform will print URLs you can use to access the sandbox.

If you want to SSH into the machine running Docker and check on status, you can do this:

    ssh -i ~/.ssh/id_rsa opc@<sandbox_public_ip>
    sudo docker ps

Output from that command will show a container ID that you can us to start an interactive shell on the container:

    sudo docker exec -it <container_id> bash
