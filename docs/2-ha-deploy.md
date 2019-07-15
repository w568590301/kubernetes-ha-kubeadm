# 二. 搭建高可用集群
## 1. 部署keepalived - apiserver高可用（任选两个master节点）
> **重要：如果是云环境，一般不支持自定义虚拟ip。这一步可以跳过了。下面所有用到虚拟ip的地方设置为其中某一台master的ip即可。**


#### 1.1 安装keepalived
```bash
# 在两个主节点上安装keepalived（一主一备）
$ yum install -y keepalived
```
#### 1.2 创建keepalived配置文件
```bash
# 创建目录
$ ssh <user>@<master-ip> "mkdir -p /etc/keepalived"
$ ssh <user>@<backup-ip> "mkdir -p /etc/keepalived"

# 分发配置文件
$ scp target/configs/keepalived-master.conf <user>@<master-ip>:/etc/keepalived/keepalived.conf
$ scp target/configs/keepalived-backup.conf <user>@<backup-ip>:/etc/keepalived/keepalived.conf

# 分发监测脚本
$ scp target/scripts/check-apiserver.sh <user>@<master-ip>:/etc/keepalived/
$ scp target/scripts/check-apiserver.sh <user>@<backup-ip>:/etc/keepalived/
```

#### 1.3 启动keepalived
```bash
# 分别在master和backup上启动服务
$ systemctl enable keepalived && service keepalived start

# 检查状态
$ service keepalived status

# 查看日志
$ journalctl -f -u keepalived

# 查看虚拟ip
$ ip a
```

## 2. 部署第一个主节点
```bash
# 准备配置文件
$ scp target/configs/kubeadm-config.yaml <user>@<node-ip>:~
# ssh到第一个主节点，执行kubeadm初始化系统（注意保存最后打印的加入集群的命令）
$ kubeadm init --config=kubeadm-config.yaml --experimental-upload-certs

# copy kubectl配置（上一步会有提示）
$ mkdir -p ~/.kube
$ cp -i /etc/kubernetes/admin.conf ~/.kube/config

# 测试一下kubectl
$ kubectl get pods --all-namespaces

# **备份init打印的join命令**

```

## 3. 部署网络插件 - calico
我们使用calico官方的安装方式来部署。
```bash
# 创建目录（在配置了kubectl的节点上执行）
$ mkdir -p /etc/kubernetes/addons

# 上传calico配置到配置好kubectl的节点（一个节点即可）
$ scp target/addons/calico* <user>@<node-ip>:/etc/kubernetes/addons/

# 部署calico
$ kubectl apply -f /etc/kubernetes/addons/calico-rbac-kdd.yaml
$ kubectl apply -f /etc/kubernetes/addons/calico.yaml

# 查看状态
$ kubectl get pods -n kube-system
```
## 4. 加入其它master节点
```bash
# 使用之前保存的join命令加入集群
$ kubeadm join ...

# 耐心等待一会，并观察日志
$ journalctl -f

# 查看集群状态
# 1.查看节点
$ kubectl get nodes
# 2.查看pods
$ kubectl get pods --all-namespaces
```

## 5. 加入worker节点
```bash
# 使用之前保存的join命令加入集群
$ kubeadm join ...

# 耐心等待一会，并观察日志
$ journalctl -f

# 查看节点
$ kubectl get nodes
```
