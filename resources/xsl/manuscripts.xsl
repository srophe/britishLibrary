<xsl:stylesheet xmlns="http://www.w3.torg/1999/xhtml" xmlns:saxon="http://saxon.sf.net/" xmlns:local="http://syriaca.org/ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:s="http://syriaca.org" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:x="http://www.w3.org/1999/xhtml" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs t s saxon" version="2.0">
    
    <!-- ================================================================== 
       Copyright 2013 New York University
       
       This file is part of the Syriac Reference Portal Places Application.
       
       The Syriac Reference Portal Places Application is free software: 
       you can redistribute it and/or modify it under the terms of the GNU 
       General Public License as published by the Free Software Foundation, 
       either version 3 of the License, or (at your option) any later 
       version.
       
       The Syriac Reference Portal Places Application is distributed in 
       the hope that it will be useful, but WITHOUT ANY WARRANTY; without 
       even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
       PARTICULAR PURPOSE.  See the GNU General Public License for more 
       details.
       
       You should have received a copy of the GNU General Public License
       along with the Syriac Reference Portal Places Application.  If not,
       see (http://www.gnu.org/licenses/).
       
       ================================================================== --> 
    
    <!-- ================================================================== 
       manuscripts.xsl
       
       This XSLT transforms tei.xml to html.
       
       parameters:

        
       code by: 
        + Winona Salesky (wsalesky@gmail.com)
          for use with eXist-db
        + Tom Elliott (http://www.paregorios.org) 
          for the Institute for the Study of the Ancient World, New York
          University, under contract to Vanderbilt University for the
          NEH-funded Syriac Reference Portal project.
        + Winona Salesky for use with eXist-db
          
       funding provided by:
        + National Endowment for the Humanities (http://www.neh.gov). Any 
          views, findings, conclusions, or recommendations expressed in 
          this code do not necessarily reflect those of the National 
          Endowment for the Humanities.
       
       ================================================================== -->
    
    <!-- =================================================================== -->
    <!-- TEMPLATES -->
    <!-- =================================================================== -->
    

    <!-- Manuscript templates -->
    <xsl:template name="mssHeader">
        <div class="title">
            <h1>
                <!-- Format title, calls template in place-title-std.xsl -->
                <xsl:call-template name="title"/>
            </h1>
            <!-- Call link icons (located in link-icons.xsl) -->
            <!--            <xsl:call-template name="link-icons"/>   -->
            <!-- End Title -->
        </div>
        <div class="header section">
           <div class="tei-note"> 
            <div>URI: <xsl:apply-templates select="//t:msDesc/t:msIdentifier/t:idno[@type='URI']"/></div>
            <xsl:if test="//t:msDesc/t:msIdentifier/t:altIdentifier/t:idno[@type='Wright-BL-Roman']">
                <div>
                    <xsl:choose>
                        <xsl:when test="//t:msDesc/t:additional/t:listBibl/t:bibl/t:ref[@target != '']">
                            <a href="{string(//t:msDesc/t:additional/t:listBibl/t:bibl/t:ref/@target)}" target="_blank">
                                Description based on Wright <xsl:apply-templates select="//t:msDesc/t:msIdentifier/t:altIdentifier/t:idno[@type='Wright-BL-Roman']"/> (<xsl:apply-templates select="//t:msDesc/t:additional/t:listBibl/t:bibl/t:citedRange[@unit='pp']"/>)
                                <img src="$nav-base/resources/images/ialogo.jpg" alt="Link to Archive.org Bibliographic record" height="18px"/>
                            </a>
                        </xsl:when>
                        <xsl:otherwise>
                            Description based on Wright <xsl:apply-templates select="//t:msDesc/t:msIdentifier/t:altIdentifier/t:idno[@type='Wright-BL-Roman']"/> (<xsl:apply-templates select="//t:msDesc/t:additional/t:listBibl/t:bibl/t:citedRange[@unit='pp']"/>)
                        </xsl:otherwise>
                    </xsl:choose>
                    </div>    
            </xsl:if>
            <xsl:if test="//t:msDesc/t:history/t:origin/t:origDate">
                <div>
                    Date: 
                    <xsl:if test="//t:msDesc/t:history/t:origin/t:origDate[@calendar='Gregorian']">
                        <xsl:value-of select="//t:msDesc/t:history/t:origin/t:origDate[@calendar='Gregorian']"/>
                        <xsl:if test="//t:msDesc/t:history/t:origin/t:origDate[not(@calendar='Gregorian')]"> / </xsl:if>
                    </xsl:if>
                    <xsl:if test="//t:msDesc/t:history/t:origin/t:origDate[not(@calendar='Gregorian')]">
                        <xsl:for-each select="//t:msDesc/t:history/t:origin/t:origDate[not(@calendar='Gregorian')]">
                            <xsl:value-of select="."/>
                            <xsl:if test="position() != last()"> / </xsl:if>
                        </xsl:for-each>
                    </xsl:if>
                </div>
            </xsl:if>
            <xsl:if test="//t:msDesc/t:history/t:origin/t:origPlace != ''">
                <div>
                    Origin: <xsl:apply-templates select="//t:msDesc/t:history/t:origin/t:origPlace" mode="mss"/>
                </div>
            </xsl:if>
                <div>
                    <xsl:if test="//t:msDesc/t:physDesc/t:handDesc/t:handNote[@scope='major']/@script">
                        <xsl:call-template name="script">
                            <xsl:with-param name="node" select="//t:msDesc/t:physDesc/t:handDesc/t:handNote[@scope='major']"/>
                        </xsl:call-template>
                    </xsl:if>
                    <xsl:if test="//t:handDesc[@hands &gt; 1]"> (multiple hands) ܀ </xsl:if>
                    <xsl:if test="//t:msDesc/t:physDesc/t:objectDesc/t:supportDesc[@material != '']">
                        <xsl:choose>
                            <xsl:when test="//t:msDesc/t:physDesc/t:objectDesc/t:supportDesc/@material = 'perg'">Parchment</xsl:when>
                            <xsl:when test="//t:msDesc/t:physDesc/t:objectDesc/t:supportDesc/@material = 'chart'">Paper</xsl:when>
                            <xsl:when test="//t:msDesc/t:physDesc/t:objectDesc/t:supportDesc/@material = 'mixed'">Mixed Material</xsl:when>
                        </xsl:choose>
                    </xsl:if> <xsl:if test="//t:msDesc/t:physDesc/t:objectDesc[@form != '']"><xsl:variable name="string" select="//t:msDesc/t:physDesc/t:objectDesc/@form"/><xsl:value-of select="concat(upper-case(substring($string,1,1)),substring($string,2))"/></xsl:if><xsl:if test="//t:msDesc/t:physDesc/t:objectDesc/t:supportDesc/t:extent/t:measure[@type='composition'][@quantity != '']">, </xsl:if>
                    <xsl:if test="//t:msDesc/t:physDesc/t:objectDesc/t:supportDesc/t:extent/t:measure[@type='composition'][@quantity != '']">
                        <xsl:choose>
                            <xsl:when test="//t:msDesc/t:physDesc/t:objectDesc/t:supportDesc/t:extent/t:measure[@type='composition'][@quantity = '1']">
                                <xsl:value-of select="//t:msDesc/t:physDesc/t:objectDesc/t:supportDesc/t:extent/t:measure[@type='composition']/@quantity"/> leaf. 
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="//t:msDesc/t:physDesc/t:objectDesc/t:supportDesc/t:extent/t:measure[@type='composition']/@quantity"/> leaves.
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:if>
                </div>
            <div>
                <xsl:if test="//t:msDesc/t:physDesc[t:additions/t:list/t:item/t:label[@content='Colophon']]                     or //t:msDesc/t:physDesc/t:decoDesc/t:decoNote                      or //t:msDesc/t:physDesc/t:additions[t:list/t:item/t:label[@content = 'Doxology']]">
                    Features: 
                    <xsl:if test="//t:msDesc/t:physDesc[t:additions/t:list/t:item/t:label[@content='Colophon']]">
                        Colophon<xsl:if test="//t:msDesc/t:physDesc/t:decoDesc/t:decoNote or //t:msDesc/t:physDesc[t:additions/t:list/t:item/t:label[@content='Doxology']]">, </xsl:if>
                    </xsl:if>
                    <xsl:if test="//t:msDesc/t:physDesc/t:decoDesc/t:decoNote">
                        Decoration<xsl:if test="//t:msDesc/t:physDesc[t:additions/t:list/t:item/t:label[@content='Doxology']]">, </xsl:if>
                    </xsl:if>
                    <xsl:if test="//t:msDesc/t:physDesc[t:additions/t:list/t:item/t:label[@content='Doxology']]">Doxology</xsl:if>
                </xsl:if>
            </div>
            <xsl:if test="//t:msDesc/t:head/t:listRelation[@type='Wright-BL-Taxonomy']/t:relation">
            <div>
                Wright's Subject Classification:
                <xsl:for-each select="//t:msDesc/t:head/t:listRelation[@type='Wright-BL-Taxonomy']/t:relation">
                    <xsl:value-of select="t:desc"/><xsl:if test="position() != last()">; </xsl:if>
                </xsl:for-each>
            </div>
            </xsl:if>
           </div>
            <xsl:if test="//t:msDesc/t:head/t:note[@type='contents-note']">
                <xsl:apply-templates select="//t:msDesc/t:head/t:note[@type='contents-note']"/>
            </xsl:if>
        </div>
        
    </xsl:template>
    
    <xsl:template match="t:msDesc">
        <xsl:if test="t:physDesc">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <h2 class="panel-title" data-toggle="collapse" data-target="#Overview">Physical Description </h2>
                </div>
                <div id="Overview" class="panel-collapse collapse in">
                    <div class="panel-body">
                        <div class="msDesc">
                            <xsl:apply-templates select="t:physDesc"/>    
                        </div>
                    </div>
                </div>
            </div>
        </xsl:if>
        <div class="panel panel-default">
            <div class="panel-heading">
                <h2 class="panel-title" data-toggle="collapse" data-target="#Contents">Manuscript Contents</h2>
            </div>
            <div id="Contents" class="panel-collapse collapse in">
                <div class="panel-body">
                    <div class="msContent">
                        <span class="summary ident">Note: Item numbering updated in digital edition.</span>
                        <xsl:apply-templates select="t:msContents | t:msPart"/>
                    </div>
                </div>
            </div>
        </div>  
        <xsl:if test="t:physDesc/t:additions and t:physDesc/t:additions/child::*">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <h2 class="panel-title" data-toggle="collapse" data-target="#Additions">Additions </h2>
                </div>
                <div id="Additions" class="panel-collapse collapse in">
                    <div class="panel-body">
                        <div class="msDesc">
                            <xsl:apply-templates select="t:physDesc/t:additions"/>    
                        </div>
                    </div>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
    <xsl:template match="t:msPart">
        <div class="panel-group" id="accordion">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <h2 class="panel-title" data-toggle="collapse" data-target="#msPart{@xml:id}">Ms Part <xsl:value-of select="@n"/></h2>
                </div>
                <div id="msPart{@xml:id}" class="panel-collapse collapse in">
                    <div class="panel-body">
                        <div class="msDesc">
                            <xsl:apply-templates select="t:msIdentifier | t:physDesc"/>    
                        </div>
                        <div class="msContent">
                            <p class="summary indent">This manuscript contains <xsl:value-of select="count(descendant::t:msItem)"/> items 
                                <xsl:if test="descendant::t:msItem/t:msItem"> <xsl:text> including nested subsections</xsl:text>
                                </xsl:if>. N.B. Items were re-numbered by Syriaca.org and may not reflect previous numeration.</p>
                            <div class="indent">
                                <xsl:apply-templates select="t:msContents | t:msPart"/>
                            </div>
                        </div>
                    </div>
                </div>
            </div>   
        </div>
    </xsl:template>
    <xsl:template match="t:msIdentifier">
        <!--
        <xsl:if test="t:country">
            <div class="tei-msIdentifier location">
                <span class="inline-h4">Current location: </span>
                <span class="location">
                    <xsl:value-of select="t:country"/>
                    <xsl:if test="t:country/following-sibling::*"> - </xsl:if>
                    <xsl:value-of select="t:settlement"/>
                    <xsl:if test="t:settlement/following-sibling::*"> - </xsl:if>
                    <xsl:value-of select="t:repository"/>
                    <xsl:if test="t:repository/following-sibling::*"> - </xsl:if>
                    <xsl:value-of select="t:collection"/>
                </span>
            </div>  
            <hr/>
        </xsl:if>
        <xsl:if test="t:altIdentifier or t:idno">
            <div class="tei-msIdentifier location">
                <span class="inline-h4">Identification: </span>
                <div class="indent">
                    <xsl:apply-templates select="t:idno | t:altIdentifier"/>
                </div>
                <hr/>
            </div>
        </xsl:if>
        -->
    </xsl:template>
    <xsl:template match="t:altIdentifier">
        <div>
            <xsl:if test="t:collection"><span class="inline-h4"><xsl:value-of select="t:collection"/>: </span></xsl:if>
            <xsl:apply-templates select="t:idno"/>            
        </div>
    </xsl:template>
    <xsl:template match="t:physDesc">
        <div class="tei-physDesc">
            <div class="indent">
                <xsl:apply-templates select="child::*[not(self::t:additions) and not(self::t:objectDesc)]"/>
            </div>
        </div>
    </xsl:template>
   
    <xsl:template match="t:objectDesc"/>
    <xsl:template match="t:condition | t:foliation |  t:collation"/>
    <xsl:template match="t:summary | t:textLang">
        <xsl:choose>
            <xsl:when test="parent::t:msContents"/>
            <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:quote | t:incipit | t:editor | t:explicit | t:colophon | t:rubric | t:finalRubric | t:filiation | t:material |  t:layoutDesc | t:origDate | t:provenance | t:acquisition | t:availability | t:custodialHist | t:history | t:origin | t:extent">
        <xsl:if test="not(empty(.))">
            <div class="tei-{local-name(.)}">
                <span class="inline-h4">
                    <xsl:choose>
                        <xsl:when test="self::t:quote">Excerpt<xsl:if test="t:folio"> <xsl:apply-templates select="t:folio"/></xsl:if>: </xsl:when>
                        <xsl:when test="self::t:rubric">Title:</xsl:when>
                        <xsl:when test="self::t:finalRubric">Subscription:</xsl:when>
                        <xsl:when test="self::t:layoutDesc">Layout:</xsl:when>
                        <xsl:when test="self::t:origDate">Date:</xsl:when>
                        <xsl:when test="self::t:custodialHist">Custodial History:</xsl:when>
                        <xsl:otherwise><xsl:value-of select="concat(upper-case(substring(local-name(.),1,1)),substring(local-name(.),2))"/>:</xsl:otherwise>
                    </xsl:choose>
                </span>
                <span>
                    <xsl:sequence select="local:attributes(.)"/>
                    <xsl:apply-templates/>
                </span>
            </div>
        </xsl:if>
    </xsl:template>
    <xsl:template match="t:additions">
        <div class="indent">
            <xsl:apply-templates/>    
        </div>
    </xsl:template>
    <xsl:template match="t:handNote">
        <xsl:choose>
            <xsl:when test="@scope='minor' and (t:desc = '' or t:desc='See additions.')"/>
            <xsl:otherwise>
                <div name="{string(@xml:id)}">
                    <span class="inline-h4">Hand <xsl:value-of select="substring-after(string(@xml:id),'ote')"/>
                        <xsl:if test="@scope or @script"> (<xsl:if test="@scope"><xsl:value-of select="@scope"/><xsl:if test="@script">, </xsl:if></xsl:if><xsl:if test="@script"><xsl:call-template name="script"><xsl:with-param name="node" select="."/></xsl:call-template></xsl:if>)</xsl:if>: </span><xsl:apply-templates mode="plain"/>
                </div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:decoNote">
        <div name="{string(@xml:id)}">
            <span class="msItem"><span class="inline-h4">Decoration<xsl:if test="@type"> (<xsl:value-of select="concat(upper-case(substring(@type,1,1)),substring(@type,2))"/> )</xsl:if><xsl:if test="@medium"> [Medium: <xsl:value-of select="@medium"/>]</xsl:if>:</span> <xsl:apply-templates mode="plain"/></span>
        </div>
    </xsl:template>
    <xsl:template match="t:msItem">
        <xsl:variable name="depth" select="count(ancestor::t:msItem)"/>
        <div class="tei-{local-name(.)}">
            <!--
            <xsl:for-each select="1 to $depth">
                <xsl:text> &gt; </xsl:text>
            </xsl:for-each>
            -->
            <span class="inline-h4">Item <xsl:value-of select="@n"/> <xsl:choose><xsl:when test="t:locus"> <xsl:apply-templates select="t:locus[1]"/></xsl:when><xsl:otherwise> (folio not specified)</xsl:otherwise></xsl:choose>: </span>
            <!--
            <xsl:choose>
                <xsl:when test="@defective = 'true' or @defective ='unknown'"><span class="inline-h4">Item <xsl:value-of select="@n"/>: </span> (defective) </xsl:when>
                <xsl:otherwise><span class="inline-h4">Item <xsl:value-of select="@n"/> <xsl:choose><xsl:when test="t:locus">&#160;<xsl:apply-templates select="t:locus[1]"/></xsl:when><xsl:otherwise>&#160;(folio not specified)</xsl:otherwise></xsl:choose>: </span></xsl:otherwise>
            </xsl:choose>
            -->
            <div class="msItemChild">
                <xsl:call-template name="msItemTitleAuthor"/>
                <xsl:apply-templates select="*[not(self::t:note) and not(self::t:locus) and not(self::t:title) and not(self::t:author) and not(self::t:msItem)]"/>
                <xsl:if test="t:note">
                    <xsl:choose>
                        <xsl:when test="count(t:note) = 1">
                            <div class="msItem-notes">
                                <span class="inline-h4">Note: </span><xsl:for-each select="t:note"><xsl:apply-templates/></xsl:for-each>    
                            </div> 
                        </xsl:when>
                        <xsl:otherwise>
                            <div class="msItem-notes">
                                <span class="inline-h4">Notes:</span>
                                <ul>
                                    <xsl:for-each select="t:note">
                                        <li> <xsl:apply-templates/></li>
                                    </xsl:for-each>    
                                </ul>
                            </div> 
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
                <xsl:apply-templates select="t:msItem"/>
                
            
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:list[parent::t:additions]">
        <xsl:apply-templates mode="mss"/>
    </xsl:template>
    <xsl:template match="t:item" mode="mss">
        <xsl:choose>
            <xsl:when test="parent::t:list/parent::t:additions">
                <div class="tei-item">
                    <xsl:if test="@n"><span class="inline-h4">Addition <xsl:value-of select="@n"/></span></xsl:if>
                    <!--
                    <xsl:if test="t:label">
                        <span class="inline-h4"> [<xsl:value-of select="t:label"/>]: </span>
                    </xsl:if>
                    -->
                    <xsl:if test="t:locus"><xsl:apply-templates select="t:locus[1]"/></xsl:if>:
                    <xsl:apply-templates select="*[not(self::t:label) and not(self::t:locus)]" mode="plain"/>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <div class="tei-item">
                    <xsl:if test="@n">
                        <span class="inline-h4"><xsl:value-of select="@n"/>. </span>
                    </xsl:if>
                    <xsl:if test="t:label">
                        <span class="inline-h4"> [<xsl:value-of select="t:label"/>]: </span>
                    </xsl:if>
                    <xsl:if test="t:locus">
                        <xsl:apply-templates select="t:locus"/>
                    </xsl:if>
                    <xsl:apply-templates select="*[not(self::t:label) and not(self::t:locus)]" mode="plain"/>
                </div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:locus">
        <xsl:choose>
            <xsl:when test="parent::t:item">
                <xsl:choose>
                    <xsl:when test="text()"/>
                    <xsl:otherwise> (Fol. <xsl:value-of select="@from"/>)</xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="parent::t:msItem">(Fol. <xsl:value-of select="@from"/>)</xsl:when>
            <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
        </xsl:choose>
        <!-- 
            
            Fol. 1a. is constructed from "Fol."+/locus @from="1a"+"." NOTE: Test, if @from is not the same as @to 
            (and if @to has a value), then use "Fols."+ /locus @from="1a"+"-"+/locus @to"+"." 
            We will also need to handle multiple /locus elements. 
            Can you write that?
        "2. Fol. 1b. At the foot of the page there is an explanatory note the last line of which is much injured. So far as legible, it runs thus:..."
        
        <item xml:id="addition2" n="2">
  <locus from="1b" to="1b"/>
  <p>At the foot of the page there is an explanatory note the last line of which is much injured. So far as legible, it runs thus:</p>
...
</item>
        -->
    </xsl:template>
    <xsl:template name="script">
        <xsl:param name="node"/>
        <xsl:choose>
            <xsl:when test="$node/@script = 'syr'">Unspecified Syriac script</xsl:when>
            <xsl:when test="$node/@script = 'syr-Syre'">Estrangela script</xsl:when>
            <xsl:when test="$node/@script = 'syr-Syrj'">West Syriac script</xsl:when>
            <xsl:when test="$node/@script = 'syr-Syrn'">East Syriac script</xsl:when>
            <xsl:when test="$node/@script = 'syr-x-syrm'">Melkite Syriac script</xsl:when>
            <xsl:when test="$node/@script = 'grc'">Greek</xsl:when>
            <xsl:when test="$node/@script = 'ar-Syrc'">Arabic Garshuni script</xsl:when>
            <xsl:when test="$node/@script = 'ar'">Unspecified Arabic script</xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:title">
        <xsl:choose>
            <xsl:when test="ancestor::t:msItem and contains(@ref,'syriaca.org')">
                <a href="{$nav-base}/search.html?ref={@ref}"><xsl:value-of select="."/></a>
                <xsl:if test="ancestor::t:msItem[@defective='true']"> [defective]</xsl:if>
            </xsl:when>
            <xsl:when test="ancestor::t:msItem">
                <xsl:choose>
                    <xsl:when test="@ref">
                        <a href="{@ref}">
                            <xsl:sequence select="local:attributes(.)"/>
                            <xsl:value-of select="."/>
                            [<xsl:value-of select="@ref"/>]
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <span>
                            <xsl:sequence select="local:attributes(.)"/>
                            <xsl:value-of select="."/>
                        </span>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="ancestor::t:msItem[@defective='true']"> [defective]</xsl:if>
            </xsl:when>
            <xsl:when test="@ref">                
                <a href="{@ref}">
                    <xsl:sequence select="local:attributes(.)"/>
                    <xsl:value-of select="."/>
                    [<xsl:value-of select="@ref"/>]
                </a>
            </xsl:when>
            <xsl:otherwise>
                <span>
                    <xsl:sequence select="local:attributes(.)"/>
                    <xsl:value-of select="."/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="msItemTitleAuthor">
        <xsl:for-each select="t:author">
            <xsl:apply-templates select="." mode="mss"/><xsl:choose>
                <xsl:when test="position() != last()">, </xsl:when>
                <xsl:otherwise>. </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <xsl:apply-templates select="t:title"/>
    </xsl:template>
    <xsl:template match="t:author" mode="mss">
        <!--
            When Syriaca.org/person URIs occurs as an attribute value inside //author/@ref then render the textnode as a 
            live link that resolves to a browse by Author page inside https://bl.vuexistapps.us with that URI selected.
            Note: I am not sure what this would look like but assume we will want to create a "Authors" tab in Browse, https://bl.vuexistapps.us/browse.html?;collection=authors and then filter that by the URI?
            facet-author - how to do this? with the uri? not sure i can. 
            
        -->
        <xsl:choose>
            <xsl:when test="@ref">
                <a href="{$nav-base}/browse.html?view=author&amp;ref={@ref}"><xsl:value-of select="."/></a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:persName" mode="mss">
        <xsl:choose>
            <xsl:when test="@ref">
                <a href="{$nav-base}/search.html?ref={@ref}"><xsl:value-of select="."/></a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:origPlace" mode="mss">
        <xsl:choose>
            <xsl:when test="@ref">
                <a href="{$nav-base}/search.html?ref={@ref}"><xsl:value-of select="."/></a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!--
    <xsl:template match="* | @*" mode="labeled">
        <xsl:if test="not(empty(.))">
            <span>
                <span class="srp-label"><xsl:value-of select="name(.)"/>: </span>
                <span class="note"><xsl:apply-templates/></span>
            </span>            
        </xsl:if>
    </xsl:template>
    -->
</xsl:stylesheet>