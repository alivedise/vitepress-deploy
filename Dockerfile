FROM node:22-slim as base

LABEL "com.github.actions.name"="Vuepress deploy"
LABEL "com.github.actions.description"="A GitHub Action to build and deploy Vuepress sites to GitHub Pages"
LABEL "com.github.actions.icon"="upload-cloud"
LABEL "com.github.actions.color"="gray-dark"

LABEL "repository"="https://github.com/alivedise/vitepress-deploy"
LABEL "homepage"="https://github.com/alivedise/vitepress-deploy"
LABEL "maintainer"="alivedise <alegnadise@gmail.com>"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    jq \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
