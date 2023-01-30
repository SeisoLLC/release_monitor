FROM ubuntu:20.04 AS base

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PIP_NO_CACHE_DIR=1

ARG VERSION
ARG COMMIT_HASH

LABEL org.opencontainers.image.title="release_monitor"
LABEL org.opencontainers.image.description="Monitor releases from a git repository for a specific commit"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.vendor="Seiso"
LABEL org.opencontainers.image.url="https://seisollc.com"
LABEL org.opencontainers.image.source="https://github.com/SeisoLLC/release_monitor"
LABEL org.opencontainers.image.revision="${COMMIT_HASH}"
LABEL org.opencontainers.image.licenses="BSD-3-Clause"

# hadolint ignore=DL3008,DL3013
RUN apt-get update \
 && apt-get install -y --no-install-recommends software-properties-common \
 && add-apt-repository ppa:deadsnakes/ppa \
 && apt-get install -y --no-install-recommends python3.9 \
                                               python3.9-venv \
 && ln -sf /usr/bin/python3.9 /usr/bin/python3 \
 && python3 -m ensurepip --upgrade \
 && pip3 install pipenv \
 && apt-get clean autoclean \
 && apt-get -y autoremove \
 && rm -rf /var/lib/apt/lists/*


FROM base AS builder

WORKDIR /tmp
COPY Pipfile Pipfile.lock ./
RUN PIP_IGNORE_INSTALLED=1 \
    PIPENV_VENV_IN_PROJECT=true \
    pipenv install --deploy --ignore-pipfile


FROM base AS final

WORKDIR /usr/src/app

# appuser creation
RUN groupadd --gid 53150 -r appuser \
 && useradd -r -g appuser -s "$(which bash)" --create-home --uid 53150 appuser
USER appuser

COPY --from=builder /tmp/.venv .venv
ENV PATH="/usr/src/app/.venv/bin:${PATH}"

COPY ./release_monitor ./release_monitor/
COPY ./main.py ./
ENTRYPOINT ["/usr/src/app/main.py"]
