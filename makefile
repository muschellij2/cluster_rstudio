all: index.html README.md 

index.html: README.Rmd 
	Rscript -e "rmarkdown::render('README.Rmd')"
	mv README.html index.html

README.md: README.Rmd 
	Rscript -e "rmarkdown::render('README.Rmd')"

clean:
	rm -f index.html README.md