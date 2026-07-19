# Nix Validation

> Validate NixOS / nix-darwin / home-manager configurations without building.
> Works on any platform -- evaluation doesn't require the target system.
> Catches import cycles, config errors, and role-gating mistakes before pushing.

---

## When to Use

- After editing NixOS or nix-darwin configurations
- After adding/removing `specialArgs` flags or `_module.args`
- After restructuring `imports` chains
- After extracting shared config into a module (inheritance verification)
- Before pushing changes to a remote NixOS host
- When debugging "infinite recursion" or "argument not provided" errors

---

## `nixe` -- Shortcut wrapper (use instead of raw `nix eval`)

The `nixe` shell function wraps `nix eval` with host resolution matching `nixb`. Always pass the host suffix as the first argument.

```bash
# Host resolution (same as nixb):
nixe game              # -> nixos-game
nixe pve               # -> nixos-pve
nixe nixos             # -> nixos
nixe utm               # -> nixos-utm

# Actions:
nixe <host>              # quick: does config evaluate?
nixe <host> warnings     # show config warnings
nixe <host> pkg          # list systemPackages names
nixe <host> svc <name>   # show a service config
nixe <host> <attr-path>  # eval arbitrary config attribute
nixe <host> dry          # dry-run build stats
nixe <host> full         # full pre-push check (eval + warnings + package count)
```

**Pre-push all hosts in one line:**
```bash
for h in nixos game pve utm; do nixe "$h"; done
```

---

## Validation Tools (by depth)

### 1. `nix flake show` -- structure check (lightest)
```bash
nix flake show --impure           # show current system's outputs
nix flake show --all-systems      # all systems
```
Validates the flake can be parsed and outputs are well-formed. Does NOT evaluate NixOS configs.

### 2. `nix build --dry-run` -- most valuable (fast mock build)
```bash
# Shows how many derivations build vs fetch, plus total download/unpack size.
# Works cross-platform -- no builder needed.
nixe <host> dry

# Equivalent raw command:
nix build --dry-run ".#nixosConfigurations.<host>.config.system.build.toplevel" --system x86_64-linux 2>&1 | grep -E 'will be (built|fetched)'
```

### 3. `nix eval` -- targeted validation
```bash
# Quick eval check
nixe <host>

# List package names
nixe <host> pkg

# Check for config warnings (catches deprecations, type mismatches)
nixe <host> warnings
# Expected: []

# Inspect any config attribute
nixe <host> <attr-path>
# Example: nixe game systemd.services.sunshine
```

### 4. `nix flake check` -- full validation (heaviest)
```bash
nix flake check -L    # evaluates all outputs; can hit infinite recursion on complex configs
```

> Note: `nix flake check` evaluates ALL NixOS configs fully. If you get infinite recursion, fall back to `nixe <host>` on individual hosts.

---

## Pre/Post Change Artifact Verification

**Use when:**
- Extracting config into a shared module
- Refactoring imports chains
- Changing specialArgs or role gating
- Any edit where you need to prove "no config regression on host X"

### Protocol

**Step 1 -- Snapshot the attribute before changes:**
```bash
# Snapshot a specific config attribute on all affected hosts
for h in host1 host2; do
  nixe "$h" <attr-path> > "/tmp/$h.before.txt" 2>&1
done
```

**Step 2 -- Make changes:**
- Create/update the shared module
- Edit host configs to import it and remove local definitions

**Step 3 -- Git-add new files (Nix flakes require tracked files):**
```bash
git add <path-to-new-module>
```

**Step 4 -- Snapshot after changes and diff:**
```bash
# Snapshot again and diff -- should be empty if no regression
for h in host1 host2; do
  nixe "$h" <attr-path> > "/tmp/$h.after.txt" 2>&1
  diff "/tmp/$h.before.txt" "/tmp/$h.after.txt" || echo "REGRESSION on $h"
done
```

**Step 5 -- Verify all hosts evaluate:**
```bash
for h in host1 host2; do nixe "$h"; done
# Expected: all print "OK"
```

**Step 6 -- Verify identical inheritance (if using shared module):**
```bash
# Compare the same attribute across hosts
for h in host1 host2 host3; do nixe "$h" <attr-path>; done
# All should show identical output
```

### Example: Sunshine module extraction

Concrete walkthrough of the protocol:

```bash
# Before: snapshot sunshine service on both hosts
nixe game svc sunshine > /tmp/game.sunshine.before.txt
nixe nixos svc sunshine > /tmp/nixos.sunshine.before.txt

# After creating modules/common/sunshine.nix and editing host configs:
git add nix/modules/common/sunshine.nix

nixe game svc sunshine > /tmp/game.sunshine.after.txt
nixe nixos svc sunshine > /tmp/nixos.sunshine.after.txt

diff /tmp/game.sunshine.before.txt /tmp/game.sunshine.after.txt    # should be empty
diff /tmp/nixos.sunshine.before.txt /tmp/nixos.sunshine.after.txt  # should be empty
nixe game && nixe nixos  # both should print "OK"
```

---

## Shared Module Inheritance Check

After extracting config into a shared module, verify ALL importing hosts pick it up correctly:

```bash
# Replace <attr-path> with the config path to verify (e.g. systemd.services.<name>)
for h in nixos game pve; do nixe "$h" <attr-path>; done
```

**Common checks to run:**
```bash
# Does a service exist on each host?
for h in nixos game pve; do nixe "$h" "systemd.services.<name>.enable"; done

# Are firewall ports consistent?
for h in nixos game pve; do nixe "$h" networking.firewall.allowedTCPPorts; done

# Are security wrappers configured?
for h in nixos game pve; do nixe "$h" "security.wrappers.<name>.source"; done

# Package list drift?
nix-diff-hosts nixos nixos-game environment.systemPackages --packages
```

---

## Common Pitfalls

### Infinite recursion: `pkgs.stdenv.isLinux` in `imports`

```nix
# WRONG -- pkgs depends on config, which depends on imports being resolved
{ pkgs, lib, ... }: {
  imports = [ ./foo.nix ] ++ lib.optionals (pkgs.stdenv.isLinux) [ ./bar.nix ];
}

# RIGHT -- use specialArgs (evaluated before modules)
{ lib, specialArgs ? {}, ... }: {
  imports = [ ./foo.nix ] ++ lib.optionals (builtins.hasAttr "game" specialArgs) [ ./bar.nix ];
}

# ALSO RIGHT -- gate within the module, not the import
{ pkgs, lib, ... }: {
  environment.systemPackages = with pkgs; [ ... ] ++ lib.optionals pkgs.stdenv.isLinux [ ... ];
}
```

### `_module.args` doesn't apply to the importing module

`_module.args` values only reach modules imported AFTER the defining module. The module that defines `_module.args` cannot use its own injected args.

```nix
# WRONG -- role.nix defines game, but index.nix can't use it directly
{ game, ... }: {  # game is not yet available here
  imports = [ ./role.nix ./other.nix ];
}

# RIGHT -- index.nix uses specialArgs directly, child modules use injected args
{ lib, specialArgs ? {}, ... }:
let game = builtins.hasAttr "game" specialArgs && specialArgs.game;
in { imports = [ ./role.nix ./child.nix ]; }

# child.nix CAN use injected args from role.nix:
{ game, ... }: { ... }
```

### New modules must be git-tracked

Nix flakes evaluate from the git tree. If you create a new `.nix` file and import it, Nix will fail with "Path is not tracked by Git" until you `git add` it.

```bash
# Always git-add new modules before running nix eval or nix build
git add <path-to-new-module>
```

---

## Validating from macOS

You can fully evaluate x86_64-linux NixOS configs on macOS. `nixe` and `nix build --dry-run` both work; only actual builds require the target system.

```bash
# All work from macOS:
nixe <host>                    # quick config check
nixe <host> dry                # dry-run build stats
nixe <host> full               # full pre-push check
nixe <host> <any-attr-path>    # inspect any config value

# Only fails on actual build (requires x86_64-linux builder):
nix build ".#nixosConfigurations.<host>.config.system.build.toplevel"
```

To build for remote deployment, use a remote builder:
```bash
nix build ".#nixosConfigurations.nixos-game.config.system.build.toplevel" --builders 'ssh://nixos-game'
```

> Note: Use `--impure` if untracked files exist (nix flakes default to git-backed pure evaluation). Or `git add` the files. Git-tracked files don't need `--impure`.

### Cross-machine drift detection (run from macOS)

Compare config between hosts to spot unintended differences:

```bash
# Diff any config attribute between two hosts
nix-diff-hosts <host1> <host2> <attr-path>

# Diff package lists
nix-diff-hosts nixos nixos-game environment.systemPackages --packages
```

### macOS pre-push summary (one command)

```bash
for h in nixos game pve utm; do nixe "$h" full; done
```

Expected output when all good:
```
=== nixos ===
  eval: OK
  warnings: []
  packages: 42
...
```

---

## Pre-Push Checklist

Run these locally before pushing to a NixOS host. All work on macOS without building.

```bash
# 1. Structure check
nix flake show --impure

# 2. Verify input versions before updating flake.lock
nix flake metadata

# 3. Evaluate each host config (catches import cycles, syntax errors)
for h in nixos game pve utm; do nixe "$h"; done

# 4. Check all hosts have zero warnings
for h in nixos game pve utm; do nixe "$h" warnings; done

# 5. Dry-run each host to compare closure sizes
for h in nixos game pve utm; do nixe "$h" dry; done

# 6. Diff package lists to spot unintended drift
nix-diff-hosts nixos nixos-game environment.systemPackages --packages
```

---

## Quick Reference

| Goal | Command |
|------|---------|
| Does flake parse? | `nix flake show --impure` |
| Check input versions? | `nix flake metadata` |
| Host config evaluates? | `nixe <host>` |
| Show config warnings? | `nixe <host> warnings` |
| List system packages? | `nixe <host> pkg` (requires `python3` in PATH) |
| Inspect a service? | `nixe <host> svc <name>` |
| Dry-run build stats? | `nixe <host> dry` |
| Full pre-push check? | `nixe <host> full` |
| Eval arbitrary attr? | `nixe <host> <attr-path>` |
| Compare two hosts? | `nix-diff-hosts <host1> <host2> <attr-path>` |
| Package list diff? | `nix-diff-hosts host1 host2 environment.systemPackages --packages` |
| Syntax check all .nix | `for f in **/*.nix; do nix-instantiate --parse "$f" 2>&1; done` |
| No regression after refactor? | Snapshot attr before, change, snapshot after, `diff` |
| Shared module inherits? | `for h in h1 h2; do nixe "$h" <attr-path>; done` |
| Build artifact audit | See artifact log at `nix/workspace/artifacts/<host>/` |
| Raw nix eval (fallback) | `nix eval --impure ".#nixosConfigurations.<host>.config.<attr>" --system x86_64-linux` |
