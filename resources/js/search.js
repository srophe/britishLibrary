let allData = [];

// Determine base URL based on environment
const getBaseUrl = () => {
    const hostname = window.location.hostname;
    if (hostname === 'localhost' || hostname === '127.0.0.1') {
        return 'http://127.0.0.1:5500/exampleData';
    } else if (hostname.includes('dev') || hostname.includes('d2tcgfyrf82nxz')) {
        return 'https://d2tcgfyrf82nxz.cloudfront.net';
    } else if (hostname.includes('bl.syriac.uk')) {
        return 'https://bl.syriac.uk';
    } else {
        return '';
    }
};
const BASE_URL = getBaseUrl();

async function loadData() {
    const response = await fetch('/manuscripts.json');
    allData = await response.json();
}

function normalize(str) {
    if (!str) return '';
    return str.toLowerCase().replace(/[^a-z0-9]/g, '');
}

function matchesField(item, field, query) {
    const value = item[field];
    if (!value) return false;
    const normQuery = normalize(query);
    if (Array.isArray(value)) {
        return value.some(v => normalize(v).includes(normQuery));
    }
    return normalize(value).includes(normQuery);
}

function searchData(params) {
    return allData.filter(item => {
        if (params.fullText && !Object.values(item).some(v => 
            (Array.isArray(v) ? v.join(' ') : String(v || '')).toLowerCase().includes(params.fullText.toLowerCase())
        )) return false;
        if (params.author && !matchesField(item, 'authors', params.author)) return false;
        if (params.title && !matchesField(item, 'displayTitleEnglish', params.title)) return false;
        if (params.syriacText && !matchesField(item, 'syrTitle', params.syriacText)) return false;
        if (params.placeName && !matchesField(item, 'placeName', params.placeName)) return false;
        if (params.persName && !matchesField(item, 'persName', params.persName)) return false;
        if (params.shelfmark && !matchesField(item, 'shelfmark', params.shelfmark)) return false;
        if (params.decorations && item.decorations !== params.decorations) return false;
        return true;
    });
}

function displayResults(results, page = 1, perPage = 20) {
    const start = (page - 1) * perPage;
    const end = start + perPage;
    const pageResults = results.slice(start, end);
    
    $('#search-info').html(`<p>Found ${results.length} results</p>`);
    
    const html = pageResults.map((item, index) => {
        const formatValue = (val, key) => {
            if (!Array.isArray(val)) return val;
            const periodFields = ['title', 'displayTitleEnglish'];
            return periodFields.includes(key) ? val.join('. ') : val.join(', ');
        };
        
        const titleFields = ['titleStmt', 'msItemTitle', 'rubric', 'syrTitle'];
        const allTitles = [];
        titleFields.forEach(field => {
            if (item[field]) {
                if (Array.isArray(item[field])) {
                    allTitles.push(...item[field]);
                } else {
                    allTitles.push(item[field]);
                }
            }
        });
        let contentSummary = allTitles.join(' ');
        contentSummary = contentSummary.replace(/<[^>]*>/g, '');
        const truncated = contentSummary.length > 500;
        const displayContent = truncated ? contentSummary.substring(0, 500) : contentSummary;
        
        const msUrl = item.id ? `${BASE_URL}/ms/${item.id.replace('ms-', '')}.html` : '#';
        
        return `
            <div class="result-item" style="padding:15px; border:1px solid #ddd; margin-bottom:10px; border-radius:5px;">
                ${item.displayTitleEnglish ? `<p>${formatValue(item.displayTitleEnglish, 'displayTitleEnglish')}</p>` : ''}
                ${contentSummary ? `<p><strong>Content:</strong> <span class="content-text" id="content-${index}">${displayContent}${truncated ? '...' : ''}</span>${truncated ? ` <a href="#" class="show-more" data-index="${index}" data-full="${contentSummary.replace(/"/g, '&quot;')}">Show more</a>` : ''}</p>` : ''}
                <p><strong>Shelfmark:</strong> ${formatValue(item.shelfmark, 'shelfmark') || 'N/A'}</p>
                <p>URL: <a href="${msUrl}" target="_blank">${msUrl}</a></p>
                <small class="text-muted">
                    ${item.material ? `Material: ${formatValue(item.material, 'material')} | ` : ''}
                    ${item.scriptLanguage ? `Script: ${item.scriptLanguage} | ` : ''}
                    ${item.classification ? `Classification: ${formatValue(item.classification, 'classification')}` : ''}
                </small>
            </div>
        `;
    }).join('');
    
    $('#search-results').html(html || '<p>No results found</p>');
    
    $('.show-more').on('click', function(e) {
        e.preventDefault();
        const index = $(this).data('index');
        const full = $(this).data('full');
        $(`#content-${index}`).text(full);
        $(this).remove();
    });
    
    const totalPages = Math.ceil(results.length / perPage);
    let paginationHtml = '';
    for (let i = 1; i <= totalPages; i++) {
        paginationHtml += `<li class="${i === page ? 'active' : ''}"><a href="#" data-page="${i}">${i}</a></li>`;
    }
    $('.searchPagination').html(paginationHtml);
    
    $('.searchPagination a').on('click', function(e) {
        e.preventDefault();
        const newPage = parseInt($(this).data('page'));
        displayResults(results, newPage, perPage);
    });
}

async function runSearch() {
    await loadData();
    
    const params = new URLSearchParams(window.location.search);
    const searchParams = {
        fullText: params.get('fullText'),
        author: params.get('author'),
        title: params.get('title'),
        syriacText: params.get('syriacText'),
        placeName: params.get('placeName'),
        persName: params.get('persName'),
        shelfmark: params.get('shelfmark'),
        decorations: params.get('decorations'),
        decorationsType: params.get('decorationsType')
    };
    
    const hasQuery = Object.values(searchParams).some(v => v);
    if (!hasQuery) {
        $('#search-info').html('<p>Enter search criteria above</p>');
        return;
    }
    
    const results = searchData(searchParams);
    displayResults(results);
}
