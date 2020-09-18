#!/bin/bash
if [ -z "$tgtcpu" ]; then
	export tgtcpu=0
fi
export isintel="$(lscpu | grep GenuineIntel)" 
if [ -z "$isintel" ]; then
	#this is an AMD machine
	echo ----------------------- CPU ${tgtcpu} Core PERF_CTL ------------------------
	export msrdec=3221291520 # 0xc0010200 (Core PERF_CTL)
	export msrcount=6
else
	#export msrdec=390  # MSR_ARCH_PERFMON_EVENTSEL0  0x186
	#export msrcount=3
	#export msrdec=777  # IA32_PERF_FIXED_CTR0  0x309
	export msrdec=909  # 0x38d: ia32_perf_fixed_ctr_ctrl, 0x222: ensure 3 FFCs enabled
	export msrcount=3
	#git clone https://github.com/pp3345/sysfs-msrs
	#make -C /home/kim/git/linux M=$(pwd) && \
	#sudo make -C /home/kim/git/linux M=$(pwd) modules_install
	sudo modprobe sysfs-msrs
	cd /sys/devices/system/cpu/cpu${tgtcpu}/msrs
	for i in  \
IA32_APERF \
IA32_FIXED_CTR0 \
IA32_FIXED_CTR1 \
IA32_FIXED_CTR2 \
IA32_FIXED_CTR_CTRL \
IA32_MPERF \
IA32_PEBS_ENABLE \
IA32_PERF_CAPABILITIES \
IA32_PERF_CTL \
IA32_PERFEVTSEL0 \
IA32_PERFEVTSEL1 \
IA32_PERFEVTSEL2 \
IA32_PERFEVTSEL3 \
IA32_PERF_GLOBAL_CTRL \
IA32_PERF_GLOBAL_INUSE \
IA32_PERF_GLOBAL_STATUS \
IA32_PERF_GLOBAL_STATUS_RESET \
IA32_PERF_GLOBAL_STATUS_SET \
IA32_PERF_STATUS \
IA32_TIME_STAMP_COUNTER \
; do echo -n $i; echo -n '	'; sudo cat  $i; done
	#ls -1 | grep FIXED | xargs sudo more
	exit
fi

for (( msradd=0; msradd<$(($msrcount * 2)); msradd+=2 ))
do
	msrhex=`printf '%x' $(($msrdec + $msradd))`
	valhex=0x`sudo rdmsr -0 -p ${tgtcpu} 0x$msrhex`
	ctlvaldec=`sudo rdmsr -u -p ${tgtcpu} 0x$msrhex`
	echo -n msr${msrhex}
	echo -n -e '  '
	echo -n $valhex
	echo -n -e '  '
	if [ $((($ctlvaldec>>22)&1)) -eq 1 ]; then 
		echo -n EN
	else
		echo -n '  '
	fi
	echo -n '  '
	# get the count now
	msrhex=`printf '%x' $((${msrdec}+${msradd}+1))`
	echo -n msr${msrhex}
	valhex2=0x`sudo rdmsr -0 -p ${tgtcpu} 0x${msrhex}`
	echo -n -e '  '
	echo -n ${valhex2}
	echo -n -e '  '
	valdec=`sudo rdmsr -u -p ${tgtcpu} 0x${msrhex}`
	#echo 47-bit count: `sudo rdmsr -p 0 --bitfield 46:0 -d 0x$msrhex`dec
	#echo count: ${valdec}dec
	if [ $valdec -ne 0 ]; then
		echo  \(${valdec}\)
	else
		echo
	fi
done
$@  # run optional workload
