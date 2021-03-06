# 更新系统
yum update -y
yum install git zip unzip wget curl vim -y

# 关闭SELinux
sed -i "s/=enforcing/=disabled/g" /etc/sysconfig/selinux

# 修改主机名
hostnamectl set-hostname cmp-node-00x

# 关闭防火墙
systemctl disable firewalld

# 安装Docker
yum install -y --nogpgcheck \
    http://mirrors.aliyun.com/docker-engine/yum/repo/main/centos/7/Packages/docker-engine-selinux-1.13.1-1.el7.centos.noarch.rpm \
    http://mirrors.aliyun.com/docker-engine/yum/repo/main/centos/7/Packages/docker-engine-1.13.1-1.el7.centos.x86_64.rpm

# 安装Kubelet
yum install -y --nogpgcheck \
    http://mirrors.aliyun.com/kubernetes/yum/pool/1eed768852fa3e497e1b7bdf4e93afbe3b4b0fdcb59fda801d817736578b9838-kubectl-1.10.5-0.x86_64.rpm \
    http://mirrors.aliyun.com/kubernetes/yum/pool/94d062f2d86b8f4f55f4d23a3610af25931da9168b7f651967c269273955a5a2-kubelet-1.10.5-0.x86_64.rpm \
    http://mirrors.aliyun.com/kubernetes/yum/pool/fe33057ffe95bfae65e2f269e1b05e99308853176e24a4d027bc082b471a07c0-kubernetes-cni-0.6.0-0.x86_64.rpm \
    http://mirrors.aliyun.com/kubernetes/yum/pool/3ea9c50d098c50a7e968c35915d3d8af7f54c58c0cedb0f9603674720743de4e-kubeadm-1.10.5-0.x86_64.rpm

# 配置Docker
sed -i "s/\/usr\/bin\/dockerd/\/usr\/bin\/dockerd --exec-opt native.cgroupdriver=systemd/g" /lib/systemd/system/docker.service

# 配置Kubelet
sed -i "s/\/usr\/bin\/kubelet/\/usr\/bin\/kubelet --pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com\/k10\/pause-amd64:3.1 --fail-swap-on=false/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# 重启Docker 
systemctl daemon-reload
systemctl enable docker
systemctl enable kubelet
systemctl start docker
systemctl start kubelet

# 创建配置
cat <<EOF > k8sconfig.yaml
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
kubernetesVersion: v1.10.5
imageRepository: registry.cn-hangzhou.aliyuncs.com/k10
networking:
  podSubnet: 10.244.0.0/16
EOF
 
# 安装Master
kubeadm init --config=k8sconfig.yaml --ignore-preflight-errors="Swap"