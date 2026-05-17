#!/usr/bin/env bash
set -euo pipefail

need() { command -v "$1" >/dev/null 2>&1; }

OUTDIR="kernel-bench-$(uname -r)-$(date +%F-%H%M%S)"
mkdir -p "$OUTDIR"

log() { echo "== $1 ==" | tee -a "$OUTDIR/summary.txt"; }

echo "Kernel benchmark started at $(date)" | tee "$OUTDIR/summary.txt"

log "KERNEL INFO"
uname -a | tee "$OUTDIR/kernel.txt"
cat /proc/cmdline | tee "$OUTDIR/cmdline.txt"

log "CPU GOVERNOR / FREQ"
if need cpupower; then
  cpupower frequency-info | tee "$OUTDIR/cpufreq.txt"
else
  echo "cpupower not found (add nixpkgs#linuxPackages.cpupower)" | tee "$OUTDIR/cpufreq.txt"
fi

log "KCONFIG (LTO / AMD_PSTATE)"
if [ -e /proc/config.gz ]; then
  zgrep -E "LTO|THINLTO|AMD_PSTATE" /proc/config.gz |
    tee "$OUTDIR/kconfig.txt" || true
else
  echo "No /proc/config.gz found" | tee "$OUTDIR/kconfig.txt"
fi

log "CYCLICTEST (LATENCY TAIL)"
if need cyclictest; then
  cyclictest -p95 -m -Sp90 -i200 -l100000 | tee "$OUTDIR/cyclictest.txt"
else
  echo "cyclictest not found (add nixpkgs#rt-tests)" | tee "$OUTDIR/cyclictest.txt"
fi

log "SCHEDULER LATENCY UNDER LOAD"
if need stress-ng && need perf; then
  stress-ng --cpu "$(nproc)" --cpu-method matrix &
  STRESS_PID=$!
  sleep 2
  perf sched record -- sleep 10
  perf sched latency | tee "$OUTDIR/perf-sched.txt"
  kill "$STRESS_PID" || true
else
  echo "missing stress-ng and/or perf (add nixpkgs#stress-ng nixpkgs#linuxPackages.perf)" |
    tee "$OUTDIR/perf-sched.txt"
fi

log "SYSCALL / BRANCH BEHAVIOR"
if need perf; then
  perf stat -e cycles,instructions,branches,branch-misses \
    ls -R /usr >/dev/null 2>"$OUTDIR/perf-stat.txt"
else
  echo "perf not found (add nixpkgs#linuxPackages.perf)" | tee "$OUTDIR/perf-stat.txt"
fi

log "POWER / FREQ SNAPSHOT (turbostat)"
if need turbostat; then
  turbostat --Summary --interval 1 --num_iterations 5 | tee "$OUTDIR/turbostat.txt"
else
  echo "turbostat not found (OK to skip). If you want it, try nixpkgs#linuxPackages.turbostat" |
    tee "$OUTDIR/turbostat.txt"
fi

log "DONE"
echo "Results saved in $OUTDIR" | tee -a "$OUTDIR/summary.txt"
