#!/usr/bin/env python
#
# Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.
#
# Utility script to export user data from Oracle Big Data Service.
# This script exports Hive Metadata, Zeppelin Notebooks, Service Configuration and Version data
# to a tar file. 
#
# This must be run as root user on Ambari Host. Hive and Zeppelin Serivce must be in 
# stopped state, otherwise, script will exit.
#
# Usage - exportBDC.py <Config File>
#         Run this script on Ambari host as root user.
#

import json
import urllib2, base64
import os, tarfile, shutil, glob, socket, sys, subprocess
from contextlib import closing
import datetime, logging as log

if(len(sys.argv) < 2):
    log.basicConfig(format='%(asctime)s %(levelname)-8s %(message)s', stream=sys.stdout, level=log.INFO)
    log.error("Usage: exportBDC.py <Config File> [-v]")
    log.error("Run this script on Ambari host as root user.")
    log.error("Use -v for more detailed log")
    sys.exit(0)

if("-v" in sys.argv):
    log.basicConfig(format='%(asctime)s %(levelname)-8s %(message)s', stream=sys.stdout, level=log.DEBUG)
else:
    log.basicConfig(format='%(asctime)s %(levelname)-8s %(message)s', stream=sys.stdout, level=log.INFO)

ambari_ip = socket.gethostname()
config_path = sys.argv[1]

FNULL = open(os.devnull, 'w')
# FNULL = subprocess.STDOUT # This helps in debugging hive export issue

ambari_port = '8080'
ambari_url = 'https://' + ambari_ip + ':' + ambari_port + '/api/v1/clusters/'

config_json = json.loads("{}")
output_path = ""
cluster_name = ""
services = []
components = {}
temp_config_tars = ""
temp_extract_path = ""
final_tarball = ""


def readConfig():
    global config_json
    if os.path.exists(config_path):
        with open(config_path) as data_file:
            config_json = json.load(data_file)
    else:
        log.error("Config file, " + config_path + " not found...")
        sys.exit(0)


def loadConfig():
    global output_path, cluster_name, temp_extract_path, final_tarball, services

    output_path = config_json["export_dir"]
    os.system('mkdir -p ' + output_path)

    cluster_name = getClusterName()
    log.debug("Cluster Name - " + cluster_name)
    temp_extract_path = output_path + "/" + cluster_name
    if(os.path.exists(temp_extract_path)):
        shutil.rmtree(temp_extract_path)
    os.mkdir(temp_extract_path)

    now = datetime.datetime.now()
    timestamp = now.strftime('%d_%b_%Y_%H_%M_%S')
    final_tarball = """%s/export_%s_%s.tar.gz"""%(output_path, cluster_name, timestamp)
    services = getServices()
    log.debug("List of services found in the cluster - " + ','.join(map(str, services)))

    log.info("Exporting Oracle Big Data Cloud Service : " + cluster_name)
    log.info("This may take a few minutes to complete.\n")

def ambariApiRes(url):
    base64string = base64.encodestring('%s:%s' % (config_json["ambari_username"], config_json["ambari_password"])).replace('\n', '')
    req = urllib2.Request(url)
    req.add_header('X-Requested-By', 'ambari')
    req.add_header("Authorization", "Basic %s" % base64string)

    try:
        response = urllib2.urlopen(req).read()
    except urllib2.HTTPError, e:
        log.debug("Ambari Rest Api failed for - " + url)
        response = "{}"

    responseJson = json.loads(response)
    return responseJson


def isServiceStopped(service_name):
    url = """%s%s/services/%s?fields=ServiceInfo/state"""%(ambari_url, cluster_name, service_name)

    log.debug("""Url to check the status of service, %s - %s"""%(service_name, url))

    base64string = base64.encodestring('%s:%s' % (config_json["ambari_username"], config_json["ambari_password"])).replace('\n', '')
    req = urllib2.Request(url)
    req.add_header('X-Requested-By', 'ambari')
    req.add_header("Authorization", "Basic %s" % base64string)

    response = urllib2.urlopen(req).read()
    responseJson = json.loads(response)

    if(responseJson["ServiceInfo"]["state"] == "INSTALLED"):
        return True
    else:
        return False


def preCheck():
    servicesToBeChecked = ["HIVE", "ZEPPELIN"]

    log.debug("Performing ")
    for service in servicesToBeChecked:
        # Checking if a service is stopped
        if not (isServiceStopped(service)):
            log.error("""%s service is not in stopped state in Ambari. Please stop it using Ambari and rerun"""%(service))
            sys.exit(0)


def ambari_config_download(url):
    # log.info("Config url  ---  " + url)
    base64string = base64.encodestring('%s:%s' % (config_json["ambari_username"], config_json["ambari_password"])).replace('\n', '')
    req = urllib2.Request(url)
    req.add_header('X-Requested-By', 'ambari')
    req.add_header("Authorization", "Basic %s" % base64string)

    try:
        # response = urllib2.urlopen(req, context=ctx)
        response = urllib2.urlopen(req)
    except urllib2.HTTPError, e:
        response = None

    return response


def getClusterName():
    url = ambari_url
    responseJson = ambariApiRes(url)

    return responseJson["items"][0]['Clusters']['cluster_name']


def getServices():
    url = ambari_url + cluster_name + '/services'
    responseJson = ambariApiRes(url)
    for item in responseJson['items']:
        services.append(item['ServiceInfo']['service_name'])
    return services


def populateComponents():
    for service in services:
        # log.info("Getting components for service, " + service)
        url = ambari_url + cluster_name + '/services/' + service + '/components'
        responseJson = ambariApiRes(url)
        for item in responseJson["items"]:
            if components.has_key(service):
                components[service].append(item["ServiceComponentInfo"]["component_name"])
            else:
                components[service] = []
                components[service].append(item["ServiceComponentInfo"]["component_name"])
    return components


def downloadFile(fileName, resp):
    with open(fileName, "w") as local_file:
        local_file.write(resp.read())


def getConfigs():
    global temp_config_tars
    # Cleaning up before downloading the configs
    # log.info("Cleaning up before downloading the configs...")
    temp_config_tars = output_path + "/config_tars/"
    if (os.path.isdir(temp_config_tars)):
        shutil.rmtree(temp_config_tars)
    os.mkdir(temp_config_tars)

    for service in components:
        for component in components[service]:
            # log.info("Getting config for service, " + service + " & component, " + component)
            url = ambari_url + cluster_name + '/services/' + service + '/components/' + component + "?format=client_config_tar"
            resp = ambari_config_download(url)
            fileName = temp_config_tars + "/" + component + "-configs.tar.gz"
            if(resp != None):
                downloadFile(fileName, resp)
                log.debug("Configuration is downloaded to " + fileName + " ...")
            else:
                log.debug("No config found for service, " + service + " & component, " + component)


def prepareForPackaging():
    temp_configs_path = temp_extract_path + "/" + "config"
    if(os.path.exists(temp_configs_path)):
        shutil.rmtree(temp_configs_path)
    os.mkdir(temp_configs_path)
    for file in glob.glob(temp_config_tars + "/*.tar.gz"):
        name = os.path.basename(file).split("-configs.tar.gz")[0]
        tf = tarfile.open(file)
        tf.extractall(path=temp_configs_path + "/" + name)
        tf.close()
    # Delete the temp config tars directory
    if(os.path.exists(temp_config_tars)):
        shutil.rmtree(temp_config_tars)


def package():
    log.debug("Creating the target tarball, " + final_tarball)
    with closing(tarfile.open(final_tarball, "w:gz")) as tar:
        tar.add(temp_extract_path, arcname='.')


def cleanup():
    log.debug("Perform final cleanup...")
    shutil.rmtree(temp_extract_path)


def backupHDPConfigs():
    log.info("")
    printDottedLine()
    log.info("Configuration")
    printDottedLine()
    log.info("Exporting Service Configuration data ....")
    populateComponents()
    getConfigs()
    prepareForPackaging()
    log.info("Completed exporting Exporting Service Configuration data.")


def getVersions():
    log.info("")
    printDottedLine()
    log.info("Stack component versions")
    printDottedLine()
    log.info("Exporting stack component versions....")
    services_list = ",".join(services)
    versions = ""
    version_file_path = temp_extract_path + "/stack"
    version_file = version_file_path + "/StackVersions.txt"
    if(os.path.isdir(version_file_path)):
        shutil.rmtree(version_file_path)
    os.mkdir(version_file_path)
    temp_file = temp_extract_path + "/StackVersions_temp"

    command=""" curl -o %s -u %s:%s -1 -s -k  'https://%s:%s/api/v1/stacks/HDP/versions/2.4/services?StackServices/service_name.in(%s)&fields=StackServices/*' """%(temp_file, config_json["ambari_username"], config_json["ambari_password"], ambari_ip,ambari_port, services_list)
    log.debug("Generated command to get the stack versions, " + command)
    subprocess.call(command, shell=True)

    f = open(temp_file, "r")
    res = f.read()

    responseJson = json.loads(res)
    for service in responseJson["items"]:
        versions = versions + service["StackServices"]["service_name"] + " : " + service["StackServices"]["service_version"] + "\n"

    f = open(version_file, "w")
    f.write(versions)
    log.debug("Cleaning temporary files created for Stack component versions Export...")
    if(os.path.exists(temp_file)):
        os.remove(temp_file)
    log.info("Completed exporting stack component versions.")


def backupZeppelinNotes():
    log.info("")
    printDottedLine()
    log.info("Zeppelin Notebooks")
    printDottedLine()
    log.info("Exporting Zeppelin Notebooks....")
    temp_zeppelin_notes = temp_extract_path + "/zeppelin/notebook"
    if (os.path.isdir(temp_zeppelin_notes)):
        shutil.rmtree(temp_zeppelin_notes)
    # The command below creates Zeppelin_Notebooks in hdfs home directory
    if (os.path.isdir("/var/lib/hadoop-hdfs/notebook")):
        shutil.rmtree("/var/lib/hadoop-hdfs/notebook")

    log.debug("Taking the zeppelin notebooks from hdfs://user/zeppelin/notebook notebook")
    command = "su - hdfs -c 'hdfs dfs -copyToLocal /user/zeppelin/notebook notebook'"
    subprocess.call(command, shell=True)

    log.debug("Cleaning temporary files created for Zeppelin Notebook Export...")
    shutil.copytree("/var/lib/hadoop-hdfs/notebook", temp_zeppelin_notes)
    shutil.rmtree("/var/lib/hadoop-hdfs/notebook")
    log.info("Completed exporting Zeppelin Notebooks.")


def getHiveMetaDBName():
    lookup = "ambari.hive.db.schema.name"
    url = """%s%s/configurations/service_config_versions?service_name=HIVE"""%(ambari_url, cluster_name)
    log.debug("Url to get the hive metastore db name - " + url)

    try:
        response_json = ambariApiRes(url)
        for config in response_json["items"]:
            if (config["is_current"] == True):
                for configuration in config["configurations"]:
                    if lookup in configuration["properties"]:
                        log.debug("Hive metastore DBName is - " + configuration["properties"][lookup])
                        return configuration["properties"][lookup]
    except:
        log.error("Failed to get hive metastore db name from Ambari. hive is the default metastore db name")
        # On failing to find return hive as default
        return "hive"


def backupHiveMetadata():
    log.info("")
    printDottedLine()
    log.info("Hive metadata")
    printDottedLine()
    log.info("Exporting Hive metadata....")

    hive_metastore_db = getHiveMetaDBName()

    if (os.path.isdir(temp_extract_path + "/hive_metadata")):
        shutil.rmtree(temp_extract_path + "/hive_metadata")
    os.mkdir(temp_extract_path + "/hive_metadata")
    temp_extract_hive_file = temp_extract_path + "/hive_metadata/hive_metadata_dump.sql"
    command="""mysqldump %s > %s"""%(hive_metastore_db, temp_extract_hive_file)
    subprocess.call(command, shell=True)

    log.info("Completed exporting Hive metadata.")

def printDottedLine():
    log.info("-------------------------------------------------------")


log.info("")
printDottedLine()
log.info("Utility to export metadata from Big Data Cloud Service")
printDottedLine()
log.info("")

readConfig()
loadConfig()

preCheck()

backupHDPConfigs()
backupZeppelinNotes()
backupHiveMetadata()
getVersions()

package()
cleanup()
log.info("")
log.info("")
log.info("""Completed export from Oracle Big Data Cloud Service : %s to %s."""%(cluster_name, final_tarball))
