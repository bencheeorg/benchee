FROM hexpm/elixir:1.20.4-erlang-29.0.6-debian-trixie-20261020

# Core build dependencies (the common-utils feature adds the non-root user + shell ergonomics)
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    curl \
    inotify-tools \
    ca-certificates \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Optional but helpful for debugging / shell ergonomics
ENV ERL_AFLAGS="+B -kernel shell_history enabled"

# Hex + Rebar are installed per-user in postCreateCommand (see devcontainer.json),
# since they live in the user's ~/.mix and the container no longer runs as root.

WORKDIR /workspace
