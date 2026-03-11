// Navbar search functionality
$(document).ready(function() {
    // Load navbar component
    const navbarHTML = `
<nav class="navbar navbar-default navbar-fixed-top" role="navigation" data-template="app:fix-links">
    <div class="navbar-header">
        <button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#navbar-collapse-1">
            <span class="sr-only">Toggle navigation</span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
        </button>
        <a class="navbar-brand banner-container" href="/index.html">
            <span class="syriaca-icon syriaca-mss banner-icon"><span class="path1"></span><span class="path2"></span><span class="path3"></span><span class="path4"></span></span>
            <span class="banner-text">Syriac Manuscripts in the British Library</span>
        </a>
    </div>
    <div class="navbar-collapse collapse pull-right" id="navbar-collapse-1">
        <ul class="nav navbar-nav">
            <li>
                <a href="/browse.html" class="nav-text">Browse</a>
            </li>
            <li data-template="app:shared-content" data-template-path="/templates/shared-links.html"></li>
            <li>
                <a href="/search.html" class="nav-text">Advanced Search</a>
            </li>
            <li>
                <div id="search-wrapper">
                    <form class="navbar-form navbar-right search-box" role="search" id="navSearchForm">
                        <div class="form-group">
                            <input type="text" class="form-control keyboard" placeholder="search" name="fullText" id="keywordNav" />
                            <span data-template="app:keyboard-select-menu" data-template-input-id="keywordNav"></span>
                            <button class="btn btn-default search-btn" id="searchbtn" type="button" title="Search">
                                <span class="glyphicon glyphicon-search"></span>
                            </button>
                        </div>
                    </form>
                </div>
            </li>
            <li data-template="app:shared-content" data-template-path="/templates/fontMenu.html"></li>
        </ul>
    </div>
</nav>`;
    
    $('#navbar-container').html(navbarHTML);
    
    $('#searchbtn').on('click', function(e) {
        e.preventDefault();
        const keyword = $('#keywordNav').val();
        if (keyword) {
            window.location.href = '/search.html?fullText=' + encodeURIComponent(keyword);
        }
    });
    
    $('#keywordNav').on('keypress', function(e) {
        if (e.which === 13) {
            e.preventDefault();
            const keyword = $(this).val();
            if (keyword) {
                window.location.href = '/search.html?fullText=' + encodeURIComponent(keyword);
            }
        }
    });
});
