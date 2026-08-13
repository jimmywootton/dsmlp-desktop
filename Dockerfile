# GUI desktop for DSMLP / DataHub
# Browser access via Jupyter path: /desktop  (jupyter-remote-desktop-proxy)
#
# Build locally (optional):
#   docker build -t dsmlp-desktop .
#
# On DSMLP after pushing to GHCR:
#   launch.sh -i ghcr.io/<github-user>/dsmlp-desktop:main -P Always -c 4 -m 16

ARG BASE_CONTAINER=ghcr.io/ucsd-ets/scipy-notebook:stable
FROM $BASE_CONTAINER

LABEL maintainer="jawootton"
LABEL description="XFCE desktop + TigerVNC via jupyter-remote-desktop-proxy"

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

# notebook user (jovyan at build time; DSMLP remaps to your campus user at runtime)
USER ${NB_USER}

RUN pip install --no-cache-dir jupyter-remote-desktop-proxy
