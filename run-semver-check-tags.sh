#!/usr/bin/env bash
# Check Semantic Version compliance
# Based on: https://gist.github.com/rverst/1f0b97da3cbeb7d93f4986df6e8e5695

function chsv_check_version() {
  if [[ $1 =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-((0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*))?(\+([0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*))?$ ]]; then
    echo "$1"
  else
    echo ""
  fi
}

function chsv_check_version_ex() {
  if [[ $1 =~ ^v.+$ ]]; then
    chsv_check_version "${1:1}"
  else
    chsv_check_version "${1}"
  fi
}

function chsv_check_all_git_tags() {
  local failed=0
  for tag in $(git tag); do
    semver=$(chsv_check_version_ex "$tag")
    if [[ ! "$semver" ]]; then
      echo "❌ '$tag' is NOT a valid semantic version"
      failed=1
    else
      echo "✅ '$tag' is valid"
    fi
  done

  if [[ $failed -ne 0 ]]; then
    echo
    echo "🚫 有不符合 SemVer 格式的 Git 标签"
    exit 3
  fi
}

function chsv_print_usage() {
  echo
  echo "Usage: check_semver.sh [OPTIONS] VERSION"
  echo
  echo "Options:"
  echo "  -v        Verbose output"
  echo "  -t        Run tests"
  echo "  -g        Check all Git tags for SemVer compliance"
  echo "  -h        Print usage"
  echo
}

function chsv_test_valid() {
  local valid=(0.0.4 1.2.3 10.20.30 1.1.2-prerelease+meta 1.1.2+meta 1.1.2+meta-valid 1.0.0-alpha 1.0.0-beta 1.0.0-alpha.beta 1.0.0-alpha.beta.1 1.0.0-alpha.1 1.0.0-alpha0.valid 1.0.0-alpha.0valid 1.0.0-alpha-a.b-c-somethinglong+build.1-aef.1-its-okay 1.0.0-rc.1+build.1 2.0.0-rc.1+build.123 1.2.3-beta 10.2.3-DEV-SNAPSHOT 1.2.3-SNAPSHOT-123 1.0.0 2.0.0 1.1.7 2.0.0+build.1848 2.0.1-alpha.1227 1.0.0-alpha+beta 1.2.3----RC-SNAPSHOT.12.9.1--.12+788 1.2.3----R-S.12.9.1--.12+meta 1.2.3----RC-SNAPSHOT.12.9.1--.12 1.0.0+0.build.1-rc.10000aaa-kk-0.1 99999999999999999999999.999999999999999999.99999999999999999 1.0.0-0A.is.legal)
  for i in "${valid[@]}"; do
    if [[ ! $(chsv_check_version "${i}") ]]; then
      echo "❌ error: '${i}' should be valid"
      exit 1
    fi
  done
  echo "✅ chsv_test_valid passed"
}

function chsv_test_invalid() {
  local invalid=(1 1.2 1.2.3-0123 1.2.3-0123.0123 1.1.2+.123 +invalid -invalid -invalid+invalid -invalid.01 alpha alpha.beta alpha.beta.1 alpha.1 alpha+beta alpha_beta alpha. alpha.. beta 1.0.0-alpha_beta -alpha. 1.0.0-alpha.. 1.0.0-alpha..1 1.0.0-alpha...1 1.0.0-alpha....1 1.0.0-alpha.....1 1.0.0-alpha......1 1.0.0-alpha.......1 01.1.1 1.01.1 1.1.01 1.2 1.2.3.DEV 1.2-SNAPSHOT 1.2.31.2.3----RC-SNAPSHOT.12.09.1--..12+788 1.2-RC-SNAPSHOT -1.0.3-gamma+b7718 +justmeta 9.8.7+meta+meta  9.8.7-whatever+meta+meta 99999999999999999999999.999999999999999999.99999999999999999----RC-SNAPSHOT.12.09.1--------------------------------..12)
  for i in "${invalid[@]}"; do
    if [[ $(chsv_check_version "${i}") ]]; then
      echo "❌ error: '${i}' should be invalid"
      exit 1
    fi
  done
  echo "✅ chsv_test_invalid passed"
}

function chsv_main() {
  test=0
  verbose=0
  version=""
  check_git=0

  while getopts ":vtgh" opt; do
    case $opt in
      t) test=1 ;;
      v) verbose=1 ;;
      g) check_git=1 ;;
      h) chsv_print_usage; exit 0 ;;
      \?) echo "Invalid option -$OPTARG" >&2; chsv_print_usage; exit 1 ;;
    esac
  done

  if [[ $test -eq 1 ]]; then
    chsv_test_valid
    chsv_test_invalid
    exit 0
  fi

  if [[ $check_git -eq 1 ]]; then
    chsv_check_all_git_tags
    exit 0
  fi

  version="${@: -1}"
  semver=$(chsv_check_version_ex "$version")

  if [[ ! "$semver" ]]; then
    if [[ $verbose -eq 1 ]]; then
      echo "'$version' is not a valid semantic version"
    fi
    exit 2
  fi

  if [[ $verbose -eq 1 ]]; then
    echo "$semver"
  fi
  exit 0
}

chsv_main "$@"
