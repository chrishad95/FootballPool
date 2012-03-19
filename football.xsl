<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="html" /> 

	<xsl:template match="/">

		<xsl:for-each select="rss/channel">
			<h2><a href="{link}" target="_blank"><xsl:value-of select="title" /></a></h2>
		</xsl:for-each>
			<xsl:for-each select="rss/channel/item">
				<p>
					<a href="{link}" target="_blank">
						<strong>
							<xsl:value-of select="title" />
						</strong>
					</a>
				</p>
			</xsl:for-each>
	</xsl:template>

</xsl:stylesheet>
