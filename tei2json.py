#!/usr/bin/env python3
"""
tei2json.py

Usage:
  # single file -> prints JSON to stdout
  python tei2json.py input.xml

  # directory -> produce one JSON file per TEI named <basename>.json
  python tei2json.py --dir ./britishLibrary-data/data/tei --outdir json_output

  # directory -> produce OpenSearch bulk file
  python tei2json.py --dir ./britishLibrary-data/data/tei --bulk bulk_data.json --index britishlibrary-index-1 --idprefix ms
"""

from lxml import etree
import argparse
import json
import os
from pathlib import Path
from typing import List

NS = {"tei": "http://www.tei-c.org/ns/1.0"}

def text_list(root, xpath) -> List[str]:
    """Return trimmed text contents for nodes matched by xpath"""
    nodes = root.xpath(xpath, namespaces=NS)
    out = []
    for n in nodes:
        # If element node with mixed content, get all text recursively
        if isinstance(n, etree._Element):
            txt = ''.join(n.itertext()).strip()
        else:
            txt = (str(n) or "").strip()
        if txt:
            out.append(" ".join(txt.split()))
    return out

def html_fragment(node):
    """Serialize an element's inner content, preserving inline markup (like <span>)"""
    if node is None:
        return ""
    parts = []
    for child in node.iterchildren():
        parts.append(etree.tostring(child, encoding="unicode", method="html"))
    # include text node before first child if present
    if (node.text or "").strip():
        parts.insert(0, node.text.strip())
    return "".join(parts).strip()

def first_text(root, xpath):
    lst = text_list(root, xpath)
    return lst[0] if lst else None

def extract_json(tree):
    root = tree.getroot()

    # Different title types
    title_stmt = text_list(root, ".//tei:titleStmt/tei:title")
    ms_item_titles = text_list(root, ".//tei:msItem//tei:title")
    rubrics = text_list(root, ".//tei:rubric")
    syr_titles = text_list(root, ".//tei:title[@xml:lang='syr'] | .//tei:rubric[@xml:lang='syr'] | .//tei:finalRubric[@xml:lang='syr']")

    # id: try msIdentifier idno type=URI or publication idno or teiHeader/fileDesc/publicationStmt/idno
    idno = first_text(root, ".//tei:msIdentifier/tei:idno[@type='URI'] | .//tei:publicationStmt/tei:idno[@type='URI'] | .//tei:msIdentifier/tei:idno")

    # displayTitleEnglish: concatenation of English titles (sample appears to concat all titles)
    display_title_english = "".join([t for t in title_stmt if t])

    # summary: from msContents/summary or profileDesc/abstract
    summary = first_text(root, ".//tei:msContents/tei:summary | .//tei:profileDesc/tei:abstract")

    # persName: collect person names in tei:persName nodes (serialize inner markup if present)
    pers_nodes = root.xpath(".//tei:persName", namespaces=NS)
    pers_list = []
    for p in pers_nodes:
        inner = html_fragment(p)
        if not inner:
            inner = (p.text or "").strip()
        if inner:
            pers_list.append(inner)

    # placeName
    place_list = text_list(root, ".//tei:placeName")

    # shelfmark: altIdentifier idno type=BL-Shelfmark or altIdentifier/ idno content
    shelfmarks = text_list(root, ".//tei:altIdentifier/tei:idno[@type='BL-Shelfmark'] | .//tei:altIdentifier/tei:idno | .//tei:msIdentifier//tei:idno[@type='BL-Shelfmark']")

    # finalRubrics
    final_rubrics = []
    for el in root.xpath(".//tei:finalRubric", namespaces=NS):
        final_rubrics.append(html_fragment(el) or (el.text or "").strip())

    # colophons: collect text from <colophon> elements and serialized contents
    colophons = []
    for el in root.xpath(".//tei:colophon", namespaces=NS):
        v = html_fragment(el)
        if not v:
            v = (el.text or "").strip()
        if v:
            colophons.append(v)

    # otherLimit: sample used additions / other special fields: try capturing <additions> and their <item> text
    other_limit = []
    for item in root.xpath(".//tei:additions//tei:item | .//tei:additions//tei:note", namespaces=NS):
        t = html_fragment(item)
        if not t:
            t = (item.text or "").strip()
        if t:
            other_limit.append(t)

    # script: collate @script on handNote/handDesc if present
    scripts = text_list(root, ".//tei:handNote/@script | .//tei:handDesc//tei:handNote/@script")
    if not scripts:
        # fallback: text nodes indicating script
        scripts = text_list(root, ".//tei:handNote | .//tei:handDesc")
    script_val = " ".join(scripts) if scripts else None

    # material: from supportDesc/support/material or physDesc supportDesc
    material = first_text(root, ".//tei:objectDesc//tei:supportDesc//tei:material | .//tei:physDesc//tei:supportDesc//tei:material | .//tei:physDesc//tei:supportDesc//tei:support//tei:material")

    # classification: collect descs under listRelation or relation descs (e.g., "Old Testament")
    classification = text_list(root, ".//tei:listRelation//tei:relation/tei:desc | .//tei:listRelation//tei:desc | .//tei:listRelation//tei:relation/tei:desc")

    # date: separate fields for each date type
    orig_dates = text_list(root, ".//tei:origDate")
    date_not_before = text_list(root, ".//tei:origDate/@notBefore | .//tei:date/@notBefore")
    date_not_after = text_list(root, ".//tei:origDate/@notAfter | .//tei:date/@notAfter")
    date_when = text_list(root, ".//tei:date/@when")
    date_calendar = text_list(root, ".//tei:origDate/@calendar | .//tei:date/@calendar")

    # script & material shorthand: collapse to strings or lists as in your example
    out = {}

    if title_stmt: out["titleStmt"] = title_stmt
    if ms_item_titles: out["msItemTitle"] = ms_item_titles
    if rubrics: out["rubric"] = rubrics
    if syr_titles: out["syrTitle"] = syr_titles
    if idno: out["idno"] = idno
    out["displayTitleEnglish"] = display_title_english or ""
    if summary: out["summary"] = summary
    if pers_list: out["persName"] = pers_list
    if place_list: out["placeName"] = place_list
    if shelfmarks: out["shelfmark"] = shelfmarks
    if final_rubrics: out["finalRubrics"] = final_rubrics
    if colophons: out["colophons"] = colophons
    if other_limit: out["otherLimit"] = other_limit
    if script_val: out["script"] = script_val
    if material: out["material"] = material
    if classification: out["classification"] = classification
    if orig_dates: out["origDate"] = orig_dates
    if date_not_before: out["dateNotBefore"] = date_not_before
    if date_not_after: out["dateNotAfter"] = date_not_after
    if date_when: out["dateWhen"] = date_when
    if date_calendar: out["dateCalendar"] = date_calendar

    return out

def process_file(path: Path):
    parser = etree.XMLParser(recover=True, remove_blank_text=True)
    tree = etree.parse(str(path), parser=parser)
    data = extract_json(tree)
    return data

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("path", help="TEI XML file or directory")
    ap.add_argument("--outdir", "-o", help="directory to write per-file JSON outputs")
    ap.add_argument("--bulk", help="write an OpenSearch bulk file (newline-delimited index JSON + doc JSON)")
    ap.add_argument("--manuscripts", help="write a manuscripts.json array file for web UI")
    ap.add_argument("--index", default="britishlibrary-index-1", help="index name for bulk")
    ap.add_argument("--idprefix", default="ms", help="prefix for _id in bulk (e.g., ms)")
    args = ap.parse_args()

    p = Path(args.path)
    targets = []
    if p.is_dir():
        targets = sorted(p.glob("*.xml"))
    elif p.is_file():
        targets = [p]
    else:
        raise SystemExit("Path not found")

    os.makedirs(args.outdir or ".", exist_ok=True)

    bulk_writer = None
    if args.bulk:
        bulk_writer = open(args.bulk, "w", encoding="utf8")
    
    manuscripts_list = []

    for f in targets:
        try:
            j = process_file(f)
        except Exception as e:
            print(f"ERROR parsing {f}: {e}")
            continue

        fname = f.stem
        # if outdir requested, write each JSON
        if args.outdir:
            outp = Path(args.outdir) / (fname + ".json")
            with open(outp, "w", encoding="utf8") as fh:
                json.dump(j, fh, ensure_ascii=False, indent=2)
            print(f"Wrote {outp}")

        # if bulk requested, write two-line bulk entry
        if bulk_writer:
            meta = {"index": {"_index": args.index, "_id": f"{args.idprefix}-{fname}"}}
            bulk_writer.write(json.dumps(meta, ensure_ascii=False) + "\n")
            bulk_writer.write(json.dumps(j, ensure_ascii=False) + "\n")
        
        # collect for manuscripts array
        if args.manuscripts:
            j["id"] = f"{args.idprefix}-{fname}"
            # Deduplicate and clean fields
            for key, value in j.items():
                if isinstance(value, list):
                    seen = set()
                    deduped = []
                    for item in value:
                        if item and item not in seen:
                            seen.add(item)
                            deduped.append(item)
                    j[key] = deduped
            # Remove composite manuscript classification
            if 'classification' in j and j['classification']:
                if isinstance(j['classification'], list):
                    j['classification'] = [c for c in j['classification'] 
                                          if not (isinstance(c, str) and c.startswith('This unit is a part of a composite manuscript'))]
            manuscripts_list.append(j)

    if bulk_writer:
        bulk_writer.close()
        print(f"Wrote bulk file {args.bulk}")
    
    if args.manuscripts:
        with open(args.manuscripts, "w", encoding="utf8") as fh:
            json.dump(manuscripts_list, fh, ensure_ascii=False, indent=2)
        print(f"Wrote manuscripts file {args.manuscripts}")
    
    # If single file with no output flags, print to stdout
    if p.is_file() and not args.outdir and not args.bulk and not args.manuscripts and len(targets) == 1:
        j = process_file(p)
        print(json.dumps(j, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
