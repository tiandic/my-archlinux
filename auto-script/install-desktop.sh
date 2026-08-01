#!/bin/bash
set -euo pipefail

sudo pacman -Syu --noconfirm --needed

# WM
sudo pacman -S --noconfirm --needed niri qt6-multimedia-ffmpeg xwayland-satellite xdg-desktop-portal-gtk kitty

niri-session &

while ! [[ -f ~/.config/niri/config.kdl ]]; do
  sleep 1
done

killall niri

sed -i 's/alacritty/kitty/g' ~/.config/niri/config.kdl

# 通知
sudo pacman -S --noconfirm --needed libnotify mako

# 输入法
sudo pacman -S --noconfirm --needed fcitx5-im fcitx5-rime rime-ice-git # fcitx5-im 是一个包组 让你选择安装其中哪些包时,直接回车安装所有包即可

fcitx5 -d &>/dev/null

while ! [[ -d ~/.config/fcitx5/conf ]]; do
  sleep 1
done

mkdir -p ~/.local/share/fcitx5/rime

cat >~/.local/share/fcitx5/rime/default.custom.yaml <<EOF
patch:
  # 这里的 rime_ice_suggestion 为雾凇方案的默认预设
  __include: rime_ice_suggestion:/
EOF

echo 'XMODIFIERS="@im=fcitx"' | sudo tee -a /etc/environment
# 最后,需要在 `~/.config/niri/config.kdl` 为`fcitx5` 配置启动,以在进入`niri`后可以直接使用`fcitx5`,而无需手动启动 (上面的 `mako` 是因为其在`/usr/lib/systemd/user/mako.service`中有`WantedBy=graphical-session.target`,所以无需手动配置启动)
echo 'spawn-at-startup "fcitx5" "-d"' >>~/.config/niri/config.kdl

killall fcitx5
cat >~/.config/fcitx5/config <<EOF
[Hotkey]
# 按住切换键的修饰键时进行轮换切换
EnumerateWithTriggerKeys=True
# 向前切换输入法
EnumerateForwardKeys=
# 向后切换输入法
EnumerateBackwardKeys=
# 轮换输入法时跳过第一个输入法
EnumerateSkipFirst=False
# 触发修饰键快捷键的时限 (毫秒)
ModifierOnlyKeyTimeout=250

[Hotkey/TriggerKeys]
0=Control+space

[Hotkey/ActivateKeys]
0=Hangul_Hanja

[Hotkey/DeactivateKeys]
0=Hangul_Romaja

[Hotkey/AltTriggerKeys]
0=Control+space

[Hotkey/EnumerateGroupForwardKeys]
0=Super+space

[Hotkey/EnumerateGroupBackwardKeys]
0=Shift+Super+space

[Hotkey/PrevPage]
0=Up

[Hotkey/NextPage]
0=Down

[Hotkey/PrevCandidate]
0=Shift+Tab

[Hotkey/NextCandidate]
0=Tab

[Hotkey/TogglePreedit]
0=Control+Alt+P

[Behavior]
# 默认激活输入法
ActiveByDefault=False
# 重新聚焦时重置状态
resetStateWhenFocusIn=No
# 共享输入状态
ShareInputState=No
# 在程序中显示预编辑文本
PreeditEnabledByDefault=True
# 切换输入法时显示输入法信息
ShowInputMethodInformation=True
# 在焦点更改时显示输入法信息
showInputMethodInformationWhenFocusIn=False
# 显示紧凑的输入法信息
CompactInputMethodInformation=True
# 显示第一个输入法的信息
ShowFirstInputMethodInformation=True
# 缺省每页候选词
DefaultPageSize=5
# 覆盖 XKB 选项
OverrideXkbOption=False
# 自定义 XKB 选项
CustomXkbOption=
# Force Enabled Addons
EnabledAddons=
# Force Disabled Addons
DisabledAddons=
# Preload input method to be used by default
PreloadInputMethod=True
# 允许在密码框中使用输入法
AllowInputMethodForPassword=False
# 输入密码时显示预编辑文本
ShowPreeditForPassword=False
# 保存用户数据的时间间隔（以分钟为单位）
AutoSavePeriod=30

EOF

cat >~/.config/fcitx5/profile <<EOF
[Groups/0]
# Group Name
Name=Default
# Layout
Default Layout=us
# Default Input Method
DefaultIM=rime

[Groups/0/Items/0]
# Name
Name=rime
# Layout
Layout=

[GroupOrder]
0=Default

EOF

fcitx5 -d &>/dev/null

yay -S --noconfirm hyprlock

if ! [[ -f ~/.config/hypr/hyprlock.conf ]]; then
  mkdir -p ~/.config/hypr
  cat >~/.config/hypr/hyprlock.conf <<EOF
# ~/.config/hypr/hyprlock.conf

background {
    path = screenshot
    blur_passes = 3
}

input-field {
    monitor =
    size = 300, 50
    position = 0, 0
    halign = center
    valign = center
}
EOF
fi
sed -i 's/swaylock/hyprlock/g' ~/.config/niri/config.kdl

# 剪贴板
yay -S --noconfirm wl-clipboard clipse

# 为其剪贴板配置启动
echo 'spawn-at-startup "clipse" "--listen"' >>~/.config/niri/config.kdl

# 配置快捷键
sed -i '/Mod+Shift+P { power-off-monitors; }/a \
\
    Alt+C hotkey-overlay-title="Open the clipboard" { spawn "kitty" "-e" "clipse"; }' .config/niri/config.kdl

# 壁纸
yay -S --noconfirm awww waypaper

# 配置启动
echo 'spawn-at-startup "awww-daemon"' >>~/.config/niri/config.kdl

# 面板
sudo pacman -S --noconfirm --needed waybar

# 应用启动器
sudo pacman -S --noconfirm --needed rofi-wayland
# 替换默认的启动器
sed -i 's/fuzzel/rofi/' ~/.config/niri/config.kdl
sed -i 's/"fuzzel"/"rofi" "-show" "drun" "-show-icons"/g' ~/.config/niri/config.kdl

# 登陆管理器
sudo pacman -S --noconfirm --needed sddm
sudo systemctl enable sddm

# 注销菜单
yay -S --noconfirm wlogout

# 配置 Win+<F4> 快捷键打开注销菜单
sed -i '/Mod+Shift+P { power-off-monitors; }/a \
\
    Mod+F4 hotkey-overlay-title="Open the logout menu" { spawn "wlogout"; }' .config/niri/config.kdl

# 文件管理器
sudo pacman -S --noconfirm --needed yazi # 一个终端文件管理器
sed -i '/Mod+Shift+P { power-off-monitors; }/a \
\
    Mod+E hotkey-overlay-title="Open the file manager." { spawn "kitty" "-e" "yazi"; }' .config/niri/config.kdl
