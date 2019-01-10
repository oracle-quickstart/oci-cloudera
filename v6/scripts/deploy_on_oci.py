#!/usr/bin/env python 

from __future__ import print_function
import socket
import time
import sys
import cm_client
from cm_client import ApiUser2
from cm_client.rest import ApiException
from pprint import pprint
# import json
import re

#
# Set Global Parameters here
#

# These will be passed eventually
vmsize = 'VM.Standard2.16'  # type: str
disk_count = '3'  # type: int

# Enable Debug Output set this to 'True'
debug = 'False'  # type: str

# Define new admin username and password
user_name = 'cdhadmin'  # type: str
password = 'somepassword'  # type: str

# This will be passed as part of TF deployment (refactor for local exec, strip IP and then execute)
cm_server = '132.145.152.119'  # type: str

# Define cluster name
cluster_name = 'TestCluster'  # type: str
api_cluster_name = cm_client.ApiClusterRef(cluster_name, cluster_name)  # type: str

# Define Cloudera Version 6 to deploy
cluster_version = '6.1.0'  # type: str

# Define Remote Parcel URL & Distribution Rate
remote_parcel_url = 'https://archive.cloudera.com/cdh6/' + cluster_version + '/parcels'  # type: str
parcel_distribution_rate = "1024000"  # type: int

# Define SSH Keyfile for access to deploy on cluster hosts
# ssh_keyfile = '/home/opc/.ssh/id_rsa'  # type: str
ssh_keyfile = '/Users/zsmith/.ssh/id_rsa'  # type: str

# Cluster Services List
# Modify this list to pick which services to install
#
# cluster_service_list = ['SOLR', 'ACCUMULO_C6', 'ADLS_CONNECTOR', 'LUNA_KMS', 'HBASE', 'SENTRY', 'HIVE', 'KUDU', 
#                        'HUE', 'FLUME', 'SPARK_ON_YARN', 'THALES_KMS', 'HDFS', 'OOZIE', 'ISILON', 'SQOOP_CLIENT', 
#                        'KS_INDEXER', 'ZOOKEEPER', 'YARN', 'KMS', 'KEYTRUSTEE', 'KEYTRUSTEE_SERVER', 'KAFKA', 'IMPALA',
#                        'AWS_S3']

# MAXIMAL - NON KERBEROS
cluster_service_list = ['SOLR', 'ACCUMULO_C6', 'HBASE', 'HIVE', 'HUE', 'FLUME',
                        'SPARK_ON_YARN', 'HDFS', 'OOZIE', 'SQOOP_CLIENT', 'ZOOKEEPER',
                        'YARN', 'KAFKA', 'IMPALA']

# MINIMAL - NON KERBEROS
# cluster_service_list = ['HDFS', 'YARN', 'SOLR', 'ZOOKEEPER']

# Cluster Host Mapping
# Use define these variables to pattern match when building host lists to use for role and
# service mapping.  For example, if your worker nodes have "worker" in the hostname, set that here.   If you want your
# Cloudera manager on a specific host, set he host identifier here.   See the "cluster_host_id_map" function.

worker_hosts_contain = "worker"
namenode_host_contains = "master-1"
secondary_namenode_host_contains = "master-2"
cloudera_manager_host_contains = "utility"

# Specify Log directory on cluster hosts
LOG_DIR = '/log/cloudera'

#
# End Global
#


#
# OCI Shape Specific Tunings - Modify at your own discretion
#
def get_parameter_value(vmsize, parameter):
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
        "BM.Standard2.52:dfs_replication": "1",
        "BM.Standard1.36:yarn_nodemanager_resource_cpu_vcores": "128",
        "BM.Standard1.36:yarn_nodemanager_resource_memory_mb": "242688",
        "BM.Standard1.36:impalad_memory_limit": "122857142857",
        "BM.Standard1.36:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1896m -Xmx1896m",
        "BM.Standard1.36:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1896m -Xmx1896m",
        "BM.Standard1.36:dfs_replication": "1",
        "VM.Standard2.24:yarn_nodemanager_resource_cpu_vcores": "80",
        "VM.Standard2.24:yarn_nodemanager_resource_memory_mb": "308224",
        "VM.Standard2.24:impalad_memory_limit": "122857142857",
        "VM.Standard2.24:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms3853m -Xmx3853m",
        "VM.Standard2.24:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms3853m -Xmx3853m",
        "VM.Standard2.24:dfs_replication": "1",
        "VM.Standard2.16:yarn_nodemanager_resource_cpu_vcores": "48",
        "VM.Standard2.16:yarn_nodemanager_resource_memory_mb": "237568",
        "VM.Standard2.16:impalad_memory_limit": "42949672960",
        "VM.Standard2.16:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1984m -Xmx1984m",
        "VM.Standard2.16:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1984m -Xmx1984m",
        "VM.Standard2.16:dfs_replication": "1",
        "VM.Standard1.16:yarn_nodemanager_resource_cpu_vcores": "48",
        "VM.Standard1.16:yarn_nodemanager_resource_memory_mb": "95232",
        "VM.Standard1.16:impalad_memory_limit": "42949672960",
        "VM.Standard1.16:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1984m -Xmx1984m",
        "VM.Standard1.16:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms1984m -Xmx1984m",
        "VM.Standard1.16:dfs_replication": "1",
        "VM.Standard2.8:yarn_nodemanager_resource_cpu_vcores": "16",
        "VM.Standard2.8:yarn_nodemanager_resource_memory_mb": "114688",
        "VM.Standard2.8:impalad_memory_limit": "21500000000",
        "VM.Standard2.8:mapreduce_map_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2368m -Xmx2368m",
        "VM.Standard2.8:mapreduce_reduce_java_opts": "-Djava.net.preferIPv4Stack=true -Xms2368m -Xmx2368m",
        "VM.Standard2.8:dfs_replication": "1",
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
        "VM.Standard1.8:dfs_replication": "1"
    }
    return switcher.get(vmsize + ":" + parameter, "NOT FOUND")


#
# Main Functions Section
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
    port = '7180'
    api_version = 'v31'
    global api_url, api_client
    api_url = api_host + ':' + port + '/api/' + api_version
    if debug == 'True':
        print("->API URL: " + api_url)
    api_client = cm_client.ApiClient(api_url)
    global clusters_api_instance, users_api_instance, manager_api_instance, parcels_api_instance, parcel_api_instance, \
        cluster_services_api_instance, auth_roles_api_instance, roles_config_api_instance, all_hosts_api_instance, \
        roles_resource_api_instance, mgmt_service_resource_api_instance, services_resource_api_instance, \
        mgmt_role_commands_resource_api_instance, mgmt_role_config_groups_resource_api_instance
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


def wait_for_active_commands(active_command):
    """
    Wait until Cloudera Manager finishes running active_command
    :return:
    """
    view = 'summary'
    wait_status = '*'
    done = '0'

    while done == '0':
        try:
            api_response = manager_api_instance.list_active_commands(view=view)
            if not api_response.items:
                done = '1'
                break
            else:
                print('\r%s - Waiting: %s' % (active_command, wait_status))
                time.sleep(10)
                wait_status = wait_status + '*'
                sys.stdout.flush()
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
        if not api_response.items:
            pass
        else:
            print('Active Command Running : %s' % api_response.items)
            if debug == 'True':
                pprint(api_response)
    except ApiException as e:
        print('Exception when calling ClouderaManagerResourceApi->list_active_commands: {}\n'.format(e))


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


def build_host_list():
    """
    Create Host List for host management
    :return:
    """
    global host_fqdn_list
    host_fqdn_list = []
    # TODO
    # Replace the FQDN list from static object to a host detection function
    #
    host_fqdn_list = ['cdh-utility-1.public3.cdhvcn.oraclevcn.com', 'cdh-master-1.private3.cdhvcn.oraclevcn.com',
                      'cdh-master-2.private3.cdhvcn.oraclevcn.com', 'cdh-worker-1.private3.cdhvcn.oraclevcn.com',
                      'cdh-worker-2.private3.cdhvcn.oraclevcn.com', 'cdh-worker-3.private3.cdhvcn.oraclevcn.com']
    ###

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
            print("\rParcel %s progress %s: %s / %s" % (parcel_product, parcel.stage, parcel.state.progress,
                                                        parcel.state.total_progress))
            time.sleep(5)
            sys.stdout.flush()

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
    :return:
    """
    body = cm_client.ApiServiceList(api_service_list)

    try:
        api_response = cluster_services_api_instance.create_services(cluster_name, body=body)
        if debug == 'True':
            pprint(api_response)
    except ApiException as e:
        print('Exception when calling ServicesResourceApi->create_services: {}\n'.format(e))


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
        except ApiException as e:
            print('Exception updating %s - %s: \n%s' % (service, rcg, e))

    for service in cluster_service_list:
        build_role_config_group_list(service)
        message = 'Cluster Build Update'
        print('->Updating ' + service + ' Configuration\n')
        if service == 'HDFS':
            for rcg in role_config_group_list:
                print('->Updating RCG: %s\n' % rcg)
                if rcg == 'HDFS-NAMENODE-BASE':
                    rcg_roletype = 'NAMENODE'  # type: str
                    dfs_replication = [cm_client.ApiConfig(name='dfs_replication',
                                                           value=get_parameter_value(vmsize, 'dfs_replication'))]
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
                    rcg_roletype = 'DATANODE'  # type: str
                    dfs_replication = [cm_client.ApiConfig(name='dfs_replication',
                                                           value=get_parameter_value(vmsize, 'dfs_replication'))]
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
                    n = 0
                    if debug == 'True':
                        print('->DEBUG - Number of Workers: ' + str(len(worker_host_ids)))
                    for host_id in worker_host_ids:
                        create_role(rcg, rcg_roletype, service, host_id, worker_hostnames[n], (n + 1))
                        n = n + 1


                if rcg == 'HDFS-SECONDARYNAMENODE-BASE':
                    rcg_roletype = 'SECONDARYNAMENODE'  # type: str
                    dfs_replication = [cm_client.ApiConfig(name='dfs_replication_factor',
                                                           value=get_parameter_value(vmsize, 'dfs_replication'))]
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

                if rcg == 'HDFS-FAILOVERCONTROLLER-BASEx':
                    failover_controller_log_dir = [cm_client.ApiConfig(name='failover_controller_log_dir',
                                                                       value=LOG_DIR + '/hadoop-hdfs')]
                    push_rcg_config(failover_controller_log_dir)

                if rcg == 'HDFS-HTTPFS-BASE':
                    httpfs_log_dir = [cm_client.ApiConfig(name='httpfs_log_dir', value=LOG_DIR + '/hadoop-httpfs')]
                    push_rcg_config(httpfs_log_dir)

                if rcg == 'HDFS-GATEWAY-BASE':
                    dfs_client_use_trash = [cm_client.ApiConfig(name='dfs_client_use_trash', value='True')]
                    push_rcg_config(dfs_client_use_trash)

                if rcg == 'HDFS-BALANCER-BASE':
                    rcg_roletype = 'BALANCER'  # type: str
                    create_role(rcg, rcg_roletype, service, snn_host_id, snn_hostname, 1)

        if service == 'SOLR':
            for rcg in role_config_group_list:
                print('->Updating RCG: %s\n' % rcg)
                if rcg == 'SOLR-GATEWAY-BASE':
                    pass

                if rcg == 'SOLR-SOLR_SERVER-BASE':
                    rcg_roletype = 'SOLR_SERVER'
                    create_role(rcg, rcg_roletype, service, snn_host_id, snn_hostname, 1)

        if service == 'YARN':
            for rcg in role_config_group_list:
                print('->Updating RCG: %s\n' % rcg)
                if rcg == 'YARN-GATEWAY-BASE':
                    rcg_roletype = 'GATEWAY'  # type: str
                    mapred_submit_replication = [cm_client.ApiConfig(name='mapred_submit_replication', value='3')]
                    mapreduce_map_java_opts = \
                        [cm_client.ApiConfig(name='mapreduce_map_java_opts',
                                             value=get_parameter_value(vmsize, 'mapreduce_map_java_opts'))]
                    mapreduce_reduce_java_opts = \
                        [cm_client.ApiConfig(name='mapreduce_reduce_java_opts',
                                             value=get_parameter_value(vmsize, 'mapreduce_reduce_java_opts'))]
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
                    rcg_roletype = 'NODEMANAGER'  # type: str
                    yarn_nodemanager_heartbeat_interval_ms = \
                        [cm_client.ApiConfig(name='yarn_nodemanager_heartbeat_interval_ms', value='100')]
                    node_manager_java_heapsize = [cm_client.ApiConfig(name='node_manager_java_heapsize',
                                                                      value='2000000000')]
                    yarn_nodemanager_local_dirs = [cm_client.ApiConfig(name='yarn_nodemanager_local_dirs',
                                                                       value=yarn_data_dir_list)]
                    yarn_nodemanager_resource_cpu_vcores = \
                        [cm_client.ApiConfig(name='yarn_nodemanager_resource_cpu_vcores',
                                             value=get_parameter_value(vmsize, 'yarn_nodemanager_resource_cpu_vcores'))]
                    yarn_nodemanager_resource_memory_mb = \
                        [cm_client.ApiConfig(name='yarn_nodemanager_resource_memory_mb',
                                             value=get_parameter_value(vmsize, 'yarn_nodemanager_resource_memory_mb'))]
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
                print('->Updating RCG: %s\n' % rcg)
                if rcg == 'ZOOKEEPER-SERVER-BASE':
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
        # print('Service %s - Role Config Group Found: %s' % (service_name, role_name))
        role_config_group_list.append(rcg_name)


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

    try:
        api_response = roles_resource_api_instance.create_roles(cluster_name, service, body=body)
        if debug == 'True':
            pprint(api_response)
    except ApiException as e:
        print('Exception when calling RolesResourceApi->create_roles: {}\n'.format(e))


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


def mgmt_role_commands(action):
    """
    Execute Management Role Command using MgmtRoleCommandsResourceApi
    Unused commands are passed here
    :return:
    """
    if action == 'restart_command':
        try:
            api_response = mgmt_role_commands_resource_api_instance.restart_command()
            if debug == 'True':
                pprint(api_response)
        except ApiException as e:
            print('Exception running MgmtRoleCommandsResourceApi->restart_command {}\n'.format(e))

    if action == 'start_command':
        pass

    if action == 'stop_command':
        pass

    if action == 'jmap_dump':
        pass

    if action == 'jmap_histo':
        pass

    if action == 'jstack':
        pass

    if action == 'lsof':
        pass


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
            api_response = mgmt_role_config_groups_resource_api_instance.read_role_config_groups(
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



#
# END FUNCTIONS
#

#
# MAIN FUNCTION
#

def main():
    parse_ssh_key()
    build_disk_lists()
    print('->Creating new admin user %s\n' % user_name)
    init_admin_user()
    print('->Building API Endpoints\n')
    build_api_endpoints()
    print('->Deleting default admin user\n')
    delete_default_admin_user()
    print('->Initializing Cluster %s\n' % cluster_name)
    init_cluster()
    print('->Building Host List\n')
    build_host_list()
    read_cluster()
    install_hosts()
    active_command = 'Host Agents Installing'
    wait_for_active_commands(active_command)
    print('\n->Host Installation Complete')
    add_hosts_to_cluster()
    active_command = 'Hosts Adding to Cluster ' + cluster_name
    wait_for_active_commands(active_command)
    print('\n->Hosts added to Cluster %s\n' % cluster_name)
    print('->Updating Parcel Remote Repo: %s\n' % remote_parcel_url)
    update_parcel_repo(remote_parcel_url, parcel_distribution_rate)
    print('->Parcel Setup Running')
    dda_parcel('CDH')
    if debug == 'True':
        print('-->DEBUG - Reading Parcel Status\n')
        get_parcel_status('CDH')
    print('->Creating Cluster Services: %s\n' % cluster_service_list)
    define_cluster_services(cluster_service_list)
    create_cluster_services(api_service_list)
    auto_configure_cluster()
    cluster_host_id_map()
    update_cluster_rcg_configuration(cluster_service_list)
    if debug == 'True':
        print('-->DEBUG - Reading Cluster Services\n')
        read_cluster_services()


#
# MAIN EXECUTION
#

main()

#build_api_endpoints()

#show_roles_full()
#for service in cluster_service_list:
#    cluster_action(action='first_run')

# cluster_action('first_run', 'ZOOKEEPER')
# cluster_action(action='mgmt_restart')

#api_instance = cm_client.RoleConfigGroupsResourceApi(api_client)
#try:
#    api_response = api_instance.read_role_config_group(cluster_name, 'HDFS-DATANODE-BASE', 'HDFS')
#    pprint(api_response)
#except ApiException as e:
#    pprint(e)

# Config Deployment Test
#build_disk_lists()
#cluster_host_id_map()
#update_cluster_rcg_configuration(cluster_service_list)

# cluster_host_id_map()
# worker_count = len(worker_hostnames)
# or x in range(0, len(worker_hostnames)):
#    print(worker_hostnames[x])

# list_hosts()

# auto_configure_cluster()
# show_rcg_full()
# update_cluster_rcg_configuration(cluster_service_list)

# list_hosts()
# print(cluster_host_list.items[0])

# list_active_commands()

# auto_assign_roles()
# auto_configure_cluster()
# delete_parcel()
