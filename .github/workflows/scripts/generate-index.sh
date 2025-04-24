#!/bin/bash

# 设置变量
repo_dir=${GITHUB_WORKSPACE:-$(pwd)}
output_file="$repo_dir/index.html"

# 创建 HTML 头部
cat > "$output_file" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>huyixi's Internet Archive</title>
    <link rel="stylesheet" href="css/index.min.css">
    <link rel="icon" type="image/png" href="/public/favicon-96x96.png" sizes="96x96" />
    <link rel="icon" type="image/svg+xml" href="/public/favicon.svg" />
    <link rel="shortcut icon" href="/public/favicon.ico" />
    <link rel="apple-touch-icon" sizes="180x180" href="/public/apple-touch-icon.png" />
    <meta name="apple-mobile-web-app-title" content="huyixi's Archive" />
    <link rel="manifest" href="/public/site.webmanifest" />
</head>
<body>
    <h1>huyixi's Internet Archive</h1>
    <ul>
EOF

# 创建临时文件
temp_file=$(mktemp)

# 查找并处理 HTML 文件
find $repo_dir -type f -name "*.html" ! -name "index.html" | while read file; do
    rel_path=$(realpath --relative-to="$repo_dir" "$file")
    html_comment=$(perl -0777 -ne 'print $& if /<!--[\s\S]*?-->/g' "$file")

    # 提取元数据
    title=$(echo "$html_comment" | perl -ne 'print $1 if /title: (.*?)(?:\n|$)/i')
    author=$(echo "$html_comment" | perl -ne 'print $1 if /author: (.*?)(?:\n|$)/i')
    date_from_file=$(echo "$html_comment" | perl -ne 'print $1 if /date: (\d{4}-\d{2}-\d{2})/i')

    if [ ! -z "$date_from_file" ]; then
        timestamp=$(date -d "$date_from_file" +%s)
    else
        timestamp=0
    fi

    echo "$timestamp|$rel_path|$date_from_file|$title|$author" >> $temp_file
done

# 排序并生成 HTML
sort -rn $temp_file | while IFS='|' read -r timestamp path date title author; do
    echo -n "<li>" >> "$output_file"

    if [ ! -z "$title" ]; then
        echo -n "<a href=\"$path\">$title</a>" >> "$output_file"
        if [ ! -z "$author" ] || [ ! -z "$date" ]; then
            echo -n "," >> "$output_file"
        fi
    else
        filename=$(basename "$path" .html)
        display_filename=$(echo "$filename" | cut -d'_' -f1)
        echo -n "<a href=\"$path\">$display_filename</a>" >> "$output_file"
        if [ ! -z "$author" ] || [ ! -z "$date" ]; then
            echo -n "," >> "$output_file"
        fi
    fi

    if [ ! -z "$author" ]; then
        echo -n " <span class=\"author\">$author</span>" >> "$output_file"
        if [ ! -z "$date" ]; then
            echo -n "," >> "$output_file"
        fi
    fi

    if [ ! -z "$date" ]; then
        echo -n " <span class=\"date\">$date</span>" >> "$output_file"
    fi

    echo "</li>" >> "$output_file"
done

# 清理临时文件
rm $temp_file

# 添加 HTML 结束标签
cat >> "$output_file" << 'EOF'
    </ul>
</body>
</html>
EOF
