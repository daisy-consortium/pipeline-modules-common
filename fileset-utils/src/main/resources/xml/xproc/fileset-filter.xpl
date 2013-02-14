<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step version="1.0" type="px:fileset-filter" name="main" xmlns:cx="http://xmlcalabash.com/ns/extensions" xmlns:p="http://www.w3.org/ns/xproc" xmlns:d="http://www.daisy.org/ns/pipeline/data" xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
    xmlns:c="http://www.w3.org/ns/xproc-step" exclude-inline-prefixes="cx px" xpath-version="2.0">

    <p:input port="source"/>
    <p:output port="result"/>

    <p:option name="href" select="''">
        <!-- href to the file in the fileset you want to retrieve -->
    </p:option>
    <p:option name="media-types" select="''">
        <!-- space separated list of whitelisted media types. suppports the glob characters '*' and '?', i.e. "image/*" or "application/*+xml". -->
    </p:option>
    <p:option name="not-media-types" select="''">
        <!-- space separated list of blacklisted media types. suppports the glob characters '*' and '?', i.e. "image/*" or "application/*+xml". -->
    </p:option>

    <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/fileset-utils/xproc/fileset-library.xpl"/>

    <p:choose>
        <p:when test="$href=''">
            <p:identity/>
        </p:when>
        <p:otherwise>
            <p:variable name="resolved-href" select="resolve-uri($href,base-uri(/*))">
                
            </p:variable>
            <p:delete>
                <p:with-option name="match" select="concat(&quot;//d:file[not(resolve-uri(@href,base-uri(.))=resolve-uri('&quot;,$resolved-href,&quot;'))]&quot;)"/>
            </p:delete>
        </p:otherwise>
    </p:choose>

    <p:choose>
        <p:when test="$media-types=''">
            <p:identity/>
        </p:when>
        <p:otherwise>
            <p:variable name="media-types-regexes" select="if ($media-types='') then '' else replace(replace(replace($media-types,'\+','\\+'),'\?','.'),'\*','.*')"/>
            <p:delete>
                <p:with-option name="match" select="concat(&quot;//d:file[@media-type='' or not(some $media-type-regex in tokenize('&quot;,$media-types-regexes,&quot;',' ') satisfies matches(@media-type,$media-type-regex))]&quot;)"/>
            </p:delete>
        </p:otherwise>
    </p:choose>

    <p:choose>
        <p:when test="$not-media-types=''">
            <p:identity/>
        </p:when>
        <p:otherwise>
            <p:variable name="not-media-types-regexes" select="if ($not-media-types='') then '' else replace(replace(replace($not-media-types,'\+','\\+'),'\?','.'),'\*','.*')"/>
            <p:delete>
                <p:with-option name="match" select="concat(&quot;//d:file[not(@media-type='') and (some $not-media-type-regex in tokenize('&quot;,$not-media-types-regexes,&quot;',' ') satisfies matches(@media-type,$not-media-type-regex))]&quot;)"/>
            </p:delete>
        </p:otherwise>
    </p:choose>

</p:declare-step>