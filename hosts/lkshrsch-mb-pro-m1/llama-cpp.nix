_: {
  # llama.cpp server in router mode, OpenAI-compatible API on 0.0.0.0:8080
  # (LAN). Requests pick a model via the "model" field:
  #   gemma-4-e2b       chat: Gemma 4 E2B QAT (UD-Q4_K_XL) with MTP
  #                     speculative decoding; 131k ctx (f16 KV ~2 GB), 2 slots.
  #   embeddinggemma-2  /v1/embeddings: EmbeddingGemma 2 BF16, 768-dim.
  # Both stay loaded (~5 GB total on this 16 GB M1).
  configurations.darwin."lkshrsch-mb-pro-m1".module =
    { lib, pkgs, ... }:
    let
      # Pinned to the latest upstream release (newer than nixpkgs) for Gemma 4
      # MTP support and speculative-decoding fixes. To bump: update
      # version/rev/hash/npmDepsHash.
      llama = pkgs.unstable.llama-cpp.overrideAttrs (_old: {
        version = "11750"; # nixpkgs stores version without "b"; tag = "b${version}"
        src = pkgs.fetchFromGitHub {
          owner = "ggml-org";
          repo = "llama.cpp";
          rev = "dd002b91f583af0b80140f9a140dc04856bfc2e0"; # release b11750
          hash = "sha256-gqy4kRQIBbsx7eSNyLwou0X9viHdLuHFF2JBA+ZGiP4=";
        };
        # nixpkgs' backport patch is already upstream at this rev.
        patches = [ ];
        # Upstream's test-download-model needs network; sandbox has none.
        doCheck = false;
        # The bundled web UI's package-lock.json differs from the nixpkgs pin.
        npmDepsHash = "sha256-hqYzdp1FwPhYkBP278fQXgY9NCKB6Q3P6Gko7BfP0m0=";
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

      # Text-only: the mmproj encoders (images/audio/video) are skipped.
      embedModel = pkgs.fetchurl {
        url = "${hf}/unsloth/embeddinggemma-2-GGUF/resolve/main/embeddinggemma-2-BF16.gguf";
        hash = "sha256-8xXLuzDdSH5E1QHIkCq+iICHVeQ3U6lr7tGWTwpIqk8=";
      };

      # Keys are llama-server flags without dashes; load-on-startup is
      # preset-only. Host/port live on the router command line.
      presets = pkgs.writeText "llama-models.ini" ''
        version = 1

        [gemma-4-e2b]
        model = ${baseModel}
        model-draft = ${drafterModel}
        spec-type = draft-mtp
        spec-draft-n-max = 1
        n-gpu-layers = 99
        flash-attn = on
        ctx-size = 131072
        parallel = 2
        ; Gemma 4 recommended sampling; per-request params override.
        temp = 1.0
        top-p = 0.95
        top-k = 64
        jinja = true
        load-on-startup = true

        [embeddinggemma-2]
        model = ${embedModel}
        embedding = true
        n-gpu-layers = 99
        ctx-size = 8192
        ; Whole 8k-token input in one ubatch; embeddings can't be split.
        batch-size = 8192
        ubatch-size = 8192
        load-on-startup = true
      '';
    in
    {
      # The app firewall allowlists by binary path (no declarative option),
      # so version bumps silently drop LAN access; re-add on each activation.
      system.activationScripts.postActivation.text = ''
        sfw=/usr/libexec/ApplicationFirewall/socketfilterfw
        "$sfw" --add "${llama}/bin/llama-server" >/dev/null
        "$sfw" --unblockapp "${llama}/bin/llama-server" >/dev/null
      '';

      # Daemon, not agent; `command` for wait4path — see meridian.nix for both.
      launchd.daemons.llama-cpp = {
        command = lib.escapeShellArgs [
          "${llama}/bin/llama-server"
          "--models-preset"
          "${presets}"
          "--host"
          "0.0.0.0"
          "--port"
          "8080"
        ];
        serviceConfig = {
          UserName = "lkshrsch";
          GroupName = "staff";
          KeepAlive = true;
          RunAtLoad = true;
          StandardOutPath = "/Users/lkshrsch/Library/Logs/llama-cpp.log";
          StandardErrorPath = "/Users/lkshrsch/Library/Logs/llama-cpp.err.log";
        };
      };
    };
}
