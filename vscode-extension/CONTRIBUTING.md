# Contributing to AI Orchestrator

First off, thank you for considering contributing to AI Orchestrator! It's people like you that make this extension great for everyone. 🎉

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Pull Request Process](#pull-request-process)
- [Style Guidelines](#style-guidelines)
- [Reporting Bugs](#reporting-bugs)
- [Requesting Features](#requesting-features)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to [support@debuggerlab.com](mailto:support@debuggerlab.com).

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) (v18 or higher)
- [VS Code](https://code.visualstudio.com/) (v1.85.0 or higher)
- [Git](https://git-scm.com/)

### Development Setup

1. **Fork the repository**
   
   Click the "Fork" button on GitHub to create your own copy.

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/ai-orchestrator-vscode.git
   cd ai-orchestrator-vscode
   ```

3. **Install dependencies**
   ```bash
   npm install
   ```

4. **Open in VS Code**
   ```bash
   code .
   ```

5. **Start the extension in debug mode**
   - Press `F5` to launch a new VS Code window with the extension loaded
   - Make changes to the code
   - Press `Ctrl+Shift+F5` to reload the extension

## Making Changes

### Branch Naming

Use descriptive branch names:
- `feature/add-model-xyz` - For new features
- `fix/api-key-validation` - For bug fixes
- `docs/update-readme` - For documentation changes
- `refactor/router-cleanup` - For code refactoring

### Commit Messages

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

Types:
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```
feat(router): add support for custom model endpoints
fix(ui): resolve chat panel scroll issue
docs(readme): add configuration examples
```

## Pull Request Process

1. **Update documentation** if you're changing functionality
2. **Add tests** for new features
3. **Ensure all tests pass** by running `npm run lint`
4. **Update the CHANGELOG.md** with your changes
5. **Submit your PR** with a clear description

### PR Title Format

Use the same format as commit messages:
```
feat(scope): Brief description of the change
```

### PR Description Template

```markdown
## Description
Brief description of the changes.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe how you tested your changes.

## Screenshots (if applicable)
Add screenshots for UI changes.

## Checklist
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review
- [ ] I have added tests
- [ ] I have updated the documentation
```

## Style Guidelines

### TypeScript

- Use TypeScript strict mode
- Prefer `const` over `let`
- Use async/await over raw Promises
- Add JSDoc comments for public APIs
- Use meaningful variable names

```typescript
// Good
const getUserDisplayName = async (userId: string): Promise<string> => {
  const user = await fetchUser(userId);
  return user.displayName;
};

// Bad
const get = async (id) => {
  const u = await f(id);
  return u.n;
};
```

### File Organization

```
src/
├── extension.ts      # Extension entry point
├── orchestrator.ts   # Core orchestration logic
├── router.ts         # Task routing logic
├── providers/        # AI provider implementations
├── views/            # Webview implementations
└── utils/            # Utility functions
```

## Reporting Bugs

When reporting bugs, please include:

1. **VS Code version**
2. **Extension version**
3. **Operating system**
4. **Steps to reproduce**
5. **Expected behavior**
6. **Actual behavior**
7. **Screenshots** (if applicable)
8. **Error logs** from Developer Tools (`Help > Toggle Developer Tools`)

[Create a Bug Report](https://github.com/DebuggerLab/ai-orchestrator-vscode/issues/new?labels=bug&template=bug_report.md)

## Requesting Features

We love feature requests! When submitting one, please:

1. **Check existing issues** to avoid duplicates
2. **Describe the problem** you're trying to solve
3. **Describe your proposed solution**
4. **Consider alternatives** you've thought about

[Request a Feature](https://github.com/DebuggerLab/ai-orchestrator-vscode/issues/new?labels=enhancement&template=feature_request.md)

## Questions?

Feel free to reach out:
- 📧 Email: [support@debuggerlab.com](mailto:support@debuggerlab.com)
- 💬 GitHub Discussions: [Start a Discussion](https://github.com/DebuggerLab/ai-orchestrator-vscode/discussions)

---

Thank you for contributing! 🙏

— The Debugger Lab Team
