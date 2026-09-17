{
  description = "transcription";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }: {
    packages = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ]
      (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.buildEnv {
            name = "runtime";
            pathsToLink = [ "/bin" "/etc/ssl/certs" ];
            paths = with pkgs; [
              bash
              coreutils
              curl
              cacert
              ffmpeg
              whisper-cpp
              ];
          };
        });
  };
}
