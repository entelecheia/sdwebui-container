# Sets the base image for subsequent instructions
ARG ARG_BUILD_FROM="nvcr.io/nvidia/pytorch:23.04-py3"
FROM $ARG_BUILD_FROM

# Setting this argument prevents interactive prompts during the build process
ARG DEBIAN_FRONTEND=noninteractive
# Updates the image and installs necessary packages
RUN apt-get update \
    && apt-get install -y curl sudo \
        fontconfig fonts-nanum tzdata locales locales-all \
        google-perftools libcairo2-dev imagemagick ffmpeg \
        software-properties-common openssh-server \
    # Adds PPA for the latest git version
    && add-apt-repository ppa:git-core/ppa -y \
    && apt-get update \
    && apt-get -y install --no-install-recommends git \
    # Cleans up unnecessary packages to reduce image size
    && apt-get autoremove -y \
    && apt-get clean -y

# Sets up the locale to en_US.UTF-8
RUN localedef -v -c -i en_US -f UTF-8 en_US.UTF-8 || true
# Fixes sudo error related to core dumps
RUN echo "Set disable_coredump false" > /etc/sudo.conf

# Setting ARGs and ENVs for user creation and workspace setup
ARG ARG_USERNAME="webui"
ARG ARG_USER_UID=1000
ARG ARG_USER_GID=$ARG_USER_UID
ARG ARG_WORKSPACE_ROOT="/workspace"
ENV USERNAME $ARG_USERNAME
ENV USER_UID $ARG_USER_UID
ENV USER_GID $ARG_USER_GID
ENV WORKSPACE_ROOT $ARG_WORKSPACE_ROOT

# Creates a non-root user with sudo privileges
RUN groupadd --gid $USER_GID $USERNAME \
    && adduser --uid $USER_UID --gid $USER_GID --force-badname --disabled-password --gecos "" $USERNAME  \
    && echo "$USERNAME:$USERNAME" | chpasswd \
    && adduser $USERNAME sudo \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Switches to the newly created user
USER $USERNAME
# Sets up the workspace for the user
RUN sudo rm -rf $WORKSPACE_ROOT && sudo mkdir -p $WORKSPACE_ROOT/projects
RUN sudo chown -R $USERNAME:$USERNAME $WORKSPACE_ROOT

# Installs Python packages required for the build
RUN sudo pip install -U pip setuptools
# Optional: Installs Ninja for faster builds
RUN sudo pip install ninja
# Installs xformers from Facebook research
RUN pip install -v -U git+https://github.com/facebookresearch/xformers.git@main#egg=xformers

# Setting ARGs and ENVs for Stable-Diffusion-WebUI GitHub repository
ARG ARG_SDW_GITHUB_USERNAME="AUTOMATIC1111"
ARG ARG_SDW_GITHUB_REPO="stable-diffusion-webui"
ARG ARG_SDW_INSTALL_ROOT="/workspace/projects"
ARG ARG_SDW_CLONE_DIR="stable-diffusion-webui"
ENV SDW_GITHUB_USERNAME $ARG_SDW_GITHUB_USERNAME
ENV SDW_GITHUB_REPO $ARG_SDW_GITHUB_REPO
ENV SDW_INSTALL_ROOT $ARG_SDW_INSTALL_ROOT
ENV SDW_CLONE_DIR $ARG_SDW_CLONE_DIR

# Sets the working directory to workspace root
WORKDIR $WORKSPACE_ROOT
# Copies scripts from host into the image
COPY ./.docker/scripts/ ./scripts/
# Installs Python dependencies listed in requirements.txt
RUN pip install -r ./scripts/requirements.txt

# Clones the stable-diffusion-webui repository from GitHub
RUN git clone "https://github.com/$SDW_GITHUB_USERNAME/$SDW_GITHUB_REPO.git" $SDW_INSTALL_ROOT/$SDW_CLONE_DIR

# Changes the working directory to the cloned repository
WORKDIR $SDW_INSTALL_ROOT/$SDW_CLONE_DIR

# Sets the time zone within the container
ENV TZ=Asia/Seoul

# Setting ARGs and ENVs for GitHub branch and server name
ARG ARG_SDW_GITHUB_BRANCH="sd-webui-docker"
ARG ARG_SDW_SERVER_NAME
ENV SDW_GITHUB_BRANCH $ARG_SDW_GITHUB_BRANCH
ENV SDW_SERVER_NAME $ARG_SDW_SERVER_NAME

# Specifies the command that will be executed when the container is run
CMD ["bash"]
