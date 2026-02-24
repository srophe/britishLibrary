# tests/test_tei2json.py
import json
import sys
from pathlib import Path
import tempfile
from lxml import etree
import pytest

# Ensure repo root (one level up from tests/) is on sys.path so we can import tei2json from repo root
repo_root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(repo_root))

import tei2json  # tei2json.py should be at repo root and expose process_file / extract_json

SAMPLE_TMPL = """<?xml version="1.0" encoding="utf-8"?>
<TEI xmlns="http://www.tei-c.org/ns/1.0" xml:lang="en" xml:id="manuscript_{id}">
  <teiHeader>
    <fileDesc>
      <titleStmt>
        <title level="a" xml:lang="en">Sample Title {id}</title>
        <title xml:lang="syr">ܫܠܡ {id}</title>
      </titleStmt>
      <publicationStmt>
        <idno type="URI">https://bl.syriac.uk/ms/{id}</idno>
      </publicationStmt>
    </fileDesc>
  </teiHeader>
  <text><body><p>body</p></body></text>
  <msDesc>
    <msIdentifier>
      <altIdentifier><idno type="BL-Shelfmark">Add. {id}</idno></altIdentifier>
    </msIdentifier>
    <msPart>
      <msContents>
        <msItem>
          <title xml:lang="en">Part title {id}</title>
          <finalRubric xml:lang="syr">ܪܘܒܪܝܩ {id}</finalRubric>
          <colophon>Colophon {id}</colophon>
          <persName>Person {id}</persName>
          <placeName>Place {id}</placeName>
        </msItem>
      </msContents>
    </msPart>
  </msDesc>
</TEI>
"""

def write_sample(dirpath: Path, idx: int) -> Path:
    p = dirpath / f"{idx}.xml"
    p.write_text(SAMPLE_TMPL.format(id=idx), encoding="utf8")
    return p

@pytest.fixture(scope="module")
def sample_dir(tmp_path_factory):
    d = tmp_path_factory.mktemp("tei_samples")
    for i in range(1, 6):
        write_sample(d, i)
    return d

def test_process_single_file(tmp_path):
    xml = tmp_path / "one.xml"
    xml.write_text(SAMPLE_TMPL.format(id="one"), encoding="utf8")
    tree = etree.parse(str(xml))
    out = tei2json.extract_json(tree)
    assert "title" in out
    assert out["title"][0].startswith("Sample Title")
    assert "syrTitle" in out
    assert out["idno"].endswith("/one")
    assert "displayTitleEnglish" in out
    assert "persName" in out and any("Person" in p for p in out["persName"])
    assert "placeName" in out and any("Place" in pl for pl in out["placeName"])
    assert "finalRubrics" in out and any("ܪܘܒܪܝܩ" in r for r in out["finalRubrics"])
    assert "colophons" in out and any("Colophon" in c for c in out["colophons"])

def test_process_directory_and_bulk(sample_dir, tmp_path):
    outdir = tmp_path / "json_output"
    outdir.mkdir()
    bulk_file = tmp_path / "bulk.json"
    results = {}
    for xml in sorted(sample_dir.glob("*.xml")):
        data = tei2json.process_file(xml)
        results[xml.stem] = data
        (outdir / (xml.stem + ".json")).write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf8")

    with open(bulk_file, "w", encoding="utf8") as fh:
        for k in sorted(results.keys()):
            meta = {"index": {"_index": "britishlibrary-index-1", "_id": f"ms-{k}"}}
            fh.write(json.dumps(meta, ensure_ascii=False) + "\n")
            fh.write(json.dumps(results[k], ensure_ascii=False) + "\n")

    written = list(outdir.glob("*.json"))
    assert len(written) == 5
    bf = bulk_file.read_text(encoding="utf8")
    assert bf.count("\n") >= 10
    assert '"_index": "britishlibrary-index-1"' in bf
    assert '"_id": "ms-1"' in bf

def test_handles_missing_optional_elements(tmp_path):
    minimal = """<?xml version="1.0"?>
<TEI xmlns="http://www.tei-c.org/ns/1.0">
  <teiHeader><fileDesc><titleStmt><title>Minimal</title></titleStmt></fileDesc></teiHeader>
</TEI>"""
    f = tmp_path / "min.xml"
    f.write_text(minimal, encoding="utf8")
    tree = etree.parse(str(f))
    out = tei2json.extract_json(tree)
    assert "title" in out or "displayTitleEnglish" in out
    assert "persName" not in out or isinstance(out.get("persName"), list)

def test_unicode_preserved(sample_dir):
    xml = sample_dir / "1.xml"
    tree = etree.parse(str(xml))
    out = tei2json.extract_json(tree)
    assert any("ܪܘܒܪܝܩ" in r for r in out.get("finalRubrics", []))
