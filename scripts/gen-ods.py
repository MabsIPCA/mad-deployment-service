#!/usr/bin/env python3
"""Generate dual-axis OWASP K8s Top 10 spreadsheet.
Reads thesis/kubernetes-vulns/data/vulnerabilities.yaml.
Outputs OWASP-K8s-Top10-Dual-Axis.ods at the repo root.
Uses only Python stdlib — no pip deps required.
"""
import os
import re
import zipfile

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.join(SCRIPT_DIR, "..")
DATA = os.path.join(REPO_ROOT, "thesis", "kubernetes-vulns", "data", "vulnerabilities.yaml")
OUT = os.path.join(REPO_ROOT, "OWASP-K8s-Top10-Dual-Axis.ods")


def parse_scanners(s):
    result = {}
    s = s.strip().lstrip("{").rstrip("}")
    for m in re.finditer(r'(\w+):\s*(?:"([^"]*?)"|([^,}]+?))\s*(?:,|$)', s):
        key = m.group(1)
        val = (m.group(2) if m.group(2) is not None else m.group(3)).strip()
        result[key] = val
    return result


def parse_vulns(path):
    entries = []
    cur = {}
    with open(path, encoding="utf-8") as f:
        for raw in f:
            line = raw.rstrip()
            if line.startswith("- id:"):
                if cur:
                    entries.append(cur)
                cur = {"id": line.split(":", 1)[1].strip()}
            elif line.startswith("  ") and ":" in line and not line.strip().startswith("#"):
                key, _, val = line.strip().partition(":")
                val = val.strip().strip('"')
                if key == "scanners":
                    cur["scanners"] = parse_scanners(val)
                else:
                    cur[key] = val
    if cur:
        entries.append(cur)
    return entries


MIME = b"application/vnd.oasis.opendocument.spreadsheet"

MANIFEST = """\
<?xml version="1.0" encoding="UTF-8"?>
<manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0"
    manifest:version="1.2">
  <manifest:file-entry manifest:full-path="/"
      manifest:media-type="application/vnd.oasis.opendocument.spreadsheet"/>
  <manifest:file-entry manifest:full-path="content.xml"
      manifest:media-type="text/xml"/>
  <manifest:file-entry manifest:full-path="styles.xml"
      manifest:media-type="text/xml"/>
  <manifest:file-entry manifest:full-path="meta.xml"
      manifest:media-type="text/xml"/>
</manifest:manifest>"""

STYLES = """\
<?xml version="1.0" encoding="UTF-8"?>
<office:document-styles
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
    xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
    office:version="1.2">
  <office:styles>
    <style:default-style style:family="table-cell">
      <style:text-properties fo:font-size="10pt" fo:font-family="Arial"/>
    </style:default-style>
  </office:styles>
</office:document-styles>"""

META = """\
<?xml version="1.0" encoding="UTF-8"?>
<office:document-meta
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    office:version="1.2">
</office:document-meta>"""

HEADERS = [
    "ID", "Title", "OWASP 2025", "OWASP 2022",
    "CWE", "CIS v1.12", "Scope", "Class", "Chart",
    "Values Flag", "KICS", "Trivy", "KubeLinter", "Kubescape",
    "Pre-Injection State",
]


def esc(s):
    return (str(s)
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace('"', "&quot;"))


def make_cell(val, bold=False):
    v = esc(val) if val else "---"
    if bold:
        return (
            '<table:table-cell office:value-type="string">'
            f'<text:p><text:span text:style-name="HeaderStyle">{v}</text:span></text:p>'
            "</table:table-cell>"
        )
    return (
        '<table:table-cell office:value-type="string">'
        f"<text:p>{v}</text:p>"
        "</table:table-cell>"
    )


def make_row(values, bold=False):
    cells = "".join(make_cell(v, bold) for v in values)
    return f"<table:table-row>{cells}</table:table-row>"


def make_content(entries):
    rows = [make_row(HEADERS, bold=True)]
    for e in entries:
        sc = e.get("scanners", {})
        rows.append(make_row([
            e.get("id", ""),
            e.get("title", ""),
            e.get("owasp2025", ""),
            e.get("owasp2022", "") or "---",
            "CWE-" + e.get("cwe", ""),
            e.get("cis", "") or "---",
            e.get("scope", ""),
            e.get("class", ""),
            e.get("chart", ""),
            e.get("valuesFlag", "") or "---",
            sc.get("kics", "") or "---",
            sc.get("trivy", "") or "---",
            sc.get("kubelinter", "") or "---",
            sc.get("kubescape", "") or "---",
            str(e.get("presentPreInjection", "")).lower(),
        ]))

    rows_xml = "\n        ".join(rows)
    return f"""\
<?xml version="1.0" encoding="UTF-8"?>
<office:document-content
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
    xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
    office:version="1.2">
  <office:automatic-styles>
    <style:style style:name="HeaderStyle" style:family="text">
      <style:text-properties fo:font-weight="bold"/>
    </style:style>
  </office:automatic-styles>
  <office:body>
    <office:spreadsheet>
      <table:table table:name="OWASP K8s Top10 Dual-Axis">
        {rows_xml}
      </table:table>
    </office:spreadsheet>
  </office:body>
</office:document-content>"""


if __name__ == "__main__":
    entries = parse_vulns(DATA)
    content = make_content(entries)
    with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("mimetype", MIME, compress_type=zipfile.ZIP_STORED)
        zf.writestr("META-INF/manifest.xml", MANIFEST)
        zf.writestr("content.xml", content)
        zf.writestr("styles.xml", STYLES)
        zf.writestr("meta.xml", META)
    print(f"Generated: {OUT} ({len(entries)} entries)")
