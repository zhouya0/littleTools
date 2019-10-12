echo "================================================"
echo "get kubernetes version"
KUBE_GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null)
KUBE_GIT_VERSION=$(git describe --tags --abbrev=14 "${KUBE_GIT_COMMIT}" | cut -d "-" -f 1)
KUBE_VERSION=${KUBE_GIT_VERSION}

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
echo "get remote images versions"
VERSION_CROSS=$(cat build/build-image/cross/VERSION)
echo 'kube-cross version:' ${VERSION_CROSS}
VERSION_PAUSE=$(grep -E "TAG=|TAG =" build/pause/Makefile | cut -d "=" -f 2 | awk '$1=$1')
echo 'kube-pause version:' ${VERSION_PAUSE}
VERSION_DEBIAN_HYPERKUBE_BASE=$(grep -E "TAG=|TAG =" build/debian-hyperkube-base/Makefile | cut -d "=" -f 2 | awk '$1=$1')
echo 'debian-hyperkube version:' ${VERSION_DEBIAN_HYPERKUBE_BASE}
VERSION_DEBIAN_BASE=$( grep "debian_base_version=" build/common.sh | cut -d "=" -f 2 | awk '$1=$1')
echo 'debian-base version:' ${VERSION_DEBIAN_BASE}
VERSION_DEBIAN_IPTABLES=$(grep "debian_iptables_version=" build/common.sh | cut -d "=" -f 2 |awk '$1=$1')
echo 'debian-iptables version:' ${VERSION_DEBIAN_IPTABLES}
docker_wrapper pull k8s.gcr.io/kube-cross:${VERSION_CROSS}
docker_wrapper pull k8s.gcr.io/pause-amd64:${VERSION_PAUSE}
docker_wrapper pull k8s.gcr.io/debian-base-amd64:${VERSION_DEBIAN_BASE}
docker_wrapper pull k8s.gcr.io/debian-iptables-amd64:${VERSION_DEBIAN_IPTABLES}
docker_wrapper pull k8s.gcr.io/debian-hyperkube-base-amd64:${VERSION_DEBIAN_HYPERKUBE_BASE}

echo "================================================"
echo "delete docker --pull parameter"
sed -i 's|"${docker_build_opts\[@\]}"||' build/lib/release.sh
sed -i 's|"k8s.gcr.io"|"${KUBE_DOCKER_REGISTRY}"|' build/lib/release.sh

echo "================================================"
echo "building kube-controller-manager kube-scheduler kube-apiserver kube-proxy..."
KUBE_BUILD_HYPERKUBE=n KUBE_BUILD_CONFORMANCE=n KUBE_DOCKER_IMAGE_TAG=${KUBE_VERSION} KUBE_DOCKER_REGISTRY=${HUB_PREFIX} KUBE_GIT_VERSION_FILE=./dce_version make quick-release-images
# For k8s 1.10, but failed
#KUBE_BUILD_HYPERKUBE=n KUBE_BUILD_CONFORMANCE=n KUBE_DOCKER_IMAGE_TAG=${KUBE_VERSION} KUBE_DOCKER_REGISTRY=${HUB_PREFIX} KUBE_GIT_VERSION_FILE=./dce_version KUBE_FASTBUILD=true KUBE_RELEASE_RUN_TESTS=n make release

KUBE_SERVER_IMAGE_TARGETS="kube-controller-manager kube-scheduler kube-apiserver kube-proxy"
for target in ${KUBE_SERVER_IMAGE_TARGETS}; do
  release_docker_image_tag="${HUB_PREFIX}/${target}-amd64:${KUBE_VERSION}"
  docker push ${release_docker_image_tag} 2>/dev/null       
done

echo "================================================"
echo "building kubelet..."
KUBE_GIT_VERSION_FILE=./dce_version build/run.sh make kubelet kubectl KUBE_BUILD_PLATFORMS=linux/amd64

tar -C _output/dockerized/bin/linux/amd64 -czvf _output/dockerized/bin/linux/amd64/kubelet.tar.gz kubelet

source /etc/qiniu_variable
qshell account $(QINIU_AK) $(QINIU_SK)
qshell rput dao-get kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubelet.tar.gz _output/dockerized/bin/linux/amd64/kubelet.tar.gz 
qshell rput dao-get kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl _output/dockerized/bin/linux/amd64/kubectl 
