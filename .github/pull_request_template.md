# Pull Request Template

## 📋 Pull Request Information

### PR Type
<!-- Mark the type of change this PR introduces -->
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Security enhancement
- [ ] Configuration change
- [ ] Other (please describe):

### Related Issues
<!-- Link to related issues using keywords like "fixes", "closes", "resolves" -->
- Fixes #
- Closes #
- Related to #

## 🎯 Description

### Summary
<!-- Provide a clear and concise description of what this PR does -->


### Motivation and Context
<!-- Why is this change required? What problem does it solve? -->


### Changes Made
<!-- List the specific changes made in this PR -->
- 
- 
- 

## 🧪 Testing

### Testing Performed
<!-- Describe the testing you've performed -->
- [ ] Local testing completed
- [ ] Cloud provider testing (specify which):
  - [ ] AWS
  - [ ] Google Cloud Platform
  - [ ] Microsoft Azure
  - [ ] DigitalOcean
  - [ ] Other: ___________
- [ ] Multi-distribution testing:
  - [ ] Ubuntu 20.04 LTS
  - [ ] Ubuntu 22.04 LTS
  - [ ] Ubuntu 24.04 LTS
  - [ ] Debian 11/12
  - [ ] CentOS/RHEL
- [ ] Security testing performed
- [ ] Performance testing completed

### Test Results
<!-- Provide details about test results -->


### Regression Testing
<!-- Confirm that existing functionality still works -->
- [ ] Existing deployments continue to work
- [ ] No breaking changes introduced
- [ ] Backward compatibility maintained

## 📊 Impact Analysis

### User Impact
<!-- How does this change affect end users? -->


### Performance Impact
<!-- Does this change affect performance? -->
- [ ] No performance impact
- [ ] Performance improvement (describe):
- [ ] Performance regression (justify):

### Security Impact
<!-- Does this change affect security? -->
- [ ] No security impact
- [ ] Security improvement (describe):
- [ ] Security considerations (describe):

### Breaking Changes
<!-- List any breaking changes and migration steps -->


## 📚 Documentation

### Documentation Updates
- [ ] README.md updated
- [ ] Troubleshooting guide updated
- [ ] Configuration documentation updated
- [ ] Changelog updated
- [ ] No documentation changes needed

### Documentation Changes Made
<!-- List specific documentation changes -->


## 🔍 Code Quality

### Code Review Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Code is well-commented
- [ ] No hardcoded credentials or sensitive data
- [ ] Error handling implemented where appropriate
- [ ] Input validation added where needed

### Security Checklist
- [ ] No sensitive information exposed
- [ ] Input sanitization implemented
- [ ] Security best practices followed
- [ ] No new security vulnerabilities introduced

## 🚀 Deployment

### Deployment Requirements
<!-- Any special deployment requirements or considerations -->


### Migration Steps
<!-- If applicable, provide migration steps for existing deployments -->


### Rollback Plan
<!-- Describe how to rollback this change if needed -->


## 📋 Reviewer Checklist

### For Reviewers
- [ ] Code changes reviewed and approved
- [ ] Testing strategy is adequate
- [ ] Documentation is updated and accurate
- [ ] Security implications considered
- [ ] Performance impact assessed
- [ ] Breaking changes properly documented
- [ ] Backward compatibility verified

## 🎯 Post-Merge Actions

### After Merge
- [ ] Update release notes
- [ ] Notify community of changes
- [ ] Update deployment guides if needed
- [ ] Monitor for issues in production
- [ ] Update related repositories if needed

## 📞 Additional Notes

### Notes for Reviewers
<!-- Any specific areas you'd like reviewers to focus on -->


### Known Issues
<!-- Any known issues or limitations with this PR -->


### Future Work
<!-- Any follow-up work planned -->


---

## ✅ Submission Checklist

Before submitting this PR, please ensure:

- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings or errors
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published in downstream modules
- [ ] I have checked my code and corrected any misspellings
- [ ] I have removed any debugging code or console.log statements
- [ ] I have verified that my changes work across different cloud providers
- [ ] I have considered the security implications of my changes
- [ ] I have updated the appropriate documentation

## 🏷️ Labels and Assignees

<!-- The following will be handled by maintainers -->
### Suggested Labels
<!-- Suggest appropriate labels for this PR -->
- 

### Suggested Reviewers
<!-- Tag specific reviewers if needed -->
@

---

**Thank you for contributing to ArcDeploy!** 🎉

Your contribution helps make infrastructure deployment simpler and more reliable for everyone. We appreciate your time and effort in making ArcDeploy better.