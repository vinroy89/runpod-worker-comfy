# Use Nvidia CUDA base image
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04 AS base

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1 

# Install Python, git and other necessary tools
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    wget

# Clean up to reduce image size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui

# Change working directory to ComfyUI
WORKDIR /comfyui

ARG SKIP_DEFAULT_MODELS
# Download checkpoints/vae/LoRA to include in image.
RUN if [ -z "$SKIP_DEFAULT_MODELS" ]; then wget -O models/checkpoints/sd_xl_base_1.0.safetensors https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors; fi
RUN if [ -z "$SKIP_DEFAULT_MODELS" ]; then wget -O models/vae/sdxl_vae.safetensors https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors; fi
RUN if [ -z "$SKIP_DEFAULT_MODELS" ]; then wget -O models/vae/sdxl-vae-fp16-fix.safetensors https://huggingface.co/madebyollin/sdxl-vae-fp16-fix/resolve/main/sdxl_vae.safetensors; fi

RUN wget -O models/checkpoints/RealVisXL_V4.0.safetensors https://huggingface.co/SG161222/RealVisXL_V4.0/resolve/main/RealVisXL_V4.0.safetensors
RUN wget -O models/checkpoints/SUPIR-v0Q_fp16.safetensors https://huggingface.co/Kijai/SUPIR_pruned/resolve/main/SUPIR-v0Q_fp16.safetensors
RUN wget -O models/checkpoints/SUPIR-v0F_fp16.safetensors https://huggingface.co/Kijai/SUPIR_pruned/resolve/main/SUPIR-v0F_fp16.safetensors

# Install ComfyUI dependencies
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 \
    && pip3 install --no-cache-dir xformers==0.0.21 \
    && pip3 install -r requirements.txt

RUN git clone https://github.com/kijai/ComfyUI-SUPIR.git custom_nodes/ComfyUI_SUPIR
RUN git clone https://github.com/Gourieff/comfyui-reactor-node.git custom_nodes/ComfyUI_Reactor
RUN git clone https://github.com/alt-key-project/comfyui-dream-project.git custom_nodes/ComfyUI_DreamProject
RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git custom_nodes/ComfyUI_KJNodes

# Install runpod
RUN pip3 install runpod requests

# Support for the network volume
ADD src/extra_model_paths.yaml ./

# Go back to the root
WORKDIR /

# Add the start and the handler
ADD src/start.sh src/rp_handler.py test_input.json ./
RUN chmod +x /start.sh

# Start the container
CMD /start.sh
