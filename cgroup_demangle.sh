declare -A id_to_tag
declare -A id_to_short
declare -A id_to_pid
declare -A id_to_cpu_cgroup
declare -A id_to_mem_cgroup
declare -A id_to_cpu
declare -A id_to_cpu_cfs_period_us
declare -A id_to_cpu_cfs_quota_us
declare -A id_to_mem

while read -r k v; do 
  id_to_tag[$k]=$v
  id_to_short[$k]=$(basename $(echo "$v" | sed 's/\([^@]*\).*/\1/'))
  pid=`docker inspect -f '{{.State.Pid}}' $k`
  id_to_pid[$k]=$pid
  cpu_cgroup=`cat /proc/$pid/cgroup | awk 'BEGIN{FS=":"} /cpuacct/{print($3)}'`
  id_to_cpu_cgroup[$k]=$cpu_cgroup
  mem_cgroup=`cat /proc/$pid/cgroup | awk 'BEGIN{FS=":"} /memory/{print($3)}'`
  id_to_mem_cgroup[$k]=$mem_cgroup
  id_to_cpu[$k]=`cat /sys/fs/cgroup/cpu/$cpu_cgroup/cpu.shares`
  id_to_cpu_cfs_period_us[$k]=`cat /sys/fs/cgroup/cpu/$cpu_cgroup/cpu.cfs_period_us`
  id_to_cpu_cfs_quota_us[$k]=`cat /sys/fs/cgroup/cpu/$cpu_cgroup/cpu.cfs_quota_us`
  id_to_mem[$k]=`cat /sys/fs/cgroup/memory/$mem_cgroup/memory.limit_in_bytes`
done < <(docker ps | awk 'NR>1{print($1" "$2)}')

function pretty() {
  echo SHORT CONTAINER_ID PID cpu.shares cpu.cfs_period_us cpu.cfs_quota_us memory.limit_in_mbytes
  for k in "${!id_to_tag[@]}"; do
    mem_mb=`expr ${id_to_mem[$k]} / 1024 / 1024`
    echo "${id_to_short[$k]} $k ${id_to_pid[$k]} ${id_to_cpu[$k]} ${id_to_cpu_cfs_period_us[$k]} ${id_to_cpu_cfs_quota_us[$k]} $mem_mb"
  done
}

pretty | column -t
