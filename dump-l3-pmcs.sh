#!/bin/bash
if [ -z "$tgtcpu" ]; then
	export tgtcpu=0
fi
export is17h="$(grep 'cpu family	: 23' /proc/cpuinfo)" 

echo ----------------------- CPU ${tgtcpu} ChL3PmcCfg ------------------------
export msrdec=3221291568  # 0xc0010230 (ChL3PmcCfg)
export msrcount=6

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
		echo -n 'EN '
	else
		echo -n '   '
	fi
	if [ -z "$is17h" ]; then
		# this is a F19h machine
		if [ $((($ctlvaldec>>46)&1)) -eq 1 ]; then echo -n 'ALLSLC '; else echo -n '       '; fi
		echo -n 'SLCID'
		echo -n $((($ctlvaldec>>48)&7))
		echo -n ' '
		if [ $((($ctlvaldec>>47)&1)) -eq 1 ]; then echo -n 'ALLC '; else echo -n '     '; fi
		echo -n 'CID'
		echo -n $((($ctlvaldec>>42)&7))
		echo -n ' '
		echo -n 'TM'
		echo -n $((($ctlvaldec>>56)&3))
		echo -n ' '
	else
		# this is a F17h machine
		if [ $((($ctlvaldec>>48)&1)) -eq 1 ]; then echo -n 'SLC0 '; else echo -n '     '; fi
		if [ $((($ctlvaldec>>49)&1)) -eq 1 ]; then echo -n 'SLC1 '; else echo -n '     '; fi
		if [ $((($ctlvaldec>>50)&1)) -eq 1 ]; then echo -n 'SLC2 '; else echo -n '     '; fi
		if [ $((($ctlvaldec>>51)&1)) -eq 1 ]; then echo -n 'SLC3 '; else echo -n '     '; fi
		if [ $((($ctlvaldec>>56)&1)) -eq 1 ]; then echo -n 'C0T0 '; else echo -n '     '; fi
		if [ $((($ctlvaldec>>57)&1)) -eq 1 ]; then echo -n 'C0T1 '; else echo -n '     '; fi
		if [ $((($ctlvaldec>>58)&1)) -eq 1 ]; then echo -n 'C1T0 '; else echo -n '     '; fi
		if [ $((($ctlvaldec>>59)&1)) -eq 1 ]; then echo -n 'C1T1 '; else echo -n '     '; fi
		if [ $((($ctlvaldec>>60)&1)) -eq 1 ]; then echo -n 'C2T0 '; else echo -n '     '; fi
		if [ $((($ctlvaldec>>61)&1)) -eq 1 ]; then echo -n 'C2T1 '; else echo -n '     '; fi
		if [ $((($ctlvaldec>>62)&1)) -eq 1 ]; then echo -n 'C3T0 '; else echo -n '     '; fi
		if [ $((($ctlvaldec>>63)&1)) -eq 1 ]; then echo -n 'C3T1 '; else echo -n '     '; fi
	fi
	echo -n '  '
	# get the count now
	msrhex=`printf '%x' $((${msrdec}+${msradd}+1))`
	echo -n msr${msrhex}
	valhex2=0x`sudo rdmsr -0 -p ${tgtcpu} 0x${msrhex}`
	echo -n -e '  '
	echo -n ${valhex2}
	
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
