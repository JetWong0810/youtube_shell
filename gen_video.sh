#!/bin/bash

folder_name=$1  #是文件夹名称
mp4_name=$2  # $2 是视频文件名称
mp3_name=$3  # $3 是音频文件名称
cur_date=$(date "+%Y-%m-%d")
format_path=`echo $YOUTUBE_FILE_PATH`/upload
script_path=`echo $YOUTUBE_SCRIPT_PATH`
sed_flag=`echo $YOUTUBE_SED_FLAG`

if [ -f $format_path/$cur_date/$folder_name/$mp4_name ]
then
    video_time_str=$(ffmpeg -i $format_path/$cur_date/$folder_name/$mp4_name 2>&1 | grep 'Duration' | cut -d ' ' -f 4 | sed s/,//) #获取视频时长
    echo "视频长度: $video_time_str"
else
    echo '原始视频文件不存在!'
    exit
fi

if [ -f $format_path/$cur_date/$folder_name/$mp3_name ]
then
    audio_time_str=$(ffmpeg -i $format_path/$cur_date/$folder_name/$mp3_name 2>&1 | grep 'Duration' | cut -d ' ' -f 4 | sed s/,//) #获取音频时长
    echo "音频长度: $audio_time_str"
else
    echo '原始音频文件不存在!'
    exit
fi

video_time_arr=(${video_time_str//:/ })
audio_time_arr=(${audio_time_str//:/ })

audio_time_num=`expr ${audio_time_arr[0]} \* 60 \* 60 + ${audio_time_arr[1]} \* 60`
audio_time_num=`echo ${audio_time_num}+${audio_time_arr[2]} | bc`
video_time_num=${video_time_arr[2]}

video_num=`echo ${audio_time_num} / ${video_time_num} + 1 | bc`

echo "视频重复次数: $video_num"

for i in `seq 1 $video_num`
do
    echo "file $mp4_name" >> $format_path/$cur_date/$folder_name/video_list.txt
done

ffmpeg -loglevel panic -y -f concat -safe 0 -i $format_path/$cur_date/$folder_name/video_list.txt -c copy -f mp4 $format_path/$cur_date/$folder_name/output.mp4 #生成指定长度视频

echo "$cur_date/$folder_name 视频生成成功"

ffmpeg -i $format_path/$cur_date/$folder_name/output.mp4 -i $format_path/$cur_date/$folder_name/$mp3_name -c:v copy -c:a aac -strict experimental -map 0:v:0 -map 1:a:0 $format_path/$cur_date/$folder_name/upload.mp4

echo "$cur_date/$folder_name 合并视频音频成功"

ffmpeg -ss 00:00:10 -i $format_path/$cur_date/$folder_name/output.mp4 -f image2 -y -frames:v 1 $format_path/$cur_date/$folder_name/cover.png  #生成视频封面缩略图

echo "$cur_date/$folder_name 生成视频封面成功"

cover_font_color=$(python3 "$script_path/script/get_img_font_color.py" $folder_name)

echo "$cur_date/$folder_name 获取封面图片文字颜色: $cover_font_color"

sed -i "" "s/color_position/$cover_font_color/g" $script_path/cover-maker/template/1/conf.ini #替换文字颜色

cp -f $format_path/$cur_date/$folder_name/cover.png "$script_path/cover-maker/template/1/cover.png"

python3 $script_path/cover-maker/cover_maker.py -o $format_path/$cur_date/$folder_name -t $script_path/cover-maker/template/1 -c $script_path/cover-maker/test.csv

echo "$cur_date/$folder_name 生成带文字封面成功"

sed -i "" "s/$cover_font_color/color_position/g" $script_path/cover-maker/template/1/conf.ini #还原文字颜色

rm -rf $format_path/$cur_date/$folder_name/video_list.txt
rm -rf $format_path/$cur_date/$folder_name/output.mp4

