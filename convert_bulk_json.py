#!/usr/bin/env python3
import json
import sys

def convert_bulk_to_array(input_file, output_file):
    """Convert OpenSearch bulk format to simple JSON array"""
    documents = []
    
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Process pairs of lines (index metadata + document)
    for i in range(0, len(lines), 2):
        if i + 1 < len(lines):
            try:
                # Parse the index line to get the ID
                index_line = json.loads(lines[i].strip())
                doc_id = index_line.get('index', {}).get('_id', f'doc-{i//2}')
                
                # Parse the document
                doc = json.loads(lines[i + 1].strip())
                doc['id'] = doc_id
                
                # Deduplicate and clean all fields
                for key, value in doc.items():
                    if isinstance(value, list):
                        # Remove duplicates while preserving order
                        seen = set()
                        deduped = []
                        for item in value:
                            if item and item not in seen:
                                seen.add(item)
                                deduped.append(item)
                        doc[key] = deduped
                    elif isinstance(value, str):
                        # Add space after commas if missing
                        doc[key] = value.replace(',', ', ').replace(',  ', ', ')
                
                # Remove classification values starting with "This unit is a part of a composite manuscript"
                if 'classification' in doc and doc['classification']:
                    if isinstance(doc['classification'], str):
                        if doc['classification'].startswith('This unit is a part of a composite manuscript'):
                            doc['classification'] = ''
                    elif isinstance(doc['classification'], list):
                        doc['classification'] = [c for c in doc['classification'] 
                                                if not (isinstance(c, str) and c.startswith('This unit is a part of a composite manuscript'))]
                
                documents.append(doc)
            except json.JSONDecodeError:
                print(f"Skipping invalid JSON at line {i}", file=sys.stderr)
                continue
    
    # Write as JSON array
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(documents, f, ensure_ascii=False, indent=2)
    
    print(f"Converted {len(documents)} documents to {output_file}")

if __name__ == '__main__':
    input_file = 'exampleData/json/bulk_data.json'
    output_file = 'manuscripts.json'
    convert_bulk_to_array(input_file, output_file)
