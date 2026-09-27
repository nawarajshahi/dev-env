ARG UV_VERSION=0.12.19
FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv

FROM ubuntu:24.04

ARG TZ=America/New_York
ENV TZ="${TZ}"
ENV DEBIAN_FRONTEND=noninteractive

ARG USERNAME=nabu
ARG CLAUDE_CODE_VERSION=latest
ARG NODE_MAJOR=24
ARG TERRAFORM_VERSION=1.16.4
ARG OPENTOFU_VERSION=1.12.6
ARG KUBECTL_VERSION=1.36.5
ARG TALOSCTL_VERSION=1.13.10
ARG HELM_VERSION=4.3.0
ARG CILIUM_CLI_VERSION=0.20.1
ARG ARGOCD_VERSION=3.5.3
ARG K9S_VERSION=0.51.0
ARG YQ_VERSION=4.53.6
ARG TFLINT_VERSION=0.64.0
ARG COREGEN_VERSION=1.1.1
ARG ANSIBLE_CORE_VERSION=2.21.4
ARG GIT_DELTA_VERSION=0.19.2
ARG ZSH_IN_DOCKER_VERSION=1.2.1

# Rename the default ubuntu user (uid/gid 1000) to ${USERNAME} and drop every
# supplementary group (sudo, adm, ...): the user must stay non-admin
RUN groupmod -n ${USERNAME} ubuntu && \
  usermod -l ${USERNAME} -d /home/${USERNAME} -m -s /bin/zsh -G "" ubuntu

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
  curl \
  wget \
  less \
  git \
  procps \
  fzf \
  zsh \
  man-db \
  unzip \
  gnupg2 \
  iptables \
  ipset \
  iproute2 \
  dnsutils \
  aggregate \
  jq \
  nano \
  vim \
  tree \
  python3 \
  python3-pip \
  python3-venv \
  python3-dev \
  pipx \
  make \
  gcc \
  build-essential \
  libkrb5-dev \
  libssl-dev \
  ca-certificates \
  shellcheck \
  rsync \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Node.js (GPG-verified apt repo instead of curl|bash)
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
  gpg --dearmor -o /usr/share/keyrings/nodesource.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" | \
  tee /etc/apt/sources.list.d/nodesource.list > /dev/null && \
  apt-get update && apt-get install -y nodejs && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# Install gh CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
  dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
  chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
  tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
  apt-get update && apt-get install -y gh && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# Set up npm global directory
RUN mkdir -p /usr/local/share/npm-global && \
  chown -R ${USERNAME}:${USERNAME} /usr/local/share/npm-global

# Persist zsh history in named volume
RUN mkdir /commandhistory && \
  touch /commandhistory/.zsh_history && \
  chown -R ${USERNAME}:${USERNAME} /commandhistory

ENV DEVCONTAINER=true

# Create workspace and config directories
RUN mkdir -p /workspace /home/${USERNAME}/.claude && \
  chown -R ${USERNAME}:${USERNAME} /workspace /home/${USERNAME}/.claude

WORKDIR /workspace

# Install git-delta
RUN ARCH=$(dpkg --print-architecture) && \
  wget -q "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# Install AWS CLI v2 (architecture-aware)
RUN ARCH=$(dpkg --print-architecture) && \
  case "$ARCH" in arm64|aarch64) AWSCLI_ARCH="aarch64" ;; *) AWSCLI_ARCH="x86_64" ;; esac && \
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWSCLI_ARCH}.zip" -o /tmp/awscliv2.zip && \
  unzip -q /tmp/awscliv2.zip -d /tmp && \
  /tmp/aws/install && \
  rm -rf /tmp/awscliv2.zip /tmp/aws

# Install Terraform (architecture-aware)
RUN ARCH=$(dpkg --print-architecture) && \
  curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" -o /tmp/terraform.zip && \
  unzip -q -o /tmp/terraform.zip terraform -d /usr/local/bin && \
  rm /tmp/terraform.zip

# Install OpenTofu
RUN ARCH=$(dpkg --print-architecture) && \
  curl -fsSL "https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_linux_${ARCH}.zip" -o /tmp/tofu.zip && \
  unzip -q -o /tmp/tofu.zip tofu -d /usr/local/bin && \
  rm /tmp/tofu.zip

# Install TFLint
RUN ARCH=$(dpkg --print-architecture) && \
  curl -fsSL "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${ARCH}.zip" -o /tmp/tflint.zip && \
  unzip -q -o /tmp/tflint.zip tflint -d /usr/local/bin && \
  rm /tmp/tflint.zip

# Install Kubernetes / Talos tooling (single static binaries)
RUN ARCH=$(dpkg --print-architecture) && \
  curl -fsSL "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" -o /usr/local/bin/kubectl && \
  curl -fsSL "https://github.com/siderolabs/talos/releases/download/v${TALOSCTL_VERSION}/talosctl-linux-${ARCH}" -o /usr/local/bin/talosctl && \
  curl -fsSL "https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-${ARCH}" -o /usr/local/bin/argocd && \
  curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${ARCH}" -o /usr/local/bin/yq && \
  chmod +x /usr/local/bin/kubectl /usr/local/bin/talosctl /usr/local/bin/argocd /usr/local/bin/yq

# Install Helm, Cilium CLI and k9s (tarballs)
RUN ARCH=$(dpkg --print-architecture) && \
  curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz" | \
    tar -xz -C /usr/local/bin --strip-components=1 "linux-${ARCH}/helm" && \
  curl -fsSL "https://github.com/cilium/cilium-cli/releases/download/v${CILIUM_CLI_VERSION}/cilium-linux-${ARCH}.tar.gz" | \
    tar -xz -C /usr/local/bin cilium && \
  curl -fsSL "https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_${ARCH}.tar.gz" | \
    tar -xz -C /usr/local/bin k9s

# Install uv (Python package/tool manager)
COPY --from=uv /uv /uvx /usr/local/bin/

# Install Ansible and Python packages
RUN pip3 install --no-cache-dir --break-system-packages \
  ansible-core==${ANSIBLE_CORE_VERSION} \
  boto3 \
  black \
  pylint \
  flake8 \
  ansible-lint

# Install Python CLIs in isolated venvs, exposed on the system PATH
ENV UV_TOOL_DIR=/opt/uv-tools \
  UV_TOOL_BIN_DIR=/usr/local/bin \
  UV_PYTHON_PREFERENCE=only-system
RUN uv tool install "git+https://github.com/skoonin/coregen.git@v${COREGEN_VERSION}" && \
  uv tool install pre-commit && \
  uv tool install ruff && \
  uv tool install mypy && \
  uv tool install pytest && \
  uv tool install tox && \
  uv cache clean

# Install commonly used Ansible collections system-wide (a plain install as root
# lands in /root/.ansible, which the unprivileged user cannot see)
RUN ansible-galaxy collection install -p /usr/share/ansible/collections \
  'amazon.aws:>=11.0.0,<12.0.0' \
  'ansible.posix:>=2.0.0,<3.0.0' \
  'community.general:>=13.0.0,<14.0.0' \
  'microsoft.ad:>=1.8.0,<2.0.0' \
  'ansible.windows:>=3.0.0,<4.0.0' \
  'community.windows:>=3.0.0,<4.0.0' \
  --force

# System-wide git config: global ignores only. No identity or credentials live
# in the container; commits and pushes happen on the host.
COPY gitignore_global /etc/gitignore_global
RUN git config --system core.excludesFile /etc/gitignore_global && \
  git config --system core.pager delta && \
  git config --system interactive.diffFilter "delta --color-only" && \
  git config --system --add safe.directory '*'

# Switch to non-root user
USER ${USERNAME}

ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin
ENV SHELL=/bin/zsh
ENV EDITOR=nano
ENV VISUAL=nano

# Install zsh with Powerlevel10k and plugins; configure zsh history correctly
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
  -p git \
  -p fzf \
  -p kubectl \
  -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
  -a "source /usr/share/doc/fzf/examples/completion.zsh" \
  -a "export HISTFILE=/commandhistory/.zsh_history" \
  -a "export HISTSIZE=10000" \
  -a "export SAVEHIST=10000" \
  -a "setopt INC_APPEND_HISTORY" \
  -x

# Install zsh-autosuggestions plugin
RUN git clone https://github.com/zsh-users/zsh-autosuggestions \
  /home/${USERNAME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions 2>/dev/null || true

# Source host bash_aliases if mounted, enable zsh-autosuggestions, and drop any
# SSH agent VS Code forwards in (the container must not hold host credentials)
RUN echo '' >> /home/${USERNAME}/.zshrc && \
  echo '# Load host aliases if mounted' >> /home/${USERNAME}/.zshrc && \
  echo '[ -f "$HOME/.bash_aliases" ] && source "$HOME/.bash_aliases"' >> /home/${USERNAME}/.zshrc && \
  echo '' >> /home/${USERNAME}/.zshrc && \
  echo '# zsh-autosuggestions' >> /home/${USERNAME}/.zshrc && \
  echo 'source ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null' >> /home/${USERNAME}/.zshrc && \
  echo '' >> /home/${USERNAME}/.zshrc && \
  echo '# No host credentials in the container' >> /home/${USERNAME}/.zshrc && \
  echo 'unset SSH_AUTH_SOCK GPG_AGENT_INFO' >> /home/${USERNAME}/.zshrc

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Firewall + entrypoint are root-owned and run only at container start (as root).
# The user gets no sudo: nothing in the container can re-run or relax them.
COPY --chmod=0755 init-firewall.sh entrypoint.sh postCreate.sh /usr/local/bin/
USER root

# Strip setuid/setgid bits so no binary can raise privileges (defense in depth
# alongside --security-opt=no-new-privileges)
RUN find / -xdev -type f -perm /6000 -exec chmod a-s {} + 2>/dev/null || true

USER ${USERNAME}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
