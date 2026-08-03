# dust/tests/smoke.star — stable across upstream dust releases.
# dust is a disk-usage visualiser (a `du` replacement). Its normal output is a
# colourised, terminal-width-dependent bar chart, so every run below pins the
# presentation explicitly and asserts computed values — file names and EXACT
# byte counts derived from a hermetic tree this script writes itself — never
# help/version prose and never a multi-word plain substring.

DUST = "dust.exe" if ocx.target_platform.os == ocx.os.Windows else "dust"

# Tier 1 + 2: liveness on the composed PATH + version SHAPE (not the vendor
# banner, not the exact version — the digits are the contract).
r_version = ocx.run(DUST, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# ─── Tier 3: real disk accounting over a hermetic tree ──────────────────────
#
# Four files of deliberately distinct, exact sizes across two directory levels.
# No newlines anywhere in the content, so no CRLF translation can shift a byte
# count on Windows — each file is exactly as many bytes as characters written.
ocx.mkdir("tree/sub")
ocx.write_file("tree/big.txt", "B" * 40000)
ocx.write_file("tree/medium.txt", "M" * 10000)
ocx.write_file("tree/noise.bin", "N" * 4000)
ocx.write_file("tree/sub/small.txt", "S" * 1000)

# The flag set that makes dust deterministic. Every one of these removes a
# source of CI flakiness rather than merely tidying the output:
#   -c  no colours          — SGR escapes land per token and would break any
#                             substring assertion (and CI is not a tty anyway,
#                             so the auto-detection differs from a local run)
#   -b  no percent bars     — the bar glyphs are what scale with terminal width
#   -w 100  fixed width     — pins the width outright; without it dust reads the
#                             terminal size, which differs runner to runner
#   -n 20  fixed line cap   — the default is terminal_HEIGHT, likewise variable
#   -P  no progress         — no spinner interleaving
#   -s  apparent size       — file LENGTH, not allocated blocks. Blocks depend on
#                             the runner's filesystem (block size, tail packing,
#                             compression), so this is what makes an exact byte
#                             assertion legitimate at all
#   -o b  bytes             — raw byte counts instead of the human-rounded "39K"
#   -F  only files          — one row per file, no directory rollup rows
#   -R  screen-reader mode  — plain aligned columns instead of the box-drawing
#                             tree, so the parse needs no Unicode glyphs
#   --skip-total  no total  — drops the trailing root row
# Paths are left SHORTENED (no -p), so every row names a bare basename and no
# `/` vs `\` separator difference can reach the assertions.
FLAGS = ["-c", "-b", "-P", "-s", "-n", "20", "-w", "100", "-o", "b", "-F", "-R", "--skip-total"]

r_all = ocx.run(DUST, *(FLAGS + ["tree"]))
expect.ok(r_all)

# 3a: the entry COUNT is the assertion with teeth. Exit code alone has none —
# a binary that walked nothing, or one that walked the whole scratch root, both
# exit 0. Four files were written, so exactly four rows must come back.
rows = [line for line in r_all.stdout.replace("\r", "").split("\n") if line.strip()]
expect.eq(len(rows), 4)

# 3b: the computed sizes. Each row is `<name> <depth> <bytes>B <pct>%`; the byte
# figure is dust's own measurement of a file whose length this script chose, so
# it reds against a truncated archive, a wrong-arch binary that cannot stat, or
# a size-accounting regression.
expect.matches(r_all.stdout, r"big\.txt\s+\d+\s+40000B")
expect.matches(r_all.stdout, r"medium\.txt\s+\d+\s+10000B")
expect.matches(r_all.stdout, r"noise\.bin\s+\d+\s+4000B")
expect.matches(r_all.stdout, r"small\.txt\s+\d+\s+1000B")

# 3c: ORDERING is dust's actual purpose — "show me the largest". Rows come back
# ascending, so the largest file must be the last row. This is the half a
# per-row `contains` cannot see: a build that found every file but ranked them
# wrongly would satisfy 3a and 3b and fail here.
expect.matches(rows[len(rows) - 1], r"^big\.txt\s")
expect.matches(rows[0], r"^small\.txt\s")

# 3d: the inverse selector over the same tree. `-e/--filter` keeps only paths
# matching the regex, so exactly ONE row must survive — this is what reds
# against a binary that ignores its filter and reports everything, and the
# result is again a COUNT rather than an exit code.
r_filtered = ocx.run(DUST, *(FLAGS + ["-e", r"\.bin$", "tree"]))
expect.ok(r_filtered)
kept = [line for line in r_filtered.stdout.replace("\r", "").split("\n") if line.strip()]
expect.eq(len(kept), 1)
expect.matches(kept[0], r"^noise\.bin\s+\d+\s+4000B")

# No Tier 4: metadata.json declares PATH only, proven by the Tier 1 liveness run.
