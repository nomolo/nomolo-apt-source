#!/bin/bash
set -euo pipefail

FINAL_DEB_DIR="${FINAL_DEB_DIR:?Need to set FINAL_DEB_DIR}"

################################################################
# 获取所需软件最新版本号
################################################################
# 获取 nerdctl 最新版本号

# 增加 GitHub Token 支持，避免 API 限流
AUTH_HEADER=""
if [ -n "${GITHUB_TOKEN:-}" ]; then
  AUTH_HEADER="Authorization: token $GITHUB_TOKEN"
fi

NERDCTL_LATEST_TAG=$(curl -H "$AUTH_HEADER" -s https://api.github.com/repos/containerd/nerdctl/releases/latest | jq -r .tag_name)

# 获取 cni-plugins 最新版本号
CNI_LATEST_TAG=$(curl -H "$AUTH_HEADER" -s https://api.github.com/repos/containernetworking/plugins/releases/latest | jq -r .tag_name)

# 获取 buildkit 最新版本号
BUILDKIT_LATEST_TAG=$(curl -H "$AUTH_HEADER" -s https://api.github.com/repos/moby/buildkit/releases/latest | jq -r .tag_name)

# 去掉 'v' 前缀用于比较 (例如 1.7.0)
NERDCTL_VERSION=${NERDCTL_LATEST_TAG#v}
CNI_VERSION=${CNI_LATEST_TAG#v}
BUILDKIT_VERSION=${BUILDKIT_LATEST_TAG#v}

echo "Latest nerdctl version: $NERDCTL_VERSION"
echo "Latest cni-plugins version: $CNI_VERSION"
echo "Latest buildkit version: $BUILDKIT_VERSION"

# 读取上次构建的版本 (如果在 gh-pages 分支有记录)
# 这里为了简单，我们检查当前目录下是否存在标记文件，或者总是尝试构建但依靠 reprepro 判重
echo "NERDCTL_VERSION=$NERDCTL_VERSION" >> $GITHUB_OUTPUT
echo "CNI_VERSION=$CNI_VERSION" >> $GITHUB_OUTPUT
echo "BUILDKIT_VERSION=$BUILDKIT_VERSION" >> $GITHUB_OUTPUT
echo "NERDCTL_TAG=$NERDCTL_LATEST_TAG" >> $GITHUB_OUTPUT
echo "CNI_TAG=$CNI_LATEST_TAG" >> $GITHUB_OUTPUT
echo "BUILDKIT_TAG=$BUILDKIT_LATEST_TAG" >> $GITHUB_OUTPUT