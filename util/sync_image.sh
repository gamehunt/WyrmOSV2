#!/bin/bash
set -euo pipefail

IMG=disk.img
IMG_SIZE_MB=512
ESP_SIZE_MB=100

MNT_BASE=mnt/wyrmos
MNT_ESP="$MNT_BASE/boot"
MNT_DATA="$MNT_BASE/data"

SYSROOT=root
BOOT_DIR=$SYSROOT/boot

if [[ ! -d $BOOT_DIR ]]; then
    echo 'Boot dir not found!'
    exit 1
fi

# Все директории, кроме boot
DATA_DIRS=($(find $SYSROOT -maxdepth 1 -mindepth 1 -type d ! -name boot -printf '%f\n' | sort))
[[ ${#DATA_DIRS[@]} -gt 0 ]] || { echo "no data directories"; exit 1; }

mkdir -p "$MNT_BASE"

# ---------- create image if missing ----------
if [[ ! -f $IMG ]]; then
  dd if=/dev/zero of="$IMG" bs=1M count=$IMG_SIZE_MB status=none

  parted "$IMG" --script mklabel gpt

  # ---------- ESP ----------
  START=1
  END=$ESP_SIZE_MB
  parted "$IMG" --script mkpart ESP fat32 ${START}MiB ${END}MiB
  parted "$IMG" --script set 1 esp on

  # ---------- single data partition ----------
  parted "$IMG" --script mkpart primary ext4 ${END}MiB 100%
fi

LOOP=$(losetup --find --partscan --show "$IMG")

cleanup() {
  for m in "$MNT_BASE"/*; do
    umount -q "$m" 2>/dev/null || true
  done
  losetup -d "$LOOP" 2>/dev/null || true
}
trap cleanup EXIT

# ---------- ESP ----------
ESP_DEV=${LOOP}p1
mkdir -p "$MNT_ESP"

blkid "$ESP_DEV" | grep -q vfat || mkfs.vfat -F32 "$ESP_DEV" >/dev/null
mount "$ESP_DEV" "$MNT_ESP"
rsync -r --delete "$BOOT_DIR"/ "$MNT_ESP"/
umount "$MNT_ESP"

# ---------- data partition ----------
DATA_DEV=${LOOP}p2
mkdir -p "$MNT_DATA"

blkid "$DATA_DEV" | grep -q ext4 || mkfs.ext4 -F "$DATA_DEV" >/dev/null

# Синхронизируем все папки кроме boot
for d in "${DATA_DIRS[@]}"; do
  rsync -r --delete "$SYSROOT"/"$d"/ "$MNT_DATA"/"$d"/
done

mount "$DATA_DEV" "$MNT_DATA"
umount "$MNT_DATA"
