#!/usr/bin/env bash
#########################################################
# Uncomment and change the variables below to your need:#
#########################################################

# Install directory without trailing slash
install_dir=${SDW_WORKSPACE_ROOT:-"/app"}
clone_dir=${SDW_CLONE_DIR:-"stable-diffusion-webui"}
# Commandline arguments for webui.py, for example: export COMMANDLINE_ARGS="--medvram --opt-split-attention"
export COMMANDLINE_ARGS="--share --listen --enable-insecure-extension-access --xformers --data-dir ./workspace"
# python3 executable
python_cmd="python3"
# git executable
export GIT="git"
# script to launch to start the app
export LAUNCH_SCRIPT="launch.py"

# install command for torch
#export TORCH_COMMAND="pip install torch==1.12.1+cu113 --extra-index-url https://download.pytorch.org/whl/cu113"

# Requirements file to use for stable-diffusion-webui
#export REQS_FILE="requirements_versions.txt"

# Fixed git repos
#export K_DIFFUSION_PACKAGE=""
#export GFPGAN_PACKAGE=""

# Fixed git commits
#export STABLE_DIFFUSION_COMMIT_HASH=""
#export TAMING_TRANSFORMERS_COMMIT_HASH=""
#export CODEFORMER_COMMIT_HASH=""
#export BLIP_COMMIT_HASH=""

# Uncomment to enable accelerated launch
export ACCELERATE="True"

# Uncomment to disable TCMalloc
#export NO_TCMALLOC="True"

# Disable sentry logging
export ERROR_REPORTING=FALSE

# Do not reinstall existing pip packages on Debian/Ubuntu
export PIP_IGNORE_INSTALLED=0

export PATH="$HOME/.local/bin:$PATH"

export
# Pretty print
delimiter="################################################################"

printf "\n%s\n" "${delimiter}"
printf "\e[1m\e[32mInstall script for stable-diffusion + Web UI\n"
printf "\e[1m\e[34mTested on Debian 11 (Bullseye)\e[0m"
printf "\n%s\n" "${delimiter}"

# Check prerequisites
gpu_info=$(lspci 2>/dev/null | grep VGA)
case "$gpu_info" in
*"Navi 1"* | *"Navi 2"*)
    export HSA_OVERRIDE_GFX_VERSION=10.3.0
    ;;
*"Renoir"*)
    export HSA_OVERRIDE_GFX_VERSION=9.0.0
    printf "\n%s\n" "${delimiter}"
    printf "Experimental support for Renoir: make sure to have at least 4GB of VRAM and 10GB of RAM or enable cpu mode: --use-cpu all --no-half"
    printf "\n%s\n" "${delimiter}"
    ;;
*) ;;
esac
if echo "$gpu_info" | grep -q "AMD" && [[ -z "${TORCH_COMMAND}" ]]; then
    # AMD users will still use torch 1.13 because 2.0 does not seem to work.
    export TORCH_COMMAND="pip install torch==1.13.1+rocm5.2 torchvision==0.14.1+rocm5.2 --index-url https://download.pytorch.org/whl/rocm5.2"
fi

for preq in "${GIT}" "${python_cmd}"; do
    if ! hash "${preq}" &>/dev/null; then
        printf "\n%s\n" "${delimiter}"
        printf "\e[1m\e[31mERROR: %s is not installed, aborting...\e[0m" "${preq}"
        printf "\n%s\n" "${delimiter}"
        exit 1
    fi
done

cd "${install_dir}"/ || {
    printf "\e[1m\e[31mERROR: Can't cd to %s/, aborting...\e[0m" "${install_dir}"
    exit 1
}
if [[ -d "${clone_dir}" ]]; then
    cd "${clone_dir}"/ || {
        printf "\e[1m\e[31mERROR: Can't cd to %s/%s/, aborting...\e[0m" "${install_dir}" "${clone_dir}"
        exit 1
    }
else
    printf "\n%s\n" "${delimiter}"
    printf "Clone stable-diffusion-webui"
    printf "\n%s\n" "${delimiter}"
    "${GIT} clone https://github.com/${SDW_GITHUB_USERNAME}/${SDW_GITHUB_REPO}.git ${clone_dir}"
    cd "${clone_dir}"/ || {
        printf "\e[1m\e[31mERROR: Can't cd to %s/%s/, aborting...\e[0m" "${install_dir}" "${clone_dir}"
        exit 1
    }
fi

cd "${install_dir}"/"${clone_dir}"/ || {
    printf "\e[1m\e[31mERROR: Can't cd to %s/%s/, aborting...\e[0m" "${install_dir}" "${clone_dir}"
    exit 1
}
printf "\n%s\n" "${delimiter}"
printf "Check out %s branch" "${SDW_GITHUB_BRANCH}"
printf "\n%s\n" "${delimiter}"
"${GIT}" fetch --all
"${GIT}" checkout "${SDW_GITHUB_BRANCH}" || {
    printf "\e[1m\e[31mERROR: Can't checkout %s branch, aborting...\e[0m" "${SDW_GITHUB_BRANCH}"
    exit 1
}

# Copy webui.py to the stable-diffusion directory
printf "\n%s\n" "${delimiter}"
printf "Copy webui.py to the stable-diffusion-webui directory"
cp -rf "${install_dir}/scripts/webui.py" "${install_dir}"/"${clone_dir}/" || {
    printf "\e[1m\e[31mERROR: Can't copy webui.py to the stable-diffusion-webui directory, aborting...\e[0m"
    exit 1
}

# Try using TCMalloc on Linux
prepare_tcmalloc() {
    if [[ "${OSTYPE}" == "linux"* ]] && [[ -z "${NO_TCMALLOC}" ]] && [[ -z "${LD_PRELOAD}" ]]; then
        TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
        if [[ -n "${TCMALLOC}" ]]; then
            echo "Using TCMalloc: ${TCMALLOC}"
            export LD_PRELOAD="${TCMALLOC}"
        else
            printf "\e[1m\e[31mCannot locate TCMalloc (improves CPU memory usage)\e[0m\n"
        fi
    fi
}

if [[ -n "${ACCELERATE}" ]] && [ "${ACCELERATE}" = "True" ] && [ -x "$(command -v accelerate)" ]; then
    printf "\n%s\n" "${delimiter}"
    printf "Accelerating launch.py..."
    printf "\n%s\n" "${delimiter}"
    prepare_tcmalloc
    exec accelerate launch --dynamo_backend=ofi --mixed_precision=fp16 --num_machines=1 --num_processes=1 --num_cpu_threads_per_process=6 "${LAUNCH_SCRIPT}" "$@"
else
    printf "\n%s\n" "${delimiter}"
    printf "Launching launch.py..."
    printf "\n%s\n" "${delimiter}"
    prepare_tcmalloc
    exec "${python_cmd}" "${LAUNCH_SCRIPT}" "$@"
fi
