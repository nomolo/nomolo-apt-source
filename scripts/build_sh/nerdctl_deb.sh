#!/bin/bash
set -e  # 遇到错误立即退出

# 从环境变量获取参数，如果没有则报错
VERSION="${NERDCTL_VERSION:?Need to set NERDCTL_VERSION}"
TAG="${NERDCTL_TAG:?Need to set NERDCTL_TAG}"
ARCH="${ARCH:-amd64}"
DEB_NAME="${DEB_NAME:-nerdctl-np}"
CONTACT_EMAIL="${CONTACT_EMAIL:-huangnomolo@gmail.com}"
FINAL_DEB_DIR="${FINAL_DEB_DIR:?Need to set FINAL_DEB_DIR}"

echo "开始构建: $DEB_NAME 版本: $VERSION ($ARCH)..."

# 准备工作目录
WORK_DIR="${DEB_NAME}_work_dir"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

# 下载 nerdctl
NERDCTL_DOWNLOAD_URL="https://github.com/containerd/nerdctl/releases/download/${TAG}/nerdctl-${NERDCTL_VERSION}-linux-${ARCH}.tar.gz"

echo "正在下载: $NERDCTL_DOWNLOAD_URL"
wget "$NERDCTL_DOWNLOAD_URL" -O "$WORK_DIR/nerdctl.tar.gz"

# 准备打包目录结构
PKG_DIR="${WORK_DIR}/${DEB_NAME}_${VERSION}_${ARCH}"
mkdir -p "$PKG_DIR"/usr/local/bin
mkdir -p "$PKG_DIR"/DEBIAN

# 解压并归位文件
echo "解压并移动文件..."
UNZIP_DIR="$WORK_DIR/unzip"
mkdir -p "$UNZIP_DIR"
tar -xzf "$WORK_DIR/nerdctl.tar.gz" -C "$UNZIP_DIR"

# 移动二进制文件 
mv "$UNZIP_DIR" "$PKG_DIR"/usr/local/bin/

# 生成 Control 文件
# 计算大小 (KB)
INSTALLED_SIZE=$(du -s "$PKG_DIR" | cut -f1)

cat <<EOF > "$PKG_DIR"/DEBIAN/control
Package: $DEB_NAME
Version: $VERSION
Section: admin
Priority: optional
Architecture: $ARCH
Maintainer: Action Bot <$CONTACT_EMAIL>
Description: Nerdctl Full Stack (nerdctl + buildkit + CNI)
 Auto-packaged from upstream nerdctl-full release.
 This package installs nerdctl, buildkitd, buildctl and CNI plugins.
 Installed to /usr/local/bin and /opt/cni/bin.
Installed-Size: $INSTALLED_SIZE
Conflicts: nerdctl
Provides: nerdctl
EOF

# 构建 .deb
echo "打包 .deb..."
dpkg-deb --build "$PKG_DIR"
mv "${WORK_DIR}/${DEB_NAME}_${VERSION}_${ARCH}.deb" "${FINAL_DEB_DIR}/${DEB_NAME}-np.deb"

# 7. 清理
rm -rf "$WORK_DIR"

echo "构建完成: ${DEB_NAME}-np.deb"