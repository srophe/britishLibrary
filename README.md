# British Library Syriac Manuscripts
A modern web application for browsing and searching Syriac manuscripts in the British Library collection.

This application provides a client-side interface for exploring TEI-encoded manuscript data with advanced search capabilities, faceted browsing, and responsive design.

## Features
* **Browse Interface** - Faceted browsing by material, script/language, and classification
* **Advanced Search** - Multi-field search supporting keyword, author, title, Syriac text, place, person, decorations, and shelfmark
* **Multi-lingual Support** - Keyboard widgets for Syriac, Arabic, and Greek text entry
* **Responsive Design** - Mobile-friendly interface using Bootstrap 3
* **Static Site Generation** - XSLT-based HTML generation from TEI XML sources
* **JSON Data Export** - Automated conversion of TEI to JSON for client-side search
* **AWS Deployment** - GitHub Actions workflow for automated deployment to S3/CloudFront

## Architecture

### Data Flow
1. **TEI XML Sources** (`exampleData/xml/`) - Original manuscript descriptions in TEI format
2. **XSLT Transformation** (`siteGenerator/xsl/tei2html.xsl`) - Converts TEI to HTML pages
3. **Python Conversion** (`tei2json.py`) - Extracts metadata to JSON for search functionality
4. **Static HTML Output** (`exampleData/ms/`) - Individual manuscript pages
5. **JSON Index** (`manuscripts.json`) - Searchable metadata for all manuscripts

### Key Components
* **browse.html** - Faceted browsing interface with material/script/classification filters
* **search.html** - Advanced search form with multi-field queries
* **resources/js/search.js** - Client-side search logic and result display
* **resources/js/navbar-search.js** - Centralized navbar search functionality
* **tei2json.py** - TEI to JSON converter with field extraction and language mapping

## Requirements
* Python 3.7+
* Saxon HE (for XSLT transformations)
* Modern web browser
* AWS CLI (for deployment)

## Getting Started

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd britishLibrary
   ```

2. **Install Python dependencies**
   ```bash
   pip install lxml pytest
   ```

3. **Convert TEI to JSON**
   ```bash
   python tei2json.py --manuscripts
   ```

4. **Serve locally**
   ```bash
   # Using Python's built-in server
   python -m http.server 5500
   
   # Or use Live Server extension in VS Code
   # Open browse.html or search.html
   ```

5. **Access the application**
   - Browse: http://localhost:5500/browse.html
   - Search: http://localhost:5500/search.html

### Adding New Manuscripts

1. **Add TEI XML file** to data repo
   - Follow TEI manuscript description schema
   - Include required elements: titleStmt, msDesc, physDesc, history
   - Add TEI XML file** to `exampleData/xml/` for testing 
      if you have expected output files in `exampleData/xml/html/` and `exampleData/xml/json/`

2. **Generate HTML** using Saxon XSLT processor
   ```bash
   java -jar saxon.jar -s:exampleData/xml/manuscript.xml \
        -xsl:siteGenerator/xsl/tei2html.xsl \
        -o:exampleData/ms/manuscript.html
   ```

3. **Update JSON index**
   ```bash
   python tei2json.py --manuscripts
   ```

4. **Commit changes** to trigger automated deployment
   if data changes in data repo only, trigger deployment manually in GitHub Actions
   dataToAWS.yml

## Data Structure

### TEI XML Fields Extracted
* **titleStmt** - Main manuscript title
* **msItemTitle** - Individual item titles within manuscript
* **rubric** - Rubric text
* **syrTitle** - Syriac language titles
* **author** - Author names
* **persName** - Person names mentioned
* **placeName** - Place names
* **shelfmark** - Library shelfmark
* **material** - Physical material (parchment, paper, etc.)
* **script** - Script codes (syr-Syre, ar, grc, etc.)
* **scriptLanguage** - Human-readable script/language names
* **classification** - Manuscript classification
* **decorations** - Decoration descriptions
* **decorationsType** - Decoration types (border, illustration, etc.)
* **origDate** - Date of origin

### Script/Language Mapping
The application maps ISO 639-3 language codes to readable names:
* `syr` → Syriac
* `syr-Syre` → Syriac (Estrangela)
* `syr-Syrj` → Syriac (Western)
* `syr-Syrn` → Syriac (Eastern)
* `ar` → Arabic
* `grc` → Greek
* `he` → Hebrew
* `en` → English
* `la` → Latin

## Deployment

### GitHub Actions Workflow
The `.github/workflows/dataToAWS.yml` workflow automatically:
1. Converts TEI XML to JSON and HTML
2. Combines json files into one manuscripts.json file
3. Commits manuscripts.json to repository
4. Uploads HTML to S3 bucket in AWS for hosting
5. Triggers on push to main branch or manual dispatch

### Environment Configuration
Base URLs are automatically detected:
* **Localhost**: `http://127.0.0.1:5500/exampleData`
* **Dev/CloudFront**: `https://d2tcgfyrf82nxz.cloudfront.net`
* **Production**: `https://bl.syriac.uk`

## Testing

Run tests to verify TEI to JSON/HTML conversion:
```bash
pytest tests/test_tei2json_examples.py

# Test only JSON conversion
pytest tests/test_tei2json_examples.py -k "json"

# Test only HTML conversion (requires Saxon JAR)
export SAXON_JAR=/path/to/saxon.jar
pytest tests/test_tei2json_examples.py -k "html"
```

## Customization

### Modify Search Fields
Edit `search.html` and `resources/js/search.js` to add/remove search fields.

### Update Facets
Modify `buildFacets()` in `browse.html` to change facet categories.

### Styling
Customize CSS in:
* `resources/css/style.css` - Main styles
* `resources/css/syriaca.css` - Syriaca-specific styles
* Inline `<style>` blocks in browse.html and search.html

## License
This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 license (CC BY-NC 4.0).

Copyright © 2011 Beth Mardutho: The Syriac Institute.