# Security Policy

## 🔒 Supported Versions

We actively support and provide security updates for the following versions of ArcDeploy:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| 0.9.x   | :white_check_mark: |
| < 0.9   | :x:                |

## 🚨 Reporting a Vulnerability

### Responsible Disclosure

We take security seriously and appreciate the security research community's efforts to help keep ArcDeploy and our users safe. If you believe you have found a security vulnerability in ArcDeploy, please report it responsibly.

### How to Report

**Please DO NOT create public GitHub issues for security vulnerabilities.**

Instead, use one of these secure methods:

#### GitHub Security Advisories (Preferred)
1. Go to the [Security tab](https://github.com/your-org/ArcDeploy/security/advisories)
2. Click "Report a vulnerability"
3. Fill out the security advisory form
4. Submit privately to maintainers

#### Email Reporting
- **Security Email**: security@arcdeploy.com
- **PGP Key**: Available at [keybase.io/arcdeploy](https://keybase.io/arcdeploy)
- **Subject Line**: `[SECURITY] ArcDeploy Vulnerability Report`

### What to Include

Please provide as much information as possible:

```
1. **Vulnerability Type**: (e.g., injection, privilege escalation, data exposure)
2. **Affected Component**: (e.g., cloud-init.yaml, documentation, configuration)
3. **Attack Vector**: (local, network, physical)
4. **Severity Assessment**: (low, medium, high, critical)
5. **Detailed Description**: Clear explanation of the vulnerability
6. **Reproduction Steps**: Step-by-step instructions
7. **Proof of Concept**: Code, commands, or screenshots
8. **Impact Assessment**: Potential damage and affected users
9. **Suggested Mitigation**: If you have ideas for fixes
10. **Discovery Credit**: How you'd like to be credited (optional)
```

## ⏱️ Response Timeline

We are committed to responding quickly to security reports:

| Timeline | Action |
|----------|--------|
| **24 hours** | Initial acknowledgment |
| **72 hours** | Preliminary assessment and severity rating |
| **7 days** | Detailed analysis and reproduction |
| **14 days** | Fix development and testing |
| **30 days** | Public disclosure (if applicable) |

## 🔍 Security Scope

### In Scope
- **Cloud-init configuration vulnerabilities**
- **Service configuration security issues**
- **Privilege escalation vulnerabilities**
- **Information disclosure issues**
- **Authentication and authorization bypasses**
- **Input validation vulnerabilities**
- **Dependency vulnerabilities in deployed services**
- **Network security misconfigurations**

### Out of Scope
- **Social engineering attacks**
- **Physical access attacks**
- **DDoS attacks**
- **Vulnerabilities in third-party cloud providers**
- **Issues requiring compromised credentials**
- **Theoretical attacks without practical impact**
- **Development tools and testing frameworks** (report to ArcDeploy-Dev)

## 🛡️ Security Best Practices

### For Users

#### Deployment Security
```yaml
# Use strong SSH keys (minimum 2048-bit RSA or Ed25519)
ssh_authorized_keys:
  - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... user@example.com"

# Configure minimal firewall rules
# Only open necessary ports
ufw:
  - rule: allow
    port: 22
    proto: tcp
  - rule: allow
    port: 80
    proto: tcp
  - rule: allow
    port: 443
    proto: tcp
```

#### Instance Security
- **Regular Updates**: Keep your deployed instances updated
- **Strong Credentials**: Use strong, unique SSH keys
- **Firewall Configuration**: Implement least-privilege network access
- **Monitoring**: Enable logging and monitoring
- **Backup Strategy**: Implement regular backups

#### Cloud Provider Security
- **IAM Policies**: Use minimal required permissions
- **Network Security**: Implement VPC/subnet isolation
- **Encryption**: Enable encryption at rest and in transit
- **Access Logging**: Enable CloudTrail/equivalent logging

### For Contributors

#### Secure Development
```bash
# Check for secrets before committing
git diff --cached | grep -E "(password|secret|key|token)"

# Validate configurations
python3 -c "import yaml; yaml.safe_load(open('cloud-init.yaml'))"

# Test security configurations
# Verify firewall rules, service configurations, user permissions
```

#### Code Review Security
- **No hardcoded secrets**: Use placeholders only
- **Input validation**: Validate all user inputs
- **Principle of least privilege**: Minimal permissions
- **Secure defaults**: Security-first configuration
- **Documentation**: Document security implications

## 🔧 Security Features

### Built-in Security

#### Authentication
- **SSH Key-only Authentication**: Password authentication disabled
- **Custom SSH Port**: Port 2222 (security through obscurity + reduces noise)
- **User Management**: Dedicated non-root user with sudo access

#### Network Security
```yaml
# Firewall configuration
ufw:
  - rule: allow
    port: 2222    # SSH (custom port)
  - rule: allow
    port: 80      # HTTP
  - rule: allow
    port: 443     # HTTPS
  - rule: deny
    direction: incoming
    policy: deny  # Default deny
```

#### Service Security
- **Service Isolation**: Services run as dedicated users
- **SSL/TLS Encryption**: HTTPS enforced where possible
- **Regular Updates**: Automated security updates enabled
- **Minimal Attack Surface**: Only required services installed

#### System Hardening
```yaml
# System security configurations
write_files:
  - path: /etc/ssh/sshd_config.d/99-security.conf
    content: |
      PasswordAuthentication no
      PubkeyAuthentication yes
      PermitRootLogin no
      Port 2222
      MaxAuthTries 3
      LoginGraceTime 30
```

## 🚨 Known Security Considerations

### Current Limitations
1. **Root Access**: Initial setup requires root privileges
2. **Network Exposure**: Services exposed to internet by default
3. **Update Management**: Manual update process required
4. **Monitoring**: Basic logging only, no advanced monitoring

### Mitigation Strategies
1. **Immediate Privilege Drop**: Switch to non-root user after setup
2. **Firewall Rules**: Strict network access controls
3. **Documentation**: Clear update and maintenance procedures
4. **Community Tools**: Advanced monitoring in ArcDeploy-Dev

## 📋 Security Checklist

### Pre-Deployment
- [ ] Review cloud-init configuration for sensitive data
- [ ] Verify SSH key is secure and properly formatted
- [ ] Confirm firewall rules are restrictive
- [ ] Check cloud provider security group settings
- [ ] Validate instance size meets security requirements

### Post-Deployment
- [ ] Verify SSH access works with key-only authentication
- [ ] Test firewall rules are active and blocking unwanted traffic
- [ ] Confirm services are running with appropriate permissions
- [ ] Check system logs for any errors or security events
- [ ] Validate SSL/TLS certificates if applicable

### Ongoing Maintenance
- [ ] Regular system updates (weekly recommended)
- [ ] Monitor system logs for anomalies
- [ ] Review and rotate SSH keys periodically
- [ ] Backup important data and configurations
- [ ] Stay informed about ArcDeploy security updates

## 🔗 Security Resources

### Documentation
- [Troubleshooting Guide](docs/troubleshooting.md) - Security troubleshooting
- [Cloud Provider Security Guides](docs/) - Provider-specific security
- [ArcDeploy-Dev Security Tools](https://github.com/your-org/ArcDeploy-Dev) - Advanced security tools

### External Resources
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CIS Controls](https://www.cisecurity.org/controls/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Cloud Security Alliance](https://cloudsecurityalliance.org/)

### Security Communities
- [r/netsec](https://reddit.com/r/netsec)
- [Information Security Stack Exchange](https://security.stackexchange.com/)
- [SANS Reading Room](https://www.sans.org/reading-room/)

## 📞 Security Contact Information

### Primary Contacts
- **Security Team**: security@arcdeploy.com
- **Project Lead**: lead@arcdeploy.com
- **Emergency Contact**: emergency@arcdeploy.com (critical issues only)

### Response Team
- **Security Engineer**: Available during business hours (UTC)
- **On-call Rotation**: 24/7 for critical vulnerabilities
- **Community Moderators**: GitHub discussions and issues

## 🏆 Security Hall of Fame

We recognize security researchers who help improve ArcDeploy security:

### 2025
- *First reporter will be listed here*

### Recognition Criteria
- **Responsible disclosure** followed
- **Valid security impact** demonstrated
- **Clear documentation** provided
- **Constructive approach** taken

### Recognition Options
- **Public acknowledgment** (with permission)
- **Security hall of fame** listing
- **CVE co-credit** (for qualifying vulnerabilities)
- **Community recognition** in project updates

## 📄 Legal and Compliance

### Safe Harbor
We commit to:
- **No legal action** for good faith security research
- **Coordinated disclosure** timeline respect
- **Credit and recognition** for valid findings
- **Transparent communication** throughout process

### Compliance
ArcDeploy aims to support compliance with:
- **SOC 2 Type II** - Security controls
- **ISO 27001** - Information security management
- **GDPR** - Data protection (where applicable)
- **HIPAA** - Healthcare data security (with proper configuration)

## 🔄 Security Updates

### Notification Channels
- **GitHub Security Advisories** - Critical vulnerabilities
- **GitHub Releases** - Security patches and updates
- **Mailing List** - security-announce@arcdeploy.com
- **RSS Feed** - GitHub releases feed

### Update Process
1. **Security patch** developed and tested
2. **Advisory published** with details
3. **Notification sent** to all channels
4. **Documentation updated** with mitigation steps
5. **Community support** provided for upgrades

---

**Thank you for helping keep ArcDeploy secure!** 🔒

If you have any questions about this security policy or need clarification on the reporting process, please don't hesitate to contact our security team.

**Last Updated**: June 2025  
**Next Review**: December 2025