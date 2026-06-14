_: {
  # llama.cpp server (Gemma 4 E2B QAT Q4_0) as an always-on launchd agent,
  # with MTP speculative decoding (n_max=1) for throughput and --jinja for
  # OpenAI-compatible tool calling (function calling).
  #
  # Tuned for this 16 GB M1: Metal offload, 131k ctx, 2 parallel slots,
  # serving an OpenAI-compatible API on 0.0.0.0:8080 (LAN-accessible).
  #
  # KV cache stays f16: Gemma 4 E2B uses sliding-window attention on most
  # layers; 131k context at f16 is ~2 GB. MTP forces f16 internally anyway.
  #
  # Host-specific for now (lives here rather than in modules/), matching the
  # per-host stack layout used under hosts/mars/deimos/.
  configurations.darwin."lkshrsch-mb-pro-m1".module =
    { pkgs, ... }:
    let
      # nixpkgs llama-cpp (b9503) predates gemma4-assistant arch support, which
      # landed in mainline at b9549 (PR #23398, "llama: add Gemma4 MTP"). The
      # stock build accepts --spec-type draft-mtp but can't *load* the draft
      # head ("unknown model architecture: 'gemma4-assistant'"), so we build
      # from the latest release. Metal is enabled by default on aarch64-darwin.
      # Drop this override once nixpkgs ships llama-cpp >= b9549.
      llama = pkgs.unstable.llama-cpp.overrideAttrs (_old: {
        version = "9626"; # nixpkgs stores version without "b"; tag = "b${version}"
        src = pkgs.fetchFromGitHub {
          owner = "ggml-org";
          repo = "llama.cpp";
          rev = "4988f6e866057afd130c1515ecef0c9bab9a15f8"; # release b9626
          hash = "sha256-ZTur0tkcMxsVtkxCGlO8LxC1Dxuf6AM3CSOkTV5PTTs=";
        };
        # The bundled web UI's package-lock.json differs from the nixpkgs pin.
        npmDepsHash = "sha256-TU4Gv+dd48WDpswhfVtm79IVIOwoCXz1fZ/DI/z40Wg=";
      });
      hf = "https://huggingface.co";

      # Base model: Gemma 4 E2B QAT Q4_0 GGUF (ungated).
      baseModel = pkgs.fetchurl {
        url = "${hf}/google/gemma-4-E2B-it-qat-q4_0-gguf/resolve/main/gemma-4-E2B_q4_0-it.gguf";
        hash = "sha256-Nka0wUfNI1pE2R3xVG07fY4ptUfb5OH4CFZBmqRV5v0=";
      };

      # Drafter: E2B MTP head GGUF (gemma4-assistant arch).
      # Q4_0 (~40 MB) from lym00 — follows Google's "unquantized-assistant"
      # naming convention used for the E4B head; AtomicChat's Q4_K_M was built
      # with a custom fork and fails with unknown arch on standard llama.cpp.
      drafterModel = pkgs.fetchurl {
        url = "${hf}/lym00/gemma-4-E2B-it-qat-q4_0-unquantized-assistant-gguf-test/resolve/main/gemma-4-E2B-it-qat-assistant-q4_0.gguf";
        hash = "sha256-ganZg7WpTQRkMVECvE0vhpuzHT32y4DOuhQAZfQH58g=";
      };
    in
    {
      launchd.agents.llama-cpp = {
        serviceConfig = {
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
