#!/bin/bash

# Basic monitoring for XEN on Pandora FMS
# This local plugin requires access to xentop, and xm tool
export LANG=POSIX

function pandora_module () {

	NAME=$1
	DATA=$2
	TYPE=$3
	DESCRIPTION=$4
	UNIT=$5

	echo "<module>"
	echo "<name>$NAME</name>"
	echo "<type>$TYPE</type>"
	echo "<data>$DATA</data>"
	echo "<description>$DESCRIPTION</description>"
	if [ "$UNIT" != "" ]
	then
		echo "<unit>$UNIT</unit>"
	fi
	echo "</module>"
}

#Definition section
STANDALONEMODE=false	#If in standalone mode, the agents will be created in separated agents.
			#False by default unless specified by the -s parameter
TMP_DIR="/tmp/xen"
PANDORA_SERVER_IP="192.168.60.4" #Only used if STANDALONEMODE mode is true
TIMESTAMP=`date +%s`

while getopts "sh" option; do
	case "$option" in
		h) echo "usage: $0 [-h] [-s]"
		   echo ""
		   echo "Parameters:"
		   echo " -s: Use it for creating the virtual machines in different agents"
		   echo " -h: Print this help and exit"
		   echo ""
       		   exit 1
       		   ;;
		s) STANDALONEMODE=true
		   ;;
		?) echo "usage: $0 [-h] [-s]"
                   echo ""
                   echo "Parameters:"
                   echo " -s: Use it for creating the virtual machines in different agents"
                   echo " -h: Print this help and exit"
                   echo ""
       		   exit -1
       		   ;;
	esac
done


#Checking section

if [ $STANDALONEMODE==true ] && [ "$PANDORA_SERVER_IP" == "" ]
then
	pandora_module "Xen_log" "The PANDORA_SERVER_IP is empty. Abort" "async_string" "XEN's agent plugin execution" ""
	exit -1
fi

if [ ! -e /usr/sbin/xentop ] && [ ! -e /sbin/xentop ] 
then
	pandora_module "Xen_log" "xentop doesnt exists. Abort" "async_string" "XEN's agent plugin execution" ""
	exit -1
fi

if [ ! -e /usr/sbin/xm ] && [ ! -e /sbin/xm ] 
then
	pandora_module "Xen_log" "xm doesnt exists. Abort" "async_string" "XEN's agent plugin execution" ""
	exit -1
fi

if [ ! -e /usr/bin/virsh ] && [ ! -e /bin/virsh ] 
then
	pandora_module "Xen_log" "virsh doesnt exists. Abort" "async_string" "XEN's agent plugin execution" ""
	exit -1
fi

if [ ! -e /usr/bin/tentacle_client ]
then
	pandora_module "Xen_log" "tentacle_client doesnt exists. Abort" "async_string" "XEN's agent plugin execution" ""
        exit -1
fi


xentop -f -b -i 3 > /tmp/xen_pandora.tmp
LINES=`cat /tmp/xen_pandora.tmp | wc -l`

# How many lines I need to get
ITEMS=`expr $LINES / 3`
ITEMS=`expr $ITEMS - 1`

# Get last items from top output
tail -$ITEMS /tmp/xen_pandora.tmp > /tmp/xen_pandora.top

# Get list of domains in the server
xm list | grep -v VCPUs | awk '{ print $1}' > /tmp/xen_pandora.domains

# For EACH domain:
for a in `cat /tmp/xen_pandora.domains`
do

	# Get status

	STATUS=`virsh dominfo $a | grep State | awk '{ print $2$3 }'`
	
	if [ "$STATUS" == "shutoff" ]
	then
		ST=0
                CPU=0
                MEM=0
                VCPU=0
                NET_TX=0
                NET_RX=0
                DISK_RD=0
                DISK_WR=0

	fi
	if [ "$STATUS" != "shutoff" ] && [ "$a" != "Domain-0" ]
	then
		ST=1
		# Get CPU %
                CPU=`cat /tmp/xen_pandora.top | grep "$a" | awk '{ print $4 }'`
                # Get MEM %
                MEM=`cat /tmp/xen_pandora.top | grep "$a" | awk '{ print $6 }'`
		# Get VCPU's
                VCPU=`cat /tmp/xen_pandora.top | grep "$a" | awk '{ print $9}'`

                # Get NET_TX
                NET_TX=`cat /tmp/xen_pandora.top | grep "$a" | awk '{ print $11 }'`

                # Get NET_RX
                NET_RX=`cat /tmp/xen_pandora.top | grep "$a" | awk '{ print $12 }'`

                # Get DISK_RD
                DISK_RD=`cat /tmp/xen_pandora.top | grep "$a" | awk '{ print $15 }'`

                # Get DISK_WR
                DISK_WR=`cat /tmp/xen_pandora.top | grep "$a" | awk '{ print $16 }'`	
	fi
	if [ "$STATUS" != "shutoff" ] && [ "$a" == "Domain-0" ]
        then
                ST=1
                # Get CPU %
                CPU=`cat /tmp/xen_pandora.top | grep "$a" | awk '{ print $4 }'`
                # Get MEM %
                MEM=`cat /tmp/xen_pandora.top | grep "$a" | awk '{ print $6 }'`
                # Get VCPU's
                VCPU=`cat /tmp/xen_pandora.top | grep "$a" | awk '{ print $10}'`

                # Get NET_TX
                NET_TX=`cat /tmp/xen_pandora.top | grep "$a" | awk '{ print $12 }'`

                # Get NET_RX
                NET_RX=`cat /tmp/xen_pandora.top | grep "$a" | awk '{ print $13 }'`

                # Get DISK_RD
                DISK_RD=`cat /tmp/xen_pandora.top | grep "$a" | awk '{ print $14 }'`

                # Get DISK_WR
                DISK_WR=`cat /tmp/xen_pandora.top | grep "$a" | awk '{ print $15 }'`
        fi

	#In normal mode, the VM's will be created inside the agent that executes this agent plugin
	if [ $STANDALONEMODE == false ]; then
                pandora_module Xen_${a}_Status "$ST" "generic_proc" "$STATUS" ""
                pandora_module Xen_${a}_CPU $CPU "generic_data" "CPU usage (%)" "%"
                pandora_module Xen_${a}_MEM $MEM "generic_data" "Memory usage (%)" "%"
                pandora_module Xen_${a}_VCPU $VCPU "generic_data" "Number of virtual CPU's" ""
                pandora_module Xen_${a}_NET_TX $NET_TX "generic_data" "Transmited kilobytes" "kB"
                pandora_module Xen_${a}_NET_RX $NET_RX "generic_data" "Received kilobytes" "kB"
                pandora_module Xen_${a}_DISK_RD $DISK_RD "generic_data" "Number of read requests" "requests"
                pandora_module Xen_${a}_DISK_WR $DISK_WR "generic_data" "Number of write requests" "requests"
        else
                echo "<?xml version='1.0' encoding='UTF-8'?>" >> $TMP_DIR/${a}.$TIMESTAMP.data
                echo "<agent_data os_name='Other' interval='300' timestamp='`date +\"%y/%m/%d %H:%M:%S\"`' agent_name='$a'>" >> $TMP_DIR/${a}.$TIMESTAMP.data
                pandora_module Xen_${a}_Status "$ST" "generic_proc" "$STATUS" "" >> $TMP_DIR/${a}.$TIMESTAMP.data
                pandora_module Xen_${a}_CPU $CPU "generic_data" "CPU usage (%)" "%" >> $TMP_DIR/${a}.$TIMESTAMP.data
                pandora_module Xen_${a}_MEM $MEM "generic_data" "Memory usage (%)" "%" >> $TMP_DIR/${a}.$TIMESTAMP.data
                pandora_module Xen_${a}_VCPU $VCPU "generic_data" "Number of virtual CPU's" "" >> $TMP_DIR/${a}.$TIMESTAMP.data
                pandora_module Xen_${a}_NET_TX $NET_TX "generic_data" "Transmited kilobytes" "kB" >> $TMP_DIR/${a}.$TIMESTAMP.data
                pandora_module Xen_${a}_NET_RX $NET_RX "generic_data" "Received kilobytes" "kB" >> $TMP_DIR/${a}.$TIMESTAMP.data
                pandora_module Xen_${a}_DISK_RD $DISK_RD "generic_data" "Number of read requests" "requests" >> $TMP_DIR/${a}.$TIMESTAMP.data
                pandora_module Xen_${a}_DISK_WR $DISK_WR "generic_data" "Number of write requests" "requests" >> $TMP_DIR/${a}.$TIMESTAMP.data
                echo "</agent_data>" >> $TMP_DIR/${a}.$TIMESTAMP.data
        fi


done

#If we are in standalone mode, we send the VM's data using Tentacle protocol to Pandora's Server
#TODO Implement some advanced options for Tentacle transfer. More information at http://www.openideas.info/wiki/index.php?title=Tentacle
if [ $STANDALONEMODE == true ]
then
	str=""
	for a in `cat /tmp/xen_pandora.domains`
	do
		str="$str $TMP_DIR/$a.$TIMESTAMP.data"
	done

	tentacle_client -a $PANDORA_SERVER_IP $str

	#Clean up the mess
	rm -f $TMP_DIR/*.data
fi

rm /tmp/xen_pandora.top
rm /tmp/xen_pandora.domains
rm /tmp/xen_pandora.tmp

