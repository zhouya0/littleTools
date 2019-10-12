source /etc/profile

echo "================================================"
echo "get kubernetes version"
KUBE_GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null)
KUBE_GIT_VERSION=$(git describe --tags --abbrev=14 "${KUBE_GIT_COMMIT}" | cut -d "-" -f 1)

export KUBE_VERSION=${KUBE_GIT_VERSION-}

echo "================================================"
echo "create kubernetes version file"
cat <<EOF >"dce_version"
KUBE_GIT_COMMIT=${KUBE_GIT_COMMIT-}
KUBE_GIT_TREE_STATE='clean'
KUBE_GIT_VERSION=${KUBE_GIT_VERSION-}
KUBE_GIT_MAJOR='${KUBE_VERSION:0:1}'
KUBE_GIT_MINOR='${KUBE_VERSION:2:2}'
EOF


echo "================================================"
echo "building kubelet and kubectl"
KUBE_GIT_VERSION_FILE=./dce_version build/run.sh make kubelet kubectl KUBE_BUILD_PLATFORMS=windows/amd64
mv _output/dockerized/bin/windows/amd64/kubelet.exe $HOME/win_bins/
mv _output/dockerized/bin/windows/amd64/kubectl.exe $HOME/win_bins/

echo "================================================"
echo "build kube-proxy and kubeadm"
bash $HOME/build_kube.sh


tar -zvcf $HOME/win-${KUBE_VERSION}.tar.gz $HOME/win_bins

source /etc/qiniu_variable
qshell account $(QINIU_AK) $(QINIU_SK)
qshell rput dao-get kubernetes-release/release/win-${KUBE_VERSION}.tar.gz $HOME/win-${KUBE_VERSION}.tar.gz
