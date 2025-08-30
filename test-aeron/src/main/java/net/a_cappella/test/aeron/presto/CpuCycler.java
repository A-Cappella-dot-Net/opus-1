package net.a_cappella.test.aeron.presto;

import java.util.BitSet;

import net.openhft.affinity.Affinity;

public class CpuCycler {
	BitSet affinity = Affinity.getAffinity();
	int i = 0;

	public int getNextCpu() {
		int nextCpu;
		if (i<0) {
			nextCpu = affinity.nextSetBit(0);
		} else {
			nextCpu = affinity.nextSetBit(i);
		}
		i = affinity.nextSetBit(nextCpu+1);
		return nextCpu;
	}

	public int getNextNonZeroCpu() {
		int cpu = getNextCpu();
		if (cpu == 0) {
			cpu = getNextCpu();
		}
		return cpu;
	}

	private final int[] _nonIsolatedCpus = affinity.stream().filter(i -> i>0).toArray();
	private int _indexAsc = 0;
	private int _indexDesc = _nonIsolatedCpus.length - 1;
	public int nextCpuAsc() {
		if (_indexAsc > _nonIsolatedCpus.length - 1) _indexAsc = 0;
		return _nonIsolatedCpus[_indexAsc++];
	}
	public int nextCpuDesc() {
		if (_indexDesc < 0) _indexDesc = _nonIsolatedCpus.length - 1;
		return _nonIsolatedCpus[_indexDesc--];
	}

	public static void main(String[] args) {
		CpuCycler cycler = new CpuCycler();
		for (int i=0; i<10; i++) {
			System.out.println(cycler.getNextNonZeroCpu()+" "+cycler.nextCpuAsc()+" "+cycler.nextCpuDesc());
		}
	}
}