#!/usr/bin/env bash
set -euo pipefail

# 配置参数
OUTPUT_NAME="mihomo"
PKG_SOURCE_URL="https://github.com/MetaCubeX/mihomo.git"
DEFAULT_VERSION="v1.19.24"
GO_PKG="github.com/metacubex/mihomo"
GO_PKG_TAGS="with_gvisor"
PKG_BUILD_TIME=$(date -u -Iseconds)
PKG_SOURCE_VERSION="${1:-$DEFAULT_VERSION}"

# 输出目录
BUILD_DIR="$(pwd)/build"
OUTPUT_DIR="$BUILD_DIR/output"
SRC_DIR="$BUILD_DIR/mihomo-src"

# 可选交叉编译参数
TARGET_GOOS="${GOOS:-linux}"
TARGET_GOARCH="${GOARCH:-amd64}"
TARGET_GOARM="${GOARM:-}"

echo "[*] 构建目标: ${TARGET_GOOS}/${TARGET_GOARCH}${TARGET_GOARM:+ GOARM=$TARGET_GOARM}"

# 准备构建环境
rm -rf "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR"

echo "[*] 克隆 mihomo 源码 ($PKG_SOURCE_VERSION)..."
git clone --depth 1 --branch "$PKG_SOURCE_VERSION" "$PKG_SOURCE_URL" "$SRC_DIR"

# 删除测试目录
if [ -d "$SRC_DIR/rules/logic_test" ]; then
  echo "[*] 删除测试目录 rules/logic_test"
  rm -rf "$SRC_DIR/rules/logic_test"
fi

pushd "$SRC_DIR" >/dev/null

# LDFLAGS
GO_LDFLAGS="-s -w -X ${GO_PKG}/constant.Version=${PKG_SOURCE_VERSION} -X ${GO_PKG}/constant.BuildTime=${PKG_BUILD_TIME}"

# 交叉编译
export GOOS="$TARGET_GOOS"
export GOARCH="$TARGET_GOARCH"
[ -n "$TARGET_GOARM" ] && export GOARM="$TARGET_GOARM"

export CGO_ENABLED=0
export GO111MODULE=on

echo "[*] go build 参数："
echo "    TAGS: ${GO_PKG_TAGS}"
echo "    LDFLAGS: ${GO_LDFLAGS}"

go build -v \
  -trimpath \
  -tags "$GO_PKG_TAGS" \
  -ldflags "$GO_LDFLAGS" \
  -o "$OUTPUT_DIR/$OUTPUT_NAME"

popd >/dev/null

chmod +x "$OUTPUT_DIR/$OUTPUT_NAME"

echo
echo "✅ 构建完成！输出文件：$OUTPUT_DIR/$OUTPUT_NAME"

file "$OUTPUT_DIR/$OUTPUT_NAME"
ls -lh "$OUTPUT_DIR/$OUTPUT_NAME"
