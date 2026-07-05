# Codex Safety Policy

This repository is currently in no-local-execution mode because local MT5, MetaEditor, tester, and PowerShell launch attempts have been observed stealing focus from the user's PC.

Until the user explicitly says local execution is allowed again:

- Do not run local shell commands, local test runners, MT5, MetaEditor, MetaTester, Strategy Tester, or helper scripts from Codex.
- Use the GitHub connector/API for repository reads and writes.
- Treat `work/MT5_LOCAL_LAUNCH_DISABLED.lock` as an active hard lock.
- Do not remove or bypass the lock file.
- Do not create unlock files such as `work/ALLOW_MT5_LOCAL_LAUNCH.unlock` or `work/ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock`.
- It is acceptable to edit files remotely through GitHub so the user can run them later on a controlled machine.

If MT5 is already running locally and causing focus flashes, the cleanup-only helper is `work/stop_mt5_stray_processes_hidden.vbs`. It starts no MT5 process; it only runs the cleanup PowerShell script hidden and waits for it to finish.
