#!/bin/sh

XMLLINT=xmllint

if [ -t 1 ]; then
  R=$(tput setaf 1)
  G=$(tput setaf 2)
  Y=$(tput setaf 3)
  N=$(tput sgr0)
fi

indent=""
use_tab=""
inplace=0

print_usage() {
  echo "Usage: check-xmllint [-i] [--indent <n>] [--tab] <files..>
  -i              Overwrite files with formatted content
  --indent <n>    Set indent size in spaces
  --tab           Use tab characters instead of spaces
  (default behavior reads from .editorconfig if exists)"
}

# 参数解析
args=$(getopt -o i -l indent:,tab -- "$@")
if [ $? -ne 0 ]; then
  print_usage
  exit 2
fi
eval set -- "$args"

while true; do
  case "$1" in
    -i)
      inplace=1
      shift
      ;;
    --indent)
      indent=$2
      use_tab=0
      shift 2
      ;;
    --tab)
      use_tab=1
      indent=""
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

if [ $# -eq 0 ]; then
  print_usage
  exit 2
fi

# 从 .editorconfig 读取设置（如果未被命令行覆盖）
read_editorconfig() {
  local file=$1
  local section_found=0
  local style=""
  local size=""

  while IFS= read -r line; do
    case "$line" in
      \[*\])
        section_found=0
        pattern=$(echo "$line" | sed -E 's/\[|\]//g')
        if [ "$pattern" = "*" ] || echo "$file" | grep -qE "$pattern"; then
          section_found=1
        fi
        ;;
      indent_style*)
        if [ $section_found -eq 1 ]; then
          style=$(echo "$line" | cut -d= -f2 | xargs)
        fi
        ;;
      indent_size*)
        if [ $section_found -eq 1 ]; then
          size=$(echo "$line" | cut -d= -f2 | xargs)
        fi
        ;;
    esac
  done < .editorconfig

  if [ -n "$style" ]; then
    if [ "$style" = "tab" ]; then
      use_tab=1
    else
      use_tab=0
    fi
  fi
  if [ -n "$size" ] && [ "$use_tab" -eq 0 ]; then
    indent=$size
  fi
}

# 生成缩进替换 sed 脚本
generate_sed() {
  local sed_script=""
  local i=1
  while [ $i -le 20 ]; do
    from_indent=$(printf "%*s" $((i * 2)) "")
    if [ "$use_tab" = "1" ]; then
      to_indent=$(printf "%${i}s" "" | tr ' ' '\t')
    else
      to_indent=$(printf "%*s" $((i * indent)) "")
    fi
    sed_script="$sed_script;s/^$from_indent/$to_indent/;"
    i=$((i + 1))
  done
  echo "$sed_script"
}

retval=0

for FILE in "$@"; do
  # 如果未指定缩进方式，尝试读取 .editorconfig
  if [ -z "$indent" ] && [ -z "$use_tab" ] && [ -f ".editorconfig" ]; then
    read_editorconfig "$FILE"
  fi

  # 默认 fallback
  [ -z "$indent" ] && indent=2
  [ -z "$use_tab" ] && use_tab=0

  sed_script=$(generate_sed)

  tmpfile=$(mktemp)
  if ! $XMLLINT --format "$FILE" 2>/dev/null | sed "$sed_script" > "$tmpfile"; then
    echo "XML check for $FILE: ${R}cannot parse${N}"
    retval=1
  else
    if ! diff "$tmpfile" "$FILE" >/dev/null; then
      if [ $inplace -eq 0 ]; then
        echo "XML check for $FILE: ${R}failed${N}"
        retval=2
      else
        cp "$tmpfile" "$FILE"
        echo "XML check for $FILE: ${Y}reformatted${N}"
      fi
    else
      echo "XML check for $FILE: ${G}OK${N}"
    fi
  fi
  rm -f "$tmpfile"
done

exit $retval
