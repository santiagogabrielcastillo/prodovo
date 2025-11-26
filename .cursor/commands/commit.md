# Git Commit

Create a git commit. If --amend is provided, amend the last commit. Mention Sentry issues if any. Mention Shortcut stories if any.

## Usage
- `/commit` - Basic commit
- `/commit [custom instructions]` - Commit with specific instructions
- `/commit --sentry <issue-id>` - Commit mentioning a Sentry issue
- `/commit --shortcut <story-id>` - Commit mentioning a Shortcut story
- `/commit --amend` - Amend the last commit
- `/commit [custom instructions] --sentry <issue-id> --shortcut <story-id>` - Combine multiple options

## Context

- Current git status: Run `git status`
- Current git diff (staged and unstaged changes): Run `git diff HEAD`
- Current branch: Run `git branch --show-current`
- Recent commits: Run `git log --oneline -10`
- If the arguments include --shortcut, use the Shortcut MCP to fetch the Shortcut story passed as argument
- If the arguments include --sentry, use the Sentry MCP to fetch Sentry issues passed as argument

## Commit message format

Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) format.

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Considering the following:

- TITLE: 50-character subject line
- BODY: 72-character wrapped longer description. This should answer:
  - Why was this change necessary?
  - How does it address the problem?
  - Are there any side effects?
  - Are there any breaking changes?
- FOOTERS: Include a link to tickets, if any.

Specifications:

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

1. Commits MUST be prefixed with a type, which consists of a noun, feat, fix, etc., followed by the OPTIONAL scope, OPTIONAL !, and REQUIRED terminal colon and space.
2. The type feat MUST be used when a commit adds a new feature to your application or library.
3. The type fix MUST be used when a commit represents a bug fix for your application.
4. A scope MAY be provided after a type. A scope MUST consist of a noun describing a section of the codebase surrounded by parenthesis, e.g., fix(parser):
5. A description MUST immediately follow the colon and space after the type/scope prefix. The description is a short summary of the code changes, e.g., fix: array parsing issue when multiple spaces were contained in string.
6. A longer commit body MAY be provided after the short description, providing additional contextual information about the code changes. The body MUST begin one blank line after the description.
7. A commit body is free-form and MAY consist of any number of newline separated paragraphs.
8. One or more footers MAY be provided one blank line after the body. Each footer MUST consist of a word token, followed by either a :<space> or <space># separator, followed by a string value (this is inspired by the git trailer convention).
9. A footer's token MUST use - in place of whitespace characters, e.g., Acked-by (this helps differentiate the footer section from a multi-paragraph body). An exception is made for BREAKING CHANGE, which MAY also be used as a token.
10. A footer's value MAY contain spaces and newlines, and parsing MUST terminate when the next valid footer token/separator pair is observed.
11. Breaking changes MUST be indicated in the type/scope prefix of a commit, or as an entry in the footer.
12. If included as a footer, a breaking change MUST consist of the uppercase text BREAKING CHANGE, followed by a colon, space, and description, e.g., BREAKING CHANGE: environment variables now take precedence over config files.
13. If included in the type/scope prefix, breaking changes MUST be indicated by a ! immediately before the :. If ! is used, BREAKING CHANGE: MAY be omitted from the footer section, and the commit description SHALL be used to describe the breaking change.
14. Types other than feat and fix MAY be used in your commit messages, e.g., docs: update ref docs.
15. The units of information that make up Conventional Commits MUST NOT be treated as case sensitive by implementors, with the exception of BREAKING CHANGE which MUST be uppercase.
16. BREAKING-CHANGE MUST be synonymous with BREAKING CHANGE, when used as a token in a footer.

## Task

Based on the above changes, create a single git commit.

## Instructions

1. If the arguments include --amend, amend the last commit.
2. If the arguments include --sentry, mention the Sentry issue in the commit message.
3. If the arguments include --shortcut, mention the Shortcut story in the commit message.
4. Unless instructed otherwise, do not add any other files to the commit.
5. If the arguments include custom instructions, follow them.
