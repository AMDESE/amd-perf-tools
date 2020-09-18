#!/bin/bash

cd `dirname $0`
#make pr-ibs
export msrdec=3221295152 # 0xc0011030 MSRC001_1030 [IBS Fetch Control] (Core::X86::Msr::IBS_FETCH_CTL)
for (( msradd=0; msradd<=12; msradd++ ))
do
	msrhex=`printf '0x%x' $(($msrdec + $msradd))`
#	echo -n cpu0 msr: $msrhex
#	echo -n -e ' \t '
	msrval=0x`sudo rdmsr -0 -p 0 $msrhex`
	./pr-ibs $msrhex $msrval
done
$@  # run optional workload
