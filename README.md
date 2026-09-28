# studio-wp-flake

Nix flake that packages the official WordPress Studio `.deb` for NixOS using `buildFHSEnv`.

Unofficial. Not affiliated with or endorsed by Automattic or WordPress.com.

## Run

```sh
nix run github:stoic-nihilist/studiowp-nix
```

## Build

```sh
git clone https://github.com/stoic-nihilist/studiowp-nix
cd studiowp-nix
nix build
./result/bin/studio
```

## Install (Home Manager)

```nix
# flake.nix
inputs.studio-wp.url = "github:stoic-nihilist/studiowp-nix";
```

```nix
# home.nix (inputs passed via extraSpecialArgs)
home.packages = [
  inputs.studio-wp.packages.${pkgs.stdenv.hostPlatform.system}.default
];
```

## Update to a new version

1. In `flake.nix`, change `version` and the version inside the `url`.
2. Set `hash = "";`.
3. Run `nix build`. It fails with a hash mismatch.
4. Paste the `got:` value into `hash`.
5. Run `nix build` again.

Get the hash directly:

```sh
nix store prefetch-file https://appscdn.wordpress.com/wp-content/uploads/2026/09/studio-x64-v1.22.0.deb
```

## How it works

- `studiowp-unwrapped` fetches the `.deb` and extracts it with `dpkg-deb --fsys-tarfile | tar`, dropping permission bits so the setuid `chrome-sandbox` doesn't break the build.
- `buildFHSEnv` supplies the shared libraries the Electron binary expects (found via `ldd`, plus libs Electron loads with `dlopen()` at runtime).
- `runScript` launches `usr/lib/studio/studio` in place, so it stays next to `libffmpeg.so`, the `.pak` files and the V8 snapshots.
- `extraInstallCommands` installs the `.desktop` entry and icon, with `Exec=` rewritten to the wrapper.

## Notes

- Launched with `--no-sandbox`: the setuid bit on `chrome-sandbox` can't survive the Nix store. Remove the flag in `runScript` if user namespaces work for you.
- Launched with `--ozone-platform-hint=auto` to pick Wayland or X11 automatically.
- Missing library at runtime? Find the package and add it to `targetPkgs`:

  ```sh
  ./result/bin/studio 2>&1 | grep -i 'error while loading'
  nix-locate -w 'lib/libFOO.so*'
  ```

- Only `x86_64-linux` is supported.

## License

The flake is MIT-licensed, see [LICENSE](LICENSE). This covers the Nix code only. WordPress Studio is distributed under its own license, see the copyright file inside the `.deb`.
