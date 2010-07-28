
targetdir = football
prodserver = 192.168.1.11
devserver = 192.168.1.27

DEVDIR=/home/chadley/dev_install/$(targetdir)
DEVFTPDIR=/j_drive/website/$(targetdir)
PRODFTPDIR=/mnt/web/website/$(targetdir)


prodobjs=$(patsubst %.aspx,$(PRODFTPDIR)/%.aspx,$(wildcard *.aspx)) \
	$(patsubst %.asp,$(PRODFTPDIR)/%.asp,$(wildcard *.asp)) \
	$(patsubst %.js,$(PRODFTPDIR)/%.js,$(wildcard *.js)) \
	$(patsubst %.vb,$(PRODFTPDIR)/%.vb,$(wildcard *.vb)) \
	$(patsubst %.css,$(PRODFTPDIR)/%.css,$(wildcard *.css)) \
	$(patsubst %.asmx,$(PRODFTPDIR)/%.asmx,$(wildcard *.asmx)) \
	$(patsubst %.xsl,$(PRODFTPDIR)/%.xsl,$(wildcard *.xsl)) \
	$(patsubst %.gif,$(PRODFTPDIR)/%.gif,$(wildcard *.gif)) \
	$(patsubst %.config,$(PRODFTPDIR)/%.config,$(wildcard *.config))

devobjs=$(patsubst %.aspx,$(DEVDIR)/%.aspx,$(wildcard *.aspx)) \
	$(patsubst %.asp,$(DEVDIR)/%.asp,$(wildcard *.asp)) \
	$(patsubst %.js,$(DEVDIR)/%.js,$(wildcard *.js)) \
	$(patsubst %.vb,$(DEVDIR)/%.vb,$(wildcard *.vb)) \
	$(patsubst %.css,$(DEVDIR)/%.css,$(wildcard *.css)) \
	$(patsubst %.xsl,$(DEVDIR)/%.xsl,$(wildcard *.xsl)) \
	$(patsubst %.gif,$(DEVDIR)/%.gif,$(wildcard *.gif)) \
	$(patsubst %.config,$(DEVDIR)/%.config,$(wildcard *.config))

GET:
	cvs update -l

dev: GET $(devobjs) 
	@echo Target is up to date.

prod: $(prodobjs)
	@echo Target is up to date.

$(PRODFTPDIR)/%.aspx: %.aspx
	cp $< $@

$(PRODFTPDIR)/%.asmx: %.asmx
	cp $< $@

$(PRODFTPDIR)/%.asp: %.asp
	cp $< $@

$(PRODFTPDIR)/%.css: %.css
	cp $< $@

$(PRODFTPDIR)/%.js: %.js
	cp $< $@

$(PRODFTPDIR)/%.vb: %.vb
	cp $< $@

$(PRODFTPDIR)/%.xsl: %.xsl
	cp $< $@

$(PRODFTPDIR)/%.gif: %.gif
	cp $< $@

$(PRODFTPDIR)/%.config: %.config
	cp $< $@


$(DEVDIR)/%.aspx: %.aspx
	devput.pl $(devserver)  $< $< $(DEVFTPDIR)
	cp $< $@

$(DEVDIR)/%.asp: %.asp
	devput.pl $(devserver)  $< $< $(DEVFTPDIR)
	cp $< $@

$(DEVDIR)/%.css: %.css
	devput.pl $(devserver)  $< $< $(DEVFTPDIR)
	cp $< $@

$(DEVDIR)/%.js: %.js
	devput.pl $(devserver)  $< $< $(DEVFTPDIR)
	cp $< $@

$(DEVDIR)/%.vb: %.vb
	devput.pl $(devserver)  $< $< $(DEVFTPDIR)
	cp $< $@

$(DEVDIR)/%.xsl: %.xsl
	devput.pl $(devserver)  $< $< $(DEVFTPDIR)
	cp $< $@

$(DEVDIR)/%.gif: %.gif
	devput.pl $(devserver)  $< $< $(DEVFTPDIR)
	cp $< $@

$(DEVDIR)/%.config: %.config
	devput.pl $(devserver)  $< $< $(DEVFTPDIR)
	cp $< $@

