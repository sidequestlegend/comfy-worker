# Base image
# FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu20.04

# ENV DEBIAN_FRONTEND=noninteractive

# # Use bash shell with pipefail option
# SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# # Set the working directory
# WORKDIR /

# # Update and upgrade the system packages (Worker Template)
# COPY builder/setup.sh /setup.sh
# RUN /bin/bash /setup.sh && \
#     rm /setup.sh

# # Install Python dependencies (Worker Template)
# COPY builder/requirements.txt /requirements.txt
# RUN python3 -m pip install --upgrade pip && \
#     python3 -m pip install --upgrade -r /requirements.txt --no-cache-dir && \
#     rm /requirements.txt

# # Add src files (Worker Template)
# ADD src .

# CMD python3 -u /handler.py

# Import necessary base images
FROM runpod/stable-diffusion:models-1.0.0 as sd-models
FROM runpod/stable-diffusion-models:2.1 as hf-cache
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04 as runtime

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set working directory and environment variables
ENV SHELL=/bin/bash
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /

# Set up system
RUN apt-get update --yes && \
    apt-get upgrade --yes && \
    apt install --yes --no-install-recommends git wget curl bash libgl1 software-properties-common openssh-server nginx rsync && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt install python3.10-dev python3.10-venv -y --no-install-recommends && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Set up Python and pip
RUN ln -s /usr/bin/python3.10 /usr/bin/python && \
    rm /usr/bin/python3 && \
    ln -s /usr/bin/python3.10 /usr/bin/python3 && \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python get-pip.py

# Install necessary Python packages
RUN pip install --upgrade --no-cache-dir pip
RUN pip install --upgrade --no-cache-dir torch==2.0.1+cu118 torchvision==0.15.2+cu118 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu118
RUN pip install --upgrade --no-cache-dir jupyterlab ipywidgets jupyter-archive jupyter_contrib_nbextensions triton xformers==0.0.18 gdown

# Set up Jupyter Notebook
RUN pip install notebook==6.5.5
RUN jupyter contrib nbextension install --user && \
    jupyter nbextension enable --py widgetsnbextension

RUN python -m venv /venv
ENV PATH="/venv/bin:$PATH"

# Install ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git && \
    cd /ComfyUI && \
    pip install -r requirements.txt

#Re-Install? TODO: Figure out why it says it is not installed.
RUN pip install torchvision

# Create necessary directories and copy necessary files
RUN set -e && mkdir -p /root/.cache/huggingface && mkdir /comfy-models
COPY --from=hf-cache /root/.cache/huggingface /root/.cache/huggingface
COPY --from=sd-models /SDv1-5.ckpt /comfy-models/v1-5-pruned-emaonly.ckpt
COPY --from=sd-models /SDv2-768.ckpt /comfy-models/SDv2-768.ckpt
RUN wget https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors -O /comfy-models/sd_xl_base_1.0.safetensors && \
    wget https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0/resolve/main/sd_xl_refiner_1.0.safetensors -O /comfy-models/sd_xl_refiner_1.0.safetensors

# NGINX Proxy
COPY --from=proxy nginx.conf /etc/nginx/nginx.conf
COPY --from=proxy readme.html /usr/share/nginx/html/readme.html

# Copy the README.md
COPY README.md /usr/share/nginx/html/README.md

# Start Scripts
COPY src/pre_start.sh /pre_start.sh
COPY src/handler.py /handler.py
COPY --from=scripts start.sh /
RUN chmod +x /start.sh

CMD [ "/start.sh" "python3 -u /handler.py" ]
