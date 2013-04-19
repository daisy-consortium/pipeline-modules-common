<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pf="http://www.daisy.org/ns/pipeline/functions" exclude-result-prefixes="#all"
    version="2.0" xmlns:f="http://www.daisy.org/ns/pipeline/internal-functions">

    <xsl:function name="pf:tokenize-uri" as="xs:string*">
        <xsl:param name="uri" as="xs:string?"/>
        <!--
            Uses the regex defined in RFC3986 (Appendix B) to tokenize the URI in 5 parts:
            1. scheme
            2. authority
            3. path
            4. query
            5. fragment
        -->
        <xsl:analyze-string select="concat('X',$uri)"
            regex="^X(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?">
            <xsl:matching-substring>
                <xsl:sequence
                    select="(regex-group(2),regex-group(4),regex-group(5),regex-group(7),regex-group(9))"
                />
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>

    <xsl:function name="pf:recompose-uri" as="xs:string">
        <xsl:param name="tokens" as="xs:string*"/>
        <xsl:sequence
            select="string-join((
            if($tokens[1]) then ($tokens[1],':') else (),
            if($tokens[2]) then ('//',$tokens[2]) else (),
            $tokens[3],
            if($tokens[4]) then ('?',$tokens[4]) else (),
            if($tokens[5]) then ('#',$tokens[5]) else ()
            ),'')"
        />
    </xsl:function>
    
    <!--TODO write tests-->
    <xsl:function name="pf:is-absolute" as="xs:boolean">
        <xsl:param name="uri" as="xs:string?"/>
        <xsl:sequence select="boolean(pf:tokenize-uri(normalize-space($uri))[1])"/>
    </xsl:function>
    
    <!--TODO write tests-->
    <xsl:function name="pf:is-relative" as="xs:boolean">
        <xsl:param name="uri" as="xs:string?"/>
        <xsl:sequence select="not(pf:is-absolute($uri))"/>
    </xsl:function>
    
    <!--TODO write tests-->
    <xsl:function name="pf:get-path" as="xs:string">
        <xsl:param name="uri" as="xs:string?"/>
        <xsl:sequence select="pf:tokenize-uri(normalize-space($uri))[3]"/>
    </xsl:function>
    
    <!--TODO write tests-->
    <xsl:function name="pf:replace-path" as="xs:string">
        <xsl:param name="uri" as="xs:string?"/>
        <xsl:param name="path" as="xs:string?"/>
        <xsl:variable name="tokens" select="pf:tokenize-uri(normalize-space($uri))" as="xs:string*"/>
        <xsl:sequence
            select="pf:recompose-uri(($tokens[1],$tokens[2],pf:normalize-path($path),$tokens[4],$tokens[5]))"
        />
    </xsl:function>

    <xsl:function name="pf:normalize-uri" as="xs:string">
        <xsl:param name="uri" as="xs:string?"/>
        <!--
            http://en.wikipedia.org/wiki/URL_normalization
            - path segment normalization
            - TODO case normalization
            - TODO percent-encoding normalization
            - TODO default http port
        -->
        <xsl:variable name="tokens" select="pf:tokenize-uri($uri)" as="xs:string*"/>
        <xsl:sequence
            select="pf:recompose-uri(($tokens[1],$tokens[2],pf:normalize-path($tokens[3]),$tokens[4],$tokens[5]))"
        />
    </xsl:function>

    <xsl:function name="pf:relativize-uri" as="xs:string">
        <xsl:param name="uri" as="xs:string?"/>
        <xsl:param name="base" as="xs:string?"/>
        <xsl:variable name="uri-tokens" select="pf:tokenize-uri(pf:normalize-uri($uri))"/>
        <xsl:variable name="base-tokens" select="pf:tokenize-uri(pf:normalize-uri($base))"/>

        <xsl:choose>
            <xsl:when
                test="(not($uri-tokens[1]) or $uri-tokens[1]=$base-tokens[1]) and (not($uri-tokens[2]) or $uri-tokens[2]=$base-tokens[2])">
                <xsl:sequence
                    select="pf:recompose-uri(('','',pf:relativize-path($uri-tokens[3],$base-tokens[3]),$uri-tokens[4],$uri-tokens[5]))"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="pf:recompose-uri($uri-tokens)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="pf:normalize-path" as="xs:string?">
        <xsl:param name="path" as="xs:string?"/>
        <xsl:variable name="normalized" as="xs:string?"
            select="
            replace(
                replace(
                    replace(
                        replace(
                            replace($path,'^(\.(/|$))+','')
                        ,'/(\.(/|$))+','/')
                    ,'/+','/')
                ,'(^|/)\.\.$','$1../')
            ,'^/\.\./$','/')
            "/>
        <xsl:sequence
            select="
            if (matches($normalized,'([^/]|\.[^/]|[^/]\.|[^/]{3,})/\.\./')) then
            pf:normalize-path(replace($normalized,'([^/]|\.[^/]|[^/]\.|[^/]{3,})/\.\./',''))
            else 
            $normalized"
        />
    </xsl:function>

    <xsl:function name="pf:relativize-path" as="xs:string">
        <xsl:param name="path" as="xs:string?"/>
        <xsl:param name="base" as="xs:string?"/>

        <xsl:choose>
            <xsl:when test="starts-with($path,'/')">
                <xsl:variable name="path-segments" select="tokenize($path, '/')"/>
                <xsl:variable name="base-segments" select="tokenize($base, '/')[position()!=last()]"/>
                <xsl:variable name="common-prefix-length"
                    select="
                    (for $i in 1 to count($base-segments) return
                         if($base-segments[$i] eq $path-segments[$i]) then () else $i -1
                    ,count($base-segments))[1]"/>
                <xsl:variable name="upSteps" select="count($base-segments) -$common-prefix-length"/>
                <xsl:sequence
                    select="string-join((
                    for $i in 1 to $upSteps
                        return '..',
                    for $i in 1 to count($path-segments) - $common-prefix-length 
                        return $path-segments[$common-prefix-length + $i]
                    ),'/')"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$path"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="pf:longest-common-uri">
        <xsl:param name="uris"/>
        <xsl:choose>
            <xsl:when test="count($uris)=1">
                <xsl:value-of select="$uris"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="a" select="for $part in tokenize(pf:normalize-uri(replace($uris[1],'/+','SLASH|/')),'/') return replace($part,'SLASH\|$','/')"/>
                <xsl:variable name="b" select="for $part in tokenize(pf:normalize-uri(replace($uris[2],'/+','SLASH|/')),'/') return replace($part,'SLASH\|$','/')"/>
                <xsl:variable name="longest-common" select="for $i in 1 to count($a) return if ($a[$i]=$b[$i]) then $a[$i] else '	'"/>
                <xsl:variable name="longest-common" select="for $i in 1 to count($a) return if ($longest-common[position()&lt;=$i]='	') then () else $longest-common[$i]"/>
                <xsl:variable name="longest-common" select="concat($longest-common[1],if (matches($longest-common[1],'^\w+:/$') and not(matches($longest-common[1],'^file:/'))) then '/' else '',string-join($longest-common[position()&gt;1],''))"/>
                <xsl:value-of select="string-join($longest-common,' | ')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!--
        percent-decode(xs:string URI) - decodes a percent-encoded string
        based on http://www.oxygenxml.com/archives/xsl-list/200911/msg00300.html by James A. Robinson
    -->
    <xsl:function name="pf:percent-decode" as="xs:string?">
        <xsl:param name="in" as="xs:string"/>
        <xsl:sequence select="f:percent-decode($in, ())"/>
    </xsl:function>
    <xsl:function name="f:percent-decode" as="xs:string?">
        <xsl:param name="in" as="xs:string"/>
        <xsl:param name="seq" as="xs:string*"/>
        
        <xsl:variable name="unreserved" as="xs:integer+" select="(45, 46, 48 to 57, 65 to 90, 95, 97 to 122, 126)"/>
        
        <xsl:choose>
            <xsl:when test="not($in)">
                <xsl:sequence select="string-join($seq, '')"/>
            </xsl:when>
            <xsl:when test="starts-with($in, '%')">
                <xsl:choose>
                    <xsl:when test="matches(substring($in, 2, 2), '^[0-9A-Fa-f][0-9A-Fa-f]$')">
                        <xsl:variable name="s" as="xs:string" select="substring($in, 2, 2)"/>
                        <xsl:variable name="d" as="xs:integer" select="f:hex-to-dec(upper-case($s))"/>
                        <xsl:variable name="c" as="xs:string" select="codepoints-to-string($d)"/>
                        <xsl:sequence select="f:percent-decode(substring($in, 4), ($seq, $c))"/>
                    </xsl:when>
                    <xsl:when test="contains(substring($in, 2), '%')">
                        <xsl:variable name="s" as="xs:string" select="substring-before(substring($in, 2), '%')"/>
                        <xsl:sequence select="f:percent-decode(substring($in, 2 + string-length($s)), ($seq, '%', $s))"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="string-join(($seq, $in), '')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="contains($in, '%')">
                <xsl:variable name="s" as="xs:string" select="substring-before($in, '%')"/>
                <xsl:sequence select="f:percent-decode(substring($in, string-length($s)+1), ($seq, $s))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="string-join(($seq, $in), '')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!-- Private function to convert a hexadecimal string into decimal -->
    <xsl:function name="f:hex-to-dec" as="xs:integer">
        <xsl:param name="hex" as="xs:string"/>
        
        <xsl:variable name="len" as="xs:integer" select="string-length($hex)"/>
        <xsl:choose>
            <xsl:when test="$len eq 0">
                <xsl:sequence select="0"/>
            </xsl:when>
            <xsl:when test="$len eq 1">
                <xsl:sequence
                    select="
                    if ($hex eq '0')       then 0
                    else if ($hex eq '1')       then 1
                    else if ($hex eq '2')       then 2
                    else if ($hex eq '3')       then 3
                    else if ($hex eq '4')       then 4
                    else if ($hex eq '5')       then 5
                    else if ($hex eq '6')       then 6
                    else if ($hex eq '7')       then 7
                    else if ($hex eq '8')       then 8
                    else if ($hex eq '9')       then 9
                    else if ($hex = ('A', 'a')) then 10
                    else if ($hex = ('B', 'b')) then 11
                    else if ($hex = ('C', 'c')) then 12
                    else if ($hex = ('D', 'd')) then 13
                    else if ($hex = ('E', 'e')) then 14
                    else if ($hex = ('F', 'f')) then 15
                    else error(xs:QName('f:hex-to-dec'))
                    "
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="
                    (16 * f:hex-to-dec(substring($hex, 1, $len - 1)))
                    + f:hex-to-dec(substring($hex, $len))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!--TODO write tests-->
    <!--
        Taken from: http://stackoverflow.com/questions/13697036/url-query-xml-and-xpath-transform
        This could (should?) be replaced by a native Java-based extension function
    -->
    <xsl:function name="pf:unescape-uri" as="xs:string">
        <xsl:param name="string" as="xs:string?"/>
        <xsl:variable name="cp-base" select="string-to-codepoints('0A')" as="xs:integer+" />
        <xsl:variable name="result">
            
            <xsl:analyze-string select="$string" regex="(%[0-9A-F]{{2}})+" flags="i">
                <xsl:matching-substring>
                    <xsl:variable name="utf8-bytes" as="xs:integer+">
                        <xsl:analyze-string select="." regex="%([0-9A-F]{{2}})" flags="i">
                            <xsl:matching-substring>
                                <xsl:variable name="nibble-pair" select="
                                    for $nibble-char in string-to-codepoints( upper-case(regex-group(1))) return
                                    if ($nibble-char ge $cp-base[2]) then
                                    $nibble-char - $cp-base[2] + 10
                                    else
                                    $nibble-char - $cp-base[1]" as="xs:integer+" />
                                <xsl:sequence select="$nibble-pair[1] * 16 + $nibble-pair[2]" />                
                            </xsl:matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:value-of select="codepoints-to-string( pf:utf8-decode( $utf8-bytes))" />
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:value-of select="." />
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:sequence select="string($result)"/>
    </xsl:function>
    
    <xsl:function name="pf:utf8-decode" as="xs:integer*">
        <xsl:param name="bytes" as="xs:integer*" />
        <xsl:choose>
            <xsl:when test="empty($bytes)" />
            <xsl:when test="$bytes[1] eq 0"><!-- The null character is not valid for XML. -->
                <xsl:sequence select="pf:utf8-decode( remove( $bytes, 1))" />
            </xsl:when>
            <xsl:when test="$bytes[1] le 127">
                <xsl:sequence select="$bytes[1], pf:utf8-decode( remove( $bytes, 1))" />
            </xsl:when>
            <xsl:when test="$bytes[1] lt 224">
                <xsl:sequence select="
                    ((($bytes[1] - 192) * 64) +
                    ($bytes[2] - 128)        ),
                    pf:utf8-decode( remove( remove( $bytes, 1), 1))" />
            </xsl:when>
            <xsl:when test="$bytes[1] lt 240">
                <xsl:sequence select="
                    ((($bytes[1] - 224) * 4096) +
                    (($bytes[2] - 128) *   64) +
                    ($bytes[3] - 128)          ),
                    pf:utf8-decode( remove( remove( remove( $bytes, 1), 1), 1))" />
            </xsl:when>
            <xsl:when test="$bytes[1] lt 248">
                <xsl:sequence select="
                    ((($bytes[1] - 224) * 262144) +
                    (($bytes[2] - 128) *   4096) +
                    (($bytes[3] - 128) *     64) +
                    ($bytes[4] - 128)            ),
                    pf:utf8-decode( $bytes[position() gt 4])" />
            </xsl:when>
            <xsl:otherwise>
                <!-- Code-point valid for XML. -->
                <xsl:sequence select="pf:utf8-decode( remove( $bytes, 1))" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>


</xsl:stylesheet>
