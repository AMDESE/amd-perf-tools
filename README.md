# amd-perf-tools
Documentation and diagnostic utilities for running Linux perf on AMD hardware

### To build:
```
make pr-ibs
```
### Usage:
#### pr-ibs
The pr-ibs utility can be used to decode raw IBS MSR values:
```
$ ./pr-ibs
usage: ./pr-ibs 0x<msr-addr> 0x<msr-val>
$ ./pr-ibs 0xc0011030 0x0221008d039915ee
ibs_fetch_ctl:	0221008d039915ee L2Miss 0 RandEn 1 L2TlbMiss 0 L1TlbMiss 0 L1TlbPgSz 1 PhyAddrValid 0 IcMiss 0 FetchComplete 0 VALid 0 ENable 1 lat   141 cnt 0x0399 max_cnt 0x15ee
```
#### PMU Register dump scripts
The dump scripts make allow one to verify whether the Core, L3, Data Fabric (DF), and IBS PMUs are being correctly programmed by perf and the kernel PMU drivers.

First, we reset the PMU registers so we don't get any residual values later:
```
$ ./reset-pmcs.sh 
```
All reset scripts reset PMUs on all CPUs, and automatically disable the NMI watchdog.

Next, we run the scripts in the context of a perf stat/record command:
```
$ sudo perf stat -a -e cpu/event=0x87,umask=0x02/ ./dump-core-pmcs.sh
----------------------- CPU 0 Core PERF_CTL ------------------------
msrc0010200  0x0000000000530287  EN  msrc0010201  0x00008000004d4fca  (140737495020713)
msrc0010202  0x0000000000000000      msrc0010203  0x0000000000000000  
msrc0010204  0x0000000000000000      msrc0010205  0x0000000000000000  
msrc0010206  0x0000000000000000      msrc0010207  0x0000000000000000  
msrc0010208  0x0000000000000000      msrc0010209  0x0000000000000000  
msrc001020a  0x0000000000000000      msrc001020b  0x0000000000000000  

 Performance counter stats for 'system wide':

       461,018,007      cpu/event=0x87,umask=0x02/                                   

       0.501346346 seconds time elapsed
```
All dump scripts take an optional workload command parameter that executes after the register dump, e.g., sleep 1 here:
```
$ sudo perf record -a -e cycles:p ./dump-ibs.sh sleep 1
ibs_fetch_ctl:	0000000000000000 L2Miss 0 RandEn 0 L2TlbMiss 0 L1TlbMiss 0 L1TlbPgSz 0 PhyAddrValid 0 IcMiss 0 FetchComplete 0 VALid 0 ENable 0 lat     0 cnt 0x0000 max_cnt 0x0000
IbsFetchLinAd:	0000000000000000
IbsFetchPhysAd:	0000000000000000
ibs_op_ctl:	0001904c00021dec CurCnt 0x001904c CntCtl 0=cycles VALid 0 ENable 1 [MaxCntHi 0x00 + MaxCntLo 0x1dec << 4] = 0d122560 left 0d20084
IbsOpRip:	ffffffffa208e00e
IbsOpData:	00000100000d0004
IbsOpData2:	0000000000000000
IbsOpData3:	0000000000c40002
IbsDCLinAd:	ffffa54e782b3958
IbsDCPhysAd:	0000001007017e40
IbsCtl:   	0000000000000100
IbsBrTarget:	ffffffffa208e00e
IcIbsExtdCtl:	0000000000000000
[ perf record: Woken up 1 times to write data ]
[ perf record: Captured and wrote 1.970 MB perf.data (25943 samples) ]
```
This feature can also be used to daisy-chain two or more register dump scripts.

Note that all MSR reads are done sequentially over time, so one cannot assume that each line of output comes from the same sample.  In other words, the PMUs are running free underneath the slow dump scripts, and the dump scripts cannot be used to replace perf to take samples.

Lastly, one can assign an environment variable 'tgtcpu' to a CPU number to get that CPU's register values instead of the default CPU 0:
```
$ sudo tgtcpu=32 perf stat -a -e amd_l3/umask=0x80,event=0x1/  ./dump-l3-pmcs.sh sleep 1
----------------------- CPU 32 ChL3PmcCfg ------------------------
msrc0010230  0xff0f000000408001  EN SLC0 SLC1 SLC2 SLC3 C0T0 C0T1 C1T0 C1T1 C2T0 C2T1 C3T0 C3T1   msrc0010231  0x000000000004aa92(374866)
msrc0010232  0x0000000000000000                                                                   msrc0010233  0x0000000000000000
msrc0010234  0x0000000000000000                                                                   msrc0010235  0x0000000000000000
msrc0010236  0x0000000000000000                                                                   msrc0010237  0x0000000000000000
msrc0010238  0x0000000000000000                                                                   msrc0010239  0x0000000000000000
msrc001023a  0x0000000000000000                                                                   msrc001023b  0x0000000000000000

 Performance counter stats for 'system wide':

        92,273,158      amd_l3/umask=0x80,event=0x1/                                   

       1.643972586 seconds time elapsed

```
