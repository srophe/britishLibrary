<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:s="http://syriaca.org" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:x="http://www.w3.org/1999/xhtml" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" exclude-result-prefixes="xs t s saxon" version="2.0">
    
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
    
    <!-- 
    
    /TEI/teiHeader/titleStmt, editionStmt, publicationStmt : will display together, currently is in the Cite This box

/TEI/teiHeader/profileDesc/textClass

/TEI/teiHeader/fileDesc/sourceDesc/msDesc/msIdentifier

/TEI/teiHeader/fileDesc/sourceDesc/msDesc/msContents

/TEI/teiHeader/fileDesc/sourceDesc/msDesc/physDesc/additions

/TEI/teiHeader/fileDesc/sourceDesc/msDesc/physDesc/p and objectDesc and handDesc and decoDesc (not all may be present)

/TEI/teiHeader/fileDesc/sourceDesc/msDesc/history

/TEI/teiHeader/fileDesc/sourceDesc/msDesc/additional/listBibl/bibl


MSParts
/TEI/teiHeader/fileDesc/sourceDesc/msDesc//msPart/msIdentifier

/TEI/teiHeader/fileDesc/sourceDesc/msDesc//msPart/msContents

/TEI/teiHeader/fileDesc/sourceDesc/msDesc//msPart/physDesc/additions

/TEI/teiHeader/fileDesc/sourceDesc/msDesc//msPart/physDesc/p and objectDesc and handDesc and decoDesc (not all may be present)

/TEI/teiHeader/fileDesc/sourceDesc/msDesc//msPart/history

/TEI/teiHeader/fileDesc/sourceDesc/msDesc//msPart/additional/listBibl/bibl

aria-expanded="false" aria-controls="collapseExample"
    -->
    <!-- Manuscript templates -->
    <xsl:template match="t:msDesc">
        <xsl:if test="t:msIdentifier or t:physDesc">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <h2 class="panel-title" data-toggle="collapse" data-target="#Overview">Physical Description </h2>
                </div>
                <div id="Overview" class="panel-collapse collapse in">
                    <div class="panel-body">
                        <div class="msDesc">
                            <xsl:apply-templates select="t:msIdentifier | t:physDesc"/>    
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
                        <p class="summary indent">This manuscript contains <xsl:value-of select="count(descendant::t:msItem)"/> items 
                            <xsl:if test="descendant::t:msItem/t:msItem"> <xsl:text> including nested subsections</xsl:text>
                            </xsl:if>. N.B. Items were re-numbered by Syriaca.org and may not reflect previous numeration.</p>
                        <xsl:apply-templates select="t:msContents | t:msPart"/>
                    </div>
                </div>
            </div>
        </div>    
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
                <xsl:apply-templates/>
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:incipit | t:title | t:editor | t:quote | t:explicit | t:colophon | t:finalRubric | t:filiation | t:material | t:foliation |          t:collation | t:additions | t:condition | t:layoutDesc | t:origDate | t:provenance | t:acquisition | t:availability | t:custodialHist | t:history |          t:summary | t:origin | t:extent">
        <xsl:if test="not(empty(.))">
            <div class="tei-{local-name(.)}">
                <span class="inline-h4">
                    <xsl:choose>
                        <xsl:when test="self::t:finalRubric">Desinit</xsl:when>
                        <xsl:when test="self::t:layoutDesc">Layout</xsl:when>
                        <xsl:when test="self::t:origDate">Date</xsl:when>
                        <xsl:when test="self::t:custodialHist">Custodial History</xsl:when>
                        <xsl:otherwise><xsl:value-of select="concat(upper-case(substring(local-name(.),1,1)),substring(local-name(.),2))"/></xsl:otherwise>
                    </xsl:choose>: 
                </span>
                <xsl:apply-templates/>
            </div>
        </xsl:if>
    </xsl:template>
    <xsl:template match="t:handNote">
        <div name="{string(@xml:id)}">
            <span class="inline-h4">Hand <xsl:value-of select="substring-after(string(@xml:id),'ote')"/>: </span>
            <div class="msItem indent">
                <xsl:if test="@scope">
                    <span class="inline-h4">Scope:</span>  <xsl:value-of select="@scope"/>
                </xsl:if>
                <xsl:if test="@script">
                    <xsl:variable name="script" select="@script"/>
                    <div>
                        <span class="inline-h4">Script: </span><xsl:value-of select="//t:langUsage/t:language[@ident = $script]/text()"/>
                    </div>
                </xsl:if>
                <xsl:if test="@medium">
                    <div>
                        <span class="inline-h4">Medium: </span> <xsl:value-of select="@medium"/>
                    </div>
                </xsl:if>
                <xsl:apply-templates mode="plain"/>
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:decoNote">
        <div name="{string(@xml:id)}">
            <span class="inline-h4">Decoration: </span>
            <div class="msItem indent">
                <xsl:if test="@type">
                    <span class="inline-h4"><xsl:value-of select="concat(upper-case(substring(@type,1,1)),substring(@type,2))"/>: </span>
                </xsl:if>
                <xsl:if test="@medium">
                    <span class="inline-h4">Medium:</span> <xsl:value-of select="@medium"/>
                </xsl:if>
                <!-- 
                
                <decoNote xml:id="p1decoNote2" type="ornamentation">
                  <locus from="1a" to="1a"/>
                  <desc>An ornamental nimbus, coloured with black, red, green, and yellow.
                  <ref target="#p1addition2">See below.</ref>
                  </desc>
                </decoNote>
                -->
                <xsl:apply-templates mode="plain"/>
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:msItem">
        <xsl:variable name="depth" select="count(ancestor::t:msItem)"/>
        <div class="tei-{local-name(.)}">
            <xsl:for-each select="1 to $depth">
                <xsl:text> &gt; </xsl:text>
            </xsl:for-each> 
            <xsl:choose>
                <xsl:when test="@defective = 'true' or @defective ='unknown'"><span class="inline-h4">Item <xsl:value-of select="@n"/>: </span> (defective) </xsl:when>
                <xsl:otherwise><span class="inline-h4">Item <xsl:value-of select="@n"/>: </span></xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates/>
        </div>
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