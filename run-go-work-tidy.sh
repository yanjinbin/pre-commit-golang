#!/bin/bash

# 确保 go.work 文件存在
if [ ! -f "go.work" ]; then
    echo "Error: go.work file not found. Ensure you're in the workspace root directory."
    exit 1
fi

# 获取传入的忽略模块参数
IGNORE_MODULES=()
while [[ "$1" =~ ^- ]]; do
    case $1 in
        --ignore)
            shift
            IGNORE_MODULES+=("$1")
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
    shift
done

# 提取 use 块中的模块路径
MODULE_PATHS=$(awk '/use \(/,/\)/ {if ($1 != "use" && $1 != "(" && $1 != ")") print $1}' go.work)

# 函数：检查模块是否在忽略列表中
function is_ignored() {
    for ignored in "${IGNORE_MODULES[@]}"; do
        if [ "$ignored" == "$1" ]; then
            return 0 # 如果模块在忽略列表中，返回 0 (表示“是”)
        fi
    done
    return 1 # 否则返回 1 (表示“不”)
}

# 遍历每个模块并运行 go mod tidy
for MODULE in $MODULE_PATHS; do
    # 检查当前模块是否在忽略列表中
    if is_ignored "$MODULE"; then
        echo "Skipping $MODULE as it is in the ignore list."
        continue
    fi

    if [ -d "$MODULE" ]; then
        echo "Running go mod tidy in $MODULE..."
        (cd "$MODULE" && go mod tidy -v "$@")
        if [ $? -ne 0 ]; then
            echo "Error: go mod tidy failed in $MODULE."
            exit 2
        fi

        # 只检查 go.mod 是否有未提交的更改，跳过 go.sum
        (cd "$MODULE" && git diff --exit-code go.mod &> /dev/null)
        if [ $? -ne 0 ]; then
            echo "Error: go.mod in $MODULE differs. Please re-add it to your commit."
            exit 3
        fi
    else
        echo "Warning: Module path $MODULE does not exist."
    fi
done

echo "All modules tidied and verified."
