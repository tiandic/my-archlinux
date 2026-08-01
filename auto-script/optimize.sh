#!/bin/bash
set -euo pipefail

git clone http://github.com/tiandic/plana-themes

# grub 主题
cd plana-themes
sudo cp -r grub/plana /boot/grub/themes/
sudo sed -n 's#GRUB_THEME=.*#GRUB_THEME="/boot/grub/themes/plana/theme.txt"#' /etc/default/grub

# plymouth 主题
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

# sddm 主题
sudo pacman -S --need sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg 7zip
7z x sddm/plana/Backgrounds/plana.7z.001 -osddm/plana/Backgrounds/
sudo cp sddm/plana/Fonts/NotoSansMono-VariableFont_wdth,wght.ttf /usr/share/fonts/ # 安装字体
sudo cp -r sddm/plana /usr/share/sddm/themes
echo "[Theme]
Current=plana" | sudo tee /etc/sddm.conf
echo "[General]
InputMethod=qtvirtualkeyboard" | sudo tee /etc/sddm.conf.d/virtualkbd.conf

# fcitx5 主题
cp -r fcitx5/OriDark "$HOME/.local/share/fcitx5/themes/"
echo "Please manually choose a theme."
fcitx5-configtool
cat >"$HOME/.local/share/fcitx5/rime/default.custom.yaml" <<EOF
patch:
  # 这里的 rime_ice_suggestion 为雾凇方案的默认预设
  # 其路径位于 /usr/share/rime-data/rime_ice_suggestion.yaml
  __include: rime_ice_suggestion:/
  __patch:
    # 方案列表
    schema_list:
      # 可以直接删除或注释不需要的方案，对应的 *.schema.yaml 方案文件也可以直接删除
      # 除了 t9，它依赖于 rime_ice，用九宫格别删 rime_ice.schema.yaml
      - schema: rime_ice               # 雾凇拼音（全拼）
EOF
cat >"$HOME/.local/share/fcitx5/rime/rime_ice.custom.yaml" <<EOF
# 其默认配置文件路径位于 /usr/share/rime-data/rime_ice.schema.yaml
# 其中一段:
# switches:
#  - name: ascii_mode
#    states: [ 中, Ａ ]
#  - name: ascii_punct  # 中英标点
#    states: [ ¥, $ ]

patch:
  "switches/@1":
    - name: ascii_punct  # 中英标点
      reset: 1
      states: [ ¥, $ ]

  # 关闭 输入 "sj" 等组合时, 候选 会有 "18:13" 的配置
  "engine/translators":
    - punct_translator
    - script_translator
    # - lua_translator@*date_translator    # 时间、日期、星期
    - lua_translator@*lunar              # 农历
    - lua_translator@*uuid               # UUID
    - table_translator@custom_phrase     # 自定义短语 custom_phrase.txt
    - table_translator@melt_eng          # 英文输入
    - table_translator@cn_en             # 中英混合词汇
    - table_translator@radical_lookup    # 部件拆字反查
    - lua_translator@*unicode            # Unicode
    - lua_translator@*number_translator  # 数字、金额大写
    - lua_translator@*calc_translator    # 计算器
EOF

# hyprlock 主题
cp hyprlock/* ~/.config/hypr/

cd ..
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

# 配置 Win键 打开 rofi
yay -S --noconfirm --needed keyd
echo "# /etc/keyd/default.conf

[ids]
*

[global]
overload_tap_timeout = 300

[main]
leftmeta = overload(meta, macro(leftmeta+0))" | sudo tee /etc/keyd/default.conf

# 全局中文
echo "LANG=zh_CN.UTF-8" | sudo tee /etc/locale.conf

# LUKS 尝试解密次数 无限制
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

# 临时文件目录 (占用磁盘空间, 重启清空)
echo "D /home/${USER}/tmp 1777 root root -" | sudo tee /etc/tmpfiles.d/mytmp.conf
sudo systemd-tmpfiles --create
