ARG ARG_BUILD_FROM="nvcr.io/nvidia/pytorch:23.04-py3"
FROM $ARG_BUILD_FROM

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y curl sudo \
        fontconfig fonts-nanum tzdata locales locales-all \
        google-perftools libcairo2-dev imagemagick ffmpeg \
        software-properties-common openssh-server \
    && add-apt-repository ppa:git-core/ppa -y \
    && apt-get update \
    && apt-get -y install --no-install-recommends git \
    && apt-get autoremove -y \
    && apt-get clean -y

# Set up locale
RUN localedef -v -c -i en_US -f UTF-8 en_US.UTF-8 || true
# fix sudo setrlimit(RLIMIT_CORE) error
RUN echo "Set disable_coredump false" > /etc/sudo.conf

# arguments
ARG ARG_USERNAME="webui"
ARG ARG_USER_UID=1000
ARG ARG_USER_GID=$ARG_USER_UID
ARG ARG_WORKSPACE_ROOT="/workspace"
# environment variables
ENV USERNAME $ARG_USERNAME
ENV USER_UID $ARG_USER_UID
ENV USER_GID $ARG_USER_GID
ENV WORKSPACE_ROOT $ARG_WORKSPACE_ROOT

# Add a non-root user to a container
# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && adduser --uid $USER_UID --gid $USER_GID --force-badname --disabled-password --gecos "" $USERNAME  \
    && echo "$USERNAME:$USERNAME" | chpasswd \
    && adduser $USERNAME sudo \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
RUN sudo rm -rf $WORKSPACE_ROOT && sudo mkdir -p $WORKSPACE_ROOT/projects
RUN sudo chown -R $USERNAME:$USERNAME $WORKSPACE_ROOT
# RUN sh -c "$(wget -qO- https://dotfiles.entelecheia.ai/install)"

# install requirements
RUN sudo pip install -U pip setuptools
# (Optional) Makes the build much faster
RUN sudo pip install ninja
# Set TORCH_CUDA_ARCH_LIST if running and building on different GPU types
RUN pip install -v -U git+https://github.com/facebookresearch/xformers.git@main#egg=xformers
# (this can take dozens of minutes)

# arguments
ARG ARG_SDW_GITHUB_USERNAME="AUTOMATIC1111"
ARG ARG_SDW_GITHUB_REPO="stable-diffusion-webui"
ARG ARG_SDW_INSTALL_ROOT="/workspace/projects"
ARG ARG_SDW_CLONE_DIR="stable-diffusion-webui"
# environment variables
ENV SDW_GITHUB_USERNAME $ARG_SDW_GITHUB_USERNAME
ENV SDW_GITHUB_REPO $ARG_SDW_GITHUB_REPO
ENV SDW_INSTALL_ROOT $ARG_SDW_INSTALL_ROOT
ENV SDW_CLONE_DIR $ARG_SDW_CLONE_DIR

# set workdir to user home
WORKDIR $WORKSPACE_ROOT
COPY ./.docker/scripts/ ./scripts/
RUN pip install -r ./scripts/requirements.txt
 
RUN git clone "https://github.com/$SDW_GITHUB_USERNAME/$SDW_GITHUB_REPO.git" $SDW_INSTALL_ROOT/$SDW_CLONE_DIR

WORKDIR $SDW_INSTALL_ROOT/$SDW_CLONE_DIR
ENV TZ=Asia/Seoul
ARG ARG_SDW_GITHUB_BRANCH="sd-webui-docker"
ARG ARG_SDW_SERVER_NAME
ENV SDW_GITHUB_BRANCH $ARG_SDW_GITHUB_BRANCH
ENV SDW_SERVER_NAME $ARG_SDW_SERVER_NAME

CMD ["bash"]
