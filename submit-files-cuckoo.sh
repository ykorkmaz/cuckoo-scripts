#!/bin/bash

# check if number of vms are at least 1 and path is a directory
if [ "$#" -ne 2 ] || [ "$1" -lt 1 ] || ! [ -d "$2" ]; then
  echo "Usage: $0 CUCKOO-VM-COUNT FILES-DIRECTORY" >&2
  exit 1
fi

num_vms=$1

TASKS=()

# initiliaze all tasks in task list with id 0
for i in $(seq 0 $((${num_vms}-1))); do
        TASKS[$i]="0"
done

FILES=()

fi=0
# read all file names in the directory and add to list
for file in $2/*.danger; do
	FILES[$fi]=$file
	let fi+=1
done

if [ "${#FILES[*]}" -eq 0 ]; then
	echo "No files in $2"
	exit 1
else
	echo "${#FILES[*]} files in $2"
fi

nextFileIndex=0

while true; do

	for i in ${!TASKS[*]}; do
		# if task id is 0, submit file to Cuckoo for analysis
	   	if [ ${TASKS[$i]} = "0" ]; then
        	      	
                        # if no file is left for analysis, quit
                        if [ "$nextFileIndex" -eq ${#FILES[*]} ]; then
                                echo "All files are submitted to Cuckoo"
                                break 2
                        fi

			# get next file to submit to Cuckco
			TASKS[$i]=$(curl -F file=@${FILES[$nextFileIndex]} http://localhost:8090/tasks/create/file 2>/dev/null | grep ".*task_id.*" | awk -F'": ' '{print $2}');
			let nextFileIndex+=1
			echo "File ${FILES[$nextFileIndex]} is submitted to Cuckoo ("${TASKS[$i]}")"

			#continue 2

	   	else
                       	STATUS=$(curl http://localhost:8090/tasks/view/${TASKS[$i]} 2>/dev/null | grep ".*status.*" | awk -F'"' '{print $4}')

	          	# if task is reported, remove it from task list
        	   	if [ $STATUS = "reported" ]; then
                	        
				echo "TASK "${TASKS[$i]}" completed"
                        	
				TASKS[$i]="0"
                               	
				continue 2
                       	fi
           	fi
        done
	
	sleep 10

done

echo "Exitting script, analysis tasks for the last submitted files could be still in progress..."
