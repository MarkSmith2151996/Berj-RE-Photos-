# CT-040 Blockers

## Summary

The requested atomic MCP connection could not be completed on this WSL machine because both candidate MCP servers target the GIMP 3 API, while the available local package is GIMP `2.10.36`.

## What Worked

- Installed `gimp 2.10.36` from Ubuntu `24.04` apt repositories.
- Installed `xvfb` for virtual-display headless startup.
- Verified headless batch startup with:

```bash
xvfb-run -a gimp -i -b '(gimp-version)' -b '(gimp-quit 0)'
```

- Cloned both candidate MCP repos into `vendor/`.
- Installed the fallback `abelduarte/gimp-mcp` Python package into `vendor/gimp-mcp-fallback/.venv`.

## What Failed

### 1. `maorcc/gimp-mcp`

- Upstream project explicitly targets GIMP `3.2+`.
- This WSL host does not have a GIMP 3 package available from apt.
- Because of that, the primary server was not a viable runtime candidate here.

### 2. `abelduarte/gimp-mcp`

- The fallback bridge plugin was copied into:

```text
~/.config/GIMP/2.10/plug-ins/gimp_mcp_bridge/gimp_mcp_bridge.py
```

- The package was installed locally and its smoke test was executed with `GIMP_APP=/usr/bin/gimp`.
- Result:

```text
Timed out waiting for GIMP MCP bridge to start
socket: /tmp/berj-gimp-test.sock
gimp_app: /usr/bin/gimp
```

- Running the bridge-start command directly under `xvfb-run` exposed the root cause:

```text
Traceback (most recent call last):
  File "/home/dev/.config/GIMP/2.10/plug-ins/gimp_mcp_bridge/gimp_mcp_bridge.py", line 20, in <module>
    gi.require_version("Gimp", "3.0")
ValueError: Namespace Gimp not available
gimp: LibGimpBase-WARNING: gimp: gimp_wire_read(): error
GIMP-Warning: The batch interpreter 'python-fu-eval' is not available. Batch mode disabled.
```

## Conclusion

The worker environment is blocked on obtaining a true GIMP 3.x runtime on WSL/Linux. Until that exists, neither MCP option can satisfy the required atomic workflow of open -> edit -> snapshot -> export.

## Suggested Next Moves

1. Install or build a GIMP 3.x runtime for Linux/WSL.
2. Re-run `CT-040` against that environment.
3. If WSL packaging remains the issue, move the worker proof-of-concept to a Linux container or another host that can run GIMP 3.x natively.
