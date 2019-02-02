#!/usr/bin/env python 

from __future__ import print_function
import socket
import time
import sys
from sys import stdout
import cm_client
from cm_client import ApiUser2
from cm_client.rest import ApiException
from pprint import pprint
import hashlib
import re
from paramiko import SFTPClient, SSHClient, AutoAddPolicy
import json
import time
import datetime
import argparse


start_time = time.time()

#
# Global Parameter Defaults - These are passed to the script, do not modify
#

disk_count = 'None'
worker_shape = 'None'
cm_server = 'None'
input_host_list = 'None'
license_file = 'None'
host_fqdn_list = []

#
# Custom Global Parameters - Customize below here until Functions section
#

# Enable Debug Output set this to 'True' for detailed output during execution
debug = 'False'  # type: str

# Define new admin username and password
user_name = 'cdhadmin'  # type: str
password = 'somepassword'  # type: str

# Set this to 'Yes' if you want to perform host lookups from the Cloudera Manager host for building your cluster
# Any other value will revert to static host list set in "build_host_list" function - you will need to manually set
# these values in this script.
# remotely_detect_hosts = 'Yes'
# Disabling for now as invocation from Terraform should provide valid hosts

# Define cluster name
cluster_name = 'TestCluster'  # type: str
# This converts the cluster name into API friendly format, do not modify
api_cluster_name = cm_client.ApiClusterRef(cluster_name, cluster_name)  # type: str
# Set port number for Cloudera Manager - used to build API endpoints and check if Manger is up/listening
cm_port = '7180'
# Set API version to use with Cloudera Manager
api_version = 'v31'

# Define Cloudera Version 6 to deploy
cluster_version = '6.1.0'  # type: str

# Define Remote Parcel URL & Distribution Rate if desired
remote_parcel_url = 'https://archive.cloudera.com/cdh6/' + cluster_version + '/parcels'  # type: str
parcel_distribution_rate = "1024000"  # type: int

# Define SSH Keyfile for access to cluster hosts - required for Cloudera Manager to deploy agents
# Example ssh_keyfile = '/home/opc/.ssh/id_rsa'  # type: str
ssh_keyfile = '/Users/zsmith/.ssh/id_rsa'  # type: str

# Cluster Services List
# Modify this list to pick which services to install
#
# cluster_service_list = ['SOLR', 'ACCUMULO_C6', 'ADLS_CONNECTOR', 'LUNA_KMS', 'HBASE', 'SENTRY', 'HIVE', 'KUDU', 
#                         'HUE', 'FLUME', 'SPARK_ON_YARN', 'THALES_KMS', 'HDFS', 'OOZIE', 'ISILON', 'SQOOP_CLIENT',
#                         'KS_INDEXER', 'ZOOKEEPER', 'YARN', 'KMS', 'KEYTRUSTEE', 'KEYTRUSTEE_SERVER', 'KAFKA', 'IMPALA',
#                         'AWS_S3']

# MAXIMAL - NON KERBEROS
cluster_service_list = ['SOLR', 'HBASE', 'HIVE', 'SPARK_ON_YARN', 'HDFS', 'OOZIE', 'SQOOP_CLIENT', 'ZOOKEEPER',
                        'YARN', 'KAFKA', 'IMPALA']

# MINIMAL - NON KERBEROS
# cluster_service_list = ['HDFS', 'YARN', 'SOLR', 'ZOOKEEPER']

# Management Roles List
#  Available role types:
#
#  mgmt_roles_list = [ 'SERVICEMONITOR', 'ACTIVITYMONITOR', 'HOSTMONITOR', 'REPORTSMANAGER', 'EVENTSERVER'
#                      'ALERTPUBLISHER', 'NAVIGATOR', 'NAVIGATORMETASERVER']
#
# REPORTSMANAGER, NAVIGATOR, NAVIGATORMETASERVER are only available with Licensed Cloudera Manager Enterprise Edition.
#
mgmt_roles_list = ['ACTIVITYMONITOR', 'ALERTPUBLISHER', 'EVENTSERVER', 'HOSTMONITOR', 'SERVICEMONITOR']

# Cluster Host Mapping
# Define these variables to match when building host lists to use for role and
# service mapping.  For example, if your worker nodes have "cdh-worker" in the hostname, set that here.
# If you want your Cloudera Manager on a specific host, set he host identifier here.
# This is used in "cluster_host_id_map" and "remote_host_detection" (if used)
#
# Worker Host Prefix
worker_hosts_contain = 'cdh-worker'
# Master Host Prefix
master_hosts_contain = 'cdh-master'
# Explicit hostname of the Master Host for NameNode
namenode_host_contains = 'cdh-master-1'
# Explicit hostname of the Master Host for SecondaryNameNode
secondary_namenode_host_contains = 'cdh-master-2'
# Explicit hostname of the Cloudera Manager Host
cloudera_manager_host_contains = 'cdh-utility-1'

# Specify Log directory on cluster hosts
LOG_DIR = '/var/log/cloudera'

#
# End Global Parameters
#

#
# OCI Shape Specific Tunings - Modify at your own discretion
#
def get_parameter_value(worker_shape, parameter):
    switcher = {
        "BM.DenseIO2.52:yarn_nodemanager_resource_cpu_vcores": "208",
        "BM.DenseIO2.52:yarn_nodemanager_resource_memory_mb": "786432",
        "BM.DenseIO2.52:impalad_memory_limit": "274877906944",
        "BM.DenseIO2.52:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2080m -Xmx2080m",
        "BM.DenseIO2.52:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2080m -Xmx2080m",
        "BM.DenseIO2.52:dfs_replication": "3",
        "BM.DenseIO1.36:yarn_nodemanager_resource_cpu_vcores": "128",
        "BM.DenseIO1.36:yarn_nodemanager_resource_memory_mb": "524288",
        "BM.DenseIO1.36:impalad_memory_limit": "274877906944",
        "BM.DenseIO1.36:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1896m -Xmx1896m",
        "BM.DenseIO1.36:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1896m -Xmx1896m",
        "BM.DenseIO1.36:dfs_replication": "3",
        "BM.Standard2.52:yarn_nodemanager_resource_cpu_vcores": "208",
        "BM.Standard2.52:yarn_nodemanager_resource_memory_mb": "786432",
        "BM.Standard2.52:impalad_memory_limit": "274877906944",
        "BM.Standard2.52:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2080m -Xmx2080m",
        "BM.Standard2.52:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2080m -Xmx2080m",
        "BM.Standard2.52:dfs_replication": "3",
        "BM.Standard1.36:yarn_nodemanager_resource_cpu_vcores": "128",
        "BM.Standard1.36:yarn_nodemanager_resource_memory_mb": "242688",
        "BM.Standard1.36:impalad_memory_limit": "122857142857",
        "BM.Standard1.36:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1896m -Xmx1896m",
        "BM.Standard1.36:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1896m -Xmx1896m",
        "BM.Standard1.36:dfs_replication": "3",
        "VM.Standard2.24:yarn_nodemanager_resource_cpu_vcores": "80",
        "VM.Standard2.24:yarn_nodemanager_resource_memory_mb": "308224",
        "VM.Standard2.24:impalad_memory_limit": "122857142857",
        "VM.Standard2.24:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms3853m -Xmx3853m",
        "VM.Standard2.24:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms3853m -Xmx3853m",
        "VM.Standard2.24:dfs_replication": "3",
        "VM.Standard2.16:yarn_nodemanager_resource_cpu_vcores": "48",
        "VM.Standard2.16:yarn_nodemanager_resource_memory_mb": "237568",
        "VM.Standard2.16:impalad_memory_limit": "42949672960",
        "VM.Standard2.16:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1984m -Xmx1984m",
        "VM.Standard2.16:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1984m -Xmx1984m",
        "VM.Standard2.16:dfs_replication": "3",
        "VM.Standard1.16:yarn_nodemanager_resource_cpu_vcores": "48",
        "VM.Standard1.16:yarn_nodemanager_resource_memory_mb": "95232",
        "VM.Standard1.16:impalad_memory_limit": "42949672960",
        "VM.Standard1.16:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1984m -Xmx1984m",
        "VM.Standard1.16:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1984m -Xmx1984m",
        "VM.Standard1.16:dfs_replication": "3",
        "VM.Standard2.8:yarn_nodemanager_resource_cpu_vcores": "16",
        "VM.Standard2.8:yarn_nodemanager_resource_memory_mb": "114688",
        "VM.Standard2.8:impalad_memory_limit": "21500000000",
        "VM.Standard2.8:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2368m -Xmx2368m",
        "VM.Standard2.8:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2368m -Xmx2368m",
        "VM.Standard2.8:dfs_replication": "3",
        "VM.DenseIO2.8:yarn_nodemanager_resource_cpu_vcores": "16",
        "VM.DenseIO2.8:yarn_nodemanager_resource_memory_mb": "114688",
        "VM.DenseIO2.8:impalad_memory_limit": "21500000000",
        "VM.DenseIO2.8:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2368m -Xmx2368m",
        "VM.DenseIO2.8:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2368m -Xmx2368m",
        "VM.DenseIO2.8:dfs_replication": "3",
        "VM.DenseIO1.8:yarn_nodemanager_resource_cpu_vcores": "16",
        "VM.DenseIO1.8:yarn_nodemanager_resource_memory_mb": "114688",
        "VM.DenseIO1.8:impalad_memory_limit": "21500000000",
        "VM.DenseIO1.8:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2368m -Xmx2368m",
        "VM.DenseIO1.8:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2368m -Xmx2368m",
        "VM.DenseIO1.8:dfs_replication": "3",
        "VM.Standard1.8:yarn_nodemanager_resource_cpu_vcores": "16",
        "VM.Standard1.8:yarn_nodemanager_resource_memory_mb": "37888",
        "VM.Standard1.8:impalad_memory_limit": "21500000000",
        "VM.Standard1.8:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2368m -Xmx2368m",
        "VM.Standard1.8:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2368m -Xmx2368m",
        "VM.Standard1.8:dfs_replication": "3"
    }
    return switcher.get(worker_shape + ":" + parameter, "NOT FOUND")


#
# SECONDARY FUNCTIONS SECTION
#

def parse_ssh_key():
    """
    Detect SSH key and parse to setup for host deployment
    :return:
    """
    global ssh_key
    if not ssh_keyfile:
        with ssh_keyfile as k:
            print('->Error ssh keyfile does not exist - verify file/path exists: {}\n'.format(k))
            sys.exit()

    if ssh_keyfile:
        with open(ssh_keyfile) as k:
            ssh_key = k.read()
        print('->SSH Keyfile Found: %s' % ssh_keyfile)


def build_api_endpoints():
    """
    Main API setup - define and make global all API endpoints used by functions
    :return:
    """
    cm_client.configuration.username = user_name
    cm_client.configuration.password = password
    api_host = 'http://' + cm_server
    global api_url, api_client
    api_url = api_host + ':' + cm_port + '/api/' + api_version
    if debug == 'True':
        print("->API URL: " + api_url)
    api_client = cm_client.ApiClient(api_url)
    global clusters_api_instance, users_api_instance, manager_api_instance, parcels_api_instance, parcel_api_instance, \
        cluster_services_api_instance, auth_roles_api_instance, roles_config_api_instance, all_hosts_api_instance, \
        roles_resource_api_instance, mgmt_service_resource_api_instance, services_resource_api_instance, \
        mgmt_role_commands_resource_api_instance, mgmt_role_config_groups_resource_api_instance, \
        mgmt_roles_resource_api_instance, cloudera_manager_resource_api
    clusters_api_instance = cm_client.ClustersResourceApi(api_client)
    users_api_instance = cm_client.UsersResourceApi(api_client)
    manager_api_instance = cm_client.ClouderaManagerResourceApi(api_client)
    parcels_api_instance = cm_client.ParcelsResourceApi(api_client)
    parcel_api_instance = cm_client.ParcelResourceApi(api_client)
    cluster_services_api_instance = cm_client.ServicesResourceApi(api_client)
    auth_roles_api_instance = cm_client.AuthRolesResourceApi(api_client)
    roles_config_api_instance = cm_client.RoleConfigGroupsResourceApi(api_client)
    all_hosts_api_instance = cm_client.AllHostsResourceApi(api_client)
    roles_resource_api_instance = cm_client.RolesResourceApi(api_client)
    mgmt_service_resource_api_instance = cm_client.MgmtServiceResourceApi(api_client)
    services_resource_api_instance = cm_client.ServicesResourceApi(api_client)
    mgmt_role_commands_resource_api_instance = cm_client.MgmtRoleCommandsResourceApi(api_client)
    mgmt_role_config_groups_resource_api_instance = cm_client.MgmtRoleConfigGroupsResourceApi(api_client)
    mgmt_roles_resource_api_instance = cm_client.MgmtRolesResourceApi(api_client)
    cloudera_manager_resource_api = cm_client.ClouderaManagerResourceApi(api_client)


def wait_for_active_cluster_commands(active_command):
    """
    Wait until Cloudera Manager finishes running cluster active_command
    :param active_command: Descriptive of what should be running - this just waits if any task is detected running
    :return:
    """
    view = 'summary'
    wait_status = '*'
    done = '0'

    while done == '0':
        stdout.write('\r%s - Waiting: %s' % (active_command, wait_status))
        try:
            api_response = manager_api_instance.list_active_commands(view=view)
            if not api_response.items:
                done = '1'
                stdout.write('\n')
                break
            else:
                sys.stdout.flush()
                time.sleep(10)
                wait_status = wait_status + '*'
        except ApiException as e:
            print('Exception waiting for active commands: {}'.format(e))
    print('\n')


def wait_for_active_mgmt_commands(active_command):
    """
    Wait until Cloudera Manager finishes running mgmt active_command
    :param active_command: Descriptive of what should be running - this just waits if any task is detected running
    :return:
    """
    view = 'summary'
    wait_status = '*'
    done = '0'

    while done == '0':
        stdout.write('\r%s - Waiting: %s' % (active_command, wait_status))
        try:
            api_response = mgmt_service_resource_api_instance.list_active_commands(view=view)
            if not api_response.items:
                done = '1'
                stdout.write('\n')
                break
            else:
                stdout.flush()
                time.sleep(10)
                wait_status = wait_status + '*'

        except ApiException as e:
            print('Exception waiting for active commands: {}'.format(e))


def list_active_commands():
    """
    Check Cloudera Manager for running commands
    :return:
    """
    view = 'summary'

    try:
        api_response = manager_api_instance.list_active_commands(view=view)
        if debug == 'True':
            pprint(api_response)
        if not api_response.items:
            pass
        else:
            print('Active Command Running : %s' % api_response.items)
    except ApiException as e:
        print('Exception when calling ClouderaManagerResourceApi->list_active_commands: {}\n'.format(e))


def list_active_mgmt_commands():
    """
    Check Cloudera Manager for running commands
    :return:
    """
    view = 'summary'

    try:
        api_response = mgmt_service_resource_api_instance.list_active_commands(view=view)
        if debug == 'True':
            pprint(api_response)
        if not api_response.items:
            pass
        else:
            print('Active Command Running : %s' % api_response.items)
    except ApiException as e:
        print('Exception when calling MgmtServiceResourceApi->list_active_commands: {}\n'.format(e))


def init_admin_user():
    """
    Setup a new Admin user
    :return:
    """
    cm_client.configuration.username = 'admin'
    cm_client.configuration.password = 'admin'
    api_host = 'http://' + cm_server
    port = '7180'
    api_version = 'v31'
    api_url = api_host + ':' + port + '/api/' + api_version
    api_client = cm_client.ApiClient(api_url)

    role_display_name = "Full Administrator"
    # UUID is unique per CM instnace - lookup and match role to display name
    custom_role_uuid = ""
    roles = cm_client.AuthRolesResourceApi(api_client).read_auth_roles().items
    for role in roles:
        if role.display_name == role_display_name:
            if debug == 'True':
                print('role.display_name matches role_display_name')
            custom_role_uuid = role.uuid

    users_api_instance = cm_client.UsersResourceApi(api_client)
    role_list = [cm_client.ApiAuthRoleRef(display_name=role_display_name, uuid=custom_role_uuid)]
    user_list = [cm_client.ApiUser2(name=user_name, password=password, auth_roles=role_list)]
    body = cm_client.ApiUser2List(user_list)

    try:
        api_response = users_api_instance.create_users2(body=body)
        if debug == 'True':
            pprint(api_response)
    except ApiException as e:
        print('Exception when calling UsersResourceApi->create_users2_with_http_info: {}\n'.format(e))


def delete_default_admin_user():
    """
    Delete Default Admin User
    :return:
    """
    delete_user_name = "admin"
    try:
        api_response = users_api_instance.delete_user2(delete_user_name)
        if debug == 'True':
            pprint(api_response)
    except ApiException as e:
        print('Exception when calling UsersResourceApi->delete_user2: {}\n'.format(e))


def init_cluster():
    """
    Initialize Cluster
    :return:
    """
    cluster = [cm_client.ApiCluster(name=cluster_name, display_name=cluster_name, full_version=cluster_version)]
    body = cm_client.ApiClusterList(cluster)

    try:
        cluster_api_response = clusters_api_instance.create_clusters(body=body)
        if debug == 'True':
            pprint(cluster_api_response)
    except ApiException as e:
        print('Exception when calling ClustersResourceApi->create_clusters: {}\n'.format(e))


def delete_cluster():
    """
    Delete Cluster
    :return:
    """

    try:
        cluster_api_response = clusters_api_instance.delete_cluster(cluster_name)
        pprint(cluster_api_response)
    except ApiException as e:
        print('Exception when calling ClustersResourceAPI->delete_cluster: {}\n'.format(e))


def read_cluster():
    """
    Read Cluster Info
    :return:
    """

    try:
        api_response = clusters_api_instance.read_cluster(cluster_name)
        global cluster_uuid
        cluster_uuid = api_response.uuid
        if debug == 'True':
            pprint(api_response)
            print('Cluster UUID: ', cluster_uuid)
    except ApiException as e:
        print('Exception while calling ClustersResourceAPI->read_cluster: {}\n'.format(e))


def remote_host_detection():
    """
    SSH to Cloudera Manager Server and detect cluster hosts
    :return:
    """
    print('->Building Host FQDN List dynamically using SSH')
    global host_fqdn_list, output
    host_fqdn_list = []
    ssh_client = SSHClient()
    ssh_client.set_missing_host_key_policy(AutoAddPolicy)
    ssh_client.connect(hostname=cm_server, username='opc', key_filename=ssh_keyfile)
    # Cloudera Manager FQDN lookup
    print('->Lookup Cloudera Manager FQDN')
    try:
        ssh_command = '/usr/bin/host ' + cloudera_manager_host_contains
        stdin, stdout, stderr = ssh_client.exec_command(ssh_command)
        output = stdout.read()
        fqdn = output.strip().split()
        if debug == 'True':
            print('Host Detection output for Cloudera Manager - %s - FQDN: %s' % (output, fqdn[0]))

        if stdout.channel.recv_exit_status() == 0:
            host_fqdn_list.append(fqdn[0])

    except:
        pass
    print('\t%d found' % len(host_fqdn_list))
    # Master Host Detection
    x = 1
    print('->Lookup Master Hosts FQDN')
    for n in range(x, 6):
        try:
            ssh_command = '/usr/bin/host ' + master_hosts_contain + '-%d' % (x,)
            stdin, stdout, stderr = ssh_client.exec_command(ssh_command)
            output = stdout.read()
            fqdn = output.strip().split()
            if debug == 'True':
                print('Host Detection output for Master Hosts - %s - FQDN: %s' % (output, fqdn[0]))

            if stdout.channel.recv_exit_status() == 0:
                host_fqdn_list.append(fqdn[0])

            else:
                print('\t%d found' % (x - 1))
                x = 0

        except:
            pass

        if x == 0:
            break
        else:
            x = x + 1

    # Worker Host Detection
    # For large scale cluster deployment, change this to a number higher than the number of workers
    max_worker_count = 100
    x = 1
    print('->Lookup Worker Hosts FQDN')
    for n in range(x, max_worker_count):
        try:
            ssh_command = '/usr/bin/host ' + worker_hosts_contain + '-%d' % (x,)
            stdin, stdout, stderr = ssh_client.exec_command(ssh_command)
            output = stdout.read()
            fqdn = output.strip().split()
            if debug == 'True':
                print('Host Detection output for Worker Hosts - %s - FQDN: %s' % (output, fqdn[0]))

            if stdout.channel.recv_exit_status() == 0:
                host_fqdn_list.append(fqdn[0])

            else:
                print('\t%d found' % (x - 1))
                x = 0

        except:
            pass

        if x == 0:
            break

        else:
            x = x + 1


def remote_worker_shape_detection():
    """
    SSH via the Cloudera Manager to the first worker in the cluster and lookup shape metadata, setting "worker_shape"
    :return:
    """
    ssh_client = SSHClient()
    ssh_client.set_missing_host_key_policy(AutoAddPolicy)
    ssh_client.connect(hostname=cm_server, username='opc', key_filename=ssh_keyfile)
    ssh_command = "ssh -oStrictHostKeyChecking=no -i /home/opc/.ssh/id_rsa opc@" + worker_hosts_contain + "-1" + \
                  " '/usr/bin/curl -s http://169.254.169.254/opc/v1/instance/'"
    stdin, stdout, stderr = ssh_client.exec_command(ssh_command)
    worker_metadata = stdout.read()
    if debug == 'True':
        print('Worker Metadata from Shape Detection:')
        print(worker_metadata)

    parsed_metadata = json.loads(worker_metadata)
    worker_shape = parsed_metadata['shape']


def build_host_list():
    """
    Create Static Host List for host management - use this if not using remote_host_detection()
    :return:
    """
    print('->Building Host FQDN List from Static Values\n')
    global host_fqdn_list
    host_fqdn_list = []
    host_fqdn_list = ['cdh-utility-1.public3.cdhvcn.oraclevcn.com',
                      'cdh-master-1.private3.cdhvcn.oraclevcn.com',
                      'cdh-master-2.private3.cdhvcn.oraclevcn.com',
                      'cdh-worker-1.private3.cdhvcn.oraclevcn.com',
                      'cdh-worker-2.private3.cdhvcn.oraclevcn.com',
                      'cdh-worker-3.private3.cdhvcn.oraclevcn.com']


def build_cluster_host_list(host_fqdn_list):
    """
    Take values from host_fqdn_list and convert them using ApiHostRef
    :param host_fqdn_list:
    :return:
    """
    global cluster_host_list
    cluster_host_list = []
    for host in host_fqdn_list:
        host_info = cm_client.ApiHostRef(host_id=host)
        cluster_host_list.append(host_info)


def build_disk_lists():
    """
    Build Disk Lists for use with HDFS and YARN
    :return:
    """
    global dfs_data_dir_list
    dfs_data_dir_list = ''
    global yarn_data_dir_list
    yarn_data_dir_list = ''
    for x in range(int(disk_count)):
        if x is 0:
            dfs_data_dir_list += "/data%d/dfs/dn" % x
            yarn_data_dir_list += "/data%d/yarn/nm" % x
        else:
            dfs_data_dir_list += ",/data%d/dfs/dn" % x
            yarn_data_dir_list += ",/data%d/yarn/nm" % x


def add_hosts_to_cluster():
    """
    Add hosts to cluster
    :return:
    """
    body = cm_client.ApiHostRefList(cluster_host_list)

    try:
        api_response = clusters_api_instance.add_hosts(cluster_name, body=body)
        if debug == 'True':
            pprint(api_response)
    except ApiException as e:
        print('Exception when calling ClustersResourceApi->add_hosts: {}\n'.format(e))


def list_hosts():
    """
    List Cluster Hosts
    :return:
    """

    try:
        api_response = clusters_api_instance.list_hosts(cluster_name)
        global cluster_host_list
        cluster_host_list = api_response
        if debug == 'True':
            pprint(api_response)
    except ApiException as e:
        print('Exception when calling ClustersResourceApi->list_hosts: {}\n'.format(e))


def install_hosts():
    """
    Perform Installation on a set of hosts
    :return:
    """

    body = cm_client.ApiHostInstallArguments(host_names=host_fqdn_list, user_name='root', private_key=ssh_key,
                                             parallel_install_count='20')

    try:
        api_response = manager_api_instance.host_install_command(body=body)
        if debug == 'True':
            pprint(api_response)
    except ApiException as e:
        print('Exception when calling ClouderaManagerResourceApi->host_install: {}\n'.format(e))


def update_parcel_repo(remote_parcel_url, parcel_distribution_rate):
    """
    Update Parcel Repository URL
    :param remote_parcel_url: Remote URL to download parcel from (archive.cloudera.com)
    :param parcel_distribution_rate: Rate limit for intra-cluster distribution of Parcels
    :return:
    """
    if not remote_parcel_url:
        print('Remote parcel URL not passed to update_parcel_repo function properly, exiting.')
        sys.exit()

    cm_configs = manager_api_instance.get_config(view='full')
    old_parcel_repo_urls = None
    for cm_config in cm_configs.items:
        if cm_config.name == 'REMOTE_PARCEL_REPO_URLS':
            old_parcel_repo_urls = remote_parcel_url
            break

    new_parcel_repo_urls = old_parcel_repo_urls + ", " + remote_parcel_url
    repo_cm_config = cm_client.ApiConfig(name='REMOTE_PARCEL_REPO_URLS', value=new_parcel_repo_urls)
    distribute_cm_config = cm_client.ApiConfig(name="PARCEL_DISTRIBUTE_RATE_LIMIT_KBS_PER_SECOND",
                                               value=parcel_distribution_rate)
    phone_home = cm_client.ApiConfig(name='PHONE_HOME', value="false")
    new_cm_configs = cm_client.ApiConfigList([repo_cm_config, distribute_cm_config, phone_home])
    updated_cm_configs = manager_api_instance.update_config(body=new_cm_configs)
    if debug == 'True':
        pprint(updated_cm_configs)
    time.sleep(10)


def dda_parcel(parcel_product):
    """
    Download, Deploy, Activate parcel
    :param parcel_product: Parcel Product Name - e.g. CDH, SPARK_ON_YARN
    :return:
    """

    def monitor_parcel(parcel_product, parcel_version, target_stage):
        while True:
            parcel = parcel_api_instance.read_parcel(cluster_name, parcel_product, parcel_version)
            if parcel.stage == target_stage:
                break
            if parcel.state.errors:
                raise Exception(str(parcel.state.errors))
            stdout.write("\rParcel %s progress %s: %s / %s" % (parcel_product, parcel.stage, parcel.state.progress,
                                                        parcel.state.total_progress))
            time.sleep(5)
            stdout.flush()

    sdtout.write('\n')
    parcels = parcels_api_instance.read_parcels(cluster_name, view='FULL')
    for parcel in parcels.items:
        if parcel.product == parcel_product:
            parcel_version = parcel.version

    print("Starting Parcel Download for %s - %s\n" % (parcel_product, parcel_version))
    parcel_api_instance.start_download_command(cluster_name, parcel_product, parcel_version)
    target_stage = 'DOWNLOADED'
    monitor_parcel(parcel_product, parcel_version, target_stage)
    print("\n%s parcel %s version %s on cluster %s" % (target_stage, parcel_product, parcel_version, cluster_name))
    print("Starting Distribution for %s - %s\n" % (parcel_product, parcel_version))
    parcel_api_instance.start_distribution_command(cluster_name, parcel_product, parcel_version)
    target_stage = 'DISTRIBUTED'
    monitor_parcel(parcel_product, parcel_version, target_stage)
    print("\n%s parcel %s version %s on cluster %s" % (target_stage, parcel_product, parcel_version, cluster_name))
    print("Activating Parcel %s\n" % parcel_product)
    parcel_api_instance.activate_command(cluster_name, parcel_product, parcel_version)


def get_parcel_status(parcel_product):
    """
    Get Parcel Status for all Parcels, filter by parcel_product
    :param parcel_product: Parcel Product Name - e.g. CDH, SPARK_ON_YARN
    :return:
    """
    parcels = parcels_api_instance.read_parcels(cluster_name, view='FULL')
    print('PARCELS: \n')
    for x in range(len(parcel.items)):
        if parcel.items[x].name == parcel_product:
            print(parcels.items[x])


def delete_parcel(parcel_product, parcel_version):
    """
    Delete specified parcel
    :param parcel_product: Parcel Product Name - e.g. CDH, SPARK_ON_YARN
    :param parcel_version: Version of Parcel
    :return:
    """
    parcel_api_instance.start_removal_of_distribution_command(cluster_name, parcel_product, parcel_version)
    parcel_api_instance.remove_download_command(cluster_name, parcel_product, parcel_version)


def restart_cluster():
    """
    Restart Cluster
    :return:
    """
    clusters_api_instance = cm_client.ClustersResourceApi(api_client)
    restart_args = cm_client.ApiRestartClusterArgs()
    restart_command = clusters_api_instance.restart_command(cluster_name, body=restart_args)
    wait(restart_command)


def define_cluster_services(cluster_service_list):
    """
    Build API packet for Cluster Services
    :param cluster_service_list: List of all Cluster Services
    :return:
    """
    global api_service_list
    api_service_list = []
    for service in cluster_service_list:
        service_info = cm_client.ApiService(cluster_ref=api_cluster_name, display_name=service, name=service,
                                            type=service)
        api_service_list.append(service_info)


def create_cluster_services(api_service_list):
    """
    Create Cluster Services using cluster_service_list
    api_service_list: API packet from define_cluster_services
    :return:
    """
    body = cm_client.ApiServiceList(api_service_list)

    try:
        api_response = cluster_services_api_instance.create_services(cluster_name, body=body)
        if debug == 'True':
            pprint(api_response)
    except ApiException as e:
        print('Exception when calling ServicesResourceApi->create_services: {}\n'.format(e))


def update_service_config(service_name, api_config_items):
    """
    Update Service Configuration with given values
    :param service_name: Name of the Cluster Service
    :param api_config_items: ApiConfig bundled item list
    :return:
    """
    body = cm_client.ApiServiceConfig(items=api_config_items)

    try:
        api_response = services_resource_api_instance.update_service_config(cluster_name, service_name, body=body)
        if debug == 'True':
            pprint(api_response)
    except ApiException as e:
        print('Exception calling ServicesResourceApi -> update_service_config {}\n'.format(e))


def get_mgmt_db_passwords():
    """
    Scrape flat file on CMS host to get DB passwords
    This will need to be updated for MySQL/Oracle deployments, currently uses PostgreSQL
    :return:
    """
    global amon_password, rman_password, navigator_password, navigator_meta_password, oozie_password, hive_meta_password
    parse_ssh_key()
    ssh_client = SSHClient()
    ssh_client.set_missing_host_key_policy(AutoAddPolicy)
    ssh_client.connect(hostname=cm_server, username='root', key_filename=ssh_keyfile)
    sftp_client = ssh_client.open_sftp()
    remote_file = sftp_client.open('/etc/cloudera-scm-server/db.mgmt.properties')
    try:
        for line in remote_file:
            if 'com.cloudera.cmf.ACTIVITYMONITOR.db.password' in line:
                amon_password = line.split('=')[1].rstrip()

            if 'com.cloudera.cmf.REPORTSMANAGER.db.password' in line:
                rman_password = line.split('=')[1].rstrip()

            if 'com.cloudera.cmf.NAVIGATOR.db.password' in line:
                navigator_password = line.split('=')[1].rstrip()

            if 'com.cloudera.cmf.NAVIGATORMETASERVER.db.password' in line:
                navigator_meta_password = line.split('=')[1].rstrip()

            if 'com.cloudera.cmf.OOZIE.db.password' in line:
                oozie_password = line.split('=')[1].rstrip()

            if 'com.cloudera.cmf.HIVEMETASTORESERVER.db.password' in line:
                hive_meta_password = line.split('=')[1].rstrip()

    finally:
        remote_file.close()


def define_cms_mgmt_service():
    """
    Build API packet for CMS service list
    :return:
    """
    global mgmt_api_packet
    mgmt_api_packet = []
    mgmt_api_packet = cm_client.ApiService(cluster_ref=api_cluster_name, display_name='Cloudera Management Service',
                                           name='mgmt', type='MGMT')


def setup_cms():
    """
    Setup the Cloudera Management Services.
    :return:
    """
    try:
        print('->Setting up %s \n' % mgmt_api_packet.display_name)
        api_response = mgmt_service_resource_api_instance.setup_cms(body=mgmt_api_packet)
        if debug == 'True':
            pprint(api_response)
    except ApiException as e:
        print('Exception calling MgmtServiceResourceApi -> setup_cms {}\n'.format(e))


def begin_trial():
    """
    Start Trial License
    :return:
    """
    try:
        api_response = manager_api_instance.begin_trial()
        if debug == 'True':
            pprint(api_response)
    except ApiException as e:
        print('Exception calling ClouderaManagerResourceApi -> begin_trial: {}\n'.format(e))


def update_mgmt_rcg(rcg_name, role, display_name, rcg_config):
    """
    Create Management Services using api_mgmt_service_list

    :return:
    """
    print('-->Updating RCG: %s\n' % rcg_name)
    body = cm_client.ApiRoleConfigGroup(name=rcg_name, role_type=role, display_name=display_name,
                                               config=rcg_config)

    try:
        api_response = mgmt_role_config_groups_resource_api_instance.update_role_config_group(rcg_name, body=body)
        if debug == 'True':
                pprint(api_response)
    except ApiException as e:
        print('Exception calling MgmtRoleConfigGroupsResourceApi -> update_role_config_group {}\n'.format(e))


def setup_mgmt_rcg(mgmt_roles_list):
    """
    Build API packet for Managment Services
    :param mgmt_service_list: List of all Management Services
    :return:
    """
    for role in mgmt_roles_list:
        rcg_name = 'mgmt-' + role + '-BASE'
        if role == "ACTIVITYMONITOR":
            display_name = 'Activity Monitor Default Group'
            firehose_database_host = [cm_client.ApiConfig(name='firehose_database_host', value=cm_hostname + ':5432')]
            firehose_database_user = [cm_client.ApiConfig(name='firehose_database_user', value='amon')]
            firehose_database_password = [cm_client.ApiConfig(name='firehose_database_password', value=amon_password)]
            firehose_database_type = [cm_client.ApiConfig(name='firehose_database_type', value='postgresql')]
            firehose_database_name = [cm_client.ApiConfig(name='firehose_database_name', value='amon')]
            mgmt_log_dir = [cm_client.ApiConfig(name='mgmt_log_dir', value=LOG_DIR + '/cloudera-scm-firehose')]
            firehose_heapsize = [cm_client.ApiConfig(name='firehose_heapsize', value='268435456')]
            role_config_list = [firehose_database_host, firehose_database_name, firehose_database_password,
                                firehose_database_type, firehose_database_user, mgmt_log_dir, firehose_heapsize]

        if role == "ALERTPUBLISHER":
            display_name = 'Alert Publisher Default Group'
            mgmt_log_dir = [cm_client.ApiConfig(name='mgmt_log_dir', value=LOG_DIR + '/cloduera-scm-alertpublisher')]
            role_config_list = [mgmt_log_dir]

        if role == "EVENTSERVER":
            display_name = 'Event SErver Default Group'
            event_server_heapsize = [cm_client.ApiConfig(name='event_server_heapsize', value='268435456')]
            mgmt_log_dir = [cm_client.ApiConfig(name='mgmt_log_dir', value=LOG_DIR + '/cloudera-scm-eventserver')]
            eventserver_index_dir = [cm_client.ApiConfig(name='eventserver_index_dir',
                                                         value=LOG_DIR + '/lib/cloudera-scm-eventserver')]
            role_config_list = [event_server_heapsize, mgmt_log_dir, eventserver_index_dir]

        if role == "HOSTMONITOR":
            display_name = 'Host Monitor Default Group'
            mgmt_log_dir = [cm_client.ApiConfig(name='mgmt_log_dir', value=LOG_DIR + '/cloudera-scm-firehose')]
            firehose_storage_dir = [cm_client.ApiConfig(name='firehose_storage_dir',
                                                        value=LOG_DIR + "/lib/cloudera-host-monitor")]
            role_config_list = [mgmt_log_dir, firehose_storage_dir]

        if role == "SERVICEMONITOR":
            display_name = 'Service Monitor Default Group'
            mgmt_log_dir = [cm_client.ApiConfig(name='mgmt_log_dir', value=LOG_DIR + '/cloudera-scm-firehose')]
            firehose_storage_dir = [cm_client.ApiConfig(name='firehose_storage_dir',
                                                        value=LOG_DIR + "/lib/cloudera-service-monitor")]
            role_config_list = [mgmt_log_dir, firehose_storage_dir]

        if role == "NAVIGATOR":
            display_name = 'Navigator Default Group'
            continue

        if role == "NAVIGATORMETADATASERVER":
            display_name = 'Navigator Metadata Server Default Group'
            continue

        if role == "REPORTSMANAGER":
            display_name = 'Reports Manager Default Group'
            headlamp_database_host = [cm_client.ApiConfig(name='headlamp_database_host', value=cm_hostname + ':5432')]
            headlamp_database_name = [cm_client.ApiConfig(name='headlamp_database_name', value='rman')]
            headlamp_databse_password = [cm_client.ApiConfig(name='headlamp_database_password', value=rman_password)]
            headlamp_database_type = [cm_client.ApiConfig(name='headlamp_database_type', value='postgresql')]
            headlamp_database_user = [cm_client.ApiConfig(name='headlamp_database_user', value='rman')]
            headlamp_scratch_dir = [cm_client.ApiConfig(name='headlamp_scrtch_dir',
                                                        value=LOG_DIR + '/lib/cloudera-scm-headlamp')]
            mgmt_log_dir = [cm_client.ApiConfig(name='mgmt_log_dir', value=LOG_DIR + '/lib/cloudera-scm-headlamp')]
            role_config_list = [headlamp_database_host, headlamp_database_name, headlamp_database_type,
                                headlamp_database_user, headlamp_databse_password, headlamp_scratch_dir,
                                mgmt_log_dir]

        if role == "OOZIE":
            display_name = 'Oozie Default Group'
            oozie_database_host = [cm_client.ApiConfig(name='oozie_database_host', value=cm_hostname + ':5432')]
            oozie_database_name = [cm_client.ApiConfig(name='oozie_database_name', value='oozie')]
            oozie_database_password = [cm_client.ApiConfig(name='oozie_database_password', value=oozie_password)]
            oozie_database_type = [cm_client.ApiConfig(name='oozie_database_type', value='postgresql')]
            oozie_database_user = [cm_client.ApiConfig(name='oozie_database_user', value='oozie')]
            oozie_log_dir = [cm_client.ApiConfig(name='oozie_log_dir', value=LOG_DIR + '/oozie')]
            role_config_list = [oozie_database_host, oozie_database_name, oozie_database_password,
                                oozie_database_type, oozie_database_user, oozie_log_dir]
        for config in role_config_list:
            rcg_config = cm_client.ApiConfigList(config)
            update_mgmt_rcg(rcg_name=rcg_name, role=role, display_name=display_name, rcg_config=rcg_config)
        create_mgmt_roles(mgmt_rcg=rcg_name, mgmt_rcg_roletype=role, mgmt_host_id=cm_host_id, mgmt_hostname=cm_hostname,
                          mrc=1)


def update_cluster_rcg_configuration(cluster_service_list):
    """
    Define Cluster Configuration Parameters here for each RCG, push them to Cloudera Manager
    When adding custom configuration, this is the section you want to use
    Add the config element to an existing rcg by creating a variable, assigning the configuration name and values
    using ApiConfig, then insert the variable to the config array.  It will be processed automatically at cluster build.
    :return:
    """

    def push_rcg_config(config):
        body = cm_client.ApiConfigList(config)

        try:
            api_response = roles_config_api_instance.update_config(cluster_name, rcg, service, message=message,
                                                                   body=body)
            if debug == 'True':
                pprint(api_response)
        except ApiException as e:
            print('Exception updating %s - %s: \n%s' % (service, rcg, e))

    for service in cluster_service_list:
        build_role_config_group_list(service)
        message = 'Cluster Build Update'
        print('->Updating ' + service + ' Configuration\n')
        if service == 'FLUME':
            for rcg in role_config_group_list:
                if rcg == 'FLUME-AGENT-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'AGENT'
                    create_role(rcg, rcg_roletype, service, cm_host_id, cm_hostname, 3)
                    pass

        if service == 'HBASE':
            for rcg in role_config_group_list:
                if rcg == 'HBASE-HBASETHRIFTSERVER-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'HBASETHRIFTSERVER'
                    pass

                if rcg == 'HBASE-MASTER-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'MASTER'
                    create_role(rcg, rcg_roletype, service, snn_host_id, snn_hostname, 1)
                    create_role(rcg, rcg_roletype, service, nn_host_id, nn_hostname, 2)
                    create_role(rcg, rcg_roletype, service, cm_host_id, cm_hostname, 3)

                if rcg == 'HBASE-REGIONSERVER-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'REGIONSERVER'
                    n = 0
                    for host_id in worker_host_ids:
                        create_role(rcg, rcg_roletype, service, host_id, worker_hostnames[n], (n + 1))
                        n = n + 1

                if rcg == 'HBASE-HBASERESTSERVER-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    pass

                if rcg == 'HBASE-GATEWAY-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'GATEWAY'
                    create_role(rcg, rcg_roletype, service, snn_host_id, snn_hostname, 1)
                    create_role(rcg, rcg_roletype, service, nn_host_id, nn_hostname, 2)
                    create_role(rcg, rcg_roletype, service, cm_host_id, cm_hostname, 3)

        if service == 'HDFS':
            for rcg in role_config_group_list:
                if rcg == 'HDFS-NAMENODE-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'NAMENODE'  # type: str
                    dfs_name_dir = [cm_client.ApiConfig(name='dfs_name_dir_list', value='/data/dfs/nn')]
                    dfs_namenode_handler_count = [cm_client.ApiConfig(name='dfs_namenode_handler_count', value='70')]
                    dfs_namenode_service_handler_count = [cm_client.ApiConfig(name='dfs_namenode_service_handler_count',
                                                                              value='70')]
                    dfs_namenode_servicerpc_address = [cm_client.ApiConfig(name='dfs_namenode_servicerpc_address',
                                                                            value='8022')]
                    namenode_java_heapsize = [cm_client.ApiConfig(name='namenode_java_heapsize', value='4196000000')]
                    namenode_log_dir = [cm_client.ApiConfig(name='namenode_log_dir', value=LOG_DIR + '/nn')]
                    nn_config_list = [dfs_namenode_service_handler_count, dfs_namenode_handler_count, dfs_name_dir,
                                      namenode_java_heapsize, namenode_log_dir, dfs_namenode_servicerpc_address]
                    for config in nn_config_list:
                        push_rcg_config(config)
                    create_role(rcg, rcg_roletype, service, snn_host_id, snn_hostname, 1)

                if rcg == 'HDFS-DATANODE-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'DATANODE'  # type: str
                    dfs_replication = [cm_client.ApiConfig(name='dfs_replication',
                                                           value=get_parameter_value(worker_shape, 'dfs_replication'))]
                    dfs_block_local = [cm_client.ApiConfig(name='dfs_block_local_path_acess_user',
                                                           value='impala,hbase,mapred,spark')]
                    dfs_data_dir = [cm_client.ApiConfig(name='dfs_data_dir_list', value=dfs_data_dir_list)]
                    datanode_java_heapsize = [cm_client.ApiConfig(name='datanode_java_heapsize', value='351272960')]
                    dfs_datanode_data_dir_perm = [cm_client.ApiConfig(name='dfs_datanode_data_dir_perm', value='755')]
                    dfs_datanode_du_reserved = [cm_client.ApiConfig(name='dfs_datanode_du_reserved',
                                                                    value='3508717158')]
                    dfs_datanode_failed_volumes_tolerated = [cm_client.ApiConfig(
                        name='dfs_datanode_failed_volumes_tolerated', value='0')]
                    dfs_datanode_max_locked_memory = [cm_client.ApiConfig(name='dfs_datanode_max_locked_memory',
                                                                          value='1257242624')]
                    dfs_datanode_max_xcievers = [cm_client.ApiConfig(name='dfs_datanode_max_xcievers', value='16384')]
                    datanode_log_dir = [cm_client.ApiConfig(name='datanode_log_dir', value=LOG_DIR + '/dn')]
                    dn_config_list = [dfs_data_dir, datanode_java_heapsize,
                                      dfs_datanode_data_dir_perm, dfs_datanode_du_reserved,
                                      dfs_datanode_failed_volumes_tolerated, dfs_datanode_max_locked_memory,
                                      dfs_datanode_max_xcievers, datanode_log_dir]
                    for config in dn_config_list:
                        push_rcg_config(config)
                    update_service_config(service_name=service, api_config_items=dfs_replication)
                    n = 0
                    if debug == 'True':
                        print('->DEBUG - Number of Workers: ' + str(len(worker_host_ids)))
                    for host_id in worker_host_ids:
                        create_role(rcg, rcg_roletype, service, host_id, worker_hostnames[n], (n + 1))
                        n = n + 1

                if rcg == 'HDFS-SECONDARYNAMENODE-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'SECONDARYNAMENODE'  # type: str
                    fs_checkpoint_dir = [cm_client.ApiConfig(name='fs_checkpoint_dir_list', value='/data/dfs/snn')]
                    secondary_namenode_java_heapsize = [cm_client.ApiConfig(name='secondary_namenode_java_heapsize',
                                                                            value='41960000000')]
                    secondary_namenode_log_dir = [cm_client.ApiConfig(name='secondarynamenode_log_dir',
                                                                      value=LOG_DIR + '/snn')]
                    snn_config_list = [fs_checkpoint_dir, secondary_namenode_java_heapsize,
                                       secondary_namenode_log_dir]
                    for config in snn_config_list:
                        push_rcg_config(config)
                    create_role(rcg, rcg_roletype, service, snn_host_id, snn_hostname, 1)

                if rcg == 'HDFS-FAILOVERCONTROLLER-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'FAILOVERCONTROLLER'
                    failover_controller_log_dir = [cm_client.ApiConfig(name='failover_controller_log_dir',
                                                                       value=LOG_DIR + '/hadoop-hdfs')]
                    push_rcg_config(failover_controller_log_dir)
                    create_role(rcg, rcg_roletype, service, cm_host_id, cm_hostname, 1)

                if rcg == 'HDFS-HTTPFS-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'HTTPFS'
                    httpfs_log_dir = [cm_client.ApiConfig(name='httpfs_log_dir', value=LOG_DIR + '/hadoop-httpfs')]
                    push_rcg_config(httpfs_log_dir)
                    create_role(rcg, rcg_roletype, service, snn_host_id, snn_hostname, 1)

                if rcg == 'HDFS-GATEWAY-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'GATEWAY'
                    dfs_client_use_trash = [cm_client.ApiConfig(name='dfs_client_use_trash', value='true')]
                    push_rcg_config(dfs_client_use_trash)

                if rcg == 'HDFS-BALANCER-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'BALANCER'  # type: str
                    create_role(rcg, rcg_roletype, service, snn_host_id, snn_hostname, 1)

                if rcg == 'HDFS-NFSGATEWAY-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'NFSGATEWAY'
                    pass

                if rcg == 'HDFS-JOURNALNODE-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'JOURNALNODE'
                    dfs_journalnode_edits_dir = [cm_client.ApiConfig(name='dfs_journalnode_edits_dir',
                                                                     value='/data/dfs/jn')]
                    push_rcg_config(dfs_journalnode_edits_dir)
                    create_role(rcg, rcg_roletype, service, nn_host_id, nn_hostname, 1)
                    create_role(rcg, rcg_roletype, service, snn_host_id, snn_hostname, 2)
                    create_role(rcg, rcg_roletype, service, cm_host_id, cm_hostname, 3)
                    pass

        if service == 'HIVE':
            for rcg in role_config_group_list:
                if rcg == 'HIVE-HIVESERVER2-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'HIVESERVER2'
                    hiveserver2_spark_driver_memory = [cm_client.ApiConfig(name='hiveserver2_spark_driver_memory',
                                                                           value='11596411699')]
                    hiveserver2_spark_executor_cores = [cm_client.ApiConfig(name='hiveserver2_spark_executor_cores',
                                                                            value='4')]
                    hiveserver2_spark_executor_memory = [cm_client.ApiConfig(name='hiveserver2_spark_executor_memory',
                                                                             value='17230744780')]
                    hiveserver2_spark_yarn_driver_memory_overhead = \
                        [cm_client.ApiConfig(name='hiveserver2_spark_yarn_driver_memory_overhead',
                                             value='1228')]
                    hiveserver2_spark_yarn_executor_memory_overhead = \
                        [cm_client.ApiConfig(name='hiveserver2_spark_yarn_executor_memory_overhead',
                                             value='2899')]
                    hive2_config_list = [hiveserver2_spark_driver_memory, hiveserver2_spark_executor_cores,
                                         hiveserver2_spark_yarn_driver_memory_overhead,
                                         hiveserver2_spark_yarn_executor_memory_overhead,
                                         hiveserver2_spark_executor_memory]
                    for config in hive2_config_list:
                        push_rcg_config(config)
                    create_role(rcg, rcg_roletype, service, snn_host_id, snn_hostname, 1)

                if rcg == 'HIVE-HIVEMETASTORE-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'HIVEMETASTORE'
                    hive_metastore_server_max_message_size = \
                        [cm_client.ApiConfig(name='hive_metastore_server_max_message_size', value='858993459')]
                    hive_metastore_database_host = [cm_client.ApiConfig(name='hive_metastore_database_host',
                                                                        value=cm_hostname)]
                    hive_metastore_database_user = [cm_client.ApiConfig(name='hive_metastore_database_user',
                                                                        value='hive')]
                    hive_metastore_database_name = [cm_client.ApiConfig(name='hive_metastore_database_name',
                                                                        value='metastore')]
                    hive_metastore_database_password = [cm_client.ApiConfig(name='hive_metastore_database_password',
                                                                             value=hive_meta_password)]
                    hive_metastore_database_port = [cm_client.ApiConfig(name='hive_metastore_database_port',
                                                                        value='5432')]
                    hive_metastore_database_type = [cm_client.ApiConfig(name='hive_metastore_database_type',
                                                                        value='postgresql')]
                    hive_meta_config = [ hive_metastore_database_host, hive_metastore_database_name,
                                         hive_metastore_database_password, hive_metastore_database_port,
                                         hive_metastore_database_type, hive_metastore_database_user]
                    push_rcg_config(hive_metastore_server_max_message_size)
                    for config in hive_meta_config:
                        update_service_config(service_name=service, api_config_items=config)
                    create_role(rcg, rcg_roletype, service, snn_host_id, snn_hostname, 1)

                if rcg == 'HIVE-WEBHCAT-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'WEBHCAT'
                    pass

                if rcg == 'HIVE-GATEWAY-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'GATEWAY'
                    n = 0
                    for host_id in worker_host_ids:
                        create_role(rcg, rcg_roletype, service, host_id, worker_hostnames[n], (n + 1))
                        n = n + 1
                    create_role(rcg, rcg_roletype, service, snn_host_id, snn_hostname, (n + 1))
                    create_role(rcg, rcg_roletype, service, cm_host_id, cm_hostname, (n + 2))

        if service == 'HUE':
            for rcg in role_config_group_list:
                if rcg == 'HUE-HUE_LOAD_BALANCER-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'HUE_LOAD_BALANCER'
                    create_role(rcg, rcg_roletype, service, cm_host_id, cm_hostname, 1)

                if rcg == 'HUE-KT_RENEWER-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'KT_RENEWER'
                    pass

                if rcg == 'HUE-HUE_SERVER-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'HUE_SERVER'
                    create_role(rcg, rcg_roletype, service, cm_host_id, cm_hostname, 1)

        if service == 'IMPALA':
            for rcg in role_config_group_list:
                if rcg == 'IMPALA-IMPALAD-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'IMPALAD'
                    n = 0
                    for host_id in worker_host_ids:
                        create_role(rcg, rcg_roletype, service, host_id, worker_hostnames[n], (n + 1))
                        n = n + 1

                if rcg == 'IMPALA-STATESTORE-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'STATESTORE'
                    create_role(rcg, rcg_roletype, service, nn_host_id, nn_hostname, 1)

                if rcg == 'IMPALA-CATALOGSERVER-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'CATALOGSERVER'
                    create_role(rcg, rcg_roletype, service, nn_host_id, nn_hostname, 1)

        if service == 'KAFKA':
            for rcg in role_config_group_list:
                if rcg == 'KAFKA-GATEWAY-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'GATEWAY'
                    create_role(rcg, rcg_roletype, service, cm_host_id, cm_hostname, 1)

                if rcg == 'KAFKA-KAFKA_BROKER-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'KAFKA_BROKER'
                    n = 0
                    for host_id in worker_host_ids:
                        create_role(rcg, rcg_roletype, service, host_id, worker_hostnames[n], (n + 1))
                        n = n + 1

                if rcg == 'KAFKA-KAFKA_MIRROR_MAKER-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'KAFKA_MIRROR_MAKER'
                    pass

        if service == 'OOZIE':
            for rcg in role_config_group_list:
                if rcg == 'OOZIE-OOZIE_SERVER-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'OOZIE_SERVER'
                    oozie_database_host = [cm_client.ApiConfig(name='oozie_database_host', value=cm_hostname)]
                    oozie_database_password = [cm_client.ApiConfig(name='oozie_database_password',
                                                                   value=oozie_password)]
                    oozie_database_type = [cm_client.ApiConfig(name='oozie_database_type', value='postgresql')]
                    oozie_database_user = [cm_client.ApiConfig(name='oozie_database_user', value='oozie')]
                    oozie_config = [oozie_database_host, oozie_database_password, oozie_database_type,
                                    oozie_database_user]
                    for config in oozie_config:
                        push_rcg_config(config)
                    create_role(rcg, rcg_roletype, service, cm_host_id, cm_hostname, 1)

        if service == 'SOLR':
            for rcg in role_config_group_list:
                if rcg == 'SOLR-GATEWAY-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'GATEWAY'
                    create_role(rcg, rcg_roletype, service, cm_host_id, cm_hostname, 1)

                if rcg == 'SOLR-SOLR_SERVER-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'SOLR_SERVER'
                    create_role(rcg, rcg_roletype, service, snn_host_id, snn_hostname, 1)

        if service == 'SPARK':
            for rcg in role_config_group_list:
                if rcg == 'SPARK-HISTORYSERVER-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'HISTORYSERVER'
                    create_role(rcg, rcg_roletype, service, cm_host_id, cm_hostname, 1)

                if rcg == 'SPARK-GATEWAY-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    pass


        if service == 'SPARK_ON_YARN':
            for rcg in role_config_group_list:
                if rcg == 'SPARK_ON_YARN-SPARK_YARN_HISTORY_SERVER-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'SPARK_YARN_HISTORY_SERVER'
                    create_role(rcg, rcg_roletype, service, cm_host_id, cm_hostname, 1)

                if rcg == 'SPARK_ON_YARN-GATEWAY-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'GATEWAY'
                    n = 0
                    for host_id in worker_host_ids:
                        create_role(rcg, rcg_roletype, service, host_id, worker_hostnames[n], (n + 1))
                        n = n + 1
                    create_role(rcg, rcg_roletype, service, cm_host_id, cm_hostname, (n + 1))
                    create_role(rcg, rcg_roletype, service, snn_host_id, snn_hostname, (n + 2))

        if service == 'SQOOP_CLIENT':
            for rcg in role_config_group_list:
                if rcg == 'SQOOP_CLIENT-GATEWAY-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'GATEWAY'
                    create_role(rcg, rcg_roletype, service, cm_host_id, cm_hostname, 1)

        if service == 'YARN':
            for rcg in role_config_group_list:
                if rcg == 'YARN-GATEWAY-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'GATEWAY'  # type: str
                    mapred_submit_replication = [cm_client.ApiConfig(name='mapred_submit_replication', value='3')]
                    mapreduce_map_java_opts = \
                        [cm_client.ApiConfig(name='mapreduce_map_java_opts',
                                             value=get_parameter_value(worker_shape, 'mapreduce_map_java_opts'))]
                    mapreduce_reduce_java_opts = \
                        [cm_client.ApiConfig(name='mapreduce_reduce_java_opts',
                                             value=get_parameter_value(worker_shape, 'mapreduce_reduce_java_opts'))]
                    io_file_buffer_size = [cm_client.ApiConfig(name='io_file_buffer_size', value='131072')]
                    io_sort_mb = [cm_client.ApiConfig(name='io_sort_mb', value='1024')]
                    yarn_app_mapreduce_am_resource_mb = [cm_client.ApiConfig(name='yarn_app_mapreduce_am_resource_mb',
                                                                             value='4096')]
                    yarn_app_mapreduce_am_max_heap = [cm_client.ApiConfig(name='yarn_app_mapreduce_am_max_heap',
                                                                          value='1073741824')]
                    gw_config_list = [mapred_submit_replication, mapreduce_map_java_opts, mapreduce_reduce_java_opts,
                                      io_file_buffer_size, io_sort_mb, yarn_app_mapreduce_am_max_heap,
                                      yarn_app_mapreduce_am_resource_mb]
                    for config in gw_config_list:
                        push_rcg_config(config)
                    create_role(rcg, rcg_roletype, service, cm_host_id, cm_hostname, 1)

                if rcg == 'YARN-NODEMANAGER-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'NODEMANAGER'  # type: str
                    yarn_nodemanager_heartbeat_interval_ms = \
                        [cm_client.ApiConfig(name='yarn_nodemanager_heartbeat_interval_ms', value='100')]
                    node_manager_java_heapsize = [cm_client.ApiConfig(name='node_manager_java_heapsize',
                                                                      value='2000000000')]
                    yarn_nodemanager_local_dirs = [cm_client.ApiConfig(name='yarn_nodemanager_local_dirs',
                                                                       value=yarn_data_dir_list)]
                    yarn_nodemanager_resource_cpu_vcores = \
                        [cm_client.ApiConfig(name='yarn_nodemanager_resource_cpu_vcores',
                                             value=get_parameter_value(worker_shape, 'yarn_nodemanager_resource_cpu_vcores'))]
                    yarn_nodemanager_resource_memory_mb = \
                        [cm_client.ApiConfig(name='yarn_nodemanager_resource_memory_mb',
                                             value=get_parameter_value(worker_shape, 'yarn_nodemanager_resource_memory_mb'))]
                    node_manager_log_dir = [cm_client.ApiConfig(name='node_manager_log_dir',
                                                                value=LOG_DIR + '/hadoop-yarn')]
                    yarn_nodemanager_log_dirs = [cm_client.ApiConfig(name='yarn_nodemanager_log_dirs',
                                                                     value=LOG_DIR + '/hadoop-yarn/container')]
                    nm_config_list = [yarn_nodemanager_heartbeat_interval_ms, node_manager_java_heapsize,
                                      yarn_nodemanager_local_dirs, yarn_nodemanager_resource_cpu_vcores,
                                      yarn_nodemanager_resource_memory_mb, node_manager_log_dir,
                                      yarn_nodemanager_log_dirs]
                    for config in nm_config_list:
                        push_rcg_config(config)
                    n = 0
                    if debug == 'True':
                        print('Number of Workers: ' + str(len(worker_host_ids)))
                    for host_id in worker_host_ids:
                        create_role(rcg, rcg_roletype, service, host_id, worker_hostnames[n], (n + 1))
                        n = n + 1

                if rcg == 'YARN-RESOURCEMANAGER-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'RESOURCEMANAGER'  # type: str
                    resource_manager_java_heapsize = [cm_client.ApiConfig(name='resource_manager_java_heapsize',
                                                                          value='2000000000')]
                    yarn_scheduler_minimum_allocation_mb = \
                        [cm_client.ApiConfig(name='yarn_scheduler_minimum_allocation_mb', value='1024')]
                    yarn_scheduler_maximum_allocation_mb = \
                        [cm_client.ApiConfig(name='yarn_scheduler_maximum_allocation_mb', value='8192')]
                    yarn_scheduler_maximum_allocation_vcores = \
                        [cm_client.ApiConfig(name='yarn_scheduler_maximum_allocation_vcores', value='2')]
                    resource_manager_log_dir = \
                        [cm_client.ApiConfig(name='resource_manager_log_dir', value=LOG_DIR + '/hadoop-yarn')]
                    rm_config_list = [resource_manager_java_heapsize, yarn_scheduler_maximum_allocation_mb,
                                      yarn_scheduler_maximum_allocation_vcores, yarn_scheduler_minimum_allocation_mb,
                                      resource_manager_log_dir]
                    for config in rm_config_list:
                        push_rcg_config(config)
                    create_role(rcg, rcg_roletype, service, snn_host_id, snn_hostname, 1)

                if rcg == 'YARN-JOBHISTORY-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'JOBHISTORY'  # type: str
                    mr2_jobhistory_java_heapsize = [cm_client.ApiConfig(name='mr2_jobhistory_java_heapsize',
                                                                        value='1000000000')]
                    mr2_jobhistory_log_dir = [cm_client.ApiConfig(name='mr2_jobhistory_log_dir',
                                                                  value=LOG_DIR + '/hadoop-mapreduce')]
                    jh_config_list = [mr2_jobhistory_java_heapsize, mr2_jobhistory_log_dir]
                    for config in jh_config_list:
                        push_rcg_config(config)
                    create_role(rcg, rcg_roletype, service, cm_host_id, cm_hostname, 1)

        if service == 'ZOOKEEPER':
            for rcg in role_config_group_list:
                if rcg == 'ZOOKEEPER-SERVER-BASE':
                    print('-->Updating RCG: %s\n' % rcg)
                    rcg_roletype = 'SERVER'  # type: str
                    maxclientcnxns = [cm_client.ApiConfig(name='maxClientCnxns', value='1024')]
                    datalogdir = [cm_client.ApiConfig(name='dataLogDir', value=LOG_DIR + '/zookeeper')]
                    datadir = [cm_client.ApiConfig(name='dataDir', value=LOG_DIR + '/zookeeper')]
                    zk_server_log_dir = [cm_client.ApiConfig(name='zk_server_log_dir', value=LOG_DIR + '/zookeeper')]
                    zk_config_list = [maxclientcnxns, datalogdir, datadir, zk_server_log_dir]
                    for config in zk_config_list:
                        push_rcg_config(config)
                    create_role(rcg, rcg_roletype, service, cm_host_id, cm_hostname, 1)
                    create_role(rcg, rcg_roletype, service, nn_host_id, nn_hostname, 2)
                    create_role(rcg, rcg_roletype, service, snn_host_id, snn_hostname, 3)


def update_cluster_services():
    """
    Update Cluster with desired services
    -Currently Defunct-
    :return:
    """
    body = cm_client.ApiCluster(cluster_name, services=api_service_list, uuid=cluster_uuid)

    try:
        api_response = clusters_api_instance.update_cluster(cluster_name, body=body)
        pprint(api_response)
    except ApiException as e:
        print('Exception when calling ClustersResourceApi->update_cluster: {}\n'.format(e))


def auto_assign_roles():
    """
    Automatically assign roles to hosts and create the roles for all the services in a cluster.
    :return:
    """

    try:
        api_response = clusters_api_instance.auto_assign_roles(cluster_name)
        pprint(api_response)
    except ApiException as e:
        print('Exception when calling ClouderaManagerResourceApi->auto_assign_roles: {}\n'.format(e))


def build_role_config_group_list(service_name):
    """
    Read Role Config Groups and build a list
    :return:
    """
    try:
        api_response = roles_config_api_instance.read_role_config_groups(cluster_name, service_name=service_name)
    except ApiException as e:
        print('Exception: {}'.format(e))
        api_response = ''

    global role_config_group_list
    role_config_group_list = []
    for x in range(len(api_response.items)):
        rcg_name = api_response.items[x].name
        if debug == 'True':
            print('Service %s - Role Config Group Found: %s' % (service_name, rcg_name))
        role_config_group_list.append(rcg_name)
    if debug == 'True':
        print('Full Role Config Group List: %s' % role_config_group_list)

def auto_configure_cluster():
    """
    Automatically configures roles and services in a cluster.
    :return:
    """

    try:
        api_response = clusters_api_instance.auto_configure(cluster_name)
        pprint(api_response)
    except ApiException as e:
        print('Exception when calling ClouderaManagerResourceApi->auto_configure: {}\n'.format(e))


def read_cluster_services():
    """
    Read Cluster Services - return all
    :return:
    """
    services = cluster_services_api_instance.read_services(cluster_name, view='FULL')
    pprint(services)
    for service in services.items:
        print(service.display_name, "-", service.type)


def cluster_host_id_map():
    """
    Map Host IDs for use in cluster services
    :return:
    """
    list_hosts()
    global nn_host_id, snn_host_id, cm_host_id, worker_host_ids
    global nn_hostname, snn_hostname, cm_hostname, worker_hostnames
    for x in range(0, len(cluster_host_list.items)):
        if cloudera_manager_host_contains in cluster_host_list.items[x].hostname:
            cm_hostname = cluster_host_list.items[x].hostname
            cm_host_id = cluster_host_list.items[x].host_id

    for x in range(0, len(cluster_host_list.items)):
        if namenode_host_contains in cluster_host_list.items[x].hostname:
            nn_hostname = cluster_host_list.items[x].hostname
            nn_host_id = cluster_host_list.items[x].host_id

    for x in range(0, len(cluster_host_list.items)):
        if secondary_namenode_host_contains in cluster_host_list.items[x].hostname:
            snn_hostname = cluster_host_list.items[x].hostname
            snn_host_id = cluster_host_list.items[x].host_id

    worker_hostnames = []
    worker_host_ids = []
    for x in range(0, len(cluster_host_list.items)):
        if worker_hosts_contain in cluster_host_list.items[x].hostname:
            worker_hostnames.append(cluster_host_list.items[x].hostname)
            worker_host_ids.append(cluster_host_list.items[x].host_id)
    x = 0
    for worker in worker_hostnames:
        if debug == 'True':
            print('Cluster Map - Worker Name: %s - ID: %s' % (worker, worker_host_ids[x]))
        x = x + 1
    if debug == 'True':
        print('NameNode : %s - %s' % (nn_hostname, nn_host_id))
        print('Secondary NameNode: %s - %s' % (snn_hostname, snn_host_id))
        print('Cloudera Manager: %s - %s' % (cm_hostname, cm_host_id))
        print('Worker Hostnames: %s' % worker_hostnames)
        print('Worker IDs: %s' % worker_host_ids)


def create_role(rcg, rcg_roletype, service, host_id, hostname, rc):
    """
    Create Role to associate with cluster hosts, services, RCGs
    REQUIRED FIELDS (ApiRole)-  name, type, host_ref(id), service_ref, role_config_group_ref
    ApiRoleList
    api_instance.create_roles(cluster_name, service_name, body=body)
    :param rcg: Role Config Group
    :param rcg_roletype: Role Config Group Type - e.g. NAMENODE, DATANODE, NODEMANAGER
    :param service: Cluster Service - e.g. HDFS, YARN
    :param host_id: Host Cluster UUID
    :param hostname: Hostname for the Cluster Host
    :param rc: Role Count - Integer to increment role name when creating multiple roles for the same rcg/service
    :return:
    """
    role_name = service + '-' + rcg_roletype + '-%d' % (rc,)
    host_ref = cm_client.ApiHostRef(host_id=host_id, hostname=hostname)
    role_config_group_ref = cm_client.ApiRoleConfigGroupRef(rcg)
    service_ref = cm_client.ApiServiceRef(cluster_name=cluster_name, service_name=service)
    role_api_packet = [cm_client.ApiRole(name=role_name, type=rcg_roletype, host_ref=host_ref,
                                         role_config_group_ref=role_config_group_ref, service_ref=service_ref)]
    body = cm_client.ApiRoleList(role_api_packet)
    print('->Creating Role %s for %s\n' % (role_name, hostname))

    try:
        api_response = roles_resource_api_instance.create_roles(cluster_name, service, body=body)
        if debug == 'True':
            pprint(api_response)
    except ApiException as e:
        print('Exception when calling RolesResourceApi->create_roles: {}\n'.format(e))


def create_mgmt_roles(mgmt_rcg, mgmt_rcg_roletype, mgmt_host_id, mgmt_hostname, mrc):
    """
    Create Management Roles to associate with Management Services
    :param mgmt_rcg: Mgmt Role Config Group
    :param mgmt_rcg_roletype: Mgmt Role Config Group Type - e.g. ALERTMONITOR, REPORTSMANAGER, etc
    :param mgmt_host_id: Mgmt Host Cluster UUID
    :param mgmt_hostname: Hostname for the Mgmt Host
    :param mrc: Mgmt Role Count - Integer to increment role name when creating multiple roles for the same rcg/service
    :return:
    """
    role_name = 'MGMT-' + mgmt_rcg_roletype + '-%d' % (mrc,)
    host_ref = cm_client.ApiHostRef(host_id=mgmt_host_id, hostname=mgmt_hostname)
    role_config_group_ref = cm_client.ApiRoleConfigGroupRef(mgmt_rcg)
    service_ref = cm_client.ApiServiceRef(cluster_name=cluster_name, service_name='mgmt')
    mgmt_role_api_packet = [cm_client.ApiRole(name=role_name, type=mgmt_rcg_roletype, host_ref=host_ref,
                                              role_config_group_ref=role_config_group_ref, service_ref=service_ref)]
    body = cm_client.ApiRoleList(mgmt_role_api_packet)

    try:
        api_response = mgmt_roles_resource_api_instance.create_roles(body=body)
        if debug == 'True':
            pprint(api_response)
    except ApiException as e:
        print('Exception calling MgmtRolesResourceApi -> create_roles {}\n'.format(e))


def show_roles_full():
    for service in cluster_service_list:
        build_role_config_group_list(service)
        filter = ''
        view = 'summary'
        try:
            api_response = roles_resource_api_instance.read_roles(cluster_name, service, filter=filter, view=view)
            print('ROLES FOR %s' % service)
            pprint(api_response)
        except ApiException as e:
            print('Exception {}'.format(e))
        for rcg in role_config_group_list:
            print('%s - %s' % (service, rcg))


def search_hostlist(hostname):
    """
    Search cluster_host_list for a specific hostname - depends on list_hosts()
    :param hostname: Hostname to look for
    :return:
    """
    for x in range(0, len(cluster_host_list.items)):
        if hostname in cluster_host_list.items[x].hostname:
            print(cluster_host_list.items[x].hostname)
    else:
        pass


def lookup_host_uuid(hostname):
    """
    Search cluster_host_list for a specific hostname - depends on list_hosts()
    :param hostname: Hostname to return UUID for
    :return:
    """
    for x in range(0, len(cluster_host_list.items)):
        if hostname in cluster_host_list.items[x].hostname:
            print(cluster_host_list.items[x].host_id)
    else:
        pass


def cluster_action(action, *kwargs):
    """
    Execute a cluster action
    :param action: Action to execute
    :return:
    """
    if action == 'restart_command':
        body = cm_client.ApiRestartClusterArgs(restart_only_stale_services=0, redeploy_client_configuration=1)
        try:
            api_response = clusters_api_instance.restart_command(cluster_name, body=body)
            if debug == 'True':
                pprint(api_response)
        except ApiException as e:
            print('Exception running ClustersResourceApi->restart_command {}\n'.format(e))

    if action == 'restart_stale_command':
        body = cm_client.ApiRestartClusterArgs(restart_only_stale_services=1, redeploy_client_configuration=1)
        try:
            api_response = clusters_api_instance.restart_command(cluster_name, body=body)
            if debug == 'True':
                pprint(api_response)
        except ApiException as e:
            print('Exception running ClustersResourceApi->restart_command {}\n'.format(e))

    if action == 'rolling_restart':
        body = cm_client.ApiRollingRestartArgs(slave_batch_size=1, sleep_seconds=5, slave_fail_count_threshold=1,
                                               stale_configs_only=0)
        try:
            api_response = clusters_api_instance.rolling_restart(cluster_name, body=body)
            if debug == 'True':
                pprint(api_response)
        except ApiException as e:
            print('Exception running ClustersResourceApi->rolling_restart {}\n'.format(e))

    if action == 'mgmt_restart':
        try:
            api_response = mgmt_service_resource_api_instance.restart_command()
            if debug == 'True':
                pprint(api_response)
        except ApiException as e:
            print('Exception running MgmtServiceResourceApi->restart_command {}\n'.format(e))

    if action == 'first_run':
        try:
            api_response = services_resource_api_instance.first_run(cluster_name, str(kwargs))
            if debug == 'True':
                pprint(api_response)
        except ApiException as e:
            print('Exception running ServicesResourceApi->first_run {}\n'.format(e))


def build_api_role_list(role):
    """
    Build API Role Name List based on role
    :param role: Role to look up RCGs
    :return:
    """
    global api_role_name_list
    api_role_name_list = []
    rcg_name = 'mgmt-' + role + '-BASE'
    api_role_list = mgmt_role_config_groups_resource_api_instance.read_roles(rcg_name).items
    for list_item in api_role_list:
        api_role_name = list_item.name
        if debug == 'True':
            print('api_role_name : %s' % api_role_name)

        api_role_name_list.append(api_role_name)


def mgmt_role_commands(action):
    """
    Execute Management Role Command using MgmtRoleCommandsResourceApi
    :param action: Action to perform
    :param role: Role to perform action on
    :return:
    """

    if action == 'restart_command':
        for role in mgmt_roles_list:
            build_api_role_list(role)
            body = cm_client.ApiRoleNameList(api_role_name_list)
            try:
                api_response = mgmt_role_commands_resource_api_instance.restart_command(body=body)
                if debug == 'True':
                    pprint(api_response)
            except ApiException as e:
                print('Exception running MgmtRoleCommandsResourceApi->restart_command {}\n'.format(e))
            active_command = action + ' ' + role
            wait_for_active_mgmt_commands(active_command)

    if action == 'start_command':
        for role in mgmt_roles_list:
            build_api_role_list(role)
            body = cm_client.ApiRoleNameList(api_role_name_list)
            try:
                api_response = mgmt_role_commands_resource_api_instance.start_command(body=body)
                if debug == 'True':
                    pprint(api_response)
            except ApiException as e:
                print('Exception running MgmtRoleCommandsResourceApi->start_command {}\n'.format(e))
            active_command = action + ' ' + role
            wait_for_active_mgmt_commands(active_command)

    if action == 'stop_command':
        for role in mgmt_roles_list:
            build_api_role_list(role)
            body = cm_client.ApiRoleNameList(api_role_name_list)
            try:
                api_response = mgmt_role_commands_resource_api_instance.stop_command(body=body)
                if debug == 'True':
                    pprint(api_response)
            except ApiException as e:
                print('Exception running MgmtRoleCommandsResourceApi->stop_command {}\n'.format(e))
            active_command = action + ' ' + role
            wait_for_active_mgmt_commands(active_command)

    if action == 'jmap_dump':
        for role in mgmt_roles_list:
            build_api_role_list(role)
            body = cm_client.ApiRoleNameList(api_role_name_list)
            try:
                api_response = mgmt_role_commands_resource_api_instance.jmap_dump(body=body)
                if debug == 'True':
                    pprint(api_response)
            except ApiException as e:
                print('Exception running MgmtRoleCommandsResourceApi->jmap_dump {}\n'.format(e))
            active_command = action + ' ' + role
            wait_for_active_mgmt_commands(active_command)

    if action == 'jmap_histo':
        for role in mgmt_roles_list:
            build_api_role_list(role)
            body = cm_client.ApiRoleNameList(api_role_name_list)
            try:
                api_response = mgmt_role_commands_resource_api_instance.jmap_histo(body=body)
                if debug == 'True':
                    pprint(api_response)
            except ApiException as e:
                print('Exception running MgmtRoleCommandsResourceApi->jmap_history {}\n'.format(e))
            active_command = action + ' ' + role
            wait_for_active_mgmt_commands(active_command)

    if action == 'jstack':
        for role in mgmt_roles_list:
            build_api_role_list(role)
            body = cm_client.ApiRoleNameList(api_role_name_list)
            try:
                api_response = mgmt_role_commands_resource_api_instance.jstack(body=body)
                if debug == 'True':
                    pprint(api_response)
            except ApiException as e:
                print('Exception running MgmtRoleCommandsResourceApi->jstack {}\n'.format(e))
            active_command = action + ' ' + role
            wait_for_active_mgmt_commands(active_command)

    if action == 'lsof':
        for role in mgmt_roles_list:
            build_api_role_list(role)
            body = cm_client.ApiRoleNameList(api_role_name_list)
            try:
                api_response = mgmt_role_commands_resource_api_instance.lsof(body=body)
                if debug == 'True':
                    pprint(api_response)
            except ApiException as e:
                print('Exception running MgmtRoleCommandsResourceApi->lsof {}\n'.format(e))
            active_command = action + ' ' + role
            wait_for_active_mgmt_commands(active_command)


def mgmt_role_config_commands(action, *kwargs):
    """
    Management ROle Config commands using MgmtRoleConfigGroupsResourceApi
    Unused actions are passed here.
    :param action:
    :return:
    """
    if action == 'read_config':
        view = 'summary'
        try:
            api_response = mgmt_role_config_groups_resource_api_instance.read_config(role_config_group_name=str(kwargs),
                                                                                     view=view)
            pprint(api_response)
        except ApiException as e:
            print('Exception calling MgmtRoleConfigGroupsResourceApi->read_config \n'.format(e))

    if action == 'read_role_config_group':
        try:
            api_response = mgmt_role_config_groups_resource_api_instance.read_role_config_group(
                role_config_group_name=str(kwargs))
            pprint(api_response)
        except ApiException as e:
            print('Exception calling MgmtRoleConfigGroupsResourceApi->read_role_config_group \n'.format(e))

    if action == 'read_role_config_groups':
        try:
            api_response = mgmt_role_config_groups_resource_api_instance.read_role_config_groups()
            pprint(api_response)
        except ApiException as e:
            print('Exception calling MgmtRoleConfigGroupsResourceApi->read_role_config_groups \n'.format(e))

    if action == 'read_roles':
        try:
            api_response = mgmt_role_config_groups_resource_api_instance.read_roles(role_config_group_name=str(kwargs))
            pprint(api_response)
        except ApiException as e:
            print('Exception calling MgmtRoleConfigGroupsResourceApi->read_roles \n'.format(e))

    if action == 'update_config':
        pass

    if action == 'update_role_config_group':
        pass


def mgmt_service(action):
    """
    Start the Cloudera Management Services
    :param action: Execute action
    :return:
    """
    if action == 'start_command':
        try:
            api_response = mgmt_service_resource_api_instance.start_command()
            if debug == 'True':
                pprint(api_response)
        except ApiException as e:
            print('Exception calling MgmtServiceResourceApi -> start_command {}\n'.format(e))
        active_command = 'MGMT ' + action
        wait_for_active_mgmt_commands(active_command)

    if action == 'restart_command':
        try:
            api_response = mgmt_service_resource_api_instance.restart_command()
            if debug == 'True':
                pprint(api_response)
        except ApiException as e:
            print('Exception calling MgmtServiceResourceApi -> restart_command {}\n'.format(e))
        active_command = 'MGMT ' + action
        wait_for_active_mgmt_commands(active_command)

    if action == 'stop_command':
        try:
            api_response = mgmt_service_resource_api_instance.stop_command()
            if debug == 'True':
                pprint(api_response)
        except ApiException as e:
            print('Exception calling MgmtServiceResourceApi -> stop_command {}\n'.format(e))
        active_command = 'MGMT ' + action
        wait_for_active_mgmt_commands(active_command)

    if action == 'auto_assign_roles':
        try:
            api_response = mgmt_service_resource_api_instance.auto_assign_roles()
            if debug == 'True':
                pprint(api_response)
        except ApiException as e:
            print('Exception calling MgmtServiceResourceApi -> auto_assign_roles {}\n'.format(e))
        active_command = 'MGMT ' + action
        wait_for_active_mgmt_commands(active_command)

    if action == 'auto_configure_roles':
        try:
            api_response = mgmt_service_resource_api_instance.auto_configure()
            if debug == 'True':
                pprint(api_response)
        except ApiException as e:
            print('Exception calling MgmtServiceResourceApi -> auto_configure_roles {}\n'.format(e))
        active_command = 'MGMT ' + action
        wait_for_active_mgmt_commands(active_command)

    if action == 'delete_cms':
        try:
            api_response = mgmt_service_resource_api_instance.delete_cms()
            if debug == 'True':
                pprint(api_response)
        except ApiException as e:
            print('Exception calling MgmtServiceResourceApi -> delete_cms {}\n'.format(e))
        active_command = 'MGMT ' + action
        wait_for_active_mgmt_commands(active_command)

    if action == 'enter_maintenance_mode':
        try:
            api_response = mgmt_service_resource_api_instance.enter_maintenance_mode()
            if debug == 'True':
                pprint(api_response)
        except ApiException as e:
            print('Exception calling MgmtServiceResourceApi -> enter_maintenance_mode {}\n'.format(e))
        active_command = 'MGMT ' + action
        wait_for_active_mgmt_commands(active_command)

    if action == 'exit_maintenance_mode':
        try:
            api_response = mgmt_service_resource_api_instance.exit_maintenance_mode()
            if debug == 'True':
                pprint(api_response)
        except ApiException as e:
            print('Exception calling MgmtServiceResourceApi -> exit_maintenance_mode {}\n'.format(e))
        active_command = 'MGMT ' + action
        wait_for_active_mgmt_commands(active_command)

    if action == 'auto_configure_roles':
        try:
            api_response = mgmt_service_resource_api_instance.auto_configure()
            if debug == 'True':
                pprint(api_response)
        except ApiException as e:
            print('Exception calling MgmtServiceResourceApi -> auto_configure {}\n'.format(e))
        active_command = 'MGMT ' + action
        wait_for_active_mgmt_commands(active_command)


def discover_roles():
    """
    Discover and List Roles in a Cluster
    :return:
    """
    cluster_service_list = []
    services = cluster_services_api_instance.read_services(cluster_name, view='summary')
    x = 0
    for x in range(len(services.items)):
        cluster_service_list.append(services.items[x].name)
    show_roles_full(cluster_service_list)


def get_deployment_full():
    """
    Get Deployment for cluster
    :return:
    """
    try:
        api_response = cloudera_manager_resource_api.get_deployment2()
        pprint(api_response)
    except ApiException as e:
        print('Exception calling ClouderaManagerResourceApi->get_deployment2 {}\n'.format(e))


def check_cm_version():
    """
    Check to see if CM API is listening by trying to get version
    :return:
    """
    global success, cm_version
    try:
        api_response = cloudera_manager_resource_api.get_version()
        cm_version = pprint(api_response)
        success = 0
    except:
        success = 1


#
# END SECONDARY FUNCTIONS
#

def options_parser(args=None):
    """
    Parse command line options passed to the script
    :return:
    """
    global objects
    parser = argparse.ArgumentParser(prog='python deploy_on_oci.py', description='Deploy a Cloudera EDH v6 Cluster on '
                                                                                 'OCI using cm_client with Cloudera '
                                                                                 'Manager API')

    parser.add_argument('-m', '--cm_server', metavar='cm_server', required='True',
                      help='Cloudera Manager IP to connect to using cm_client')
    parser.add_argument('-i', '--input_host_list', metavar='host.fqdn', nargs='+', required='True',
                      help='List of Cluster Hosts (FQDN) to deploy')
    parser.add_argument('-d', '--disk_count', metavar='disk_count', required='True',
                      help='Number of disks attached to Worker Instances, used to calculate DFS configuration')
    parser.add_argument('-l', '--license_file', metavar='license_file',
                      help='Cloudera Manager License File Name')
    parser.add_argument('-w', '--worker_shape', metavar='worker_shape', required='True',
                      help='Shape of Worker Instances in the Cluster')

    options = parser.parse_args(args)
    return (options.cm_server, options.input_host_list, options.disk_count, options.license_file, options.worker_shape)


#
# MAIN FUNCTION FOR CLUSTER DEPLOYMENT
#

def main():
    parse_ssh_key()
    build_disk_lists()
    print('->Building API Endpoints\n')
    build_api_endpoints()
    try:
        api_response = users_api_instance.read_user2(user_name)
        if api_response.auth_roles:
            print('%s user exists...' % user_name)
            if debug == 'True':
                pprint(api_response)

    except ApiException as e:
        if debug == 'True':
            pprint(e)

        print('->Creating new admin user %s\n' % user_name)
        init_admin_user()
        build_api_endpoints()
        print('->Deleting default admin user\n')
        delete_default_admin_user()

    build_api_endpoints()
    print('->Initializing Cluster %s\n' % cluster_name)
    init_cluster()
    # if remotely_detect_hosts == 'Yes':
    #     remote_host_detection()
    #     build_cluster_host_list(host_fqdn_list)
    #     remote_worker_shape_detection()

    # else:
    #     build_host_list()
    #     build_cluster_host_list(host_fqdn_list)
    build_cluster_host_list(host_fqdn_list)
    read_cluster()
    install_hosts()
    active_command = 'Host Agents Installing'
    wait_for_active_cluster_commands(active_command)
    print('\n->Host Installation Complete')
    add_hosts_to_cluster()
    active_command = 'Hosts Adding to Cluster ' + cluster_name
    wait_for_active_cluster_commands(active_command)
    print('\n->Hosts added to Cluster %s\n' % cluster_name)
    print('->Updating Parcel Remote Repo: %s\n' % remote_parcel_url)
    update_parcel_repo(remote_parcel_url, parcel_distribution_rate)
    print('->Parcel Setup Running')
    dda_parcel('CDH')
    if debug == 'True':
        print('-->DEBUG - Reading Parcel Status\n')
        get_parcel_status('CDH')
    print('->Mapping Cluster Hostnames and Host IDs\n')
    cluster_host_id_map()
    print('->Reading DB Passwords\n')
    get_mgmt_db_passwords()
    print('->Creating Cluster Services: %s\n' % cluster_service_list)
    define_cluster_services(cluster_service_list)
    create_cluster_services(api_service_list)
    print('->Running Cluster Auto Configuration\n')
    auto_configure_cluster()
    print('->Updating Cluster Service Role Config Groups\n')
    update_cluster_rcg_configuration(cluster_service_list)
    if debug == 'True':
        print('-->DEBUG - Reading Cluster Services\n')
        read_cluster_services()
    print('->Setting up CMS\n')
    define_cms_mgmt_service()
    setup_cms()
    print('->Auto Configuring Management Roles\n')
    mgmt_service('auto_configure_roles')
    print('->Updating Management RCG\n')
    setup_mgmt_rcg(mgmt_roles_list)
    print('->Restart MGMT Service\n')
    mgmt_service('restart_command')
    wait_for_active_mgmt_commands('MGMT Service Restart')
    print('->Restart MGMT Roles\n')
    mgmt_role_commands(action='restart_command')
    # TODO - Need to refactor here if license is provided
    print('->Activating Trial License\n')
    begin_trial()
    print('->Executing first_run on Cluster - %s' % cluster_name)
    try:
        api_response = clusters_api_instance.first_run(cluster_name)
        if debug == 'True':
            pprint(api_response)
    except ApiException as e:
        print('Exception calling ClustersResourceApi -> first_run {}\n'.format(e))
    active_command = 'First Run on ' + cluster_name
    wait_for_active_cluster_commands(active_command)
    print('---> CLUSTER SETUP COMPLETE <---')
    deployment_seconds = time.time() - start_time
    print('SETUP TIME: %s ' % str(datetime.timedelta(seconds=deployment_seconds)))



#
# MAIN EXECUTION
#

if __name__ == '__main__':
    cm_server, host_fqdn_list, disk_count, license_file, worker_shape = options_parser(sys.argv[1:])
    if debug == 'True':
        print('cm_server = %s' % cm_server)
        print('input_host_list = %s' % host_fqdn_list)
        print('disk_count = %s' % disk_count)
        print('license_file = %s' % license_file)
        print('worker_shape = %s' % worker_shape)

    user_name = 'admin'
    password = 'admin'
    ready = 1
    active_command = 'Cloudera Manager Startup'
    wait_status = '*'
    while ready == 1:
        stdout.write('\r%s - Waiting: %s' % (active_command, wait_status))
        check_cm_version()
        if success == 0:
            stdout.write('\n')
            print('\nCloudera Manager Detected: %s' % cm_version)
            ready = 0
        else:
            sys.stdout.flush()
            time.sleep(30)
            wait_status = wait_status + '*'


    # main()






