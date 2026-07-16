# Cartographer ROS2 环境

基于 Docker (Ubuntu 22.04 + ROS2 Humble) 的 Cartographer SLAM 开发环境，支持从源码编译和运行。

## 快速开始

```bash
git clone <this-repo>.git cartographer_ws
cd cartographer_ws

# 1. 下载源码
cd src
git clone https://github.com/ros2/cartographer.git -b ros2
git clone https://github.com/ros2/cartographer_ros.git -b ros2
cd ..

# 2. 构建 Docker 镜像
docker build -t cartographer-ros2:V1.0 -f docker/Dockerfile .

# 3. 启动容器
./docker/run.sh

# 4. 容器内编译
colcon build --symlink-install
source install/setup.bash

# 5. 在宿主机下载官方数据集并转换（见下方 数据集 章节），然后容器内运行
ros2 launch cartographer_ros offline_backpack_2d.launch.py \
    bag_filenames:=/workspace/rosbag/b2-2016-04-27-12-31-41_ros2
```

## 仓库结构

```
cartographer_ws/              # clone 后的初始状态
├── docker/                   # Docker 构建环境
│   ├── Dockerfile            # 镜像定义（ROS2 Humble + 依赖）
│   ├── run.sh                # 启动容器脚本
│   └── entrypoint.sh         # 容器入口点
├── src/                      # 源码目录（放入 cartographer + cartographer_ros 后编译）
│   └── .keep
├── rosbag/                   # 数据集目录（下载 .bag 文件后放入此处）
│   └── .keep
├── .dockerignore
├── .gitignore
└── README.md
```

## 源码下载

`src/` 目录已随仓库创建，进入后 clone ROS2 分支即可：

```bash
cd cartographer_ws/src

# Cartographer 核心算法库（纯 C++，ROS 无关）
git clone https://github.com/ros2/cartographer.git -b ros2

# Cartographer ROS2 集成层
git clone https://github.com/ros2/cartographer_ros.git -b ros2
```

> **注意**：Google 官方 `cartographer-project` 组织下的仓库没有 ROS2 分支。ROS2 移植版在 `github.com/ros2` 组织下，分支名为 `ros2`。

## 环境构建

### Docker 镜像

```bash
cd cartographer_ws
docker build -t cartographer-ros2:V1.0 -f docker/Dockerfile .
```

镜像包含 Ubuntu 22.04、ROS2 Humble (desktop) 及全部编译依赖（Ceres Solver、Eigen3、PCL、Abseil、Protobuf、Lua、gflags/glog、Cairo、Boost）。

### 启动容器

```bash
cd cartographer_ws
./docker/run.sh
```

`cartographer_ws` 目录挂载到容器内 `/workspace`，宿主机和容器内文件实时同步。

## 编译

在容器内执行：

```bash
# 首次全量编译
colcon build --symlink-install

# 后续只编译某个包
colcon build --symlink-install --packages-select cartographer_ros

# 编译后 source
source install/setup.bash
```

> `--symlink-install`：Python 文件通过软链接安装，修改 launch 文件无需重新编译。

## 数据集

Cartographer 官方数据集页面：https://google-cartographer-ros.readthedocs.io/en/latest/data.html

### 下载

| 数据集 | 场景 | 下载地址 |
|--------|------|---------|
| `b2-2016-04-27-12-31-41.bag` | 德意志博物馆 2D 背包 | `https://storage.googleapis.com/cartographer-public-data/bags/backpack_2d/b2-2016-04-27-12-31-41.bag` |

`rosbag/` 目录已随仓库创建，下载后放入即可。

### ROS1 Bag → ROS2 格式转换

官方数据集是 ROS1 格式（`.bag`），ROS2 使用 `rosbag2`，需要转换：

```bash
# 安装转换工具
pip3 install rosbags

# 转换
rosbags-convert \
    --src rosbag/b2-2016-04-27-12-31-41.bag \
    --dst rosbag/b2-2016-04-27-12-31-41_ros2
```

## 运行

### 离线模式（推荐）

以最快速度处理完 bag，不依赖实时时钟：

```bash
source install/setup.bash
ros2 launch cartographer_ros offline_backpack_2d.launch.py \
    bag_filenames:=/workspace/rosbag/b2-2016-04-27-12-31-41_ros2
```

### 在线模式（RViz 可视化）

按实时速度播放，在 RViz 中观察建图过程：

```bash
source install/setup.bash
ros2 launch cartographer_ros demo_backpack_2d.launch.py \
    bag_filename:=/workspace/rosbag/b2-2016-04-27-12-31-41_ros2
```

## 配置参考

### Launch 文件

| Launch 文件 | 用途 |
|------------|------|
| `offline_backpack_2d.launch.py` | 2D 离线建图 |
| `offline_backpack_3d.launch.py` | 3D 离线建图 |
| `demo_backpack_2d.launch.py` | 2D 在线建图 + RViz |
| `demo_backpack_3d.launch.py` | 3D 在线建图 + RViz |
| `backpack_2d.launch.py` | 2D 纯建图节点（不含 bag 播放） |
| `assets_writer_backpack_2d.launch.py` | 从 `.pbstream` 导出地图 |

Launch 文件位于 `src/cartographer_ros/cartographer_ros/launch/`。

### Lua 配置

| 配置文件 | 对应场景 |
|---------|---------|
| `backpack_2d.lua` | 2D 背包（Deutsche Museum 数据集） |
| `backpack_3d.lua` | 3D 背包 |
| `revo_lds.lua` | Revo LDS 激光雷达 |
| `pr2.lua` | PR2 机器人 |
| `taurob_tracker.lua` | Taurob Tracker 机器人 |

配置文件位于 `src/cartographer_ros/cartographer_ros/configuration_files/`。

## 常见问题

### SHM 错误 `Failed to create segment`

容器内 `/dev/shm` 只读导致的 FastRTPS 共享内存错误，不影响功能，可忽略。

### `No storage could be initialized`

Bag 文件是 ROS1 格式，需用 `rosbags-convert` 转为 ROS2 格式（见 数据集 章节）。

### RViz 没有图像

确认 `cartographer_offline_node` 进程没有崩溃（`exit code -6`）——检查 bag 路径和格式是否正确。
