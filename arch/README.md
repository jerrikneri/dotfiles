### packages
- Concatenated list of `pacmans` and `yays`

### pacmans
- List of `pacman` packages
- generate with
  - `pacman -Q | awk '{print $1} > pacmans`
- use existing with
  - `pacman -S --needed - < pacmans`

### yays
- List of `yay` packages
- generate with
  - `yay -Qm | awk '{print $1} > yays`
- use existing with
  - `yay -S --needed - < packages` // yay can handle installing `aur` and `yay` packages


### Installing `yay`
```
  pacman -S --needed git base-devel
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si
```

