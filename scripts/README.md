# ArcDeploy Scripts Directory

This directory contains deployment and testing scripts for the ArcDeploy project. These scripts are designed for local development and testing purposes only.

## 🚨 Important Notice

**This entire `scripts/` directory is ignored by Git** (see `.gitignore`). These scripts are not included in the main repository for the following reasons:

1. **Local Development Only**: These scripts contain deployment automation that should remain on developer machines
2. **Security**: Prevents accidental commit of scripts that might contain sensitive paths or configurations
3. **Environment Specific**: Scripts may be customized per developer's local environment
4. **Clean Repository**: Keeps the main codebase focused on the core ArcDeploy functionality

## 📁 Scripts Overview

| Script | Purpose | Usage |
|--------|---------|--------|
| `check-setup.sh` | Validates local environment and Hetzner Cloud API setup | `./scripts/check-setup.sh` |
| `quick-deploy.sh` | Simple one-command deployment with sensible defaults | `./scripts/quick-deploy.sh [size/location]` |
| `deploy-test-server.sh` | Full-featured deployment with all configuration options | `./scripts/deploy-test-server.sh [name] [type] [location]` |
| `example-workflow.sh` | Interactive guide demonstrating common deployment workflows | `./scripts/example-workflow.sh` |

## 🚀 Quick Start

1. **Setup Requirements**:
   - Hetzner Cloud API token set in environment
   - SSH key configured for server access
   - Required tools: `curl`, `jq`, `ssh`

2. **Validate Setup**:
   ```bash
   ./scripts/check-setup.sh
   ```

3. **Deploy Test Server**:
   ```bash
   ./scripts/quick-deploy.sh
   ```

## 📖 Detailed Documentation

For complete usage instructions, troubleshooting, and examples, see:
- `../DEPLOYMENT.md` - Comprehensive deployment guide
- Individual script help: `./scripts/[script-name].sh --help`

## ⚠️ Developer Notes

- Scripts are designed to be self-contained and include comprehensive error handling
- All scripts include validation and confirmation prompts before making changes
- Cleanup functions are built into each script to remove test resources
- Scripts log activities and provide detailed output for debugging

## 🔧 Customization

You can safely modify these scripts for your local development needs without affecting the main repository. Common customizations include:

- Default server sizes and locations
- SSH key paths and user preferences
- Cloud-init template modifications
- Deployment validation timeouts

## 🆘 Support

If you encounter issues with these scripts:

1. Run `./scripts/check-setup.sh` to validate your environment
2. Check the troubleshooting section in `../DEPLOYMENT.md`
3. Review script output for specific error messages
4. Open an issue in the main repository with debug information

---

**Note**: These scripts are part of the ArcDeploy development workflow but are intentionally kept separate from the main codebase to maintain repository security and cleanliness.