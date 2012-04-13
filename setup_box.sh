#!/bin/bash -e

#
# EarnstoneUtils: Earnstone Utilities.
# 
# Copyright 2010 Corey Hulen, Earnstone Corporation
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License. 
#

# IF NO ARGUMENTS WERE PROVIDED
function USAGE ()
{
    echo ""
    echo "USAGE: "
    echo "    setup_box.sh [-?pazs] actionscript"
    echo ""
    echo "OPTIONS:"
    echo "    -p  the name of your .pem key without the .pem entension"
    echo "    -a  the amazon AMI id to launch the instance with"
    echo "    -z  the amazon availability-zone"
    echo "    -s  the size of the EBS and epherimal volume"
    echo "    -?  this usage information"
    echo ""
    echo "    actionscript is the .sh script that will be uploaded and"
    echo "       run on the server."
    echo ""
    echo "EXAMPLE:"    
    echo "    setup_box.sh -p my_pem_key_file -z us-east-1c -s 40"
    echo ""
    echo ""
    exit $E_OPTERROR    # Exit and explain usage, if no argument(s) given.
}

# LAUNCH EC2 INSTANCE AND ATTACH STORAGE
function LAUNCH_BOX () 
{    
    # create the instance and capture the instance id
    echo "Launching instance..."
    instanceid=$(ec2-run-instances --key $pemkeypair --availability-zone $avzone $ami | egrep ^INSTANCE | cut -f2)
    if [ -z "$instanceid" ]; then
        echo "ERROR: could not create instance";
        exit;
    else
        echo "Launched with instanceid=$instanceid"
    fi    

    if [ -n "$ebssize" ]; then
        echo "Creating EBS volume instance..."
        volid=$(ec2-create-volume --availability-zone $avzone -s $ebssize | egrep ^VOLUME | cut -f2)    
        if [ -z "$instanceid" ]; then
            echo "ERROR: could nt create EBS volume";
            exit;
        else
            echo "Created volume with volid=$volid"
        fi
    fi

    # wait for the instance to be fully operational
    echo -n "Waiting for instance to start running..." 
    while host=$(ec2-describe-instances "$instanceid" | egrep ^INSTANCE | cut -f4) && test -z $host; do echo -n .; sleep 1; done
    echo ""
    echo "Running with host=$host"

    echo -n "Verifying ssh connection to box..."
    while ssh -o StrictHostKeyChecking=no -q -i $EC2_HOME/id_rsa-$pemkey ubuntu@$host true && test; do echo -n .; sleep 1; done
    echo ""

    echo "Sleeping for 3s before accessing server"
    sleep 3

    if [ -n "$ebssize" ]; then
        echo "Attaching EBS $volid to $instanceid"
        attached=$(ec2-attach-volume -d /dev/sdh -i $instanceid $volid)
    fi
}

# VERIFY AND PROCESS CMD LINE ARGS
function VERIFY_CMD_LINE() {       
    if [ -z "$pemkey" ]; then
        if [ -z "$EC2_DEFAULT_PEM" ]; then
            echo "ERROR: -p pem argument must be set. See help -?";
            exit;
        else
            pemkey=$EC2_DEFAULT_PEM
        fi
    fi

    pemkeypairfile=${pemkey##*/}
    pemkeypair=${pemkeypairfile%%.*}    

    if [ -z "$ami" ]; then
        echo "WARN: -a ami unset defaulted to ubuntu oneiric amd64 'ami-8baa73e2'";
        ami="ami-8baa73e2";
    fi

    if [ -z "$avzone" ]; then
        echo "WARN: -z zone unset defaulted to 'us-east-1c'";
        avzone="us-east-1c";
    fi

    if [ -z "$ebssize" ]; then
        echo "WARN: -s size unset defaulted to no EBS storage being attached.";
    fi

    if [ -z "$actionscript" ]; then
        echo "WARN: No action script was specified.";
    fi
}

JAVA_HOME=${JAVA_HOME:?JAVA_HOME is not set}
EC2_HOME=${EC2_HOME:?EC2_HOME is not set}
EC2_PRIVATE_KEY=${EC2_PRIVATE_KEY:?EC2_PRIVATE_KEY is not set}
EC2_CERT=${EC2_CERT:?EC2_CERT is not set}

#PROCESS ARGS
while getopts ":p:a:z:s:?" Option
do
    case $Option in
        p    ) pemkey=$OPTARG;;
        a    ) ami=$OPTARG;;
        z    ) avzone=$OPTARG;;
        s    ) ebssize=$OPTARG;;
        ?    ) USAGE
               exit 0;;
        *    ) echo ""
               echo "Unimplemented option chosen."
               USAGE   # DEFAULT
    esac
done

shift $(($OPTIND - 1))

actionscript=$1;
datafile=$2;

VERIFY_CMD_LINE;
LAUNCH_BOX;

if [ -n "$datafile" ]; then
    echo "uploading $datafile data file..."
    scp -o StrictHostKeyChecking=no -i $pemkey $datafile ubuntu@$host:~	
fi


if [ -n "$actionscript" ]; then
    echo "uploading $actionscript script..."
    scp -o StrictHostKeyChecking=no -i $pemkey $actionscript ubuntu@$host:~	

    echo "connecting and running $actionscript script..."
    ssh -o StrictHostKeyChecking=no -i $pemkey ubuntu@$host "chmod u+x ./$actionscript"
    ssh -o StrictHostKeyChecking=no -i $pemkey ubuntu@$host "./$actionscript"	

    echo "rebooting instance..."
    ec2-reboot-instances $instanceid
    sleep 7

    echo -n "waiting for ssh connection to start..."
    while ssh -o StrictHostKeyChecking=no -q -i $pemkey ubuntu@$host true && test; do echo -n .; sleep 1; done
    echo ""

    echo "sleeping for 3s before accessing server..."
    sleep 3

    echo "Connection to host $host..."
    ssh -o StrictHostKeyChecking=no -q -i $pemkey ubuntu@$host
fi



