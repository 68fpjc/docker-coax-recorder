#!/bin/sh
set -eu

: "${RECPATH:?RECPATH is required}"

# 小数点を常に "." にして、ffprobe の値を awk と ffmpeg に渡す
export LC_ALL=C
# ASS 単体の出力は字幕ストリームを基準とするため、録画全体との開始時刻差を補う
recording_start=$(/usr/bin/ffprobe -v error -show_entries format=start_time -of default=noprint_wrappers=1:nokey=1 "$RECPATH")
subtitle_starts=$(/usr/bin/ffprobe -v error -select_streams s:0 -show_entries stream=start_time -of default=noprint_wrappers=1:nokey=1 "$RECPATH")
# ffprobe は MPEG-TS の同じストリームを複数行返すことがあるため、値がすべて一致することも確認する
subtitle_offset=$(printf '%s\n' "$subtitle_starts" | awk -v recording_start="$recording_start" '
    BEGIN {
        number = "^-?[0-9]+([.][0-9]+)?$"
        if (recording_start !~ number) {
            print "Invalid recording start time: " recording_start > "/dev/stderr"
            invalid = 1
            exit 1
        }
    }
    {
        if ($0 !~ number || (seen && $0 != subtitle_start)) {
            print "Invalid subtitle start time: " $0 > "/dev/stderr"
            invalid = 1
            exit 1
        }
        subtitle_start = $0
        seen = 1
    }
    END {
        if (invalid) exit 1
        if (!seen) {
            print "Subtitle start time not found" > "/dev/stderr"
            exit 1
        }
        printf "%.6f\n", subtitle_start - recording_start
    }
')

recording_dir=${RECPATH%/*}
recording_name=${RECPATH##*/}
subtitle_path="${recording_dir}/${recording_name%.*}.ass"

# 時刻差の取得に使った最初の字幕ストリームを出力し、録画の隣に ASS を保存する
/usr/bin/ffmpeg -nostdin -fix_sub_duration -i "$RECPATH" -map 0:s:0 -output_ts_offset "$subtitle_offset" "$subtitle_path"
