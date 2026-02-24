# tests/test_tei2json_examples.py
import json
import subprocess
import os
import sys
from pathlib import Path
import difflib
import pytest
from lxml import html as lxml_html

# ensure repo root on sys.path so we can import tei2json if needed
repo_root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(repo_root))

import tei2json

EXAMPLES_DIR = Path("exampleData/xml")
EXPECTED_JSON_DIR = Path("exampleData/json")
EXPECTED_HTML_DIR = Path("exampleData/ms")
SAXON_JAR = os.environ.get("SAXON_JAR") or "saxon.jar"

def normalize_json(obj):
    return json.dumps(obj, ensure_ascii=False, sort_keys=True, separators=(",", ":"))

def normalize_html_string(s: str) -> str:
    try:
        doc = lxml_html.fromstring(s)
        return lxml_html.tostring(doc, encoding="unicode", method="html").strip()
    except Exception:
        return " ".join(s.split())

def run_saxon_transform(input_xml: Path, xsl_path: Path, out_path: Path):
    jar = Path(SAXON_JAR)
    if not jar.exists():
        raise FileNotFoundError(f"Saxon JAR not found at {jar}")
    cmd = ["java", "-jar", str(jar), "-s:" + str(input_xml), "-xsl:" + str(xsl_path), "-o:" + str(out_path)]
    subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

def all_example_xmls():
    if not EXAMPLES_DIR.exists():
        return []
    return sorted(EXAMPLES_DIR.rglob("*.xml"))

@pytest.mark.parametrize("xml_path", all_example_xmls())
def test_example_json_matches_fixture(xml_path, tmp_path):
    data = tei2json.process_file(xml_path)
    produced = normalize_json(data)
    expected_file = EXPECTED_JSON_DIR / (xml_path.stem + ".json")
    if not expected_file.exists():
        pytest.skip(f"Expected JSON fixture not found for {xml_path.stem}: {expected_file}")
    expected_obj = json.loads(expected_file.read_text(encoding="utf8"))
    expected = normalize_json(expected_obj)
    if produced != expected:
        pretty_prod = json.dumps(json.loads(produced), ensure_ascii=False, indent=2, sort_keys=True)
        pretty_exp = json.dumps(json.loads(expected), ensure_ascii=False, indent=2, sort_keys=True)
        diff = "\n".join(difflib.unified_diff(pretty_exp.splitlines(), pretty_prod.splitlines(),
                                              fromfile="expected", tofile="produced", lineterm=""))
        pytest.fail(f"JSON mismatch for {xml_path}:\n{diff}")

@pytest.mark.parametrize("xml_path", all_example_xmls())
def test_example_html_matches_fixture(xml_path, tmp_path):
    expected_html_file = EXPECTED_HTML_DIR / (xml_path.stem + ".html")
    if not expected_html_file.exists():
        pytest.skip(f"Expected HTML fixture not found for {xml_path.stem}: {expected_html_file}")
    xsl_path = Path("siteGenerator/xsl/tei2html.xsl")
    if not xsl_path.exists():
        pytest.skip(f"XSLT stylesheet not found at {xsl_path}; cannot produce HTML for comparison.")
    jar = Path(SAXON_JAR)
    if not jar.exists():
        pytest.skip(f"Saxon JAR not found at {jar}; set SAXON_JAR env or put saxon.jar at repo root to run HTML tests.")
    out_html = tmp_path / (xml_path.stem + ".html")
    try:
        run_saxon_transform(xml_path, xsl_path, out_html)
    except subprocess.CalledProcessError as e:
        stderr = e.stderr.decode() if hasattr(e, "stderr") else str(e)
        pytest.fail(f"Saxon transform failed for {xml_path} with error:\n{stderr}")
    produced_raw = out_html.read_text(encoding="utf8")
    expected_raw = expected_html_file.read_text(encoding="utf8")
    produced_norm = normalize_html_string(produced_raw)
    expected_norm = normalize_html_string(expected_raw)
    if produced_norm != expected_norm:
        diff = "\n".join(difflib.unified_diff(expected_norm.splitlines(), produced_norm.splitlines(),
                                              fromfile="expected_html", tofile="produced_html", lineterm=""))
        pytest.fail(f"HTML mismatch for {xml_path}:\n{diff}")
