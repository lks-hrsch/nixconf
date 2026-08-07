_: {
  # llama.cpp server: Gemma 4 E2B QAT (UD-Q4_K_XL) with MTP speculative
  # decoding, OpenAI-compatible API on 0.0.0.0:8080 (LAN). Tuned for this
  # 16 GB M1: Metal offload, 131k ctx (f16 KV ~2 GB), 2 slots.
  configurations.darwin."lkshrsch-mb-pro-m1".module =
    { pkgs, ... }:
    let
      # Pinned to the latest upstream release (newer than nixpkgs) for Gemma 4
      # MTP support and speculative-decoding fixes. To bump: update
      # version/rev/hash/npmDepsHash.
      llama = pkgs.unstable.llama-cpp.overrideAttrs (_old: {
        version = "10299"; # nixpkgs stores version without "b"; tag = "b${version}"
        src = pkgs.fetchFromGitHub {
          owner = "ggml-org";
          repo = "llama.cpp";
          rev = "e40bf886420d9449cee9aab8a417081cde4620d1"; # release b10299
          hash = "sha256-j3wAW7HAzM6uOC96HgG+sXP8tR2I2zXiz+AQkTzIe7Y=";
        };
        # The bundled web UI's package-lock.json differs from the nixpkgs pin.
        npmDepsHash = "sha256-FHvd2bMvBc9EXrJEzu8EN78oUVSLcOKYCc0232V+L4A=";
      });
      hf = "https://huggingface.co";

      # unsloth UD-Q4_K_XL: QAT-faithful, unlike Google's own qat-q4_0 GGUF
      # which loses the QAT calibration in conversion.
      baseModel = pkgs.fetchurl {
        url = "${hf}/unsloth/gemma-4-E2B-it-qat-GGUF/resolve/main/gemma-4-E2B-it-qat-UD-Q4_K_XL.gguf";
        hash = "sha256-5TEAchjfq5kEhqXednamky1uqN6iM9H2mNfCHPihaIk=";
      };

      # unsloth's official E2B MTP head. Q4_0 and n_max=1 benchmarked fastest
      # on this M1 (37.2 tok/s; F16/BF16 heads and n_max 2/4 all slower);
      # drafter precision never affects output quality.
      drafterModel = pkgs.fetchurl {
        url = "${hf}/unsloth/gemma-4-E2B-it-qat-GGUF/resolve/main/MTP/mtp-gemma-4-E2B-it-Q4_0.gguf";
        hash = "sha256-WG8kYLkJAIZAmB7DQGCqhk4DwUT7q/sxc8QzUIfkquA=";
      };
    in
    {
      # The app firewall allowlists by binary path (no declarative option),
      # so version bumps silently drop LAN access; re-add on each activation.
      system.activationScripts.postActivation.text = ''
        sfw=/usr/libexec/ApplicationFirewall/socketfilterfw
        "$sfw" --add "${llama}/bin/llama-server" >/dev/null
        "$sfw" --unblockapp "${llama}/bin/llama-server" >/dev/null
      '';

      # Daemon, not agent — see meridian.nix for the rationale.
      launchd.daemons.llama-cpp = {
        serviceConfig = {
          UserName = "lkshrsch";
          GroupName = "staff";
          ProgramArguments = [
            "${llama}/bin/llama-server"
            "-m"
            "${baseModel}"
            "-md"
            "${drafterModel}"
            "--spec-type"
            "draft-mtp"
            "--spec-draft-n-max"
            "1"
            "-ngl"
            "99"
            "-fa"
            "on"
            "-c"
            "131072"
            "--parallel"
            "2"
            # Gemma 4 recommended sampling; per-request params override.
            "--temp"
            "1.0"
            "--top-p"
            "0.95"
            "--top-k"
            "64"
            "--jinja"
            "--host"
            "0.0.0.0"
            "--port"
            "8080"
          ];
          KeepAlive = true;
          RunAtLoad = true;
          StandardOutPath = "/Users/lkshrsch/Library/Logs/llama-cpp.log";
          StandardErrorPath = "/Users/lkshrsch/Library/Logs/llama-cpp.err.log";
        };
      };
    };
}
