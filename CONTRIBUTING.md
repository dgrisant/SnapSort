# Contributing to SnapSort

Thank you for your interest in contributing to SnapSort! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Branch Strategy](#branch-strategy)
- [Making Changes](#making-changes)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Reporting Bugs](#reporting-bugs)
- [Requesting Features](#requesting-features)

---

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on the code, not the person
- Help others learn and grow

---

## Getting Started

### Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- Git

### Setup

1. Fork the repository on GitHub
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/SnapSort.git
   cd SnapSort
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/dgrisant/SnapSort.git
   ```
4. Open in Xcode:
   ```bash
   open SnapSort.xcodeproj
   ```

---

## Branch Strategy

| Branch | Purpose | Merges From | Merges To |
|--------|---------|-------------|-----------|
| `main` | Public releases | `prod` | - |
| `prod` | Tested features | `dev` | `main` |
| `dev` | Active development | `feature/*` | `prod` |
| `feature/*` | Individual features | - | `dev` |

### Workflow

```
feature/my-feature → dev → prod → main
                      ↑
                    (PR review)
```

---

## Making Changes

### 1. Create a Feature Branch

```bash
# Ensure you're up to date
git checkout dev
git pull upstream dev

# Create feature branch
git checkout -b feature/your-feature-name
```

### 2. Make Your Changes

- Follow the [coding standards](#coding-standards)
- Write clear, self-documenting code
- Add comments for complex logic
- Update documentation if needed

### 3. Test Your Changes

```bash
# Build the project
xcodebuild -project SnapSort.xcodeproj -scheme SnapSort build

# Run the app and test manually
open ~/Library/Developer/Xcode/DerivedData/SnapSort-*/Build/Products/Debug/SnapSort.app
```

### 4. Commit Your Changes

```bash
git add .
git commit -m "Add: Brief description of change

- Detailed point 1
- Detailed point 2"
```

### 5. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub targeting the `dev` branch.

---

## Pull Request Process

### Before Submitting

- [ ] Code builds without errors
- [ ] Code builds without new warnings
- [ ] Tested on macOS 13+
- [ ] Documentation updated (if applicable)
- [ ] Commit messages are clear and descriptive

### PR Description Template

```markdown
## Summary
Brief description of what this PR does.

## Changes
- Change 1
- Change 2

## Testing
How was this tested?

## Screenshots
(if applicable)

## Related Issues
Fixes #123
```

### Review Process

1. Submit PR to `dev` branch
2. Automated checks run (if configured)
3. Code review by maintainers
4. Address feedback
5. Merge when approved

---

## Coding Standards

### Swift Style

```swift
// MARK: - Section Name

/// Documentation comment for public APIs
/// - Parameter name: Description
/// - Returns: Description
func functionName(parameter: Type) -> ReturnType {
    // Implementation
}
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes/Structs | PascalCase | `FileWatcherService` |
| Functions/Variables | camelCase | `processFile()` |
| Constants | camelCase | `let maxRetries = 3` |
| Protocols | PascalCase + suffix | `FileWatcherDelegate` |

### File Organization

```swift
import Framework

// MARK: - Constants

private let kConstant = "value"

// MARK: - Protocol

protocol MyProtocol { }

// MARK: - Class/Struct

class MyClass {
    // MARK: - Properties

    // MARK: - Initialization

    // MARK: - Public Methods

    // MARK: - Private Methods
}

// MARK: - Extensions

extension MyClass: SomeProtocol { }
```

### Best Practices

- Use `guard` for early exits
- Prefer `let` over `var`
- Use Swift's native types
- Handle errors gracefully
- Avoid force unwrapping (`!`)
- Use meaningful variable names

---

## Reporting Bugs

### Before Reporting

1. Check existing issues for duplicates
2. Ensure you're on the latest version
3. Try to reproduce the issue

### Bug Report Template

```markdown
## Description
Clear description of the bug.

## Steps to Reproduce
1. Step one
2. Step two
3. ...

## Expected Behavior
What should happen.

## Actual Behavior
What actually happens.

## Environment
- macOS version:
- SnapSort version:
- Other relevant info:

## Screenshots/Logs
(if applicable)
```

---

## Requesting Features

### Feature Request Template

```markdown
## Summary
Brief description of the feature.

## Problem
What problem does this solve?

## Proposed Solution
How should it work?

## Alternatives Considered
Other approaches you've thought about.

## Additional Context
Any other information.
```

---

## Questions?

- Open an issue with the `question` label
- Check existing documentation in `/docs`

Thank you for contributing to SnapSort!
