#!/bin/bash
# สลับ preset ของมุมมองกราฟ Obsidian
# ใช้:  bash _presets/swap.sh A     (หรือ B, C, reset)
#
# Obsidian อ่าน graph.json ตอนเปิดแอป และเขียนทับตอนปิด
# เพราะงั้นต้องปิด Obsidian ก่อนสลับเสมอ ไม่งั้นค่าจะโดนทับกลับ

set -e
V="$(cd "$(dirname "$0")/.." && pwd)"
G="$V/.obsidian/graph.json"
P="$V/_presets"

case "$1" in
  A|a) SRC="$P/A-org-map.json";      NAME="A · แผนที่องค์กร" ;;
  B|b) SRC="$P/B-living.json";       NAME="B · เฉพาะที่มีชีวิต" ;;
  C|c) SRC="$P/C-problem-hunt.json"; NAME="C · ล่าปัญหา" ;;
  reset) SRC="$P/_backup-original.json"; NAME="ค่าเดิมก่อนแตะ" ;;
  *)
    echo "ใช้: bash _presets/swap.sh [A|B|C|reset]"
    echo ""
    echo "  A  แผนที่องค์กร     ลงสีตาม wiki ซ่อนผี กระจายให้โปร่ง"
    echo "  B  เฉพาะที่มีชีวิต   ซ่อนโน้ตกำพร้า ลงสีตามประเภทงาน จับกลุ่มแน่น"
    echo "  C  ล่าปัญหา        โชว์ผีกับกำพร้า ไฮไลต์ไฟล์ชื่อซ้ำเป็นสีแดง"
    exit 1 ;;
esac

if pgrep -x Obsidian > /dev/null; then
  echo "Obsidian ยังเปิดอยู่ ปิดก่อนด้วย Cmd+Q แล้วรันใหม่"
  echo "ไม่งั้นตอนปิดแอปมันจะเขียนทับค่าที่เพิ่งใส่"
  exit 1
fi

# เก็บค่าเดิมไว้ครั้งแรกครั้งเดียว
if [ ! -f "$P/_backup-original.json" ] && [ -f "$G" ]; then
  cp "$G" "$P/_backup-original.json"
  echo "เก็บค่าเดิมไว้ที่ _presets/_backup-original.json แล้ว"
fi

if [ ! -f "$SRC" ]; then echo "ไม่เจอไฟล์ preset: $SRC"; exit 1; fi

cp "$SRC" "$G"
echo "เปลี่ยนเป็น preset $NAME แล้ว"
echo "เปิด Obsidian แล้วกดมุมมองกราฟได้เลย"
