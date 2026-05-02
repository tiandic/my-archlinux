#!/bin/bash
set -euo pipefail

systemctl enable --now grub-btrfsd

# 创建自动备份配置
snapper -c root create-config /
snapper -c home create-config /home

# / 的配置
sed -i 's/ALLOW_GROUPS=""/ALLOW_GROUPS="wheel"/' /etc/snapper/configs/root
sed -Ei 's/NUMBER_LIMIT="[0-9]+"/NUMBER_LIMIT="15"/' /etc/snapper/configs/root
sed -Ei 's/TIMELINE_LIMIT_HOURLY="[0-9]+"/TIMELINE_LIMIT_HOURLY="1"/' /etc/snapper/configs/root
sed -Ei 's/TIMELINE_LIMIT_DAILY="[0-9]+"/TIMELINE_LIMIT_DAILY="1"/' /etc/snapper/configs/root
 
sed -Ei 's/TIMELINE_MIN_AGE="[0-9]+"/TIMELINE_MIN_AGE="0"/' /etc/snapper/configs/root
sed -Ei 's/TIMELINE_LIMIT_WEEKLY="[0-9]+"/TIMELINE_LIMIT_WEEKLY="0"/' /etc/snapper/configs/root
sed -Ei 's/TIMELINE_LIMIT_MONTHLY="[0-9]+"/TIMELINE_LIMIT_MONTHLY="0"/' /etc/snapper/configs/root
sed -Ei 's/TIMELINE_LIMIT_QUARTERLY="[0-9]+"/TIMELINE_LIMIT_QUARTERLY="0"/' /etc/snapper/configs/root
sed -Ei 's/TIMELINE_LIMIT_YEARLY="[0-9]+"/TIMELINE_LIMIT_YEARLY="0"/' /etc/snapper/configs/root

# /home 的配置
sed -i 's/ALLOW_GROUPS=""/ALLOW_GROUPS="wheel"/' /etc/snapper/configs/home
sed -Ei 's/NUMBER_LIMIT="[0-9]+"/NUMBER_LIMIT="10"/' /etc/snapper/configs/home
sed -Ei 's/TIMELINE_LIMIT_HOURLY="[0-9]+"/TIMELINE_LIMIT_HOURLY="1"/' /etc/snapper/configs/home
sed -Ei 's/TIMELINE_LIMIT_DAILY="[0-9]+"/TIMELINE_LIMIT_DAILY="1"/' /etc/snapper/configs/home
 
sed -Ei 's/TIMELINE_MIN_AGE="[0-9]+"/TIMELINE_MIN_AGE="0"/' /etc/snapper/configs/home
sed -Ei 's/TIMELINE_LIMIT_WEEKLY="[0-9]+"/TIMELINE_LIMIT_WEEKLY="0"/' /etc/snapper/configs/home
sed -Ei 's/TIMELINE_LIMIT_MONTHLY="[0-9]+"/TIMELINE_LIMIT_MONTHLY="0"/' /etc/snapper/configs/home
sed -Ei 's/TIMELINE_LIMIT_QUARTERLY="[0-9]+"/TIMELINE_LIMIT_QUARTERLY="0"/' /etc/snapper/configs/home
sed -Ei 's/TIMELINE_LIMIT_YEARLY="[0-9]+"/TIMELINE_LIMIT_YEARLY="0"/' /etc/snapper/configs/home

# 启动按时间自动创建快照和自动清理
systemctl enable --now snapper-timeline.timer
systemctl enable --now snapper-cleanup.timer
