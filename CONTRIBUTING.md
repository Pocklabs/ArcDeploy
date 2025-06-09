# Contributing to ArcDeploy

Thank you for your interest in contributing to ArcDeploy! This document provides guidelines for contributing to the **production ArcDeploy repository**.

> **Note**: If you're interested in contributing to development tools, testing frameworks, or advanced features, please see the [ArcDeploy-Dev repository](https://github.com/Pocklabs/ArcDeploy-Dev) instead.

## 🎯 Repository Purpose

This repository contains the **production-ready** ArcDeploy deployment system optimized for:

- Simple 10-minute cloud deployments
- End-user accessibility
- Minimal file size and complexity
- Universal cloud provider compatibility
- Enterprise-grade security

## 🤝 How to Contribute

### Types of Contributions Welcome

#### ✅ Production Repository Contributions

- **Bug fixes** for deployment issues
- **Security improvements** and patches
- **Documentation improvements** and clarifications
- **Cloud provider compatibility** enhancements
- **Performance optimizations** for deployment speed
- **User experience improvements** for ease of use

#### ❌ Not for This Repository

- Development tools and testing frameworks → Use [ArcDeploy-Dev](https://github.com/Pocklabs/ArcDeploy-Dev)
- Experimental features → Use [ArcDeploy-Dev](https://github.com/Pocklabs/ArcDeploy-Dev)
- Debug tools and diagnostic scripts → Use [ArcDeploy-Dev](https://github.com/Pocklabs/ArcDeploy-Dev)

## 🚀 Getting Started

### Prerequisites

- GitHub account
- Basic understanding of cloud-init and YAML
- Experience with at least one major cloud provider
- Understanding of Linux system administration

### Development Environment Setup

1. **Fork the repository**
   ```bash
   # Fork via GitHub UI, then clone your fork
   git clone https://github.com/your-username/ArcDeploy.git
   cd ArcDeploy
   ```

2. **Set up upstream remote**
   ```bash
   git remote add upstream https://github.com/Pocklabs/ArcDeploy.git
   ```

3. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

### Testing Your Changes

#### Local Validation

```bash
# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('cloud-init.yaml'))"

# Check file structure
ls -la

# Validate documentation
markdown-link-check README.md
```

#### Cloud Testing (Required)

Before submitting a PR, test your changes on at least one cloud provider:

1. **Choose a test cloud provider** (AWS, GCP, Azure, DigitalOcean, etc.)
2. **Deploy with your changes** using a small instance
3. **Verify the deployment** works as expected
4. **Document test results** in your PR

## 📋 Contribution Process

### 1. Issue First (Recommended)

- **Check existing issues** before creating new ones
- **Create an issue** describing the problem or enhancement
- **Wait for feedback** from maintainers
- **Get approval** before starting work on large changes

### 2. Making Changes

#### Code Standards

- **YAML formatting**: Use 2-space indentation
- **Comments**: Add clear comments for complex configurations
- **Security**: Never include real credentials or sensitive data
- **Backwards compatibility**: Maintain compatibility with existing deployments

#### Documentation Standards

- **Clear language**: Write for users of all skill levels
- **Examples**: Include practical examples
- **Updated**: Keep all documentation current
- **Tested**: Verify all instructions work

### 3. Submitting Changes

#### Pull Request Requirements

- [ ] **Issue reference**: Link to related issue
- [ ] **Clear description**: Explain what and why
- [ ] **Testing evidence**: Show successful deployment
- [ ] **Documentation**: Update relevant docs
- [ ] **No secrets**: Verify no credentials included
- [ ] **Backwards compatible**: Confirm existing deployments work

#### PR Title Format

```
[TYPE] Brief description

Examples:
[FIX] Resolve nginx configuration issue on Ubuntu 24.04
[FEAT] Add support for Hetzner Cloud deployment
[DOCS] Improve troubleshooting guide for firewall issues
[SEC] Update SSH configuration for enhanced security
```

#### PR Template

Use the provided PR template and fill out all relevant sections.

## 🔒 Security Guidelines

### Security-First Approach

- **No real credentials**: Use placeholders only
- **Secure defaults**: Follow security best practices
- **Input validation**: Validate all user inputs
- **Minimal exposure**: Limit open ports and services

### Reporting Security Issues

- **Private reporting**: Use GitHub Security Advisories
- **No public disclosure**: Don't create public issues for security bugs
- **Responsible disclosure**: Allow time for fixes before disclosure

## 📚 Style Guidelines

### YAML Style

```yaml
# Good: Clear, commented, consistent indentation
users:
  - name: arc
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    shell: /bin/bash
    # SSH key will be added during deployment
    ssh_authorized_keys:
      - "SSH_PUBLIC_KEY_PLACEHOLDER"

# Bad: No comments, inconsistent formatting
users:
- name: arc
  sudo: ['ALL=(ALL) NOPASSWD:ALL']
  shell: /bin/bash
  ssh_authorized_keys: ["SSH_PUBLIC_KEY_PLACEHOLDER"]
```

### Documentation Style

```markdown
# Good: Clear headings, practical examples
## Installing on AWS

1. **Launch EC2 instance** with Ubuntu 22.04 LTS
2. **Configure security group** to allow ports 22, 80, 443
3. **Add cloud-init configuration** in user data

# Bad: Vague, no examples
## AWS
Configure AWS and deploy.
```

## 🧪 Testing Requirements

### Required Testing

- [ ] **Syntax validation**: YAML parses correctly
- [ ] **Cloud deployment**: Works on at least one cloud provider
- [ ] **Service functionality**: All services start and work
- [ ] **Security verification**: No security regressions
- [ ] **Documentation accuracy**: All docs are current

### Testing Checklist

```bash
# Pre-submission testing checklist
□ YAML syntax validated
□ Deployed successfully on cloud provider: ___________
□ All services running (nginx, blocklet-server, ssh)
□ Firewall configured correctly
□ SSL/TLS working if applicable
□ No sensitive data in commits
□ Documentation updated and tested
□ Backwards compatibility verified
```

## 🏷️ Issue and PR Labels

### Issue Labels

- `bug` - Something isn't working
- `enhancement` - New feature or improvement
- `documentation` - Documentation improvements
- `security` - Security-related issues
- `cloud-provider` - Cloud provider specific issues
- `performance` - Performance improvements
- `user-experience` - UX improvements

### Priority Labels

- `priority-critical` - System breaking, needs immediate attention
- `priority-high` - Important, should be addressed soon
- `priority-medium` - Normal priority
- `priority-low` - Nice to have

## 🔄 Review Process

### What to Expect

1. **Automated checks**: CI/CD validation runs automatically
2. **Maintainer review**: Code and approach review
3. **Community feedback**: Optional community input
4. **Testing verification**: Deployment testing confirmation
5. **Approval and merge**: Final approval and integration

### Review Criteria

- **Functionality**: Does it work as intended?
- **Security**: No security vulnerabilities introduced?
- **Performance**: No significant performance impact?
- **Compatibility**: Works across cloud providers and OS versions?
- **Documentation**: Properly documented and explained?

## 📞 Getting Help

### Where to Get Help

- **General questions**: [GitHub Discussions](https://github.com/Pocklabs/ArcDeploy/discussions)
- **Development help**: [ArcDeploy-Dev repository](https://github.com/Pocklabs/ArcDeploy-Dev)
- **Bug reports**: [GitHub Issues](https://github.com/Pocklabs/ArcDeploy/issues)
- **Security issues**: [Security Advisories](https://github.com/Pocklabs/ArcDeploy/security)

### Response Times

- **Critical issues**: 24-48 hours
- **Bug reports**: 3-5 business days
- **Feature requests**: 1-2 weeks
- **Pull requests**: 3-7 business days

## 🎉 Recognition

### Contributor Recognition

- **Contributors file**: All contributors listed in CONTRIBUTORS.md
- **Release notes**: Significant contributions mentioned
- **Community recognition**: Featured in project updates

### Becoming a Maintainer

Regular contributors who demonstrate:

- Consistent quality contributions
- Understanding of project goals
- Good community interaction
- Technical expertise

May be invited to become maintainers.

## 📜 Code of Conduct

### Our Standards

- **Respectful**: Treat all community members with respect
- **Inclusive**: Welcome people of all backgrounds and experience levels
- **Collaborative**: Work together constructively
- **Professional**: Maintain professional communication

### Enforcement

- **Warning**: First violation gets a warning
- **Temporary ban**: Repeated violations result in temporary ban
- **Permanent ban**: Severe or continued violations result in permanent ban

## 📄 License

By contributing to ArcDeploy, you agree that your contributions will be licensed under the [MIT License](LICENSE).

## 🙏 Thank You

Thank you for contributing to ArcDeploy! Your contributions help make infrastructure deployment simpler and more reliable for everyone.

---

## 📊 Quick Reference

### Contribution Workflow

```
1. Fork repository
2. Create feature branch
3. Make changes
4. Test thoroughly
5. Submit pull request
6. Address review feedback
7. Get merged! 🎉
```

### File Structure (Keep Minimal)

```
ArcDeploy/
├── README.md              # Main documentation
├── cloud-init.yaml        # Deployment configuration
├── LICENSE                # MIT license
├── .gitignore             # Git ignore rules
├── CONTRIBUTING.md        # This file
├── docs/                  # Additional documentation
└── .github/               # GitHub templates and workflows
```

### Contact Information

- **Project Lead**: [Maintainer Name](mailto:maintainer@example.com)
- **Security Contact**: [security@example.com](mailto:security@example.com)
- **Community**: [GitHub Discussions](https://github.com/Pocklabs/ArcDeploy/discussions)

**Happy Contributing!** 🚀