# GUI desktop for DSMLP / DataHub (CSE 151B CUDA 12.8 stack)
# Browser access via Jupyter path: /desktop (jupyter-remote-desktop-proxy)
#
# Base: ghcr.io/ucsd-ets/sp26-cuda128:main (PyTorch 2.11 + cu128)
#
# Build locally (optional):
#   docker build -t dsmlp-desktop .
#
# On DSMLP after pushing to GHCR:
#   launch.sh -i ghcr.io/jimmywootton/dsmlp-desktop:main -P Always \
#     -W CSE151B_SP26_A00 -l gpu-class=medium -g 1 -c 8 -m 64

ARG BASE_CONTAINER=ghcr.io/ucsd-ets/sp26-cuda128:main
FROM $BASE_CONTAINER

LABEL maintainer="jawootton"
LABEL description="XFCE desktop + TigerVNC on sp26-cuda128 (CUDA 12.8)"

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NOWARNINGS="yes"

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
 && apt-get remove -y -qq xfce4-screensaver light-locker || true \
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

RUN uv pip install --system jupyter-remote-desktop-proxy
