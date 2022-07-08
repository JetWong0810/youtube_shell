#!/bin/bash

gen_video_num=$1
cur_date=$(date "+%Y-%m-%d")
format_path=`echo $YOUTUBE_FILE_PATH`/upload
script_path=`echo $YOUTUBE_SCRIPT_PATH`

mp4_str=$(python3 "$script_path/script/get_unuse_video.py" $gen_video_num)
mp3_str=$(python3 "$script_path/script/get_unuse_mp3.py" $gen_video_num)

echo "----------------从数据库获取视频ID: $mp4_str----------------"
echo "----------------从数据库获取音频ID: $mp3_str----------------"

mp4_ids=(`echo $mp4_str | tr ',' ' '`)
mp3_ids=(`echo $mp3_str | tr ',' ' '`)

folder_num=1
if [ ${#mp4_ids[*]} -gt ${#mp3_ids[*]} ]
then
    folder_num=${#mp3_ids[*]}
else
    folder_num=${#mp4_ids[*]}
fi

if [ ! -d $format_path/$cur_date/ ]
then
    mkdir $format_path/$cur_date
fi

echo "----------------创建当前日期文件夹完毕，当前日期: ${cur_date}----------------"

rm -rf $format_path/$cur_date/*

echo "----------------删除当前文件夹下所有文件完毕----------------"

echo "----------------当日生成视频数量: ${folder_num}----------------"

for i in `seq 1 $folder_num`
do  
    dir_name=$format_path/$cur_date/${mp4_ids[i-1]}_${mp3_ids[i-1]}
    mkdir $dir_name
    origin_mp3_path=$(find $YOUTUBE_FILE_PATH/mp3 -name "${mp3_ids[i-1]}.*")
    origin_mp4_path=$(find $YOUTUBE_FILE_PATH/mp4 -name "${mp4_ids[i-1]}.*")
    mp3_ext=${origin_mp3_path##*.}
    mp4_ext=${origin_mp4_path##*.}
    cp $origin_mp3_path $dir_name/origin.$mp3_ext
    cp $origin_mp4_path $dir_name/origin.$mp4_ext

    echo "---------------开始生成第${i}个视频----------------"
    sh $script_path/shell/gen_video.sh ${mp4_ids[i-1]}_${mp3_ids[i-1]} origin.$mp4_ext origin.$mp3_ext
    echo "----------------生成第${i}个视频完毕----------------"

    $(python3 "$script_path/script/create_metadata.py" ${mp3_ids[i-1]} ${mp4_ids[i-1]})

    echo "----------------生成第${i}个视频metadata信息完毕----------------"
done

echo "----------------生成当日所有视频及音频完毕----------------"

echo "----------------开始执行youtube上传----------------"

cd $script_path/youtube-upload

for i in `seq 1 $folder_num`
do
    echo "----------------开始上传第${i}个视频到youtube，视频ID:${mp4_ids[i-1]}，音频ID:${mp3_ids[i-1]}----------------"

    dir_name=$format_path/$cur_date/${mp4_ids[i-1]}_${mp3_ids[i-1]}

    python3 upload.py --video $dir_name/upload.mp4 --meta $dir_name/metadata.json -t $dir_name/cover.png
    
    echo "----------------第${i}个视频到youtube上传完毕----------------"

    #更新视频和音频记录使用状态
    $(python3 "$script_path/script/update_mp3_status.py" ${mp3_ids[i-1]})
    $(python3 "$script_path/script/update_video_status.py" ${mp4_ids[i-1]})

    echo "----------------第${i}个视频及音频更新使用状态成功----------------"

    # echo "----------------延迟执行60s----------------"

    # sleep 60
done