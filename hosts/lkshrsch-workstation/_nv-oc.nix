{ pkgs }:
pkgs.writers.writePython3Bin "nv-oc"
  {
    libraries = [ pkgs.python3Packages.nvidia-ml-py ];
    flakeIgnore = [
      "E501"
      "E305"
      "E722"
      "W293"
    ];
  }
  ''
    import sys
    import pynvml


    def get_handle():
        pynvml.nvmlInit()
        handle = pynvml.nvmlDeviceGetHandleByIndex(0)
        print(f"Targeting GPU 0: {pynvml.nvmlDeviceGetName(handle)}")
        return handle


    def apply_oc(mem_offset, power_limit_watts):
        handle = get_handle()

        mem_min, mem_max = pynvml.nvmlDeviceGetMemClkMinMaxVfOffset(handle)
        if not (mem_min <= mem_offset <= mem_max):
            sys.exit(f"Memory offset {mem_offset} out of range [{mem_min}, {mem_max}]")

        pl_min, pl_max = pynvml.nvmlDeviceGetPowerManagementLimitConstraints(handle)
        power_limit_mw = power_limit_watts * 1000
        if not (pl_min <= power_limit_mw <= pl_max):
            sys.exit(f"Power limit {power_limit_watts}W out of range [{pl_min / 1000}, {pl_max / 1000}]W")

        pynvml.nvmlDeviceSetPowerManagementLimit(handle, power_limit_mw)
        pynvml.nvmlDeviceSetMemClkVfOffset(handle, mem_offset)

        cur_offset = pynvml.nvmlDeviceGetMemClkVfOffset(handle)
        cur_power = pynvml.nvmlDeviceGetPowerManagementLimit(handle)
        print(f"Memory offset now: {cur_offset} MHz")
        print(f"Power limit now: {cur_power / 1000} W")

        pynvml.nvmlShutdown()


    def reset():
        handle = get_handle()
        pynvml.nvmlDeviceSetMemClkVfOffset(handle, 0)
        default_power = pynvml.nvmlDeviceGetPowerManagementDefaultLimit(handle)
        pynvml.nvmlDeviceSetPowerManagementLimit(handle, default_power)
        print(f"Reset: memory offset 0 MHz, power limit {default_power / 1000} W")
        pynvml.nvmlShutdown()


    if __name__ == "__main__":
        try:
            if len(sys.argv) == 2 and sys.argv[1] == "reset":
                reset()
            elif len(sys.argv) == 3:
                apply_oc(int(sys.argv[1]), int(sys.argv[2]))
            else:
                sys.exit("Usage: sudo nv-oc <mem_offset_mhz> <power_limit_watts>\n       sudo nv-oc reset")
        except pynvml.NVMLError as e:
            sys.exit(f"NVML Error: {e}")
  ''
