{ pkgs, ... }:
{
  home.file.uwsm-env = {
    enable = true;
    target = ".config/uwsm/env";
    text = ''
      ##### General UI / toolkit ###############################################
      # export NIXOS_OZONE_WL="1"
      # export AQ_DRM_DEVICES="/dev/dri/card0:/dev/dri/card1"
      export GRIMBLAST_HIDE_CURSOR=0

      # Input-method
      export XMODIFIERS="@im=fcitx"
      export QT_IM_MODULE="fcitx"

      ##### NVIDIA / VA-API / Firefox ##########################################
      export LIBVA_DRIVER_NAME="nvidia"
      export GBM_BACKEND="nvidia-drm"
      export NVD_BACKEND="direct"

      export MOZ_ENABLE_WAYLAND="1"
      export MOZ_USE_XINPUT2="1"
      export MOZ_DISABLE_RDD_SANDBOX="1"
      export MOZ_DRM_DEVICE="/dev/dri/renderD128"

      ##### Steam & Proton #####################################################
      export STEAM_EXTRA_COMPAT_TOOLS_PATH="$HOME/.steam/root/compatibilitytools.d"

      ##### CMake / Ninja tool-chain ###########################################
      export CMAKE_C_COMPILER="$HOME/.nix-profile/bin/clang"
      export CMAKE_CXX_COMPILER="$HOME/.nix-profile/bin/clang++"
      export CMAKE_MAKE_PROGRAM="${pkgs.ninja}/bin/ninja"
      export CMAKE_GENERATOR="Ninja"

      ##### CUDA & linker flags ###############################################
      export CUDA_PATH="${pkgs.cudatoolkit}"
      export LDFLAGS="-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
    '';
  };
}
