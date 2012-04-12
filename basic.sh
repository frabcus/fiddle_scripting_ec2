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
 
export DEBIAN_FRONTEND=noninteractive


#echo "deb http://us.ec2.archive.ubuntu.com/ubuntu/ karmic multiverse" | sudo -E tee -a /etc/apt/sources.list
#echo "deb-src http://us.ec2.archive.ubuntu.com/ubuntu/ karmic multiverse" | sudo -E tee -a /etc/apt/sources.list	
#echo "deb http://us.ec2.archive.ubuntu.com/ubuntu/ karmic-updates multiverse" | sudo -E tee -a /etc/apt/sources.list
#echo "deb-src http://us.ec2.archive.ubuntu.com/ubuntu/ karmic-updates multiverse" | sudo -E tee -a /etc/apt/sources.list

 
# run an update and upgarde
sudo -E apt-get update	-y	
sudo -E apt-get upgrade -y


# Install munin node to monitor this instance
sudo -E apt-get install -y munin-node
# Replace the Munin cpu plugin with one that recognizes "steal" CPU cycles
#sudo -E curl -o /usr/share/munin/plugins/cpu https://anvilon.s3.amazonaws.com/web/20081117-munin/cpu
#sudo -E curl -o /usr/share/munin/plugins/plugin.sh https://anvilon.s3.amazonaws.com/web/20081117-munin/plugin.sh
#sudo -E /etc/init.d/munin-node restart

	
#install the ntp time server
sudo -E apt-get install -y ntp


# configure and mount the EBS drive if one was created.
#if [ -e /dev/sdh ]; then
#    sudo -E apt-get install -y xfsprogs
#    sudo -E mkfs.xfs /dev/sdh
#    echo "/dev/sdh /backupvol xfs noatime 0 0" | sudo -E tee -a /etc/fstab
#    sudo -E mkdir -m 000 /backupvol
#    sudo -E mount /backupvol    
#fi


