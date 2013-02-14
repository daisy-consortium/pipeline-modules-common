<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:svrl="http://purl.oclc.org/dsdl/svrl" xmlns:c="http://www.w3.org/ns/xproc-step"
    xmlns:d="http://www.daisy.org/ns/pipeline/data" xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="#all">
    <xsl:output xml:space="default" media-type="text/html" indent="yes"/>
    <xsl:template match="/">
        <div class="document-validation-report" id="{generate-id()}">
            <xsl:choose>
                <xsl:when
                    test="count(descendant::svrl:failed-assert) = 0 and
                    count(descendant::svrl:successful-report) = 0 and 
                    count(descendant::d:error) = 0">
                    <xsl:apply-templates select="descendant::d:document-info"/>
                    <p>No errors found.</p>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <xsl:template match="*">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="d:document-info">
        <div class="document-info">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <!-- document info -->
    <xsl:template match="d:document-name">
        <h2>
            <code>
                <xsl:value-of select="text()"/>
            </code>
        </h2>
    </xsl:template>

    <xsl:template match="d:document-type">
        <p>Validated as <code><xsl:value-of select="text()"/></code></p>
    </xsl:template>

    <xsl:template match="d:document-path">
        <p>Path: <code><xsl:value-of select="text()"/></code></p>
    </xsl:template>

    <xsl:template match="d:reports">
        <ul class="document-errors">
            <xsl:apply-templates/>
        </ul>
    </xsl:template>

    <!-- failed asserts and successful reports are both notable events in SVRL -->
    <xsl:template match="svrl:failed-assert | svrl:successful-report">
        <!-- TODO can we output the line number too? -->
        <li class="error">
            <p>
                <xsl:value-of select="svrl:text/text()"/>
            </p>
            <div>
                <h3>Location (XPath)</h3>
                <pre><xsl:value-of select="@location"/></pre>
            </div>
        </li>
    </xsl:template>

    <xsl:template match="d:error">
        <li class="error">
            <p>
                <xsl:value-of select="./d:desc"/>
            </p>
            <xsl:if test="./d:file">
                <pre><xsl:value-of select="./d:file"/></pre>    
            </xsl:if>
            <div>
                <h3>Location</h3>
                <pre>
                    <xsl:choose>
                        <xsl:when test="./d:location/@href">
                            <xsl:value-of select="./d:location/@href"/>    
                        </xsl:when>
                        <xsl:otherwise>
                            <em>Line <xsl:value-of select="./d:location/@line"/>, Column <xsl:value-of select="./d:location/@column"/></em>
                        </xsl:otherwise>
                    </xsl:choose>
                </pre>
            </div>
        </li>
    </xsl:template>
    
    <!-- things to ignore.there are probably more than just these-->
    <xsl:template match="svrl:schematron-output">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="svrl:ns-prefix-in-attribute-values | svrl:active-pattern | svrl:fired-rule"/>
    <xsl:template match="text()"/>
    
        
    
</xsl:stylesheet>