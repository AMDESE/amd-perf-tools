#!/bin/bash
#echo ----------------------- TURNING OFF WATCHDOG ------------------------
sudo sysctl kernel.nmi_watchdog=0 >& /dev/null
export isintel="$(lscpu | grep GenuineIntel)" 
if [ -z "$isintel" ]; then
	#this is an AMD machine
	export msrdec=3221291520 # 0xc0010200 (Core PERF_CTL)
	export msrcount=6
	for (( msradd=0; msradd<=$((2*$msrcount-1)); msradd++ ))
	do
		msrhex=`printf '0x%x' $(($msrdec + $msradd))`
		sudo wrmsr -a $msrhex 0x0
	done
	export msrdec=3221291568  # 0xc0010230 (ChL3PmcCfg)
	export msrcount=6
	for (( msradd=0; msradd<=$((2*$msrcount-1)); msradd++ ))
	do
		msrhex=`printf '0x%x' $(($msrdec + $msradd))`
		sudo wrmsr -a $msrhex 0x0
	done
	export msrdec=3221291584  # 0xc0010240 (DF_PERF_CTL)
	export msrcount=4
	for (( msradd=0; msradd<=$((2*$msrcount-1)); msradd++ ))
	do
		msrhex=`printf '0x%x' $(($msrdec + $msradd))`
		sudo wrmsr -a $msrhex 0x0
	done
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
; do echo 0 | sudo tee $i; echo -n $i; echo -n '	'; sudo cat  $i; done
	#ls -1 | grep FIXED | xargs sudo more
	exit
fi
