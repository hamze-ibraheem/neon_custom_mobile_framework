# Contributing to Neon Framework ⚡

Thank you for your interest in contributing to **Neon Framework**, an open-source project by **Task Foundation LLC** and founder **Hamza Ibrahim**.

---

## 🔒 Contributor Policy for Features & Enhancements

To preserve architectural integrity, stability, and high performance across native platforms (Android and iOS):

1. **Bug Fixes & Documentation**:
   - Open to everyone! Community members are welcome to report bugs, improve documentation, and submit pull requests for verified defects without pre-approval.
2. **Features & Enhancements**:
   - Pull requests introducing new features or structural enhancements on `dev-beta-version-1.0.0` or `main` are **restricted to authorized project contributors**.
   - Community members wishing to propose a feature should first open an **RFC / Feature Proposal Issue** in the repository.
   - Once reviewed and approved by maintainers, a maintainer will assign the `contributor-approved` label to your pull request, allowing the CI pipeline and review process to proceed.

---

## 🛠️ Development Setup

1. **Prerequisites**:
   - Dart SDK `^3.0.0`
   - Android Studio (API 34) / Xcode 15+ (macOS)
2. **Clone and Install**:
   ```bash
   git clone https://github.com/hamze-ibraheem/neon_custom_mobile_framework.git
   cd neon_custom_mobile_framework/NeonFramework-2/neon_framework
   dart pub get
   ```
3. **Run the Test Suite**:
   ```bash
   dart test
   ```
   All 400+ automated unit and integration tests must pass before opening a PR.

---

## ⚙️ Implementing New Features with `NeonFeatureOptions`

When adding new capabilities or experimental APIs in branch `dev-beta-version-1.0.0`:
- Encapsulate the behavior inside `NeonFeatureOptions` (located in `lib/src/core/feature_options.dart`).
- Provide safe defaults that preserve backward compatibility.
- Ensure the option can be observed and toggled dynamically at runtime via `NeonFeatureOptionsManager`.

---

## 📝 Pull Request Checklist

Before submitting a PR:
- [ ] Ran `dart analyze` with zero errors or warnings.
- [ ] Ran `dart test` with all tests passing.
- [ ] Added automated tests for any new widgets, state behaviors, or feature options.
- [ ] Kept the framework 100% standalone (no `package:flutter` dependencies).
- [ ] Included descriptive PR details following `.github/pull_request_template.md`.

