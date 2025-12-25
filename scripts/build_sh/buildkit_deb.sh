#!/bin/bash
set -euo pipefail  # 遇到错误立即退出

# 从环境变量获取参数，如果没有则报错
VERSION="${BUILDKIT_VERSION:?Need to set BUILDKIT_VERSION}"
TAG="${BUILDKIT_TAG:?Need to set BUILDKIT_TAG}"
ARCH="${ARCH:-amd64}"
DEB_NAME="buildkit-np"
CONTACT_EMAIL="${CONTACT_EMAIL:-huangnomolo@gmail.com}"
FINAL_DEB_DIR="${FINAL_DEB_DIR:?Need to set FINAL_DEB_DIR}"

echo "开始构建: $DEB_NAME 版本: $VERSION ($ARCH)..."

# 准备工作目录
WORK_DIR="${DEB_NAME}_work_dir"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

# 下载 nerdctl
DOWNLOAD_URL="https://github.com/moby/buildkit/releases/download/${TAG}/buildkit-${TAG}.linux-amd64.tar.gz"

echo "正在下载: $DOWNLOAD_URL"
wget "$DOWNLOAD_URL" -O "$WORK_DIR/buildkit.tgz"

# 准备打包目录结构
PKG_DIR="${WORK_DIR}/${DEB_NAME}_${VERSION}_${ARCH}"
mkdir -p "${PKG_DIR}/usr/local/bin"
mkdir -p "${PKG_DIR}/DEBIAN"

# 解压并归位文件
echo "解压并移动文件..."
tar -xzf "$WORK_DIR/buildkit.tgz" -C "${PKG_DIR}/usr/local/bin/"

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
Description: BuildKit Debian Package
 Auto-packaged from upstream buildkit release.
 This package installs moby/buildkit binaries.
 Installed to /usr/local/bin.
Installed-Size: $INSTALLED_SIZE
Conflicts: buildkit, docker-buildx
Provides: buildkit
EOF

# 
cat > "$PKG_DIR"/DEBIAN/postinst <<EOF
#!/bin/bash
set -e

cat > /etc/buildkit/buildkitd.toml <<EOL
[worker.oci]
  enabled = false

[worker.containerd]
  enabled = true
  # namespace should be "k8s.io" for Kubernetes (including Rancher Desktop)
  namespace = "default"
EOL

chmod 644 /etc/buildkit/buildkitd.toml
chmod +x /usr/local/bin/buildkitd
/usr/local/bin/buildkitd
EOF

# 构建 .deb
echo "打包 .deb..."
dpkg-deb --build "$PKG_DIR"
mv "${WORK_DIR}/${DEB_NAME}_${VERSION}_${ARCH}.deb" "${FINAL_DEB_DIR}/${DEB_NAME}.deb"

# 清理
rm -rf "$WORK_DIR"

echo "构建完成: ${DEB_NAME}.deb"