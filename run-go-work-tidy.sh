#!/usr/bin/env bash

# 检查 go.work 文件是否存在
if [ -f "go.work" ]; then
  # 从 go.work 中提取模块路径
  MODULE_PATHS=$(grep -E '^\s*use ' go.work | awk '{print $2}')

  # 对每个有改动的模块运行 go mod tidy
  for MODULE in $MODULE_PATHS; do
    if [ -d "$MODULE" ]; then
      # 检查 go.mod 或 go.sum 是否有改动
      (cd "$MODULE" && git diff --exit-code go.mod go.sum &> /dev/null)
      if [ $? -ne 0 ]; then
        echo "检测到 $MODULE 中有改动。正在运行 go mod tidy..."
        (cd "$MODULE" && go mod tidy -v $@)
        if [ $? -ne 0 ]; then
          exit 2
        fi
      else
        echo "$MODULE 的 go.mod 或 go.sum 没有改动。"
      fi
    else
      echo "警告: 模块路径 $MODULE 不存在。"
    fi
  done

  # 检查 go.work 文件是否有改动
  git diff --exit-code go.work &> /dev/null
  if [ $? -ne 0 ]; then
      echo "go.work 文件有改动，正在运行 go work sync..."
      go work sync
      if [ $? -ne 0 ]; then
        exit 4
      fi
  fi
else
  echo "错误: 当前目录中未找到 go.work 文件。"
  exit 1
fi