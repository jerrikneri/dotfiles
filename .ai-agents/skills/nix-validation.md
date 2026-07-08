# Nix Validation

> Validate NixOS / nix-darwin / home-manager configurations without building.
> Works on any platform — evaluation doesn't require the target system.
> Catches import cycles, config errors, and role-gating mistakes before pushing.

---

## When to Use

- After editing NixOS or nix-darwin configurations
- After adding/removing `specialArgs` flags or `_module.args`
- After restructuring `imports` chains
- Before pushing changes to a remote NixOS host
- When debugging "infinite recursion" or "argument not provided" errors

---

## Validation Tools (by depth)

### 1. `nix flake show` — structure check (lightest)
```bash
nix flake show           # show current system's outputs
nix flake show --all-systems  # all systems
```
Validates the flake can be parsed and outputs are well-formed. Does NOT evaluate NixOS configs.

### 2. `nix build --dry-run` — most valuable (fast mock build)
```bash
# Shows how many derivations build vs fetch, plus total download/unpack size.
# Works cross-platform — no builder needed.
nix build --dry-run ".#nixosConfigurations.nixos-game.config.system.build.toplevel" --system x86_64-linux 2>&1 | grep -E 'will be (built|fetched)'

# Example output:
#   these 769 derivations will be built:
#   these 3613 paths will be fetched (13.0 GiB download, 35.7 GiB unpacked):
```

To track impact of role changes, diff dry-run stats between hosts:
```bash
for host in nixos nixos-game nixos-utm; do
  echo "=== $host ==="
  nix build --dry-run ".#nixosConfigurations.$host.config.system.build.toplevel" --system x86_64-linux 2>&1 | grep -E 'will be (built|fetched)'
done
```

### 3. `nix eval` — targeted validation
```bash
# List package names for a host
nix eval --impure ".#nixosConfigurations.nixos-game.config.environment.systemPackages" --json 2>/dev/null \
  | python3 -c "
import json, sys
pkgs = json.load(sys.stdin)
names = sorted(set(p.split('/')[-1][33:] for p in pkgs))
for n in names: print(n)
"

# Check for config warnings (catches deprecations, type mismatches)
nix eval --impure ".#nixosConfigurations.nixos-game.config.warnings" --json
# [] = no warnings

# Check for failed assertions
nix eval --impure ".#nixosConfigurations.nixos-game.config.assertions" --json
```

### 4. `nix flake check` — full validation (heaviest)
```bash
nix flake check -L    # evaluates all outputs; can hit infinite recursion on complex configs
```

> Note: `nix flake check` evaluates ALL NixOS configs fully. If you get infinite recursion, fall back to `nix eval` on individual hosts.

---

## Common Pitfalls

### Infinite recursion: `pkgs.stdenv.isLinux` in `imports`

```nix
# WRONG — pkgs depends on config, which depends on imports being resolved
{ pkgs, lib, ... }: {
  imports = [ ./foo.nix ] ++ lib.optionals (pkgs.stdenv.isLinux) [ ./bar.nix ];
}

# RIGHT — use specialArgs (evaluated before modules)
{ lib, specialArgs ? {}, ... }: {
  imports = [ ./foo.nix ] ++ lib.optionals (builtins.hasAttr "game" specialArgs) [ ./bar.nix ];
}

# ALSO RIGHT — gate within the module, not the import
{ pkgs, lib, ... }: {
  environment.systemPackages = with pkgs; [ ... ] ++ lib.optionals pkgs.stdenv.isLinux [ ... ];
}
```

### `_module.args` doesn't apply to the importing module

`_module.args` values only reach modules imported AFTER the defining module. The module that defines `_module.args` cannot use its own injected args.

```nix
# WRONG — role.nix defines game, but index.nix can't use it directly
{ game, ... }: {  # game is not yet available here
  imports = [ ./role.nix ./other.nix ];
}

# RIGHT — index.nix uses specialArgs directly, child modules use injected args
{ lib, specialArgs ? {}, ... }:
let game = builtins.hasAttr "game" specialArgs && specialArgs.game;
in { imports = [ ./role.nix ./child.nix ]; }

# child.nix CAN use injected args from role.nix:
{ game, ... }: { ... }
```

---

## Validating from macOS

You can fully evaluate x86_64-linux NixOS configs on macOS. `nix build --dry-run` works; only actual builds require the target system.

```bash
# Works: evaluation + dry-run
nix eval --impure ".#nixosConfigurations.nixos-game.config.system.build.toplevel" --system x86_64-linux
nix build --dry-run ".#nixosConfigurations.nixos-game.config.system.build.toplevel" --system x86_64-linux

# Only fails on actual build (requires x86_64-linux builder)
nix build ".#nixosConfigurations.nixos-game.config.system.build.toplevel"
```

To build for remote deployment, use a remote builder:
```bash
nix build ".#nixosConfigurations.nixos-game.config.system.build.toplevel" --builders 'ssh://nixos-game'
```

> Note: Use `--impure` if untracked files exist (nix flakes default to git-backed pure evaluation). Or `git add` the files. Git-tracked files don't need `--impure`.

---

## Pre-Push Checklist

Run these locally before pushing to a NixOS host. All work on macOS without building.

```bash
# 1. Structure check
nix flake show --impure

# 2. Evaluate each host config (catches import cycles, syntax errors)
for host in nixos nixos-game nixos-pve nixos-utm; do
  echo "=== $host ==="
  nix eval --impure ".#nixosConfigurations.$host.config.system.build.toplevel.drvPath" --system x86_64-linux 2>&1 | tail -1
done

# 3. Check all hosts have zero warnings
for host in nixos nixos-game nixos-pve nixos-utm; do
  echo -n "$host warnings: "
  nix eval --impure ".#nixosConfigurations.$host.config.warnings" --json 2>/dev/null
done

# 4. Dry-run each host to compare closure sizes
for host in nixos nixos-game nixos-pve nixos-utm; do
  echo "=== $host ==="
  nix build --dry-run ".#nixosConfigurations.$host.config.system.build.toplevel" --system x86_64-linux 2>&1 | grep -E 'will be (built|fetched)'
done

# 5. Diff package lists to verify role gating
diff <(nix eval --impure ".#nixosConfigurations.nixos.config.environment.systemPackages" --json 2>/dev/null | python3 -c "import json,sys; [print(p.split('/')[-1][33:]) for p in sorted(set(json.load(sys.stdin)))]") \
     <(nix eval --impure ".#nixosConfigurations.nixos-game.config.environment.systemPackages" --json 2>/dev/null | python3 -c "import json,sys; [print(p.split('/')[-1][33:]) for p in sorted(set(json.load(sys.stdin)))]")
```

---

## Quick Reference

| Goal | Command |
|------|---------|
| Does flake parse? | `nix flake show --impure` |
| Host config evaluates? | `nix eval --impure ".#nixosConfigurations.<host>.config.system.build.toplevel" --system x86_64-linux` |
| What gets built vs fetched? | `nix build --dry-run ".#nixosConfigurations.<host>.config.system.build.toplevel" --system x86_64-linux` |
| Any config warnings? | `nix eval --impure ".#nixosConfigurations.<host>.config.warnings" --json` |
| Packages per host? | `nix eval --impure ".#nixosConfigurations.<host>.config.environment.systemPackages" --json` |
| Compare two hosts? | `diff <(eval host1) <(eval host2)` |
| Syntax check all .nix | `for f in **/*.nix; do nix-instantiate --parse "$f" 2>&1; done` |
