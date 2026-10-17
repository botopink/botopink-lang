# pool.sh — the bounded worker pool the gate's shell runners share
# (conformance/run.sh). Sourced, never run.
#
# The rule is `botopink-lib-test`'s ("Parallel cells" in
# modules/lib-test-runner/AGENTS.md), so every pool of the gate sizes and
# admits the same way:
#
#   pool_default_jobs   one job per CPU, bounded by `MemAvailable / 768 MiB`
#                       (a compiler child plus its node/erl peaks at a few
#                       hundred MB, and several gates share one machine);
#                       at least 1. Where /proc/meminfo does not exist, CPUs.
#   pool_admit <dir>    before a job starts, while another job of THIS run is
#                       in flight (a file in <dir>), wait until
#                       `procs_running` — the runnable threads now, 4th field
#                       of /proc/loadavg, not the 1-minute average — is at most
#                       the CPU count. A run with nothing in flight is always
#                       admitted, so it never waits on other gates forever;
#                       with no /proc/loadavg nothing waits.
#   pool_job <dir> <cmd…>   admit, mark the job in flight, run it, unmark.
#   pool_share <total> <percent>
#                       that part of a run's one total of jobs, at least 1 —
#                       how `scripts/gate.sh` hands each side-by-side stage
#                       its share (§ job budget there; 144 B-29 step G).
#
# A caller exports what its jobs need (`export -f`), runs them with
# `xargs -P "$jobs" bash -c '… pool_job "$inflight" <fn> …'` and keeps its output
# order independent of completion order (each job writes its own file; the
# caller prints them in its own order afterwards), so `--jobs 1` and the default
# print the same bytes.
#
# bash 3.2 clean (the macOS runner): no associative arrays, no `wait -n`.

pool_cpus() {
    getconf _NPROCESSORS_ONLN 2>/dev/null || nproc 2>/dev/null || echo 4
}

pool_default_jobs() {
    local jobs avail_kb by_mem
    jobs="$(pool_cpus)"
    avail_kb="$(awk '/^MemAvailable:/ { print $2 }' /proc/meminfo 2>/dev/null)"
    if [ -n "$avail_kb" ]; then
        by_mem=$(( avail_kb / (768 * 1024) ))
        [ "$by_mem" -ge 1 ] || by_mem=1
        [ "$by_mem" -lt "$jobs" ] && jobs="$by_mem"
    fi
    echo "$jobs"
}

# pool_budget_jobs <avail_kb> <cpus> <fixed_mib> <reserve_mib> <libs_mib> <conf_mib> <tsc_mib>
# The one total of jobs `scripts/gate.sh` shares among its side-by-side stages
# (§ job budget there): the largest n <= cpus, at least 1, whose estimated peak
#   fixed + share(n,50) * libs + share(n,30) * conf + share(n,10) * tsc
# stays within MemAvailable - reserve. <fixed_mib> is what runs beside the pools
# uncounted by any of them (test-web's wasm compile, test-cli); the three
# per-job figures are the stages' measured peaks, in MiB. Pure arithmetic over
# its arguments, so a test gives it a MemAvailable and a CPU count.
pool_budget_jobs() {
    local avail_kb="$1" cpus="$2" fixed="$3" reserve="$4" libs="$5" conf="$6" tsc="$7"
    local room n cost
    room=$(( avail_kb / 1024 - reserve - fixed ))
    n="$cpus"
    while [ "$n" -gt 1 ]; do
        cost=$(( $(pool_share "$n" 50) * libs + $(pool_share "$n" 30) * conf + $(pool_share "$n" 10) * tsc ))
        [ "$cost" -le "$room" ] && break
        n=$(( n - 1 ))
    done
    echo "$n"
}

# pool_check_jobs <value> <who> — exit 2 unless a positive count
pool_check_jobs() {
    case "$1" in
        ''|*[!0-9]*|0) echo "$2: --jobs must be a positive count (got '$1')" >&2; exit 2 ;;
    esac
}

pool_share() { # <total> <percent>
    local n=$(( $1 * $2 / 100 ))
    [ "$n" -ge 1 ] || n=1
    echo "$n"
}

pool_admit() { # <inflight dir>
    local r cpus
    [ -r /proc/loadavg ] || return 0
    cpus="$(pool_cpus)"
    while [ -n "$(ls -A "$1" 2>/dev/null)" ]; do
        read -r _ _ _ r _ </proc/loadavg
        [ "${r%%/*}" -le "$cpus" ] && return 0
        sleep 0.2
    done
}

pool_job() { # <inflight dir> <cmd…>
    local dir="$1" mark
    shift
    pool_admit "$dir"
    mark="$(mktemp "$dir/job.XXXXXX")"
    "$@"
    local rc=$?
    rm -f "$mark"
    return $rc
}

# with_timeout <seconds> <cmd…> — run a command under a wall-clock limit on
# every runner the gate meets: GNU `timeout`, Homebrew's `gtimeout`, or — on
# a stock macOS, which ships neither — perl's alarm, which survives the exec
# and ends the command with SIGALRM. The callers only read pass or fail, never
# timeout's 124, so the three are interchangeable.
with_timeout() {
    local secs="$1"; shift
    if command -v timeout >/dev/null 2>&1; then
        timeout "$secs" "$@"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$secs" "$@"
    else
        perl -e 'alarm shift; exec @ARGV or exit 127' "$secs" "$@"
    fi
}
