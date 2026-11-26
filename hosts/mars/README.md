# mars

TrueNAS SCALE NAS, not managed by this flake. It hosts the Incus instances
deimos and phobos (see their READMEs). Reach it at `root@10.10.1.4` (wg0) or
`root@192.168.1.16` (LAN). Use the `mars` skill before running anything there.

## Findings

What was measured on mars and still holds. The applied HDD power state is in
`docs/mars-hdd-idle-tuning.md`.

### Disks and SMART

- **The 90-minute SMART alert poll wakes the SAS drives.** middlewared's
  `SMARTAlertSource` runs `smartctl -x` on every disk. It has no GUI toggle, and
  alert class "Never" only hides notifications. The only off switch is the
  private `midclt call alert.block_source SMART <secs>`, held in memory and
  re-applied by a Post-Init script (applied 2026-10-28).
- **SG_IO is invisible to diskstats.** `smartctl` and other passthrough
  commands do not show in `/proc/diskstats`, so not in the pool-watch logs. Only
  a `bpftrace` `scsi:scsi_dispatch_cmd_start` sweep sees them, and catching the
  90-minute poller needs a sweep of at least 2 hours.
- **Toshiba SAS PHY counters survive warm reboots** (`sg_logs --page=0x18`);
  only a drive power-cycle resets them, and each warm reboot adds about 4 to 11
  invalid dwords and 1 to 2 loss-of-sync per drive. Judge links by growth during
  uptime.
- **NVMe thermal-throttle counters are lifetime.** The MP510's
  `Thermal Temp. 1/2 Total Time` and `Warning Comp. Temperature Time` predate
  current use: diff them over time before calling throttling current. The 970
  EVO Plus is the hot drive (63 to 70 °C nightly).
- **Disk temperature history is in Scrutiny, not Grafana**: Prometheus scrapes
  nothing from mars. Use `http://192.168.1.13:8084/api/summary` for device WWNs,
  then `/api/device/<wwn>/details?duration_key=year` (one sample per day, about
  00:15).

### HDD wake sources

Wakes are batched into 11:00 to 13:05: SABnzbd `resume_post` 11:00 and
`pause_post` 13:00 (restored from the schedule on restart), Jellyfin media tasks
at 12:30 and 13:05. Remaining wakes: Time Machine from the MacBook
(192.168.1.180, `pool/timemachine`), the Home Assistant backup (about 05:30,
192.168.1.10, `backup` share), the 00:00 rsync and snapshots, and Sonarr's 12 h
Refresh Series. Read a pool-active block's sections B (`pool/` datasets) and C
before guessing the cause.

Identical per-dataset counters in consecutive pool-watch blocks mean a retry
loop (2026-10-28: a Sonarr import retrying every 15 minutes).

### PCIe and ASPM

- `pcie_aspm=off` does not disable ASPM: it only stops Linux managing it, and
  the BIOS already enables L1 on NVMe, chipset, Realtek, SATA and USB. It also
  empties every device's `link/` sysfs directory.
- Without the flag, the kernel's latency check turns L1 off on the HBA link
  `00:01.1 ↔ 01:00.0` (SAS3416 acceptable L1 below 1 µs, link exit below
  64 µs), whatever the policy; the CPU root ports have no L1.1/L1.2. So
  `pcie_aspm=off` stays (2026-11-03), which keeps the BIOS's L1 on the HBA. HBA
  ROC temperature is no L1 indicator.
- The onboard Realtek `eno1` (no IP, not in `br1`) received the flooded
  download stream; it was disabled in the BIOS on 2026-11-03. `enp15s0`
  (ConnectX-3 10G) is the only uplink. The Omada switch-port check is open.

### Power and memory

- **NVMe APST gains little** while nvme-pool sees about 100 writes/s around
  the clock (mostly `.ix-virt/containers/deimos`). RAPL measures the CPU
  package only, so APST savings show only on a wall meter.
- **RAPL comparisons need deimos in the same state**: package power was 21 W
  with deimos running and 15 W stopped. SMT is disabled in the BIOS (8 threads);
  deimos is no longer CPU-pinned (changing `limits.cpu` restarts it).
- **ARC collapses come from memory pressure**, not a setting:
  `zfs_arc_max=0` (c_max 57.5G of 58.5G), no swap, `zfs_arc_pc_percent=300`.
  deimos `limits.memory` is a cgroup cap, not a reservation. Collapses of 5 to
  35 GB coincide with import and remux bursts; history is in
  `midclt call reporting.netdata_get_data '[{"name":"arcsize"}]'`.
- **Wall power is not readable**: the plug `Hausflur Unten Steckdose Server` has
  only its on/off switch exposed to the Home Assistant MCP (Assist could cut
  power to the NAS), not its power sensor.

### Audit tooling

`scripts/mars-collect.sh` flags data pools at 80 to 89 % as WARN (the plan
continues) and at 90 % or more as CONFLICT (it stops the ranked plan).
