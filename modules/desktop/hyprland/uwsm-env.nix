_: {
  flake.modules.homeManager.desktop-hyprland-uwsm-env =
    { lib, pkgs, osConfig, ... }:
    let
      isNvidia = builtins.elem "nvidia" (osConfig.services.xserver.videoDrivers or [ ]);
    in
    {
      home.file.uwsm-env = {
        enable = true;
        target = ".config/uwsm/env";
        text = ''
          ##### General UI / toolkit ###############################################
          # export NIXOS_OZONE_WL="1"
          # export AQ_DRM_DEVICES="/dev/dri/card0:/dev/dri/card1"
          export GRIMBLAST_HIDE_CURSOR=0
          export GTK_IM_MODULE="ibus"
          export QT_IM_MODULE="ibus"
          export XMODIFIERS="@im=ibus"

          export MOZ_ENABLE_WAYLAND="1"
          export MOZ_USE_XINPUT2="1"
          export MOZ_DISABLE_RDD_SANDBOX="1"
          export MOZ_DRM_DEVICE="/dev/dri/renderD128"

          ##### CMake / Ninja tool-chain ###########################################
          export CMAKE_C_COMPILER="$HOME/.nix-profile/bin/clang"
          export CMAKE_CXX_COMPILER="$HOME/.nix-profile/bin/clang++"
          export CMAKE_MAKE_PROGRAM="${pkgs.ninja}/bin/ninja"
          export CMAKE_GENERATOR="Ninja"
        ''
        + lib.optionalString isNvidia ''

          ##### NVIDIA / VA-API / Firefox ##########################################
          export LIBVA_DRIVER_NAME="nvidia"
          export GBM_BACKEND="nvidia-drm"
          export NVD_BACKEND="direct"
          export __GLX_VENDOR_LIBRARY_NAME="nvidia"

          ##### CUDA & linker flags ###############################################
          export CUDA_PATH="${pkgs.cudatoolkit}"
          export LDFLAGS="-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
          export LD_LIBRARY_PATH="${pkgs.linuxPackages.nvidia_x11}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        ''
        + lib.optionalString (!isNvidia) ''

          ##### Intel iGPU / VA-API #################################################
          export LIBVA_DRIVER_NAME="iHD"
        '';
      };
    };
}
