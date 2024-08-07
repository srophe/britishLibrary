xquery version "3.1";
(:~ 
 : @depreciated, use facets.xql for eXist v5+ to take advantage of built in Lucene facets and fields
 : Srophe facets v2.0 
 : Removes in memory nodes created by orginal 
 : 
 : Uses the following eXist-db specific functions:
 :      util:eval 
 :      request:get-parameter
 :      request:get-parameter-names()
 : 
 : @author Winona Salesky
 : @version 2.0 
 :
 : @see http://expath.org/spec/facet   
   @Note:  no longer matches spec. 
 : Spec builds in memory nodes and causes very poor performance.
 : See v1.0 for more spec compliant version 
 :)
 
module namespace facet = "http://expath.org/ns/facet";
import module namespace global="http://srophe.org/srophe/global" at "global.xqm";
import module namespace functx="http://www.functx.com";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~
 : XPath filter to be passed to main query
 : creates XPath based on facet:facet-definition//facet:sub-path.
 : @param $facet-def facet:facet-definition element
:)
declare function facet:facet-filter($facet-definitions as node()*)  as item()*{
       string-join(
        for $facetparam in request:get-parameter-names()[starts-with(., 'facet-')]
        let $facet-name := substring-after($facetparam, '-') 
        for $getFacets in request:get-parameter($facetparam, ())
        let $facet-def := $facet-definitions/descendant-or-self::facet:facet-definition[@name = $facet-name[1]]
        let $path := 
             if(matches($facet-def[1]/facet:sub-path/text(), '^/@')) then 
                concat('descendant::*/',substring($facet-def[1]/facet:group-by/facet:sub-path/text(),2))
             else $facet-def[1]/facet:group-by/facet:sub-path/text()
        let $facet-value := normalize-space($getFacets)
        where $facet-value != ''
        return 
                if($facet-value != '') then 
                    if($facet-def/facet:range) then
                        if($facet-def/facet:group-by[@function='facet:keywordType']) then
                           concat('[',$facet-def/facet:range/facet:bucket[@name = $facet-value]/@path,']')
                        else if($facet-def/facet:range/facet:bucket[@name = $facet-value]/@lt and $facet-def/facet:range/facet:bucket[@name = $facet-value]/@lt != '') then
                            concat('[',$path,'[string(.) >= "', facet:type($facet-def/facet:range/facet:bucket[@name = $facet-value]/@gt, $facet-def/facet:range/facet:bucket[@name = $facet-value]/@type),'" and string(.) <= "',facet:type($facet-def/facet:range/facet:bucket[@name = $facet-value]/@lt, $facet-def/facet:range/facet:bucket[@name = $facet-value]/@type),'"]]')                        
                        else if($facet-def/facet:range/facet:bucket[@name = $facet-value]/@eq and $facet-def/facet:range/facet:bucket[@name = $facet-value]/@eq != '') then
                            concat('[',$path,'[', $facet-def/facet:range/facet:bucket[@name = $facet-value]/@eq ,']]')
                        else concat('[',$path,'[string(.) >= "', facet:type($facet-def/facet:range/facet:bucket[@name = $facet-value]/@gt, $facet-def/facet:range/facet:bucket[@name = $facet-value]/@type),'" ]]')
                    else if($facet-def/facet:group-by[@function="facet:group-by-array"]) then 
                        concat('[',$path[1],'[matches(., "',$facet-value,'(\W|$)")]',']')                     
                    else concat('[',$path[1],'[normalize-space(.) = "',replace($facet-value,'"','""'),'"]',']')
                else()              
        ,'')
};

(:~
 : Adds type casting when type is specified facet:facet:group-by/@type
 : @param $value of xpath
 : @param $type value of type attribute
:)
declare function facet:type($value as item()*, $type as xs:string?) as item()*{
    if($type != '') then  
        if($type = 'xs:string') then xs:string($value)
        else if($type = 'xs:string') then xs:string($value)
        else if($type = 'xs:decimal') then xs:decimal($value)
        else if($type = 'xs:integer') then xs:integer($value)
        else if($type = 'xs:long') then xs:long($value)
        else if($type = 'xs:int') then xs:int($value)
        else if($type = 'xs:short') then xs:short($value)
        else if($type = 'xs:byte') then xs:byte($value)
        else if($type = 'xs:float') then xs:float($value)
        else if($type = 'xs:double') then xs:double($value)
        else if($type = 'xs:dateTime') then xs:dateTime($value)
        else if($type = 'xs:date') then xs:date($value)
        else if($type = 'xs:gYearMonth') then xs:gYearMonth($value)        
        else if($type = 'xs:gYear') then xs:gYear($value)
        else if($type = 'xs:gMonthDay') then xs:gMonthDay($value)
        else if($type = 'xs:gMonth') then xs:gMonth($value)        
        else if($type = 'xs:gDay') then xs:gDay($value)
        else if($type = 'xs:duration') then xs:duration($value)        
        else if($type = 'xs:anyURI') then xs:anyURI($value)
        else if($type = 'xs:Name') then xs:Name($value)
        else $value
    else $value
};

(: Print facet results to HTML page :)
declare function facet:output-html-facets($results as item()*, $facet-definitions as element(facet:facet-definition)*) as item()*{
<div class="facets">
    {   
    for $facet in $facet-definitions
    return 
        <div class="facetDefinition">
            {for $facets at $i in facet:facet($results, $facet)
             return $facets}
        </div>
    }
</div>
};

(:~
 : Pass facet definition to correct XQuery function;
 : Range, User defined function or default group-by function
 : Facet defined by facets:facet-definition/facet:group-by/facet:sub-path 
 : @param $results results to be faceted on. 
 : @param $facet-definitions one or more facet:facet-definition element
 : TODO: Handle nested facet-definition
:) 
declare function facet:facet($results as item()*, $facet-definitions as element(facet:facet-definition)?) as item()*{
    if($facet-definitions/facet:group-by/@function) then
        util:eval(concat($facet-definitions/facet:group-by/@function,'($results,$facet-definitions)'))
    else if($facet-definitions/facet:range) then
        facet:group-by-range($results, $facet-definitions)   
    else facet:group-by($results, $facet-definitions)
};

(:~
 : Default facet function. 
 : Facet defined by facets:facet-definition/facet:group-by/facet:sub-path 
 : @param $results results to be faceted on. 
 : @param $facet-definitions one or more facet:facet-definition element
:) 
declare function facet:group-by($results as item()*, $facet-definition as element(facet:facet-definition)?) as element(facet:key)*{
    let $path := concat('$results/',$facet-definition/facet:group-by/facet:sub-path/text())
    let $sort := $facet-definition/facet:order-by
    return 
        if($sort/@direction = 'ascending') then 
            let $facets := 
                for $f in util:eval($path)
                group by $facet-grp := $f
                let $label := string($facet-grp)
                order by $label[1] ascending
                return if(normalize-space($label) != '') then facet:key($label, $facet-grp, count($f), $facet-definition) else ()
            let $count := count($facets)
            return facet:list-keys($facets, $count, $facet-definition) 
        else 
            let $facets := 
                for $f in util:eval($path)
                group by $facet-grp := $f
                let $label := string($facet-grp)
                order by $label[1] descending 
                return if(normalize-space($label) != '') then facet:key($label, $facet-grp, count($f), $facet-definition) else ()
            let $count := count($facets)   
            return facet:list-keys($facets, $count, $facet-definition)
};
   
(:~ 
 : Range values defined by: range and range/bucket elements
 : Facet defined by facets:facet-definition/facet:group-by/facet:sub-path 
 : @param $results results to be faceted on. 
 : @param $facet-definitions one or more facet:facet-definition element
:) 
declare function facet:group-by-range($results as item()*, $facet-definition as element(facet:facet-definition)*) as element(facet:key)*{
    let $ranges := $facet-definition/facet:range
    let $sort := $facet-definition/facet:order-by
    let $facets := 
        for $range in $ranges/facet:bucket
        let $path := if($range/@lt and $range/@lt != '') then
                        concat('$results/',$facet-definition/descendant::facet:sub-path/text(),'[. >= "', facet:type($range/@gt, $ranges/@type),'" and . <= "',facet:type($range/@lt, $ranges/@type),'"]')
                     else if($range/@eq) then
                        concat('$results/',$facet-definition/descendant::facet:sub-path/text(),'[', $range/@eq ,']')
                     else concat('$results/',$facet-definition/descendant::facet:sub-path/text(),'[. >= "', facet:type($range/@gt, $ranges/@type),'"]')
        let $f := util:eval($path)
        order by 
                if($sort/text() = 'value') then $f[1]
                else if($sort/text() = 'count') then count($f)
                else if($sort/text() = 'order') then xs:integer($range/@order)
                else count($f)
            descending
        let $count := count($f)
        return facet:key(string($range/@name), string($range/@name), count($f), $facet-definition)
    let $count := count($facets)        
    return 
        if($count gt 0) then
            <div class="facetDefinition facet-grp">
                <h4>{string($facet-definition/@name)}</h4>
                {$facets}
            </div>
        else ()
};   

(:~
 : Syriaca.org specific group-by function for correctly labeling attributes with arrays.
 : Used for TEI relationships where multiple URIs may be coded in a single element or attribute
:)
declare function facet:group-by-array($results as item()*, $facet-definition as element(facet:facet-definition)?){
    let $path := concat('$results/',$facet-definition/facet:group-by/facet:sub-path/text()) 
    let $sort := $facet-definition/facet:order-by
    let $d := tokenize(string-join(util:eval($path),' '),' ')
    let $facets := 
        for $f in $d
        group by $facet-grp := tokenize($f,' ')
        order by 
            if($sort/text() = 'value') then $f[1]
            else count($f)
            descending
        return facet:key($facet-grp, $facet-grp, count($f), $facet-definition) 
    let $count := count($facets)           
    return facet:list-keys($facets, $count, $facet-definition)
};

declare function facet:list-keys($facets as item()*, $count, $facet-definition as element(facet:facet-definition)*){        
if($count gt 0) then 
    let $max := if(xs:integer($facet-definition/facet:max-values)) then xs:integer($facet-definition/facet:max-values) else 10
    let $show := if(xs:integer($facet-definition/facet:max-values/@show)) then xs:integer($facet-definition/facet:max-values/@show) else 5
    return 
        <div class="facetDefinition facet-grp">
            <h4>{string($facet-definition/@name)}</h4>
            <div class="facet-list show">{
            for $key at $l in subsequence($facets,1,$show)
            return $key
            }</div>
            {if($count gt ($show)) then 
                (<div class="facet-list collapse" id="{concat('show',replace(string($facet-definition/@name),' ',''))}">{
                    for $key at $l in subsequence($facets,$show + 1,$max)
                    where $count gt 0
                    return $key
                }</div>,
                <a class="facet-label togglelink btn btn-info" 
                data-toggle="collapse" data-target="#{concat('show',replace(string($facet-definition/@name),' ',''))}" href="#{concat('show',replace(string($facet-definition/@name),' ',''))}" 
                data-text-swap="Less"> More &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>)
            else()}
        </div>
else ()
};

declare function facet:key($label, $value, $count, $facet-definition){
   let $facetName := string($facet-definition/@name)
   let $paramName := concat('facet-',$facetName)
   let $active := if(request:get-parameter($paramName, ()) = $value) then 'active' else ()
   let $new-fq := concat($paramName,'=',$value)
   let $params := 
                if($active = 'active') then 
                    concat('?',facet:url-params($paramName, $value))
                else if(facet:url-params((),()) != '') then
                    concat('?',$new-fq, '&amp;', facet:url-params((),()))
                else concat('?',$new-fq) 
   return 
        if($count gt 0) then 
           <a href="{$params}" class="facet-label btn btn-default {$active}">{if($active) then <span class="glyphicon glyphicon-remove facet-remove"></span> else ()}{$label} <span class="count"> ({string($count)})</span> </a>
        else ()        
};

(:~ 
 : Builds new facet params for html links.
 : Uses request:get-parameter-names() to get all current params      
 :)
declare function facet:url-params($name, $value){
    string-join(
    for $param in request:get-parameter-names()
    for $getFacets in request:get-parameter($param, ())
    let $facet-value := normalize-space($getFacets)
    where $facet-value != ''
    return
        if($param = 'start') then 'start=1'
        else if(($param = $name) and ($facet-value = $value)) then ()
        else concat($param, '=',$facet-value),'&amp;')
};


(: END :)
(: BL Custom :)
declare function facet:script($results as item()*, $facet-definition as element(facet:facet-definition)?) as element(facet:key)*{
    let $path := concat('$results/',$facet-definition/facet:group-by/facet:sub-path/text())
    let $sort := $facet-definition/facet:order-by
    let $facets := 
        for $f in util:eval($path)
        group by $facet-grp := $f
        let $label := 
            if($facet-grp = 'syr-Syre') then 'Estrangela script'
            else if($facet-grp = 'syr-Syrj') then 'West Syriac script'
            else if($facet-grp = 'syr-Syrn') then 'East Syriac script'
            else if($facet-grp = 'syr-x-syrm') then 'Melkite Syriac script'
            else if($facet-grp = 'grc') then 'Greek'
            else if($facet-grp = 'ar-Syrc') then 'Arabic Garshuni script'
            else if($facet-grp = 'ar') then 'Unspecified Arabic script'
            else if($facet-grp = 'syr') then 'Unspecified Syriac script'
            else if($facet-grp = 'fr') then 'French'
            else if($facet-grp = 'he') then 'Hebrew'
            else if($facet-grp = 'hy') then 'Armenian'
            else string($facet-grp)
        order by $label[1] ascending
        return if(normalize-space($label) != '') then facet:key($label, $facet-grp, count($f), $facet-definition) else () 
    let $count := count($facets)
    return facet:list-keys($facets, $count, $facet-definition)  
        
};
declare function facet:material($results as item()*, $facet-definition as element(facet:facet-definition)?) as element(facet:key)*{
    let $path := concat('$results/',$facet-definition/facet:group-by/facet:sub-path/text())
    let $sort := $facet-definition/facet:order-by
    let $facets := 
        for $f in util:eval($path)
        group by $facet-grp := $f
        let $label := 
             if($facet-grp = 'perg') then 'Parchment'
             else if($facet-grp = 'chart') then 'Paper'
             else if($facet-grp = 'mixed') then 'Mixed Material'
             else string($facet-grp)
        order by $label[1] ascending
        return if(normalize-space($label) != '') then facet:key($label, $facet-grp, count($f), $facet-definition) else () 
    let $count := count($facets)
    return facet:list-keys($facets, $count, $facet-definition)        
};

