{
description = "WordPress Studio (StudioWP) flake for NixOS";

inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

outputs = { self, nixpkgs }:

  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };

    version = "1.22.0";

    src = pkgs.fetchurl {
        url = "https://appscdn.wordpress.com/wp-content/uploads/2026/09/studio-x64-v1.22.0.deb";  
        hash = "sha256-/WmConZzgCT3IkIHqREjm2SLhtUfOdyhfXeBuq7BpRM=
";
    };

    studiowp-unwrapped = pkgs.stdenv.mkDerivation {
        pname = "studiowp-unwrapped";
        inherit version src;
        nativeBuildInputs = [ pkgs.dpkg ];
        unpackPhase = "dpkg-deb --fsys-tarfile $src | tar -x --no-same-permissions --no-same-owner";
        installPhase = ''
            mkdir -p $out
            cp -r usr $out/
            '';        
        };

  in {
    packages.${system} = {
        studio = pkgs.buildFHSEnv {
            name = "studio";
            targetPkgs = pkgs: with pkgs; [
                glib nspr nss atk at-spi2-atk at-spi2-core cups dbus cairo gtk3
                pango expat libgbm libxkbcommon systemd alsa-lib xorg.libX11    
                xorg.libXcomposite xorg.libXdamage xorg.libXext xorg.libXfixes
                xorg.libXrandr xorg.libxcb

  # not in ldd output, but Electron dlopen()s these at runtime
                libGL libdrm vulkan-loader fontconfig freetype openssl
                zlib curl xorg.libxshmfence
                ];

    runScript = "${studiowp-unwrapped}/usr/lib/studio/studio --no-sandbox --ozone-platform-hint=auto";

    extraInstallCommands = ''
        mkdir -p $out/share
        cp -r ${studiowp-unwrapped}/usr/share/applications $out/share/
        cp -r ${studiowp-unwrapped}/usr/share/pixmaps $out/share/
        chmod -R u+w $out/share/applications
        sed -i -E "s|^Exec=[^ ]+|Exec=$out/bin/studio|" $out/share/applications/*.desktop
        '';
    };

    

    default = self.packages.${system}.studio;    
    };

    apps.${system}.default = {
        type = "app";
        program = "${self.packages.${system}.studio}/bin/studio";
        };
    };

}  
