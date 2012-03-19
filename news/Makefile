
targetdir = football/news
prodserver = www.rexfordroad.com
testserver = 192.168.1.12

PRODDIR=/home/chadley/web/football/prod/$(targetdir)
TESTDIR=/home/chadley/web/football/test/$(targetdir)

PRODFTPDIR=$(targetdir)
TESTFTPDIR=$(targetdir)

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

testobjs=$(patsubst %.aspx,$(TESTDIR)/%.aspx,$(wildcard *.aspx)) \
	$(patsubst %.html,$(TESTDIR)/%.html,$(wildcard *.html)) \
	$(patsubst %.js,$(TESTDIR)/%.js,$(wildcard *.js)) \
	$(patsubst %.vb,$(TESTDIR)/%.vb,$(wildcard *.vb)) \
	$(patsubst %.css,$(TESTDIR)/%.css,$(wildcard *.css)) \
	$(patsubst %.xsl,$(TESTDIR)/%.xsl,$(wildcard *.xsl)) \
	$(patsubst %.gif,$(TESTDIR)/%.gif,$(wildcard *.gif)) \
	$(patsubst %.jpg,$(TESTDIR)/%.jpg,$(wildcard *.jpg)) \
	$(patsubst %.png,$(TESTDIR)/%.png,$(wildcard *.png)) \
	$(patsubst %.config,$(TESTDIR)/%.config,$(wildcard *.config))

GET:
	get status

prod: $(PRODDIR) $(prodobjs)
	@echo Target is up to date.

test: $(testobjs)
	@echo Target is up to date.

$(PRODDIR):
	mkdir -p $(PRODDIR)

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


$(TESTDIR)/%.aspx: %.aspx
	devput.pl --hostname $(testserver) -r $< -l $< -d $(TESTFTPDIR)
	cp $< $@

$(TESTDIR)/%.js: %.js
	devput.pl --hostname $(testserver) -r $< -l $< -d $(TESTFTPDIR)
	cp $< $@
	
$(TESTDIR)/%.vb: %.vb
	devput.pl --hostname $(testserver) -r $< -l $< -d $(TESTFTPDIR)
	cp $< $@

$(TESTDIR)/%.xsl: %.xsl
	devput.pl --hostname $(testserver) -r $< -l $< -d $(TESTFTPDIR)
	cp $< $@

$(TESTDIR)/%.config: %.config
	devput.pl --hostname $(testserver) -r $< -l $< -d $(TESTFTPDIR)
	cp $< $@


$(TESTDIR)/%.css: %.css
	devput.pl --hostname $(testserver) -r $< -l $< -d $(TESTFTPDIR)
	cp $< $@


$(TESTDIR)/%.html: %.html
	devput.pl --hostname $(testserver) -r $< -l $< -d $(TESTFTPDIR)
	cp $< $@



$(TESTDIR)/%.jpg: %.jpg
	devput.pl --binary --hostname $(testserver) -r $< -l $< -d $(TESTFTPDIR)
	cp $< $@

$(TESTDIR)/%.gif: %.gif
	devput.pl --binary --hostname $(testserver) -r $< -l $< -d $(TESTFTPDIR)
	cp $< $@


$(TESTDIR)/%.png: %.png
	devput.pl --binary --hostname $(testserver) -r $< -l $< -d $(TESTFTPDIR)
	cp $< $@


