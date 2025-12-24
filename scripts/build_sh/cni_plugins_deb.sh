#!/bin/bash
set -e  # 遇到错误立即退出

# 从环境变量获取参数，如果没有则报错
VERSION="${CNI_VERSION:?Need to set CNI_VERSION}"
TAG="${CNI_TAG:?Need to set CNI_TAG}"
ARCH="${ARCH:-amd64}"
DEB_NAME="cni-plugins-np"
CONTACT_EMAIL="${CONTACT_EMAIL:-huangnomolo@gmail.com}"
FINAL_DEB_DIR="${FINAL_DEB_DIR:?Need to set FINAL_DEB_DIR}"

echo "开始构建: $DEB_NAME 版本: $VERSION ($ARCH)..."

# 准备工作目录
WORK_DIR="${DEB_NAME}_work_dir"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

# 下载 nerdctl
DOWNLOAD_URL="https://github.com/containernetworking/plugins/releases/download/${TAG}/cni-plugins-linux-amd64-${TAG}.tgz"

echo "正在下载: $DOWNLOAD_URL"
wget "$DOWNLOAD_URL" -O "$WORK_DIR/cni.tgz"

# 准备打包目录结构
PKG_DIR="${WORK_DIR}/${DEB_NAME}_${VERSION}_${ARCH}"
mkdir -p "${PKG_DIR}/opt/cni/bin"
mkdir -p "${PKG_DIR}/DEBIAN"

# 解压并归位文件
echo "解压并移动文件..."
tar -xzf "$WORK_DIR/cni.tgz" -C "${PKG_DIR}/opt/cni/bin/"

# 生成 Control 文件
# 计算大小 (KB)
INSTALLED_SIZE=$(du -s "$PKG_DIR" | cut -f1)

cat > "$PKG_DIR"/DEBIAN/control <<EOF
Package: $DEB_NAME
Version: $VERSION
Section: admin
Priority: optional
Architecture: $ARCH
Maintainer: Action Bot <$CONTACT_EMAIL>
Description: CNI Plugins Debian Package
 Auto-packaged from upstream containernetworking plugins release.
 This package installs containernetworking plugins binaries.
 Installed to /opt/cni/bin.
Installed-Size: $INSTALLED_SIZE
Conflicts: cni-plugins
Provides: cni-plugins
EOF

# 构建 .deb
echo "打包 .deb..."
dpkg-deb --build "$PKG_DIR"
mv "${WORK_DIR}/${DEB_NAME}_${VERSION}_${ARCH}.deb" "${FINAL_DEB_DIR}/${DEB_NAME}.deb"

# 清理
rm -rf "$WORK_DIR"

echo "构建完成: ${DEB_NAME}.deb"