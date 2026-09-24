{ pkgs }:
pkgs.writers.writePython3Bin "nv-fan-control"
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


    def set_fan_speed(speed):
        try:
            pynvml.nvmlInit()
            count = pynvml.nvmlDeviceGetCount()
            if count == 0:
                print("No NVIDIA GPUs found.")
                return

            # Target GPU 0 (usually the main one)
            handle = pynvml.nvmlDeviceGetHandleByIndex(0)
            name = pynvml.nvmlDeviceGetName(handle)
            print(f"Targeting GPU 0: {name}")

            try:
                fan_count = pynvml.nvmlDeviceGetNumFans(handle)
            except Exception:
                fan_count = 1

            print(f"Found {fan_count} fans")

            for i in range(fan_count):
                # NVML_FAN_POLICY_MANUAL = 1
                try:
                    pynvml.nvmlDeviceSetFanControlPolicy(handle, i, 1)
                    print(f"Set policy to Manual for Fan {i}")
                except pynvml.NVMLError as e:
                    # Some drivers might not support policy
                    print(f"Note: Fan policy not set: {e}")

                print(f"Setting fan {i} to {speed}%")
                pynvml.nvmlDeviceSetFanSpeed_v2(handle, i, int(speed))

        except pynvml.NVMLError as e:
            print(f"NVML Error: {e}")
        finally:
            try:
                pynvml.nvmlShutdown()
            except Exception:
                pass


    if __name__ == "__main__":
        if len(sys.argv) < 2:
            print("Usage: sudo nv-fan-control <speed_percent>")
            print("       sudo nv-fan-control auto")
            sys.exit(1)

        if sys.argv[1] == "auto":
            # Reset to auto
            try:
                pynvml.nvmlInit()
                handle = pynvml.nvmlDeviceGetHandleByIndex(0)
                # NVML_FAN_POLICY_TEMPERATURE_CONTINUOUS_SW = 0 (Auto)
                try:
                    fan_count = pynvml.nvmlDeviceGetNumFans(handle)
                except Exception:
                    fan_count = 1

                for i in range(fan_count):
                    pynvml.nvmlDeviceSetFanControlPolicy(handle, i, 0)
                    pynvml.nvmlDeviceSetDefaultFanSpeed_v2(handle, i)
                print("Reset to Auto")
            except Exception as e:
                print(e)
        else:
            set_fan_speed(int(sys.argv[1]))
  ''
