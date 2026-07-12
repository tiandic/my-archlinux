#!/bin/bash

git clone http://github.com/tiandic/plana-themes

cd plana-themes
sudo cp -r grub/plana /boot/grub/themes/
sudo sed -n 's#GRUB_THEME=.*#GRUB_THEME="/boot/grub/themes/plana/theme.txt"#' /etc/default/grub

sudo yay -S --noconfirm plymouth-git
sudo python3 -c '
with open("/etc/mkinitcpio.conf") as f:
    lines=f.readlines()

out_lines=[]

for line in lines:
    if not line.startswith("HOOKS="):
        out_lines.append(line)
    elif "sd-encrypt" in line:
        out_lines.append(line.replace("sd-encrypt","plymouth sd-encrypt"))
    elif "encrypt" in line:
        out_lines.append(line.replace("encrypt","plymouth encrypt"))
    else:
        out_lines.append(line.replace(")"," plymouth)"))

with open("/etc/mkinitcpio.conf","w") as f:
    for line in out_lines:
        f.write(line)
'
sudo cp -r plymouth/plana /usr/share/plymouth/themes/
sudo plymouth-set-default-theme -R plana

sudo pacman -S --need sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg 7zip
7z x sddm/plana/Backgrounds/plana.7z.001 -osddm/plana/Backgrounds/
sudo cp sddm/plana/Fonts/NotoSansMono-VariableFont_wdth,wght.ttf /usr/share/fonts/ # 安装字体
sudo cp -r sddm/plana /usr/share/sddm/themes
echo "[Theme]
Current=plana" | sudo tee /etc/sddm.conf
echo "[General]
InputMethod=qtvirtualkeyboard" | sudo tee /etc/sddm.conf.d/virtualkbd.conf

cp -r fcitx5/OriDark $HOME/.local/share/fcitx5/themes/
echo "Please manually choose a theme."
fcitx5-configtool

cp hyprlock/* ~/.config/hypr/

rm -rf plana-themes

# dotfiles
git clone --recursive https://github.com/tiandic/dotfiles.git ~/dotfiles
cd ~/dotfiles

back_config() {
  local name="$1"
  [ -e "~/.config/${name}" ] && mv "~/.config/${name}" "~/.config/${name}.$(date +'%Y-%m-%d_%H:%M.%S').bak"
}

for n in "niri" "rofi" "waybar" "kitty" "nvim"; do
  back_config "$n"
done

[ -e ~/.zshrc ] && mv ~/.zshrc "~/.zshrc.$(date +"%Y-%m-%d_%H:%M.%S").bak"

stow kitty
stow rofi
stow nvim
stow zsh
stow waybar
stow niri

sudo pacman -S --noconfirm --needed keyd
echo "# /etc/keyd/default.conf

[ids]
*

[global]
overload_tap_timeout = 300

[main]
leftmeta = overload(meta, macro(leftmeta+0))" | sudo tee /etc/keyd/default.conf

echo "LANG=zh_CN.UTF-8" | sudo tee /etc/locale.conf

sudo python3 -c '
with open("/etc/default/grub") as f:
    lines=f.readlines()

out_lines=[]

for line in lines:
    if not line.startswith("GRUB_CMDLINE_LINUX="):
        out_lines.append(line)
    else:
        if line.count("\"")!=2:
            print("Please manually add \"rd.luks.options=tries=0\" to GRUB_CMDLINE_LINUX in \"/etc/default/grub\".")
            exit(1)
        else:
            idx=line.rfind("\"")
            out_lines.append(line[:idx]+" rd.luks.options=tries=0"+line[idx:])

with open("/etc/default/grub","w") as f:
    for line in out_lines:
        f.write(line)
'
