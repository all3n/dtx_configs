#!/bin/bash

# 配置信息
BUCKET="s3://dev/qxdata/dtx"
PROFILE="r2"
METADATA_FILE="metadata.json"


R2_ENDPOINT_URL=""
if [[ -n "$R2_ACCOUNT_ID" ]];then
    R2_ACCOUNT_ID="${R2_ACCOUNT_ID}"
    R2_ENDPOINT_URL="https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com"
fi

# 开始JSON数组
echo "[" > "$METADATA_FILE"

# 计数器
count=0
total_files=$(ls *.cfg | wc -l)

upload_s3_file(){
    local LOCAL_FILE=$1
    local TARGET_FILE=$2
    if [[ -n "$R2_ACCOUNT_ID" ]];then
        aws --endpoint=$R2_ENDPOINT_URL --profile="$PROFILE" s3 cp "$LOCAL_FILE" "$BUCKET/$TARGET_FILE"
    else
        aws --profile="$PROFILE" s3 cp "$LOCAL_FILE" "$BUCKET/$TARGET_FILE"
    fi
}
echo "开始上传 .cfg 文件..."

# 遍历所有.cfg文件
for file in *.cfg; do
    ((count++))
    echo "正在处理 ($count/$total_files): $file"
    
    # 计算文件hash (SHA256)
    file_hash=$(sha256sum "$file" | awk '{print $1}')
    file_md5=$(md5sum "$file" |awk '{print $1}')
    
    upload_s3_file $file $file
    
    if [ $? -eq 0 ]; then
        echo "✓ 上传成功: $file"
        
        # 构建URL (根据你的实际URL结构调整)
        url="https://r2dev.all3n.top/qxdata/dtx/$file"
        
        # 添加到JSON
        if [ $count -eq 1 ]; then
            echo "  {" >> "$METADATA_FILE"
        else
            echo "  ,{" >> "$METADATA_FILE"
        fi
        
        cat >> "$METADATA_FILE" << EOF
    "filename": "$file",
    "url": "$url",
    "sha256": "$file_hash",
    "md5": "$file_md5",
    "upload_time": "$(date -Iseconds)"
  }
EOF
        
    else
        echo "✗ 上传失败: $file"
    fi
done

# 结束JSON数组
echo "]" >> "$METADATA_FILE"

echo ""
echo "完成! 已上传 $count 个文件"
echo "元数据已保存到: $METADATA_FILE"
METADATA_FILENAME=$(basename $METADATA_FILE)
upload_s3_file $METADATA_FILE $METADATA_FILENAME
