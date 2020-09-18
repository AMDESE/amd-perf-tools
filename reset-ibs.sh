#!/bin/bash

export msrdec=3221295152 # 0xc0011030
for (( msradd=0; msradd<=12; msradd++ ))
do
	# check for read-only 0xc001103a 
	if [ $msradd -eq 10 ]; then
		continue
	fi
	msrhex=`printf '0x%x' $(($msrdec + $msradd))`
	#ibs works on all cpus
	sudo wrmsr -a  $msrhex 0x0
done
$@  # run optional workload
