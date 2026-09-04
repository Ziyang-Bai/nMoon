#!/usr/bin/env python3
"""Build nMoon.tns from the tracked Lua source and XML template."""

from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from xml.etree import ElementTree
from xml.sax.saxutils import escape

PROJECT_ROOT = Path(__file__).resolve().parent
SOURCE_PATH = PROJECT_ROOT / "src" / "nMoon.lua"
TEMPLATE_PATH = PROJECT_ROOT / "build" / "nMoon.xml"
DEFAULT_OUTPUT = PROJECT_ROOT / "dist" / "nMoon.tns"
SCRIPT_TAG = "{urn:TI.ScriptApp}script"


class BuildError(RuntimeError):
    """An actionable build configuration or input error."""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build a verified TI-Nspire document from src/nMoon.lua."
    )
    parser.add_argument(
        "--tnstools",
        metavar="PATH",
        type=Path,
        help="path to tnstools.py (overrides the TNS_TOOLS environment variable)",
    )
    parser.add_argument(
        "--output",
        metavar="PATH",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"output .tns path (default: {DEFAULT_OUTPUT.relative_to(PROJECT_ROOT)})",
    )
    return parser.parse_args()


def require_file(path: Path, description: str) -> Path:
    path = path.expanduser().resolve()
    if not path.is_file():
        raise BuildError(f"{description} not found or is not a file: {path}")
    return path


def resolve_tnstools(cli_path: Path | None) -> Path:
    configured = cli_path or (Path(value) if (value := os.environ.get("TNS_TOOLS")) else None)
    if configured is None:
        raise BuildError(
            "tnstools.py was not specified; pass --tnstools PATH or set TNS_TOOLS"
        )
    return require_file(configured, "tnstools.py")


def require_directory(path: Path, description: str) -> Path:
    path = path.expanduser().resolve()
    if not path.is_dir():
        raise BuildError(f"{description} not found or is not a directory: {path}")
    return path


def render_problem_xml(template: bytes, source: bytes) -> bytes:
    try:
        template_text = template.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise BuildError(f"XML template is not valid UTF-8: {TEMPLATE_PATH / 'Problem1.xml'}") from exc
    try:
        source_text = source.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise BuildError(f"Lua source is not valid UTF-8: {SOURCE_PATH}") from exc

    opening = "<sc:script"
    closing = "</sc:script>"
    if template_text.count(opening) != 1 or template_text.count(closing) != 1:
        raise BuildError("Problem1.xml must contain exactly one sc:script element")
    opening_start = template_text.index(opening)
    body_start = template_text.find(">", opening_start)
    body_end = template_text.index(closing, body_start + 1)
    if body_start == -1:
        raise BuildError("the sc:script opening tag in Problem1.xml is malformed")

    rendered = template_text[: body_start + 1] + escape(source_text) + template_text[body_end:]
    rendered_bytes = rendered.encode("utf-8")
    try:
        root = ElementTree.fromstring(rendered_bytes)
    except ElementTree.ParseError as exc:
        raise BuildError(f"generated Problem1.xml is not valid XML: {exc}") from exc
    scripts = root.findall(f".//{SCRIPT_TAG}")
    if len(scripts) != 1 or scripts[0].text != source_text:
        raise BuildError("generated XML does not preserve src/nMoon.lua byte-for-byte")
    return rendered_bytes


def publish_atomically(source: Path, output: Path) -> None:
    output = output.expanduser().resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    if output.exists() and not output.is_file():
        raise BuildError(f"output path is not a file: {output}")

    descriptor, staging_name = tempfile.mkstemp(
        prefix=f".{output.name}.", suffix=".tmp", dir=output.parent
    )
    staging = Path(staging_name)
    try:
        with os.fdopen(descriptor, "wb") as destination, source.open("rb") as built:
            shutil.copyfileobj(built, destination)
            destination.flush()
            os.fsync(destination.fileno())
        os.replace(staging, output)
    except BaseException:
        staging.unlink(missing_ok=True)
        raise

    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    print(f"Built {output} ({output.stat().st_size} bytes, SHA-256 {digest})")


def build(tnstools: Path, output: Path) -> int:
    source = require_file(SOURCE_PATH, "Lua source")
    template = require_directory(TEMPLATE_PATH, "XML template directory")
    problem = require_file(template / "Problem1.xml", "Problem1.xml template")

    with tempfile.TemporaryDirectory(prefix="nmoon-build-") as temporary_name:
        temporary = Path(temporary_name)
        xml_tree = temporary / "nMoon.xml"
        shutil.copytree(template, xml_tree)
        (xml_tree / "Problem1.xml").write_bytes(
            render_problem_xml(problem.read_bytes(), source.read_bytes())
        )
        temporary_tns = temporary / "nMoon.tns"
        completed = subprocess.run(
            [
                sys.executable,
                str(tnstools),
                "-xml",
                str(xml_tree),
                "-out",
                str(temporary_tns),
                "--verify",
            ],
            cwd=temporary,
            check=False,
        )
        if completed.returncode != 0:
            return completed.returncode
        if not temporary_tns.is_file():
            raise BuildError("tnstools.py succeeded but did not create the requested output")
        publish_atomically(temporary_tns, output)
    return 0


def main() -> int:
    args = parse_args()
    try:
        tnstools = resolve_tnstools(args.tnstools)
        return build(tnstools, args.output)
    except (BuildError, OSError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
