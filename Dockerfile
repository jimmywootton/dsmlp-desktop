# GUI desktop for DSMLP / DataHub
# Browser access via Jupyter path: /desktop  (jupyter-remote-desktop-proxy)
#
# Build locally (optional):
#   docker build -t dsmlp-desktop .
#
# On DSMLP after pushing to GHCR (RTX 6000 / b24gb):
#   launch.sh -i ghcr.io/<github-user>/dsmlp-desktop:main -P Always \
#     -g 1 -v b24gb -c 8 -m 32
#
# scipy-ml includes CUDA/PyTorch/TF so DSMLP GPUs (including b24gb) are usable.
# Request the GPU at launch with -g 1; DSMLP injects the NVIDIA driver.

ARG BASE_CONTAINER=ghcr.io/ucsd-ets/scipy-ml-notebook:stable
FROM $BASE_CONTAINER

LABEL maintainer="jawootton"
LABEL description="XFCE desktop + TigerVNC + CUDA/ML stack for DSMLP GPUs"

USER root

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq \
 && apt-get install -y -qq --no-install-recommends \
      dbus-x11 \
      xfce4 \
      xfce4-panel \
      xfce4-session \
      xfce4-settings \
      xorg \
      xubuntu-icon-theme \
      fonts-dejavu \
      tigervnc-standalone-server \
      xclip \
 && apt-get remove -y -qq xfce4-screensaver || true \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /opt/install \
 && chown -R ${NB_UID}:${NB_GID} /opt/install

# GPU pods bind-mount NVIDIA GL/EGL ICDs. Xtigervnc then segfaults during
# GLX init (libnvidia-egl-gbm + Mesa swrast). Force Mesa software GL for the
# virtual desktop; CUDA/PyTorch still use the NVIDIA GPU.
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    LIBGL_ALWAYS_SOFTWARE=1 \
    __GLX_VENDOR_LIBRARY_NAME=mesa \
    __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json \
    __EGL_EXTERNAL_PLATFORM_CONFIG_DIRS=/etc/dsmlp-desktop/no-egl-external

RUN mkdir -p /etc/dsmlp-desktop/no-egl-external

# notebook user (jovyan at build time; DSMLP remaps to your campus user at runtime)
USER ${NB_USER}

RUN pip install --no-cache-dir jupyter-remote-desktop-proxy
