
targetdir = pp
prodserver = www.rexfordroad.com

PRODDIR=/home/chadley/prod_install/$(targetdir)
PRODFTPDIR=$(targetdir)

prodobjs=$(patsubst %.aspx,$(PRODDIR)/%.aspx,$(wildcard *.aspx)) \
	$(patsubst %.html,$(PRODDIR)/%.html,$(wildcard *.html)) \
	$(patsubst %.js,$(PRODDIR)/%.js,$(wildcard *.js)) \
	$(patsubst %.vb,$(PRODDIR)/%.vb,$(wildcard *.vb)) \
	$(patsubst %.css,$(PRODDIR)/%.css,$(wildcard *.css)) \
	$(patsubst %.xsl,$(PRODDIR)/%.xsl,$(wildcard *.xsl)) \
	$(patsubst %.gif,$(PRODDIR)/%.gif,$(wildcard *.gif)) \
	$(patsubst %.jpg,$(PRODDIR)/%.jpg,$(wildcard *.jpg)) \
	$(patsubst %.config,$(PRODDIR)/%.config,$(wildcard *.config))

GET:
	cvs update -l

prod: $(prodobjs)
	@echo Target is up to date.

$(PRODDIR)/%.aspx: %.aspx
	devput.pl --hostname $(prodserver) -r $< -l $< -d $(PRODFTPDIR)
	cp $< $@

$(PRODDIR)/%.html: %.html
	devput.pl --hostname $(prodserver) -r $< -l $< -d $(PRODFTPDIR)
	cp $< $@

$(PRODDIR)/%.jpg: %.jpg
	devput.pl --binary --hostname $(prodserver) -r $< -l $< -d $(PRODFTPDIR)
	cp $< $@


