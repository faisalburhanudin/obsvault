## Running VMs

- [ ] **106 lambda-podman-fleet**
  - [ ] Restart: `qm shutdown 106 && qm start 106`
  - [ ] Trim: `qm guest cmd 106 fstrim` (or `fstrim -av` inside the VM)
  - [ ] Verify: `lvs pve/vm-106-disk-0`

- [x] **107 lambda-quicksand-fleet**
	- [x] Remove ISO
	- [x] Restart: `qm shutdown 107 && qm start 107`
	- [x] Trim: `qm guest cmd 107 fstrim` (or `fstrim -av` inside the VM)
	- [x] Verify: `lvs pve/vm-107-disk-0`

- [x] **110 corelens-dev** (qcow2 on `data`; frees the GPU for VM 100 while stopped)
  - [x] Restart: `qm shutdown 110 && qm start 110`
  - [x] Trim: `qm guest cmd 110 fstrim`
  - [x] Verify: `du -h $(pvesm path data:110/vm-110-disk-0.qcow2)`

- [x] **111 gh-runner** (check no CI jobs are running first)
  - [x] Restart: `qm shutdown 111 && qm start 111`
  - [x] Trim: `qm guest cmd 111 fstrim` (or `fstrim -av` inside the VM)
  - [x] Verify: `lvs pve/vm-111-disk-0`

- [ ] **112 kuma** (monitoring is down during restart)
  - [x] Restart: `qm shutdown 112 && qm start 112`
  - [x] install qemu agent
  - [x] Trim: `qm guest cmd 112 fstrim` (or `fstrim -av` inside the VM)
  - [x] Verify: `lvs pve/vm-112-disk-0`

- [ ] **113 lambda-corelens-podman-fleet** (stops browser sessions)
  - [ ] Restart: `qm shutdown 113 && qm start 113`
  - [ ] Trim: `qm guest cmd 113 fstrim`
  - [ ] Verify: `lvs pve/vm-113-disk-0` (expect ~3%, was 54.52%)

## Stopped VMs (Discard applies on next start)

- [ ] **100 PopOS-GPU-1** (qcow2 on `data`; shares the GPU with 110)
	- [x] Fix Display from None to VirtIO
	- [ ] blocker didn't know the password
	- [ ] Trim after next start: `qm guest cmd 100 fstrim` (or `fstrim -av` inside the VM)
	- [ ] Verify: `du -h $(pvesm path data:100/vm-100-disk-0.qcow2)`

- [x] **101 lambda-chromefleet-vm**
  - [x] Trim after next start: `qm guest cmd 101 fstrim` (or `fstrim -av` inside the VM)
  - [x] Verify: `lvs pve/vm-101-disk-0`

- [x] **103 lambda-remotebrowser**
  - [x] Trim after next start: `qm guest cmd 103 fstrim` (or `fstrim -av` inside the VM)
  - [x] Verify: `lvs pve/vm-103-disk-0`

- [ ] **109 lambda-llm**
  - [ ] Trim after next start: `qm guest cmd 109 fstrim` (or `fstrim -av` inside the VM)
  - [ ] Verify: `lvs pve/vm-109-disk-0`

- [ ] **9020 lambda-daytona** (qcow2 on `data`)
  - [ ] Trim after next start: `qm guest cmd 9020 fstrim` (or `fstrim -av` inside the VM)
  - [ ] Verify: `du -h $(pvesm path data:9020/vm-9020-disk-0

## After all VMs

- [ ] Check nothing is pending: `for id in $(qm list | awk 'nding $id | grep -q '^new' && echo "$id still pending"; done`
- [ ] Check pool: `lvs pve/data` (Data% was 32.59%)
- [ ] Optional: daily trim cron on host for all VMs with the