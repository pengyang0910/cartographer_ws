# Cartographer ROS2 环境

基于 Docker (Ubuntu 22.04 + ROS2 Humble) 的 Cartographer SLAM 开发环境，支持从源码编译和运行。

## 环境架构

```
cartographer_ws/
├── docker/                   # Docker 构建环境
│   ├── Dockerfile            # 镜像定义（ROS2 Humble + 依赖）
│   ├── run.sh                # 启动容器脚本
│   └── entrypoint.sh         # 容器入口点
├── src/                      # 源码
│   ├── cartographer/         # 核心算法库（纯 C++，ROS 无关）
│   └── cartographer_ros/     # ROS2 集成层
├── rosbag/                   # 数据集
└── docs/                     # 文档
```

## 环境构建

### 1. 构建 Docker 镜像

```bash
cd cartographer_ws
docker build -t cartographer-ros2:V1.0 -f docker/Dockerfile .
```

镜像包含：
- Ubuntu 22.04
- ROS2 Humble (ros-humble-desktop)
- 编译依赖（Ceres Solver、Eigen3、PCL、Abseil、Protobuf、Lua、gflags/glog、Cairo、Boost）

### 2. 启动容器

```bash
cd cartographer_ws
./docker/run.sh
```

容器内 workstation 目录 `/workspace` 挂载到当前 `cartographer_ws`，所有修改宿主机和容器内同步。

## 源码下载

### Clone ROS2 分支

```bash
cd cartographer_ws/src

# Cartographer 核心算法库
git clone https://github.com/ros2/cartographer.git -b ros2

# Cartographer ROS2 集成
git clone https://github.com/ros2/cartographer_ros.git -b ros2
```

> **注意**：Google 官方 `cartographer-project` 组织下的仓库没有 ROS2 分支。ROS2 官方移植版在 `github.com/ros2` 组织下，分支名为 `ros2`。

## 编译

在容器内执行：

```bash
# 编译（首次全量编译，后续增量）
colcon build --symlink-install

# 只编译某个包
colcon build --symlink-install --packages-select cartographer_ros

# 编译后 source
source install/setup.bash
```

> `--symlink-install`：install 目录下的 Python 文件通过软链接指向 src，修改 Python launch 文件无需重新编译。

## 数据集下载

Cartographer 官方数据集下载页面：
https://google-cartographer-ros.readthedocs.io/en/latest/data.html

### 常用数据集

| 数据集 | 说明 | 下载地址 |
|--------|------|---------|
| **b2-2016-04-27-12-31-41.bag** | 德意志博物馆 2D 背包 | `https://storage.googleapis.com/cartographer-public-data/bags/backpack_2d/b2-2016-04-27-12-31-41.bag` |

下载后放入 `rosbag/` 目录。

> **重要**：官方数据集是 **ROS1 格式**（`.bag`），ROS2 版 Cartographer 使用 `rosbag2` 读取，不兼容 ROS1 格式。使用前需要转换。

### ROS1 Bag 转 ROS2 格式

安装转换工具（宿主机或容器内）：

```bash
pip3 install rosbags
```

转换：

```bash
rosbags-convert \
    --src rosbag/b2-2016-04-27-12-31-41.bag \
    --dst rosbag/b2-2016-04-27-12-31-41_ros2
```

## 运行

### 离线模式（推荐，最快速度处理）

快速跑完整包数据，不依赖实时时钟：

```bash
source install/setup.bash
ros2 launch cartographer_ros offline_backpack_2d.launch.py \
    bag_filenames:=/workspace/rosbag/b2-2016-04-27-12-31-41_ros2
```

### 在线模式（带 RViz 可视化）

按实时速度播放 bag，在 RViz 中观察建图过程：

```bash
source install/setup.bash
ros2 launch cartographer_ros demo_backpack_2d.launch.py \
    bag_filename:=/workspace/rosbag/b2-2016-04-27-12-31-41_ros2
```

### 常用 launch 文件

| Launch 文件 | 用途 |
|------------|------|
| `offline_backpack_2d.launch.py` | 2D 离线建图（处理 `.bag` 文件） |
| `offline_backpack_3d.launch.py` | 3D 离线建图 |
| `demo_backpack_2d.launch.py` | 2D 在线建图 + RViz（实时播包） |
| `demo_backpack_3d.launch.py` | 3D 在线建图 + RViz |
| `backpack_2d.launch.py` | 2D 纯建图节点（不含 bag 播放） |
| `assets_writer_backpack_2d.launch.py` | 从 `.pbstream` 导出地图资源 |

### 常用配置

配置文件位于 `src/cartographer_ros/cartographer_ros/configuration_files/`：

| 配置文件 | 对应场景 |
|---------|---------|
| `backpack_2d.lua` | 2D 背包（官方 Deutsche Museum 数据集） |
| `backpack_3d.lua` | 3D 背包 |
| `revo_lds.lua` | Revo LDS 激光雷达 |
| `pr2.lua` | PR2 机器人 |
| `taurob_tracker.lua` | Taurob Tracker 机器人 |

## 常见问题

### Q: SHM 错误 `Failed to create segment`

容器内 `/dev/shm` 只读导致的 FastRTPS 共享内存错误，不影响功能，可忽略。

### Q: `No storage could be initialized`

Bag 文件是 ROS1 格式，需用 `rosbags-convert` 转为 ROS2 格式（见上文）。

### Q: RViz 没有图像

确认 `cartographer_offline_node` 进程没有崩溃——如果有进程退出，检查 bag 文件路径和格式是否正确。
