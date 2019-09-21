#!/bin/bash

## functions
initPath () {
	let localhost=$1+11310
	source $(pwd)/devel/setup.bash
	cd src/Firmware
	source Tools/setup_gazebo.bash $(pwd) $(pwd)/build/px4_sitl_default
	export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:$(pwd)
	export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:$(pwd)/Tools/sitl_gazebo
	export ROS_MASTER_URI=http://localhost:$localhost
	export GAZEBO_MASTER_URI=http://localhost:11460
	sudo route add -net 224.0.0.0 netmask 224.0.0.0 wlp2s0
	cd ../..
	export | grep localhost | awk '{print $3}'
}


killSync () {
	processID=`ps -ax | grep [m]aster_sync_add"$1".launch | awk '{print $1}'`
	kill -2 $processID
}

launchGroundStation () {
	roslaunch master_discovery_fkie master_discovery_arg.launch rpc_port:=11610 & 
	sleep 10s
	roslaunch master_sync_fkie master_sync_gs.launch &
	sleep 5s
	roslaunch px4 only_gazebo.launch &
}

addUav () {
	id=$1

	roslaunch master_discovery_fkie master_discovery_arg.launch rpc_port:=$(($id+11610)) & 
	sleep 10s
	roslaunch master_sync_fkie master_sync_add"$id".launch &
	sleep 5s
	roslaunch px4 add_uav"$id".launch &
	sleep 10s
}

startRunner() {
	initPath $1
	roslaunch high_level_control simple_run.launch hostname:=uav"$1" id:="$1" &
}

startSim () {
	## args
	if [ "$#" != 1 ];	
	then
		echo "false number of arguments given:"
		echo "give the number of UAV's, and their rosmaster localhost will be (11310+id)."
		echo "exiting."
		return
	fi 
	#######
	launchGroundStation
	uavNumber=$1
	index=0
	while [ $index -lt $uavNumber ]; do
		let index=index+1
		echo $index
		initPath $index
		addUav $index	
	done
	sleep 10s	
	index=0
	while [ $index -lt $uavNumber ]; do
		let index=index+1
		echo $index
		startRunner $index
	done

}

###################################

## main

initPath 0
echo "initial path setup is done."
echo "to start simulation, type 'startSim <number of UAV's>'"
echo "after start, you can change PATH variables with 'initPath <id>'; (ground station id is 0, UAV id's are from 1 to 4)"
echo "for linkcut, type 'killSync <id of UAV to be killed>'"
	

###################################
