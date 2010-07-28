
targetdir = football
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
	$(patsubst %.png,$(PRODDIR)/%.png,$(wildcard *.png)) \
	$(patsubst %.config,$(PRODDIR)/%.config,$(wildcard *.config))

GET:
	cvs update -l

prod: $(prodobjs)
	@echo Target is up to date.

$(PRODDIR)/%.aspx: %.aspx
	devput.pl --hostname $(prodserver) -r $< -l $< -d $(PRODFTPDIR)
	cp $< $@

$(PRODDIR)/%.js: %.js
	devput.pl --hostname $(prodserver) -r $< -l $< -d $(PRODFTPDIR)
	cp $< $@
	
$(PRODDIR)/%.vb: %.vb
	devput.pl --hostname $(prodserver) -r $< -l $< -d $(PRODFTPDIR)
	cp $< $@

$(PRODDIR)/%.xsl: %.xsl
	devput.pl --hostname $(prodserver) -r $< -l $< -d $(PRODFTPDIR)
	cp $< $@

$(PRODDIR)/%.config: %.config
	devput.pl --hostname $(prodserver) -r $< -l $< -d $(PRODFTPDIR)
	cp $< $@


$(PRODDIR)/%.css: %.css
	devput.pl --hostname $(prodserver) -r $< -l $< -d $(PRODFTPDIR)
	cp $< $@


$(PRODDIR)/%.html: %.html
	devput.pl --hostname $(prodserver) -r $< -l $< -d $(PRODFTPDIR)
	cp $< $@



$(PRODDIR)/%.jpg: %.jpg
	devput.pl --binary --hostname $(prodserver) -r $< -l $< -d $(PRODFTPDIR)
	cp $< $@

$(PRODDIR)/%.gif: %.gif
	devput.pl --binary --hostname $(prodserver) -r $< -l $< -d $(PRODFTPDIR)
	cp $< $@


$(PRODDIR)/%.png: %.png
	devput.pl --binary --hostname $(prodserver) -r $< -l $< -d $(PRODFTPDIR)
	cp $< $@


