#!/usr/bin/env python3
"""
tei2json.py

Usage:
  # single file -> prints JSON to stdout
  python tei2json.py input.xml
  or if data directory is in same folder:
  python britishLibrary/tei2json.py britishLibrary-data/data/tei/10.xml

  # directory -> produce one JSON file per TEI named <basename>.json
  python britishLibrary/tei2json.py britishLibrary-data/data/tei/10.xml --outdir json_output

  # directory -> produce OpenSearch bulk file
  python britishLibrary/tei2json.py britishLibrary-data/data/tei/10.xml --outdir json_output --bulk bulk_data.json 

"""

from lxml import etree
import argparse
import json
import os
from pathlib import Path
from typing import List

NS = {"tei": "http://www.tei-c.org/ns/1.0"}

# ISO 639-3 language code mapping for scripts
SCRIPT_LANG_MAP = {
    "syr": "Syriac",
    "syr-Syre": "Syriac (Estrangela)",
    "syr-Syrj": "Syriac (Western)",
    "syr-Syrn": "Syriac (Eastern)",
    "ar": "Arabic",
    "grc": "Greek",
    "he": "Hebrew",
    "en": "English",
    "la": "Latin",
    "mul": "Multiple languages",
    "cop": "Coptic",
    "fr": "French",
    "hy": "Armenian",
    "zh-hant": "Chinese (Traditional)",
    "hyr": "Armenian",
    "qhy-x-cpas":"Classical Syriac (ܟܬܒܢܝܐ)",
    "xcl": "Lycian",
    "und": "Undetermined",
    "syr-x-syrm": "Syriac (Melkite script)",
    "ar-syr": "Arabic language written in Syriac script"
}
MATERIALS_MAP = {
    "perg": "Parchment",
    "chart": "Paper",
    "mixed": "Mixed",
    "unknown": "Unknown",
    "Vellum": "Parchment"
}

def map_script_to_language(script_codes):
    """Convert script codes to language names"""
    if not script_codes:
        return None
    codes = script_codes.split()
    langs = []
    for code in codes:
        lang = SCRIPT_LANG_MAP.get(code.strip(), code.strip())
        if lang not in langs:
            langs.append(lang)
    return ", ".join(langs) if langs else None

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

def extract_json(tree, part_node=None):
    """Extract JSON from a TEI tree or a specific msPart node.
    
    Args:
        tree: The full TEI document tree
        part_node: Optional msPart element to extract from (if None, extracts from root)
    """
    root = tree.getroot() if part_node is None else part_node
    
    # For msPart, we need to look at both the part and the parent document for some fields
    doc_root = tree.getroot()

    # Different title types
    title_stmt = text_list(root, ".//tei:titleStmt/tei:title")
    ms_item_titles = text_list(root, ".//tei:msItem//tei:title")
    rubrics = text_list(root, ".//tei:rubric")
    syr_titles = text_list(root, ".//tei:title[@xml:lang='syr'] | .//tei:rubric[@xml:lang='syr'] | .//tei:finalRubric[@xml:lang='syr']")

    # id: try msIdentifier idno type=URI or publication idno or teiHeader/fileDesc/publicationStmt/idno
    idno = first_text(root, ".//tei:msIdentifier/tei:idno[@type='URI'] | .//tei:publicationStmt/tei:idno[@type='URI'] | .//tei:msIdentifier/tei:idno")
    
    # For msPart, get the part number from @n attribute
    part_num = None
    if part_node is not None and part_node.get('n'):
        part_num = part_node.get('n')

    # displayTitleEnglish: concatenation of English titles (sample appears to concat all titles)
    display_title_english = " ".join([t for t in title_stmt if t])

    # summary: from msContents/summary or profileDesc/abstract
    summary = first_text(root, ".//tei:msContents/tei:summary | .//tei:profileDesc/tei:abstract")

    # persName: collect person names in tei:persName nodes (serialize inner markup if present)
    pers_nodes = root.xpath(".//tei:persName", namespaces=NS)
    pers_list = []
    for p in pers_nodes:
        # Get all text including nested elements like placeName
        txt = ''.join(p.itertext()).strip()
        if txt:
            # Normalize whitespace
            txt = ' '.join(txt.split())
            pers_list.append(txt)

    # placeName
    place_list = text_list(root, ".//tei:placeName")
    origin_place_list = text_list(root, ".//tei:origPlace")

    # shelfmark: altIdentifier idno type=BL-Shelfmark or altIdentifier/ idno content
    # For parts, inherit from document root if not found in part
    shelfmarks = text_list(root, ".//tei:altIdentifier/tei:idno[@type='BL-Shelfmark-display']")
    if not shelfmarks and part_node is not None:
        shelfmarks = text_list(doc_root, ".//tei:altIdentifier/tei:idno[@type='BL-Shelfmark-display'] ")

    # finalRubrics
    final_rubrics = []
    for el in root.xpath(".//tei:finalRubric", namespaces=NS):
        final_rubrics.append(html_fragment(el) or (el.text or "").strip())

    # colophons: collect text from additions/list/item with label "Colophon"
    colophons = []
    for el in root.xpath(".//tei:additions//tei:list//tei:item[tei:label/text() = 'Colophon']//tei:quote", namespaces=NS):
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
    script_lang = map_script_to_language(script_val) if script_val else None

    # material: first try @material attribute, then fall back to material element text
    material_attr = first_text(root, ".//tei:physDesc//tei:objectDesc//tei:supportDesc/@material")
    if material_attr:
        material = MATERIALS_MAP.get(material_attr, material_attr)
    else:
        material = first_text(root, ".//tei:physDesc//tei:objectDesc//tei:supportDesc//tei:material | .//tei:objectDesc//tei:supportDesc//tei:material | .//tei:physDesc//tei:supportDesc//tei:material | .//tei:physDesc//tei:supportDesc//tei:support//tei:material")
    
    # form: from physDesc/objectDesc/@form, capitalized
    form = first_text(root, ".//tei:physDesc//tei:objectDesc/@form")
    if form:
        form = form.capitalize()

    # extent: from physDesc/objectDesc/supportDesc/extent/measure (text or @quantity)
    extent = first_text(root, ".//tei:physDesc//tei:objectDesc//tei:supportDesc//tei:extent//tei:measure")
    # Wright entry number: from msIdentifier/altIdentifier/idno[@type='Wright-BL-Roman']
    wright_num = first_text(root, ".//tei:msIdentifier//tei:altIdentifier//tei:idno[@type='Wright-BL-Roman']")
    if wright_num:
        wright_num = f"[Wright {wright_num}]"
    # contents note: from head/note[@type='contents-note']
    contents_note = first_text(root, ".//tei:head/tei:note[@type='contents-note']")

    # classification: collect descs under listRelation or relation descs (e.g., "Old Testament")
    # classification = text_list(root, ".//tei:listRelation//tei:relation/tei:desc | .//tei:listRelation//tei:desc | .//tei:listRelation//tei:relation/tei:desc")

    # classification: from head/listRelation[@type='Wright-BL-Taxonomy']/relation/desc
    classification = text_list(root, ".//tei:head/tei:listRelation[@type='Wright-BL-Taxonomy']/tei:relation/tei:desc")
    # Exclude classifications about composite manuscripts
    if classification:
        classification = [c for c in classification 
                         if not c.lower().startswith("this unit is a part of a composite manuscript") 
                         and not c.lower().startswith("this composite")
                         and not c.lower().startswith("this manuscript")]

    # date: separate fields for each date type
    orig_dates = first_text(root, ".//tei:origDate")
    date_not_before = text_list(root, ".//tei:origDate/@notBefore | .//tei:date/@notBefore")
    date_not_after = text_list(root, ".//tei:origDate/@notAfter | .//tei:date/@notAfter")
    date_when = text_list(root, ".//tei:date/@when")
    date_calendar = text_list(root, ".//tei:origDate/@calendar | .//tei:date/@calendar")

    # decorations: from decoNote elements
    decorations = text_list(root, ".//tei:decoNote")
    decoration_types = text_list(root, ".//tei:decoNote/@type")

    # author: from msItem/author/persName
    authors = text_list(root, ".//tei:msItem//tei:author//tei:persName")
    # msItem/author/@ref
    authorsUri = text_list(root, ".//tei:msItem//tei:author/@ref")
    
    # incipits: from msItem/incipit
    incipits = text_list(root, ".//tei:msItem//tei:incipit")
    # explicits: from msItem/explicit
    explicits = text_list(root, ".//tei:msItem//tei:explicit")

    # script & material shorthand: collapse to strings or lists as in your example
    out = {}

    if title_stmt: out["titleStmt"] = title_stmt
    if ms_item_titles: out["msItemTitle"] = ms_item_titles
    if rubrics: out["rubric"] = rubrics
    if syr_titles: out["syrTitle"] = syr_titles
    if idno: out["idno"] = idno
    if part_num: out["partNum"] = part_num
    out["displayTitleEnglish"] = display_title_english or ""
    if summary: out["summary"] = summary
    if pers_list: out["persName"] = pers_list
    if place_list: out["placeName"] = place_list
    if origin_place_list: out["origPlace"] = origin_place_list
    if shelfmarks: out["shelfmark"] = shelfmarks
    if final_rubrics: out["finalRubrics"] = final_rubrics
    if colophons: out["colophons"] = colophons
    if other_limit: out["otherLimit"] = other_limit
    if script_val: out["script"] = script_val
    if script_lang: out["scriptLanguage"] = script_lang
    if material: out["material"] = material
    if classification: out["classification"] = classification
    if orig_dates: out["origDate"] = orig_dates
    if date_not_before: out["dateNotBefore"] = date_not_before
    if date_not_after: out["dateNotAfter"] = date_not_after
    if date_when: out["dateWhen"] = date_when
    if date_calendar: out["dateCalendar"] = date_calendar
    if decorations: out["decorations"] = decorations
    if decoration_types: out["decorationsType"] = decoration_types
    if authors: out["author"] = authors
    if authorsUri: out["authorUri"] = authorsUri
    if incipits: out["incipit"] = incipits
    if explicits: out["explicit"] = explicits
    if form: out["form"] = form
    if extent: out["extent"] = extent
    if wright_num: out["wrightNum"] = wright_num
    if contents_note: out["contentsNote"] = contents_note
    
    # Deduplicate all list values
    for key, value in out.items():
        if isinstance(value, list):
            seen = set()
            deduped = []
            for item in value:
                # Normalize whitespace: replace newlines and multiple spaces with single space
                if item:
                    normalized = ' '.join(str(item).split())
                    if normalized and normalized not in seen:
                        seen.add(normalized)
                        deduped.append(normalized)
            out[key] = deduped
        elif isinstance(value, str):
            # Normalize string values too
            out[key] = ' '.join(value.split())
    
    return out

def process_file(path: Path):
    """Process a TEI file and return a list of JSON records (one per msPart, or one for the whole doc)."""
    parser = etree.XMLParser(recover=True, remove_blank_text=True)
    tree = etree.parse(str(path), parser=parser)
    root = tree.getroot()
    
    # Check if document has msPart elements
    ms_parts = root.xpath(".//tei:msPart", namespaces=NS)
    
    results = []
    
    if ms_parts:
        # Process each msPart as a separate record
        for part in ms_parts:
            data = extract_json(tree, part_node=part)
            results.append(data)
    else:
        # No parts, process the whole document
        data = extract_json(tree)
        results.append(data)
    
    return results

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
            records = process_file(f)
        except Exception as e:
            print(f"ERROR parsing {f}: {e}")
            continue

        fname = f.stem
        
        # Process each record (could be multiple if file has msParts)
        for idx, j in enumerate(records):
            # Generate unique ID for parts
            if len(records) > 1:
                record_id = f"{fname}-part{idx+1}"
            else:
                record_id = fname
            
            # if outdir requested, write each JSON
            if args.outdir:
                outp = Path(args.outdir) / (record_id + ".json")
                with open(outp, "w", encoding="utf8") as fh:
                    json.dump(j, fh, ensure_ascii=False, indent=2)
                print(f"Wrote {outp}")

            # if bulk requested, write two-line bulk entry
            if bulk_writer:
                meta = {"index": {"_index": args.index, "_id": f"{args.idprefix}-{record_id}"}}
                bulk_writer.write(json.dumps(meta, ensure_ascii=False) + "\n")
                bulk_writer.write(json.dumps(j, ensure_ascii=False) + "\n")
            
            # collect for manuscripts array
            if args.manuscripts:
                j["id"] = f"{args.idprefix}-{record_id}"
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
        records = process_file(p)
        for j in records:
            print(json.dumps(j, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
