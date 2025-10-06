# 使用通用的 Ubuntu 基础镜像（支持 CPU 和 AMD GPU）
# 如果你有 NVIDIA GPU，可以改用: nvidia/cuda:12.6.0-runtime-ubuntu22.04
FROM ubuntu:22.04

# 设置工作目录
WORKDIR /app

# 避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    wget \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# 创建符号链接使 python 指向 python3
RUN ln -sf /usr/bin/python3 /usr/bin/python

# 升级 pip
RUN python -m pip install --upgrade pip

# 复制项目文件
COPY requirements.txt* ./
COPY environment.yml* ./

# 安装 Python 依赖（指定兼容版本）
RUN pip install \
    numpy \
    tqdm \
    loguru \
    click \
    pillow \
    opencv-python-headless \
    PyQt6 \
    transformers \
    "huggingface_hub>=0.20.0" \
    diffusers \
    pyyaml \
    psutil

# 安装 iopaint（需要在其他依赖之后）
RUN pip install iopaint

# 安装 PyTorch (CPU 版本 - 兼容所有硬件)
# 如果你有 NVIDIA GPU，改用: --index-url https://download.pytorch.org/whl/nightly/cu126
# 如果你有 AMD GPU，改用: --index-url https://download.pytorch.org/whl/rocm6.0
RUN pip install \
    torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cpu

# 复制应用代码
COPY *.py ./
COPY *.yml ./
COPY *.md ./

# 创建输入输出目录和模型缓存目录
RUN mkdir -p /app/input /app/output /root/.cache

# 创建模型下载脚本（在首次运行时自动下载）
RUN echo '#!/bin/bash\n\
if [ ! -d "/root/.cache/lama" ]; then\n\
    echo "Downloading LaMA model for the first time..."\n\
    iopaint download --model lama || true\n\
fi\n\
exec "$@"' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

# 设置环境变量
ENV QT_QPA_PLATFORM=offscreen
ENV DISPLAY=:99

# 暴露端口（如果需要 web 界面）
EXPOSE 8080

# 设置入口点
ENTRYPOINT ["/app/entrypoint.sh"]

# 默认命令：显示帮助信息
CMD ["python", "remwm.py", "--help"]
