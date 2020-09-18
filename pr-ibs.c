#include <stdlib.h>
#include <stdio.h>
#include <errno.h>

/* from arch/x86/include/asm/msr-index.h */
#define MSR_AMD64_IBSFETCHCTL           0xc0011030
#define MSR_AMD64_IBSFETCHLINAD         0xc0011031
#define MSR_AMD64_IBSFETCHPHYSAD        0xc0011032
#define MSR_AMD64_IBSFETCH_REG_COUNT    3
#define MSR_AMD64_IBSFETCH_REG_MASK     ((1UL<<MSR_AMD64_IBSFETCH_REG_COUNT)-1)
#define MSR_AMD64_IBSOPCTL              0xc0011033
#define MSR_AMD64_IBSOPRIP              0xc0011034
#define MSR_AMD64_IBSOPDATA             0xc0011035
#define MSR_AMD64_IBSOPDATA2            0xc0011036
#define MSR_AMD64_IBSOPDATA3            0xc0011037
#define MSR_AMD64_IBSDCLINAD            0xc0011038
#define MSR_AMD64_IBSDCPHYSAD           0xc0011039
#define MSR_AMD64_IBSOP_REG_COUNT       7
#define MSR_AMD64_IBSOP_REG_MASK        ((1UL<<MSR_AMD64_IBSOP_REG_COUNT)-1)
#define MSR_AMD64_IBSCTL                0xc001103a
#define MSR_AMD64_IBSBRTARGET           0xc001103b
#define MSR_AMD64_IBSOPDATA4            0xc001103d
#define MSR_AMD64_IBS_REG_COUNT_MAX     8 /* includes MSR_AMD64_IBSBRTARGET */

/* From linux' arch/x86/include/asm/perf_event.h */

/* IBS fetch bits/masks */
#define IBS_FETCH_L2_MISS        (1ULL<<58)
#define IBS_FETCH_RAND_EN        (1ULL<<57)
#define IBS_FETCH_L2_TLB_MISS    (1ULL<<56)
#define IBS_FETCH_L1_TLB_MISS    (1ULL<<55)
#define IBS_FETCH_L1_TLB_PG_SZ   (3ULL<<53)
#define IBS_FETCH_PHY_ADDR_VALID (1ULL<<52)
#define IBS_FETCH_IC_MISS        (1ULL<<51)
#define IBS_FETCH_COMP           (1ULL<<50)  /* insn fetch complete */
#define IBS_FETCH_VAL            (1ULL<<49)
#define IBS_FETCH_ENABLE         (1ULL<<48)
#define IBS_FETCH_LAT            0xFFFF00000000ULL
#define IBS_FETCH_CNT            0x0000FFFF0000ULL
#define IBS_FETCH_MAX_CNT        0x00000000FFFFULL

/*
 * IBS op bits/masks
 * The lower 7 bits of the current count are random bits
 * preloaded by hardware and ignored in software
 */
#define IBS_OP_CUR_CNT          (0xFFF80ULL<<32)
#define IBS_OP_CUR_CNT_RAND     (0x0007FULL<<32)
#define IBS_OP_CNT_CTL          (1ULL<<19)
#define IBS_OP_VAL              (1ULL<<18)
#define IBS_OP_ENABLE           (1ULL<<17)
#define IBS_OP_MAX_CNT          0x0000FFFFULL
#define IBS_OP_MAX_CNT_EXT      0x007FFFFFULL   /* not a register bit mask */
#define IBS_RIP_INVALID         (1ULL<<38)


void pr_ibs_op_ctl(unsigned long long config)
{
        printf("ibs_op_ctl:\t%016llx CurCnt 0x%07llx CntCtl %d=%s VALid %d ENable %d [MaxCntHi 0x%02llx + MaxCntLo 0x%04llx << 4] = 0d%lld%s left 0d%lld\n",
		config,
		config >> 32,
		!!(config & IBS_OP_CNT_CTL),
		(config & IBS_OP_CNT_CTL) ? "uOps" : "cycles",
		!!(config & IBS_OP_VAL),
		!!(config & IBS_OP_ENABLE),
		(config >> 20) & 0x7f /* MaxCntHi */,
		(config & 0xffff) /* MaxCntLo */,
		((((config >> 20) & 0x7f) << 16) + (config & 0xffff)) << 4,
		((((config >> 20) & 0x7f) << 16) + (config & 0xffff)) <= 0x8 ? " (RESERVED!)" : "",
		(((((config >> 20) & 0x7f) << 16) + (config & 0xffff)) << 4) - (config >> 32));
}

void pr_ibs_fetch_ctl(unsigned long long config)
{
        printf("ibs_fetch_ctl:\t%016llx L2Miss %d RandEn %d L2TlbMiss %d L1TlbMiss %d L1TlbPgSz %lld PhyAddrValid %d IcMiss %d FetchComplete %d VALid %d ENable %d lat %5lld cnt 0x%04llx max_cnt 0x%04llx\n",
		config,
		!!(config & IBS_FETCH_L2_MISS),
		!!(config & IBS_FETCH_RAND_EN),
		!!(config & IBS_FETCH_L2_TLB_MISS),
		!!(config & IBS_FETCH_L1_TLB_MISS),
		(config & IBS_FETCH_L1_TLB_PG_SZ) >> 53,
		!!(config & IBS_FETCH_PHY_ADDR_VALID),
		!!(config & IBS_FETCH_IC_MISS),
		!!(config & IBS_FETCH_COMP),
		!!(config & IBS_FETCH_VAL),
		!!(config & IBS_FETCH_ENABLE),
		(config & IBS_FETCH_LAT) >> 32,
		(config & IBS_FETCH_CNT) >> 16,
		config & IBS_FETCH_MAX_CNT);
}

void usage(void) {
	printf("usage: pr-ibs 0x<msr-addr> 0x<msr-val>\n");
	exit(-1);
}

int main(int argc, char **argv)
{
	unsigned long long msr_addr, msr_val;

	if (argc != 3) {
		printf("usage: %s 0x<msr-addr> 0x<msr-val>\n", argv[0]);
		exit(-1);
	}
	errno = 0;
	msr_addr = strtoull(argv[1], NULL, 16);
	msr_val = strtoull(argv[2], NULL, 16);
	if (errno)
		usage();

	switch (msr_addr) {
	case MSR_AMD64_IBSFETCHCTL:
		pr_ibs_fetch_ctl(msr_val);
		break;
	case MSR_AMD64_IBSFETCHLINAD:
		printf("IbsFetchLinAd:\t%016llx\n", msr_val);
		break;
	case MSR_AMD64_IBSFETCHPHYSAD:
		printf("IbsFetchPhysAd:\t%016llx\n", msr_val);
		break;
	case MSR_AMD64_IBSOPCTL:
		pr_ibs_op_ctl(msr_val);
		break;
	case MSR_AMD64_IBSOPRIP:
		printf("IbsOpRip:\t%016llx\n", msr_val);
		break;
	case MSR_AMD64_IBSOPDATA:
		printf("IbsOpData:\t%016llx\n", msr_val);
		break;
	case MSR_AMD64_IBSOPDATA2:
		printf("IbsOpData2:\t%016llx\n", msr_val);
		break;
	case MSR_AMD64_IBSOPDATA3:
		printf("IbsOpData3:\t%016llx\n", msr_val);
		break;
	case MSR_AMD64_IBSDCLINAD:
		printf("IbsDCLinAd:\t%016llx\n", msr_val);
		break;
	case MSR_AMD64_IBSDCPHYSAD:
		printf("IbsDCPhysAd:\t%016llx\n", msr_val);
		break;
	case MSR_AMD64_IBSCTL:
		printf("IbsCtl:   \t%016llx\n", msr_val);
		break;
	case MSR_AMD64_IBSBRTARGET:
		printf("IbsBrTarget:\t%016llx\n", msr_val);
		break;
	case MSR_AMD64_IBSOPDATA4:
		printf("IbsOpData4:\t%016llx\n", msr_val);
		break;
	case 0xc001103c:
		printf("IcIbsExtdCtl:\t%016llx\n", msr_val);
		break;
	default:
		printf("msr%08llx:\t%016llx\n", msr_addr, msr_val);
	}

	exit(0);
}
