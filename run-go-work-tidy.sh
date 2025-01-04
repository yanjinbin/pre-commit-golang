#!/usr/bin/env bash

# 确保脚本在工作区根目录运行
if [ ! -f "go.work" ]; then
  echo "Error: go.work file not found. Ensure you're in the workspace root directory."
  exit 1
fi

# 读取 go.work 中的模块路径
MODULE_PATHS=$(grep -E '^\s*use ' go.work | awk '{print $2}' | tr -d '"')
echo "MODULE_PATHS: $MODULE_PATHS"

# 遍历每个模块并运行 go mod tidy
for MODULE in $MODULE_PATHS; do
    echo "MODULE: $MODULE"
    if [ -d "$MODULE" ]; then
        echo "Running go mod tidy in $MODULE..."
        (cd "$MODULE" && go mod tidy -v "$@")
        if [ $? -ne 0 ]; then
            echo "Error: go mod tidy failed in $MODULE."
            exit 2
        fi

        # 检查 go.mod 或 go.sum 是否有未提交的更改
        (cd "$MODULE" && git diff --exit-code go.mod go.sum &> /dev/null)
        if [ $? -ne 0 ]; then
            echo "Error: go.mod or go.sum in $MODULE differs. Please re-add it to your commit."
            exit 3
        fi
    else
        echo "Warning: Module path $MODULE does not exist."
    fi
done

echo "All modules tidied and verified."
