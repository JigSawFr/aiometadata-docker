Issue #1 (undici / Node 20 incompatibility) is resolved by upgrading both build and runtime stages to Node 24.

- PR: #5 (Use Node 24 for image builds) was merged.
- This commit closes issue #1 and also triggers the Rebuild workflow (commit message contains "node").

If you still observe crash-loops with the latest images, please reopen the issue with logs and I will investigate.
