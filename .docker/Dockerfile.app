# Sets the base image for subsequent instructions
ARG ARG_BUILD_FROM="ghcr.io/entelecheia/sdwebui:latest-base"
FROM $ARG_BUILD_FROM

# Setting ARGs and ENVs for user creation and workspace setup
ARG ARG_USERNAME="app"
ARG ARG_USER_UID=9001
ARG ARG_USER_GID=$ARG_USER_UID
ARG ARG_WORKSPACE_ROOT="/workspace"
ENV USERNAME $ARG_USERNAME
ENV USER_UID $ARG_USER_UID
ENV USER_GID $ARG_USER_GID
ENV WORKSPACE_ROOT $ARG_WORKSPACE_ROOT

# Creates a non-root user with sudo privileges
USER root

# Installs Python packages required for the build
RUN pip install -U pip setuptools
# Optional: Installs Ninja for faster builds
RUN pip install ninja
# Installs xformers from Facebook research
RUN pip install -v -U git+https://github.com/facebookresearch/xformers.git@main#egg=xformers

# check if user exists and if not, create user
RUN if id -u $USERNAME >/dev/null 2>&1; then \
    echo "User exists"; \
    else \
    groupadd --gid $USER_GID $USERNAME && \
    adduser --uid $USER_UID --gid $USER_GID --force-badname --disabled-password --gecos "" $USERNAME && \
    echo "$USERNAME:$USERNAME" | chpasswd && \
    adduser $USERNAME sudo && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME; \
    fi

# Switches to the newly created user
USER $USERNAME
# Sets up the workspace for the user
RUN sudo rm -rf $WORKSPACE_ROOT && sudo mkdir -p $WORKSPACE_ROOT/projects
RUN sudo chown -R $USERNAME:$USERNAME $WORKSPACE_ROOT



# Sets the working directory to workspace root
WORKDIR $WORKSPACE_ROOT
# Copies scripts from host into the image
COPY ./.docker/scripts/ ./scripts/
# Installs Python dependencies listed in requirements.txt
RUN pip install -r ./scripts/requirements.txt

# Setting ARGs and ENVs for Stable-Diffusion-WebUI GitHub repository
ARG ARG_APP_SOURCE_REPO="AUTOMATIC1111/stable-diffusion-webui"
ARG ARG_APP_INSTALL_ROOT="/workspace/projects"
ARG ARG_APP_CLONE_DIRNAME="stable-diffusion-webui"
ARG ARG_APP_SOURCE_BRANCH="master"
ARG ARG_APP_SERVER_NAME="sdwebui"
ENV APP_SOURCE_REPO $ARG_APP_SOURCE_REPO
ENV APP_INSTALL_ROOT $ARG_APP_INSTALL_ROOT
ENV APP_CLONE_DIRNAME $ARG_APP_CLONE_DIRNAME
ENV APP_SOURCE_BRANCH $ARG_APP_SOURCE_BRANCH
ENV APP_SERVER_NAME $ARG_APP_SERVER_NAME

# Clones the stable-diffusion-webui repository from GitHub
RUN git clone "https://github.com/$ARG_APP_SOURCE_REPO.git" $ARG_APP_INSTALL_ROOT/$ARG_APP_CLONE_DIRNAME

# Specifies the command that will be executed when the container is run
CMD ["bash"]
