xquery version "3.0";
(:~  
 : Basic data interactions, returns raw data for use in other modules  
 : Used by ../app.xql and content-negotiation/content-negotiation.xql  
:)
module namespace data="http://srophe.org/srophe/data";

import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";
import module namespace global="http://srophe.org/srophe/global" at "global.xqm";
import module namespace facet="http://expath.org/ns/facet" at "facet.xqm";
import module namespace sf="http://srophe.org/srophe/facets" at "facets.xql";
import module namespace slider = "http://srophe.org/srophe/slider" at "date-slider.xqm";
import module namespace functx="http://www.functx.com";

declare namespace srophe="https://srophe.app";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $data:QUERY_OPTIONS := map {
    "leading-wildcard": "yes",
    "filter-rewrite": "yes"
};

declare variable $data:SORT_FIELDS := $config:get-config//*:sortFields/*:fields;


declare function data:searchField($fieldName, $term){
    $fieldName || ':(' || $term ||')'
};

declare function data:sanitizeURI($uri){
   replace($uri,'(/|:)','\\$1')
};

(:~
 : Return document by id/tei:idno or document path
 : Return by id if get-parameter $id
 : Return by document path if @param $doc
:)
declare function data:get-document() {
    (: Get document by id or tei:idno:)
    if(request:get-parameter('id', '') != '') then  
        if($config:document-id) then 
            let $idno := if(ends-with(request:get-parameter('id', ''),'/tei')) then request:get-parameter('id', '') else concat(request:get-parameter('id', ''),'/tei')
            return collection($config:data-root)//tei:idno[. = $idno or . = request:get-parameter('id', '')][@type='URI']/ancestor::tei:TEI
        else collection($config:data-root)/id(request:get-parameter('id', ''))/ancestor::tei:TEI
    (: Get document by document path. :)
    else if(request:get-parameter('doc', '') != '') then 
        if(starts-with(request:get-parameter('doc', ''),$config:data-root)) then 
            if(ends-with(request:get-parameter('doc', ''),'.xml')) then
                 doc(xmldb:encode-uri(request:get-parameter('doc', '')))
            else doc(xmldb:encode-uri(request:get-parameter('doc', '') || '.xml'))
        else if(ends-with(request:get-parameter('doc', ''),'.xml')) then
            doc(xmldb:encode-uri($config:data-root || "/" || request:get-parameter('doc', '')))
        else doc(xmldb:encode-uri($config:data-root || "/" || request:get-parameter('doc', '') || '.xml'))
    else ()
};

(:~
 : Return document by id/tei:idno or document path
 : @param $id return document by id or tei:idno
 : @param $doc return document path relative to data-root
:)
declare function data:get-document($id as xs:string?) {
    if(starts-with($id,'http')) then
        if($config:document-id) then 
            collection($config:data-root)//tei:idno[. = $id][@type='URI']/ancestor::tei:TEI
        else collection($config:data-root)/id($id)/ancestor::tei:TEI
    else if(starts-with($id,$config:data-root)) then 
            doc(xmldb:encode-uri($id || '.xml'))
    else doc(xmldb:encode-uri($config:data-root || "/" || $id || '.xml'))
};

(:~
  : @depreciated
  : Select correct tei element to base browse list on. 
  : Places use tei:place/tei:placeName
  : Persons use tei:person/tei:persName
  : Defaults to tei:title
:)
declare function data:element($element as xs:string?) as xs:string?{
    if(request:get-parameter('element', '') != '') then 
        request:get-parameter('element', '') 
    else if($element) then $element        
    else "tei:titleStmt/tei:title[@level='a']"  
};

(:~
 : @depreciated
 : Make XPath language filter. 
 : @param $element used to select browse element: persName/placeName/title
:)
declare function data:element-filter($element as xs:string?) as xs:string? {    
    if(request:get-parameter('lang', '') != '') then 
        if(request:get-parameter('alpha-filter', '') = 'ALL') then 
            concat("/descendant::",$element,"[@xml:lang = '", request:get-parameter('lang', ''),"']")
        else concat("/descendant::",$element,"[@xml:lang = '", request:get-parameter('lang', ''),"']")
    else
        if(request:get-parameter('alpha-filter', '') = 'ALL') then 
            concat("/descendant::",$element)
        else concat("/descendant::",$element)
};

(:~
 : Build browse/search path.
 : @param $collection name from repo-config.xml
 : @note parameters can be passed to function via the HTML templates or from the requesting url
 : @note there are two ways to define collections, physical collection and tei collection. TEI collection is defined in the seriesStmt
 : Enhancement: It would be nice to be able to pass in multiple collections to browse function
:)
declare function data:build-collection-path($collection as xs:string?) as xs:string?{  
    let $collection-path := 
            if(config:collection-vars($collection)/@data-root != '') then concat('/',config:collection-vars($collection)/@data-root)
            else if($config:get-config//repo:collections[@title = $collection]) then concat('/',$config:get-config//repo:collections[@title = $collection]/@data-root)                
            else ()
    let $get-series :=  
            if(config:collection-vars($collection)/@collection-URI != '') then string(config:collection-vars($collection)/@collection-URI)
            else ()                             
    let $series-path := 
            if($get-series != '') then concat("//tei:idno[. = '",$get-series,"'][ancestor::tei:seriesStmt]/ancestor::tei:TEI")
            else "//tei:TEI"
    return concat("collection('",$config:data-root,$collection-path,"')",$series-path)
};

(:~
 : Get all data for browse pages 
 : @param $collection collection to limit results set by
 : @param $element TEI element to base sort order on. 
:)
declare function data:get-records($collection as xs:string*, $element as xs:string?){
    let $sort := 
        if(request:get-parameter('sort', '') != '') then request:get-parameter('sort', '') 
        else if(request:get-parameter('sort-element', '') != '') then request:get-parameter('sort-element', '')
        else ()  
    let $facet-config := global:facet-definition-file($collection)    
    let $hits := util:eval(concat(data:build-collection-path($collection),facet:facet-filter($facet-config),slider:date-filter('origDate')))
    return 
        if(request:get-parameter('view', '') = 'map') then $hits  
        else if(request:get-parameter('view', '') = 'timeline') then $hits
        else if(request:get-parameter('alpha-filter', '') != '' 
            and request:get-parameter('alpha-filter', '') != 'All'
            and request:get-parameter('alpha-filter', '') != 'ALL'
            and request:get-parameter('alpha-filter', '') != 'all') then
                for $hit in $hits
                let $root := $hit/ancestor-or-self::tei:TEI
                let $s := 
                    if(contains($sort, 'author')) then ft:field($hit, "author")[1]
                    else if(request:get-parameter('sort', '') = 'title') then 
                        if(request:get-parameter('lang', '') = 'syr') then ft:field($hit, "titleSyriac")[1]
                        else if(request:get-parameter('lang', '') = 'ar') then ft:field($hit, "titleArabic")[1]
                        else ft:field($hit, "title")
                    else if(request:get-parameter('lang', '') = 'syr') then ft:field($hit, "titleSyriac")[1]
                    else if(request:get-parameter('lang', '') = 'ar') then ft:field($hit, "titleArabic")[1]
                    else if(request:get-parameter('sort', '') = $data:SORT_FIELDS) then
                        ft:field($hit, request:get-parameter('sort', ''))[1]
                    else if(request:get-parameter('sort', '') != '' and request:get-parameter('sort', '') != 'title' and not(contains($sort, 'author'))) then
                        if($collection = 'bibl') then
                            data:add-sort-options-bibl($hit, $sort)[1]
                        else data:add-sort-options($hit, $sort)[1] 
                    else ft:field($hit, "title")[1]  
                order by $s[1] collation 'http://www.w3.org/2013/collation/UCA'
                where matches($s[1],global:get-alpha-filter())
                return $root
        else 
                for $hit in $hits
                let $root := $hit/ancestor-or-self::tei:TEI
                let $s := 
                        if(contains($sort, 'author')) then ft:field($hit, "author")[1]
                        else if(request:get-parameter('sort', '') = 'title') then 
                            if(request:get-parameter('lang', '') = 'syr') then ft:field($hit, "titleSyriac")[1]
                            else if(request:get-parameter('lang', '') = 'ar') then ft:field($hit, "titleArabic")[1]
                            else ft:field($hit, "title")[1]
                        else if(request:get-parameter('sort', '') = $data:SORT_FIELDS) then
                            ft:field($hit, request:get-parameter('sort', ''))[1]
                        else if(request:get-parameter('sort', '') != '' and request:get-parameter('sort', '') != 'title' and not(contains($sort, 'author'))) then
                            if($collection = 'bibl') then
                                data:add-sort-options-bibl($hit, $sort)[1]
                            else data:add-sort-options($hit, $sort)[1]  
                        else ft:field($hit, "title")[1]                
                order by $s[1] collation 'http://www.w3.org/2013/collation/UCA', ft:field($hit, "author")[1]  collation 'http://www.w3.org/2013/collation/UCA'
                return $root 
};

(:~
 : Main search functions.
 : Build a search XPath based on search parameters. 
 : Add sort options. 
:)
declare function data:search($collection as xs:string*, $queryString as xs:string*, $sort-element as xs:string*) {                      
    let $params := 
        for $p in request:get-parameter-names()
        where request:get-parameter($p, '') != ''
        return $p  
    let $facet-config := global:facet-definition-file($collection)
    let $hits :=
            if($params != '') then
                if($queryString != '') then 
                    if(ends-with($queryString,'//tei:body') or ends-with($queryString,'//tei:TEI')) then () 
                    else util:eval(concat($queryString, facet:facet-filter($facet-config),slider:date-filter('origDate')))
                else if(data:create-query($collection) != '') then
                    util:eval(concat(data:build-collection-path($collection), data:create-query($collection),facet:facet-filter($facet-config),slider:date-filter('origDate')))
                else () 
            else ()      
    let $sort := if($sort-element != '') then 
                    $sort-element
                 else if(request:get-parameter('sort-element', '') != '') then
                    request:get-parameter('sort-element', '')
                 else ()
    return 
       (: <div>{concat(data:build-collection-path($collection), data:create-query($collection),slider:date-filter(()))}</div>:)
       if((request:get-parameter('sort-element', '') != '' and request:get-parameter('sort-element', '') != 'relevance') or ($sort-element != '' and $sort-element != 'relevance')) then 
            for $hit in $hits
            let $s := 
                    if(contains($sort, 'author')) then ft:field($hit, "author")[1]
                    else if(request:get-parameter('sort', '') = 'title') then 
                        if(request:get-parameter('lang', '') = 'syr') then ft:field($hit, "titleSyriac")[1]
                        else if(request:get-parameter('lang', '') = 'ar') then ft:field($hit, "titleArabic")[1]
                        else ft:field($hit, "title")[1]
                    else if(request:get-parameter('sort', '') = $data:SORT_FIELDS) then
                        ft:field($hit, request:get-parameter('sort', ''))[1]
                    else if(request:get-parameter('sort', '') != '' and request:get-parameter('sort', '') != 'title' and not(contains($sort, 'author'))) then
                        if($collection = 'bibl') then
                            data:add-sort-options-bibl($hit, $sort)[1]
                        else data:add-sort-options($hit, $sort)[1]                    
                    else ft:field($hit, "title")[1]                
            order by $s[1] collation 'http://www.w3.org/2013/collation/UCA'
            return $hit
        else 
            for $hit in $hits
            order by ft:score($hit) descending
            return $hit
};

(:~
 : API search functions. Called from content-negotiation.xql
 : Build a search XPath based on search parameters. 
 : Add sort options. 
:)
declare function data:apiSearch($collection as xs:string*, $element as xs:string?, $queryString as xs:string?, $sort-element as xs:string?) {                      
    let $elementSearch :=  
                if(exists($element) and $element != '') then  
                    for $e in $element
                    return concat("/descendant::tei:",$element,"[ft:query(.,'",data:clean-string($queryString),"',data:search-options())]")            
                else ()                        
    let $eval-string := concat(data:build-collection-path($collection), $elementSearch)
    let $hits := util:eval($eval-string)     
    let $sort := if($sort-element != '') then 
                    $sort-element
                 else if(request:get-parameter('sort', '') != '') then
                    request:get-parameter('sort', '')
                 else if(request:get-parameter('sort-element', '') != '') then
                    request:get-parameter('sort-element', '')
                 else ()
    return 
        if((request:get-parameter('sort-element', '') != '' and request:get-parameter('sort-element', '') != 'relevance') or ($sort-element != '' and $sort-element != 'relevance')) then 
            for $hit in $hits
            let $s := 
                    if(contains($sort, 'author')) then ft:field($hit, "author")[1]
                    else if(request:get-parameter('sort', '') = 'title') then 
                        if(request:get-parameter('lang', '') = 'syr') then ft:field($hit, "titleSyriac")[1]
                        else if(request:get-parameter('lang', '') = 'ar') then ft:field($hit, "titleArabic")[1]
                        else ft:field($hit, "title")
                    else if(request:get-parameter('sort', '') = $data:SORT_FIELDS) then
                        ft:field($hit, request:get-parameter('sort', ''))[1]                  
                    else $hit              
            order by $s collation 'http://www.w3.org/2013/collation/UCA'
            return $hit
        else 
            for $hit in $hits
            order by ft:score($hit) descending
            return $hit 
};

(:~   
 : Builds general search string.
:)
declare function data:create-query($collection as xs:string?) as xs:string?{
    let $search-config := 
        if($collection != '') then concat($config:app-root, '/', string(config:collection-vars($collection)/@app-root),'/','search-config.xml')
        else concat($config:app-root, '/','search-config.xml')
    return 
         if(doc-available($search-config)) then 
            concat(string-join(data:dynamic-paths($search-config),''),data:relation-search())
        else concat(
            data:keyword-search(),
            data:bl-author(),
            data:bl-title(),
            data:bl-place(),
            data:bl-person(),
            data:bl-syrText(),
            data:bl-decorations(),
            data:field-search('syrTitle',data:clean-string(request:get-parameter('syrTitle', ''))),
            data:element-search('idno',request:get-parameter('idno', '')),
            data:relation-search(),
            data:orginPlaceSearch(),
            data:bl-shelfmark(),
            data:ref()
            ) 
        (:
            concat(
            data:keyword-search(),
            data:element-search('title',request:get-parameter('title', '')),
            data:element-search('author',request:get-parameter('author', '')),
            data:element-search('placeName',request:get-parameter('placeName', '')),
            data:element-search('idno',request:get-parameter('idno', '')),
            data:relation-search(),
            data:orginPlaceSearch(),
            data:ref()
            ) 
            :)
};


declare function data:field-search($fieldName as xs:string?, $fieldValue as xs:string?){
    if($fieldValue != '') then
        concat('[ft:query(.,"',$fieldName,':',$fieldValue,'")]')
    else ()
};

(:~ 
 : Adds sort filter based on sort prameter
 : Currently supports sort on title, author, publication date and person dates
 : @param $sort-option
:)
declare function data:add-sort-options($hit, $sort-option as xs:string*){
    if($sort-option != '') then
        if($sort-option = 'title') then 
            global:build-sort-string($hit/descendant::tei:titleStmt/tei:title[1],request:get-parameter('lang', ''))
        else if($sort-option = 'author') then 
            if($hit/descendant::tei:titleStmt/tei:author[1]) then 
                if($hit/descendant::tei:titleStmt/tei:author[1]/descendant-or-self::tei:surname) then 
                    $hit/descendant::tei:titleStmt/tei:author[1]/descendant-or-self::tei:surname[1]
                else $hit//descendant::tei:author[1]
            else 
                if($hit/descendant::tei:titleStmt/tei:editor[1]/descendant-or-self::tei:surname) then 
                    $hit/descendant::tei:titleStmt/tei:editor[1]/descendant-or-self::tei:surname[1]
                else $hit/descendant::tei:titleStmt/tei:editor[1]
        else if($sort-option = 'pubDate') then 
            $hit/descendant::tei:teiHeader/descendant::tei:imprint[1]/descendant-or-self::tei:date[1]
        else if($sort-option = 'pubPlace') then 
            $hit/descendant::tei:teiHeader/descendant::tei:imprint[1]/descendant-or-self::tei:pubPlace[1]
        else if($sort-option = 'persDate') then
            if($hit/descendant::tei:birth) then $hit/descendant::tei:birth/@syriaca-computed-start
            else if($hit/descendant::tei:death) then $hit/descendant::tei:death/@syriaca-computed-start
            else ()
        else $hit
    else $hit
};

(:~ 
 : Adds sort filter based on sort prameter
 : Currently supports sort on title, author, publication date and person dates
 : @param $sort-option
:)
declare function data:add-sort-options-bibl($hit, $sort-option as xs:string*){
    if($sort-option != '') then
        if($sort-option = 'title') then 
            if($hit/descendant::tei:body/tei:biblStruct) then 
                global:build-sort-string($hit/descendant::tei:body/tei:biblStruct/descendant::tei:title[1],request:get-parameter('lang', ''))
            else global:build-sort-string($hit/descendant::tei:titleStmt/tei:title[1],request:get-parameter('lang', ''))
        else if($sort-option = 'author') then 
            if($hit/descendant::tei:body/tei:biblStruct) then 
                if($hit/descendant::tei:body/tei:biblStruct/descendant::tei:author) then 
                    if($hit/descendant::tei:body/tei:biblStruct/descendant::tei:author[1]/descendant-or-self::tei:surname) then 
                        $hit/descendant::tei:body/tei:biblStruct/descendant::tei:author[1]/descendant-or-self::tei:surname[1]
                    else $hit/descendant::tei:body/tei:biblStruct/descendant::tei:author[1]
                else 
                    if($hit/descendant::tei:body/tei:biblStruct/descendant::tei:editor[1]/descendant-or-self::tei:surname) then 
                        $hit/descendant::tei:body/tei:biblStruct/descendant::tei:editor[1]/descendant-or-self::tei:surname[1]
                    else $hit/descendant::tei:body/tei:biblStruct/descendant::tei:editor[1]
            else if($hit/descendant::tei:titleStmt/tei:author[1]) then 
                if($hit/descendant::tei:titleStmt/tei:author[1]/descendant-or-self::tei:surname) then 
                    $hit/descendant::tei:titleStmt/tei:author[1]/descendant-or-self::tei:surname[1]
                else $hit//descendant::tei:author[1]
            else 
                if($hit/descendant::tei:titleStmt/tei:editor[1]/descendant-or-self::tei:surname) then 
                    $hit/descendant::tei:titleStmt/tei:editor[1]/descendant-or-self::tei:surname[1]
                else $hit/descendant::tei:titleStmt/tei:editor[1]
        else if($sort-option = 'pubDate') then 
            if($hit/descendant::tei:body/tei:biblStruct/descendant::tei:imprint) then
                $hit/descendant::tei:body/tei:biblStruct/descendant::tei:imprint[1]/tei:date[1]
            else $hit/descendant::tei:teiHeader/descendant::tei:imprint[1]/descendant-or-self::tei:date[1]
        else if($sort-option = 'pubPlace') then 
            if($hit/descendant::tei:body/tei:biblStruct/descendant::tei:imprint/descendant-or-self::tei:pubPlace) then
                $hit/descendant::tei:body/tei:biblStruct/descendant::tei:imprint[1]/descendant-or-self::tei:pubPlace[1]
            else $hit/descendant::tei:teiHeader/descendant::tei:imprint[1]/descendant-or-self::tei:pubPlace[1]
        else if($sort-option = 'persDate') then
            if($hit/descendant::tei:birth) then $hit/descendant::tei:birth/@syriaca-computed-start
            else if($hit/descendant::tei:death) then $hit/descendant::tei:death/@syriaca-computed-start
            else ()
        else $hit
    else $hit
};


(:~ 
 : Adds sort filter based on sort prameter
 : Currently supports sort on title, author, publication date and person dates
 : @param $sort-option
:)
declare function data:sort-element($hit, $sort-element as xs:string*, $lang as xs:string?){
    if($sort-element != '') then
        if($sort-element = "tei:place/tei:placeName[@srophe:tags='#headword']") then 
            if($lang != '') then
                $hit/descendant::tei:place/tei:placeName[@srophe:tags='#headword'][@xml:lang=$lang][1]
            else $hit/descendant::tei:place/tei:placeName[@srophe:tags='#headword'][1]
        else if($sort-element = "tei:place/tei:placeName") then 
            if($lang != '') then
                $hit/descendant::tei:place/tei:placeName[@xml:lang=$lang][1]
            else $hit/descendant::tei:place/tei:placeName[1]            
        else if($sort-element = "tei:person/tei:persName[@srophe:tags='#headword']") then 
            if($lang != '') then
                $hit/descendant::tei:person/tei:pers[@srophe:tags='#headword'][@xml:lang=$lang][1]
            else $hit/descendant::tei:person/tei:pers[@srophe:tags='#headword'][1]
        else if($sort-element = "tei:person/tei:persName") then 
            if($lang != '') then
                $hit/descendant::tei:person/tei:persName[@xml:lang=$lang][1]
            else $hit/descendant::tei:person/tei:persName[1]
        else if($sort-element = "tei:titleStmt/tei:title[@level='a']") then 
            if($lang != '') then
                $hit/descendant::tei:titleStmt/tei:title[@level='a'][@xml:lang=$lang][1]
            else $hit/descendant::tei:titleStmt/tei:title[@level='a'][1]
        else if($sort-element = "tei:titleStmt/tei:title") then 
            if($lang != '') then
                $hit/descendant::tei:titleStmt/tei:title[@xml:lang=$lang][1]
            else $hit/descendant::tei:titleStmt/tei:title[1]
        else if($sort-element = "tei:title") then 
            if($lang != '') then
                $hit/descendant::tei:title[@xml:lang=$lang][1]
            else $hit/descendant::tei:title[1]
        else 
            if($lang != '') then
                util:eval(concat('$hit/descendant::',$sort-element,'[@xml:lang="',$lang,'"][1]'))
            else util:eval(concat('$hit/descendant::',$sort-element,'[1]'))            
    else $hit/descendant::tei:titleStmt/tei:title[1]
};

(:~
 : Search options passed to ft:query functions
 : Defaults to AND
:)
declare function data:search-options(){
    <options>
        <default-operator>and</default-operator>
        <phrase-slop>1</phrase-slop>
        <leading-wildcard>yes</leading-wildcard>
        <filter-rewrite>yes</filter-rewrite>
    </options>
};

(:~
 : Cleans search parameters to replace bad/undesirable data in strings
 : @param-string parameter string to be cleaned
:)
declare function data:clean-string($string){
let $query-string := $string
let $query-string := 
	   if (functx:number-of-matches($query-string, '"') mod 2) then 
	       replace($query-string, '"', ' ')
	   else $query-string   (:if there is an uneven number of quotation marks, delete all quotation marks.:)
let $query-string := 
	   if ((functx:number-of-matches($query-string, '\(') + functx:number-of-matches($query-string, '\)')) mod 2 eq 0) 
	   then $query-string
	   else translate($query-string, '()', ' ') (:if there is an uneven number of parentheses, delete all parentheses.:)
let $query-string := 
	   if ((functx:number-of-matches($query-string, '\[') + functx:number-of-matches($query-string, '\]')) mod 2 eq 0) 
	   then $query-string
	   else translate($query-string, '[]', ' ') (:if there is an uneven number of brackets, delete all brackets.:)
let $query-string := replace($string,"'","''")	   
return 
    if(matches($query-string,"(^\*$)|(^\?$)")) then 'Invalid Search String, please try again.' (: Must enter some text with wildcard searches:)
    else replace(replace($query-string,'<|>|@|&amp;',''), '(\.|\[|\]|\\|\||\-|\^|\$|\+|\{|\}|\(|\)|(/))','\\$1')

};

(:~
 : Build XPath filters from values in search-config.xml
 : Matches request paramters with @name in search-config to find the matching XPath. 
:)
declare function data:dynamic-paths($search-config as xs:string?){
    let $config := doc($search-config)
    let $params := request:get-parameter-names()
    return string-join(
        for $p in $params
        return 
            if(request:get-parameter($p, '') != '') then
                if($p = 'keyword') then
                    data:keyword-search()
                else if(string($config//input[@name = $p]/@element) = '.') then
                    concat("[ft:query(.//tei:body,'",data:clean-string(request:get-parameter($p, '')),"',data:search-options())]")
                else if(string($config//input[@name = $p]/@element) != '') then
                    concat("[ft:query(.//",string($config//input[@name = $p]/@element),",'",data:clean-string(request:get-parameter($p, '')),"',data:search-options())]")
                else ()    
            else (),'')
};

(:
 : General keyword anywhere search function 
:)
declare function data:keyword-search(){
let $keyword := (request:get-parameter('keyword', ''),request:get-parameter('q', ''))
let $cleanString := data:clean-string($keyword[1])
return         
    if($cleanString != '') then 
         concat("[descendant::tei:msDesc[ft:query(.,'",($cleanString),"',data:search-options())]]")
    else ()
};

(:~
 : Add a generic relationship search to any search module. 
:)
declare function data:relation-search(){
    if(request:get-parameter('relation-id', '') != '') then
        if(request:get-parameter('relation-type', '') != '') then
            concat("[descendant::tei:relation[@passive[matches(.,'",request:get-parameter('relation-id', ''),"(\W.*)?$')] or @mutual[matches(.,'",request:get-parameter('relation-id', ''),"(\W.*)?$')]][@ref = '",request:get-parameter('relation-type', ''),"' or @name = '",request:get-parameter('relation-type', ''),"']]")
        else concat("[descendant::tei:relation[@passive[matches(.,'",request:get-parameter('relation-id', ''),"(\W.*)?$')] or @mutual[matches(.,'",request:get-parameter('relation-id', ''),"(\W.*)?$')]]]")
    else ()
};

(:~
 : Add a generic relationship search to any search module. 
:)
declare function data:ref(){
    if(request:get-parameter('ref', '') != '') then
        concat("[.//@ref = '",request:get-parameter('ref', ''),"']")
    else ()
};

declare function data:orginPlaceSearch(){
    if(request:get-parameter('origPlace', '') != '') then
       concat("[descendant::tei:origPlace[@ref = '",request:get-parameter('origPlace', ''),"']]")
    else ()
};

(:~
 : Generic URI search
 : Searches record URIs and also references to record ids.
:)
declare function data:uri() as xs:string? {
    if(request:get-parameter('uri', '') != '') then 
        let $q := request:get-parameter('uri', '')
        return 
        concat("
        [ft:query(descendant::*,'&quot;",$q,"&quot;',data:search-options()) or 
            .//@passive[matches(.,'",$q,"(\W.*)?$')]
            or 
            .//@mutual[matches(.,'",$q,"(\W.*)?$')]
            or 
            .//@active[matches(.,'",$q,"(\W.*)?$')]
            or 
            .//@ref[matches(.,'",$q,"(\W.*)?$')]
            or 
            .//@target[matches(.,'",$q,"(\W.*)?$')]
        ]")
    else ''    
};

(:
 : General search function to pass in any TEI element. 
 : @param $element element name must have a lucene index defined on the element
 : @param $query query text to be searched. 
:)
declare function data:element-search($element, $query){
    if(exists($element) and $element != '') then 
        if(request:get-parameter($element, '') != '') then 
            for $e in $element
            return concat("[ft:query(descendant::tei:",$element,",'",data:clean-string($query),"',data:search-options())]")            
        else ()
    else ()
};

(:
 : Add your custom search paths here: 
 : Example of a complex search used by Syriaca.org
 : Search for bibl records with matching URI
 declare function search:bibl(){
    if($search:bibl != '') then  
        let $terms := data:clean-string($search:bibl)
        let $ids := 
            if(matches($search:bibl,'^http://syriaca.org/')) then
                normalize-space($search:bibl)
            else 
                string-join(distinct-values(
                for $r in collection($global:data-root || '/bibl')//tei:body[ft:query(.,$terms, data:search-options())]/ancestor::tei:TEI/descendant::tei:publicationStmt/tei:idno[starts-with(.,'http://syriaca.org')][1]
                return concat(substring-before($r,'/tei'),'(\s|$)')),'|')
        return concat("[descendant::tei:bibl/tei:ptr[@target[matches(.,'",$ids,"')]]]")
    else ()  
};
:)

(: Custom BL searches :)
(:
 : author search 
:)
declare function data:bl-author(){
let $author := request:get-parameter('author', '')
let $cleanString := data:clean-string($author[1])
return         
    if($cleanString != '') then
         if(starts-with($author,'http')) then
           concat("[descendant::tei:author/@ref='",($author),"' or descendant::tei:editor/@ref='",($author),"']") 
         else 
         concat("[ft:query(descendant::tei:author,'",($cleanString),"',data:search-options()) or ft:query(descendant::tei:editor,'",($cleanString),"',data:search-options())]")
    else ()
};
(:
 : place search 
:)
declare function data:bl-place(){
let $place := request:get-parameter('place', '')
let $cleanString := data:clean-string($place[1])
return         
    if($cleanString != '') then 
         if(request:get-parameter('origPlaceLimit', '')='true') then 
            concat("[ft:query(descendant::tei:origPlace,'",($cleanString),"',data:search-options())]")
         else concat("[ft:query(descendant::tei:placeName[not(parent::tei:persName)],'",($cleanString),"',data:search-options()) or ft:query(descendant::tei:origPlace,'",($cleanString),"',data:search-options())]")
    else ()
};
(:
 : person search
 : TEI:author, editor, and persName. 
:)
declare function data:bl-person(){
let $person := request:get-parameter('person', '')
let $cleanString := data:clean-string($person[1])
return         
    if($cleanString != '') then 
        if(starts-with($person,'http')) then
           concat("[descendant::tei:author/@ref='",($person),"' or descendant::tei:editor/@ref='",($person),"' or descendant::tei:persName/@ref='",($person),"']") 
        else 
         concat("[ft:query(descendant::tei:author,'",($cleanString),"',data:search-options()) or ft:query(descendant::tei:editor,'",($cleanString),"',data:search-options()) or ft:query(descendant::tei:persName,'",($cleanString),"',data:search-options()) ]")
    else ()
};

(:
 : General keyword anywhere search function 
:)
declare function data:bl-keyword-search(){
let $keyword := (request:get-parameter('keyword', ''),request:get-parameter('q', ''))
let $cleanString := data:clean-string($keyword[1])
return         
    if($cleanString != '') then 
         concat("[ft:query(.,'",($cleanString),"',data:search-options())]")
    else ()
};
(:
 : title search 
:)
declare function data:bl-title(){
let $title := request:get-parameter('title', '')
let $cleanString := data:clean-string($title[1])
return  
    if($cleanString != '') then
         if(starts-with($title,'http')) then
           concat("[descendant::tei:title/@ref='",($title),"']") 
         else 
            concat("[ft:query(descendant::tei:title,'",($cleanString),"',data:search-options())]")
    else ()
};
(:
 : title search 
:)
declare function data:bl-syriTitle(){
let $author := request:get-parameter('syrTitle', '')
let $cleanString := data:clean-string($author[1])
return         
    if($cleanString != '') then
         if(starts-with($author,'http')) then
           concat("[descendant::tei:author/@ref='",($author),"' or descendant::tei:editor/@ref='",($author),"']") 
         else 
         concat("[ft:query(descendant::tei:author,'",($cleanString),"',data:search-options()) or ft:query(descendant::tei:editor,'",($cleanString),"',data:search-options())]")
    else ()
};

(:
 : Syriac text search 
:)
declare function data:bl-syrText(){
let $query := request:get-parameter('syrText', '')
let $cleanString := data:clean-string($query[1])
let $limits := 
    string-join(
            (
            if(request:get-parameter('syrOtherLimit', '') = 'true') then 
                concat("[ft:query(descendant::tei:quote[@xml:lang='syr'],'",($cleanString),"',data:search-options()) or ft:query(descendant::tei:foreign[@xml:lang='syr'],'",($cleanString),"',data:search-options())]")
            else(), 
            if(request:get-parameter('syrColophonsLimit', '') = 'true') then 
                concat("[ft:query(descendant::tei:additions/descendant::tei:item[tei:label = 'Colophon'],'",($cleanString),"',data:search-options())]")
            else(), 
            if(request:get-parameter('syrExplicitsLimit', '') = 'true') then 
                concat("[ft:query(descendant::tei:explicit,'",($cleanString),"',data:search-options())]")
            else(), 
            if(request:get-parameter('syrIncipitsLimit', '') = 'true') then 
                concat("[ft:query(descendant::tei:incipit,'",($cleanString),"',data:search-options())]")
            else(), 
            if(request:get-parameter('syrFinalRubricsLimit', '') = 'true') then 
                concat("[ft:query(descendant::tei:finalRubric,'",($cleanString),"',data:search-options())]")
            else(), 
            if(request:get-parameter('syrRubricsLimit', '') = 'true') then                
               concat("[ft:query(descendant::tei:title[@xml:lang='syr'],'",($cleanString),"',data:search-options()) or ft:query(descendant::tei:rubric,'",($cleanString),"',data:search-options())]")
            else()
            ),' or ')
return         
    if($query != '' and $limits != '') then
         concat("[",$limits,"]")
    else ()
};

declare function data:bl-shelfmark(){
let $shelfmark := request:get-parameter('shelfmark', '')
let $cleanString := data:clean-string($shelfmark[1])
return         
    if($cleanString != '') then
        concat("[descendant::tei:idno[@type='BL-Shelfmark' or @type='BL-Shelfmark-simplified'][ft:query(.,'",($cleanString),"',data:search-options())]]")
    else ()
};
declare function data:bl-decorations(){
let $decorations := request:get-parameter('decorations', '')
let $cleanString := data:clean-string($decorations[1])
return         
    if($cleanString != '') then
        concat("[descendant::tei:decoNote[ft:query(.,'",($cleanString),"',data:search-options())]]")
    else ()
};
