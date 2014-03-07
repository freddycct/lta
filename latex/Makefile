FILE=anomaly
OUTDIR=latex_output
TEXDIR=tex
BIBDIR=$(TEXDIR)

pdf: $(OUTDIR)/$(FILE).pdf
	open $(OUTDIR)/$(FILE).pdf

$(OUTDIR)/$(FILE).pdf: $(OUTDIR)/$(FILE).ps
	ps2pdf -dEmbedAllFonts=true $(OUTDIR)/$(FILE).ps $(OUTDIR)/$(FILE).pdf

$(OUTDIR)/$(FILE).ps: $(OUTDIR)/$(FILE).dvi
	dvips -P pdf -t letter -o $(OUTDIR)/$(FILE).ps $(OUTDIR)/$(FILE).dvi

$(OUTDIR)/$(FILE).bbl: $(TEXDIR)/references.bib
	latex -output-directory=$(OUTDIR) $(TEXDIR)/$(FILE).tex
	env BIBINPUTS=$(BIBDIR) bibtex $(OUTDIR)/$(FILE)

$(OUTDIR)/$(FILE).dvi: $(OUTDIR)/$(FILE).bbl $(TEXDIR)/$(FILE).tex
	latex -output-directory=$(OUTDIR) $(TEXDIR)/$(FILE).tex
	latex -output-directory=$(OUTDIR) $(TEXDIR)/$(FILE).tex

clean:
	rm -f $(OUTDIR)/$(FILE).aux $(OUTDIR)/$(FILE).bbl $(OUTDIR)/$(FILE).blg $(OUTDIR)/$(FILE).log $(OUTDIR)/$(FILE).dvi $(OUTDIR)/$(FILE).ps
