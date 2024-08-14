xquery version "3.1";        
(:~  
 : Builds HTML search forms and HTMl search results Srophe Collections and sub-collections   
 :) 
module namespace search="http://srophe.org/srophe/search";

(:eXist templating module:)
import module namespace templates="http://exist-db.org/xquery/templates" ;

(: Import KWIC module:)
import module namespace kwic="http://exist-db.org/xquery/kwic";

(: Import Srophe application modules. :)
import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";
import module namespace data="http://srophe.org/srophe/data" at "../lib/data.xqm";
import module namespace global="http://srophe.org/srophe/global" at "../lib/global.xqm";
import module namespace facet="http://expath.org/ns/facet" at "../lib/facet.xqm";
import module namespace sf="http://srophe.org/srophe/facets" at "../lib/facets.xql";
import module namespace page="http://srophe.org/srophe/page" at "../lib/paging.xqm";
import module namespace slider = "http://srophe.org/srophe/slider" at "../lib/date-slider.xqm";
import module namespace tei2html="http://srophe.org/srophe/tei2html" at "../content-negotiation/tei2html.xqm";

(: Syriaca.org search modules :)
import module namespace bibls="http://srophe.org/srophe/bibls" at "bibl-search.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
(:declare namespace facet="http://expath.org/ns/facet";:)

(: Global Variables:)
declare variable $search:start {
    if(request:get-parameter('start', 1)[1] castable as xs:integer) then 
        xs:integer(request:get-parameter('start', 1)[1]) 
    else 1};
declare variable $search:perpage {
    if(request:get-parameter('perpage', 25)[1] castable as xs:integer) then 
        xs:integer(request:get-parameter('perpage', 25)[1]) 
    else 25
    };

(:~
 : Search results stored in map for use by other HTML display functions 
:)
declare %templates:wrap function search:search-data($node as node(), $model as map(*), $collection as xs:string?, $sort-element as xs:string?){
    let $queryExpr := ()                      
    let $hits := data:search($collection,(),())
    return
         map {
                "hits" :
                    if(exists(request:get-parameter-names())) then $hits 
                    else if(ends-with(request:get-url(), 'search.html')) then ()
                    else $hits,
                "query" : $queryExpr
        }   
};

(:~ 
 : Builds results output
:)
declare 
    %templates:default("start", 1)
function search:show-hits($node as node()*, $model as map(*), $collection as xs:string?, $kwic as xs:string?) {
    let $hits := $model("hits")
    let $facet-config := global:facet-definition-file($collection)
    return( 
        (:<div>{$hits}</div>:)
        if(not(empty($facet-config))) then 
            <div class="row" id="search-results" xmlns="http://www.w3.org/1999/xhtml">
                <div class="col-md-8 col-md-push-4">
                    <div class="indent" id="search-results" xmlns="http://www.w3.org/1999/xhtml">{
                            let $hits := $model("hits")
                            for $hit at $p in subsequence($hits, $search:start, $search:perpage)
                            let $id := replace($hit/descendant::tei:idno[1],'/tei','')
                            let $kwic := if($kwic = ('true','yes','true()','kwic')) then kwic:expand($hit) else () 
                            return 
                             <div class="row record" xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px dotted #eee; padding-top:.5em">
                                 <div class="col-md-1" style="margin-right:-1em; padding-top:.25em;">        
                                     <span class="badge" style="margin-right:1em;">{$search:start + $p - 1}</span>
                                    
                                 </div>
                                 <div class="col-md-11" style="margin-right:-1em; padding-top:.25em;">
                                     {tei2html:summary-view($hit, '', $id)}
                                     {
                                        if($kwic//exist:match) then 
                                           tei2html:output-kwic($kwic, $id)
                                        else ()
                                     }
                                 </div>
                             </div>   
                    }</div>
                </div>
                <div class="col-md-4 col-md-pull-8">{
                 (slider:browse-date-slider($hits, 'origDate'),
                 let $hits := $model("hits")
                 let $facet-config := global:facet-definition-file($collection)
                 return 
                     if(not(empty($facet-config))) then 
                        (: sf:display($model("hits"),$facet-config):)facet:output-html-facets($hits, $facet-config/descendant::facet:facet-definition)
                     else ()  
                )}</div>
        </div>
        else 
         <div class="indent" id="search-results" xmlns="http://www.w3.org/1999/xhtml">
         {
                 let $hits := $model("hits")
                 for $hit at $p in subsequence($hits, $search:start, $search:perpage)
                 let $id := replace($hit/descendant::tei:idno[1],'/tei','')
                 let $kwic := if($kwic = ('true','yes','true()','kwic')) then kwic:expand($hit) else () 
                 return 
                  <div class="row record" xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px dotted #eee; padding-top:.5em">
                      <div class="col-md-1" style="margin-right:-1em; padding-top:.25em;">        
                          <span class="badge" style="margin-right:1em;">{$search:start + $p - 1}</span>
                      </div>
                      <div class="col-md-11" style="margin-right:-1em; padding-top:.25em;">
                          {tei2html:summary-view($hit, '', $id)}
                          {
                             if($kwic//exist:match) then 
                                tei2html:output-kwic($kwic, $id)
                             else ()
                          }
                      </div>
                  </div>   
         }</div>)
};

(:~
 : Build advanced search form using either search-config.xml or the default form search:default-search-form()
 : @param $collection. Optional parameter to limit search by collection. 
 : @note Collections are defined in repo-config.xml
 : @note Additional Search forms can be developed to replace the default search form.
 : @depreciated: do a manual HTML build, add xquery keyboard options 
:)
declare function search:search-form($node as node(), $model as map(*), $collection as xs:string?){
if(exists(request:get-parameter-names())) then ()
else 
    let $search-config := 
        if($collection != '') then concat($config:app-root, '/', string(config:collection-vars($collection)/@app-root),'/','search-config.xml')
        else concat($config:app-root, '/','search-config.xml')
    return 
        if($collection ='bibl') then <div>{bibls:search-form()}</div>
        else if(doc-available($search-config)) then 
            search:build-form($search-config)             
        else search:default-search-form()
};

(:~
 : Builds a simple advanced search from the search-config.xml. 
 : search-config.xml provides a simple mechinisim for creating custom inputs and XPaths, 
 : For more complicated advanced search options, especially those that require multiple XPath combinations
 : we recommend you add your own customizations to search.xqm
 : @param $search-config a values to use for the default search form and for the XPath search filters.
 : @depreciated: do a manual HTML build, add xquery keyboard options 
:)
declare function search:build-form($search-config) {
    let $config := doc($search-config)
    return 
        <form method="get" class="form-horizontal indent" role="form">
            <h1 class="search-header">{if($config//label != '') then $config//label else 'Search'}</h1>
            {if($config//desc != '') then 
                <p class="indent info">{$config//desc}</p>
            else() 
            }
            <div class="well well-small search-box">
                <div class="row">
                    <div class="col-md-10">{
                        for $input in $config//input
                        let $name := string($input/@name)
                        let $id := concat('s',$name)
                        return 
                            <div class="form-group">
                                <label for="{$name}" class="col-sm-2 col-md-3  control-label">{string($input/@label)}: 
                                {if($input/@title != '') then 
                                    <span class="glyphicon glyphicon-question-sign text-info moreInfo" aria-hidden="true" data-toggle="tooltip" title="{string($input/@title)}"></span>
                                else ()}
                                </label>
                                <div class="col-sm-10 col-md-9 ">
                                    <div class="input-group">
                                        <input type="text" 
                                        id="{$id}" 
                                        name="{$name}" 
                                        data-toggle="tooltip" 
                                        data-placement="left" class="form-control keyboard"/>
                                        {($input/@title,$input/@placeholder)}
                                        {
                                            if($input/@keyboard='yes') then 
                                                <span class="input-group-btn">{global:keyboard-select-menu($id)}</span>
                                             else ()
                                         }
                                    </div> 
                                </div>
                            </div>}
                    </div>
                </div> 
            </div>
            <div class="pull-right">
                <button type="submit" class="btn btn-info">Search</button>&#160;
                <button type="reset" class="btn btn-warning">Clear</button>
            </div>
            <br class="clearfix"/><br/>
        </form> 
};

(:~
 : Simple default search form to us if not search-config.xml file is present. Can be customized. 
:)
declare function search:default-search-form() {
    <form method="get" class="form-horizontal indent" role="form">
        <h1 class="search-header">Search</h1>
        <div class="well well-small search-box">
            <div class="row">
                <div class="col-md-10">
                    <!-- Keyword -->
                    <div class="form-group">
                        <label for="q" class="col-sm-2 col-md-3  control-label">Keyword: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="keyword" name="keyword" class="form-control keyboard"/>
                                <div class="input-group-btn">
                                {global:keyboard-select-menu('keyword')}
                                </div>
                            </div> 
                        </div>
                    </div>
                    <!-- Title-->
                    <div class="form-group">
                        <label for="title" class="col-sm-2 col-md-3  control-label">Title: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="title" name="title" class="form-control keyboard"/>
                                <div class="input-group-btn">
                                {global:keyboard-select-menu('title')}
                                </div>
                            </div>   
                        </div>
                    </div>
                   <!-- Place Name-->
                    <div class="form-group">
                        <label for="placeName" class="col-sm-2 col-md-3  control-label">Place Name: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="placeName" name="placeName" class="form-control keyboard"/>
                                <div class="input-group-btn">
                                {global:keyboard-select-menu('placeName')}
                                </div>
                            </div>   
                        </div>
                    </div>
                <!-- end col  -->
                </div>
                <!-- end row  -->
            </div>    
            <div class="pull-right">
                <button type="submit" class="btn btn-info">Search</button>&#160;
                <button type="reset" class="btn">Clear</button>
            </div>
            <br class="clearfix"/><br/>
        </div>
    </form>
};

(: Bl Search form :)
declare function search:bl-search-form($node as node(), $model as map(*)) {
<div class="searchForm" xmlns="http://www.w3.org/1999/xhtml">
    <div class="searchHeading">
        <span class="h4">Advanced Search</span>
        <a class="btn btn-default search-btn pull-right" data-toggle="collapse" data-target="#advancedSearchBox" data-text-swap="Show search options">
            <span class="glyphicon glyphicon-cog"></span> Show Search Options
        </a>
        
    </div>
    
    <div id="advancedSearchBox">
        {if(exists(request:get-parameter-names()) and count($model("hits")) gt 0) then 
           attribute class{'searchHeading collapse'}  
        else attribute class{'searchHeading collapse in'} 
        }
        <form method="get" class="form-horizontal indent" role="form">
            <div class="row">
                <div class="col-md-10">
                    <!-- Keyword -->
                    <div class="form-group">
                        <label for="keyword" class="col-sm-2 col-md-3  control-label">Keyword in Any Language: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="keyword" name="keyword" class="form-control keyboard"/>
                                {if(request:get-parameter('keyword', '') != '') then
                                    attribute value {request:get-parameter('keyword', '')}
                                else()}
                                <div class="input-group-btn">
                                    {global:keyboard-select-menu('keyword')}
                                </div>
                            </div> 
                        </div>
                    </div>
                    <!-- Author-->
                    <div class="form-group">
                        <label for="title" class="col-sm-2 col-md-3  control-label">Author: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="author" name="author" class="form-control keyboard"/>
                                 {if(request:get-parameter('author', '') != '') then
                                    attribute value {request:get-parameter('author', '')}
                                else()}
                                <div class="input-group-btn">
                                   {global:keyboard-select-menu('author')}
                                </div>
                            </div>   
                        </div>
                    </div>
                    <!-- Title-->
                    <div class="form-group">
                        <label for="title" class="col-sm-2 col-md-3  control-label">Translated Title: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="title" name="title" class="form-control keyboard"/>
                                 {if(request:get-parameter('title', '') != '') then
                                    attribute value {request:get-parameter('title', '')}
                                else()}
                                <div class="input-group-btn">
                                    {global:keyboard-select-menu('title')}
                                </div>
                            </div>   
                        </div>
                    </div>
                    <!-- Syriac Title-->
                    <div class="form-group">
                        <label for="title" class="col-sm-2 col-md-3  control-label">Syriac Text: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="syrText" name="syrText" class="form-control keyboard"/>
                                 {if(request:get-parameter('syrText', '') != '') then
                                    attribute value {request:get-parameter('syrText', '')}
                                else()}
                                <div class="input-group-btn">
                                {global:keyboard-select-menu('syrTitle')}
                                </div>
                            </div>   
                            <br/>
                                <!-- origPlaceLimit -->
                                Search in: 
                                <input type="checkbox" id="syrRubricsLimit" name="syrRubricsLimit" value="true" checked="checked"/> Titles/Rubrics 
                                &#160;<input type="checkbox" id="syrFinalRubricsLimit" name="syrFinalRubricsLimit" value="true" checked="checked"/> Final Rubrics/Subscriptions
                                &#160;<input type="checkbox" id="syrIncipitsLimit" name="syrIncipitsLimit" value="true" checked="checked"/> Incipits
                                &#160;<input type="checkbox" id="syrExplicitsLimit" name="syrExplicitsLimit" value="true" checked="checked"/> Explicits/Desinits
                                &#160;<input type="checkbox" id="syrColophonsLimit" name="syrColophonsLimit" value="true" checked="checked"/> Colophons
                                &#160;<input type="checkbox" id="syrOtherLimit" name="syrOtherLimit" value="true" checked="checked"/> Other
                        </div>
                    </div>
                    <!-- Place-->
                    <div class="form-group">
                        <label for="place" class="col-sm-2 col-md-3  control-label">Place: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="place" name="place" class="form-control keyboard"/>
                                {if(request:get-parameter('place', '') != '') then
                                    attribute value {request:get-parameter('place', '')}
                                else()}
                                <div class="input-group-btn">
                                {global:keyboard-select-menu('place')}
                                </div>
                            </div>   
                            <br/>
                            <!-- origPlaceLimit -->
                            Limit search to place of origin:
                            <input type="checkbox" id="origPlaceLimit" name="origPlaceLimit" value="true"/>
                        </div>
                        
                    </div>
                    <!-- Person-->
                    <div class="form-group">
                        <label for="person" class="col-sm-2 col-md-3  control-label">Person: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="person" name="person" class="form-control keyboard"/>
                                {if(request:get-parameter('person', '') != '') then
                                    attribute value {request:get-parameter('person', '')}
                                else()}
                                <div class="input-group-btn">
                                {global:keyboard-select-menu('person')}
                                </div>
                            </div>   
                        </div>
                        <!-- origPlaceLimit -->
                    </div>
                    <div class="form-group">
                        <label for="decorations" class="col-sm-2 col-md-3  control-label">Decorations: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="decorations" name="decorations" class="form-control keyboard"/>
                                {if(request:get-parameter('decorations', '') != '') then
                                    attribute value {request:get-parameter('decorations', '')}
                                else()}
                                <div class="input-group-btn">
                                {global:keyboard-select-menu('decorations')}
                                </div>
                            </div>  
                            
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="shelfmark" class="col-sm-2 col-md-3  control-label">Shelfmark: </label>
                        <div class="col-sm-10 col-md-9 ">
                            <div class="input-group">
                                <input type="text" id="shelfmark" name="shelfmark" class="form-control keyboard"/>
                                {if(request:get-parameter('shelfmark', '') != '') then
                                    attribute value {request:get-parameter('shelfmark', '')}
                                else()}
                            </div>   
                        </div>
                    </div>
                    <!--
                        <hr/>
                        <div class="form-group">
                            <label for="place" class="col-sm-2 col-md-3  control-label">Search In: </label>
                            <div class="col-sm-9 col-md-8 ">
                                Manuscript Contents: <input type="checkbox" id="limitByMSContents" name="limitByMSContents" value="true" checked="checked"/>&#160;
                                Physical Descriptions: <input type="checkbox" id="limitByPhysDesc" name="limitByPhysDesc" value="true" checked="checked"/>&#160;
                                Additions, Marginalia, Etc.: <input type="checkbox" id="limitByAdditions" name="limitByAdditions" value="true" checked="checked"/>&#160;
                                Provenance: <input type="checkbox" id="limitByHistory" name="limitByHistory" value="true" checked="checked"/>&#160;
                            </div>
                        </div>
                        -->
                    <!-- end col  -->
                </div>
                <!-- end row  -->
            </div>    
            <div class="pull-right">
                <button type="submit" class="btn btn-info">Search</button> 
                <button type="reset" class="btn">Clear</button>
            </div>
            <br class="clearfix"/>
            <br/>
        </form> 
    </div> 
</div>
};