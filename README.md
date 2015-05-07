# rio: A Swiss-army knife for data I/O #

The aim of **rio** is to make data file I/O in R as easy as possible by implementing three simple functions in Swiss-army knife style:

 - `export` and `import` provide a painless data I/O experience by automatically choosing the appropriate data read or write function based on file extension
 - `convert` wraps `import` and `export` to allow the user to easily convert between file formats (thus providing a FOSS replacement for programs like [Stat/Transfer](https://www.stattransfer.com/) or [Sledgehammer](http://www.openmetadata.org/site/?page_id=1089))

The core advantage of **rio** is that it makes assumptions that the user is probably willing to make. Five of these are important:

 1. **rio** uses the file extension of a file name to determine what kind of file it is. This is the same logic used by Windows OS, for example, in determining what application is associated with a given file type. By taking away the need to manually match a file type (which a beginner may not recognize) to a particular import or export function, **rio** allows almost all common data formats to be read with the same function. [The **reader** package](http://cran.r-project.org/web/packages/reader/index.html) does something similar for reading certain text formats and R binary files and [**io**](http://cran.r-project.org/web/packages/io/index.html) offers a set of methods for reading and writing to file formats defined by that package, but **rio** supports a much broader set of commonly used file types for import and export.
 2. For text-delimited file formats, the package uses `data.table::fread` to automatically determine the file format regardless of the extension. So, a CSV that is actually tab-separated will still be correctly read in. 
 3. When importing tabular data (CSV, TSV, etc.), **rio** does not convert strings to factors.
 4. The data import functions in base R only support import of local files or web-based data from websites serving HTTP, not SSL (HTTPS). For example, data stored on GitHub as publicly visible files cannot be read directly into R without either manually downloading them or reading them in via **RCurl** or **httr**. `import` supports HTTPS automatically.
 5. `import` reads from single-file .zip and .tar archives automatically, without the need to explicitly decompress them first.
 
The package also wraps a variety of faster, more stream-lined I/O packages than those provided by base R or the **foreign** package. Namely, the package uses [**haven**](https://github.com/hadley/haven) for reading and writing SAS, Stata, and SPSS files, [the `fread` function from **data.table**](https://github.com/Rdatatable/data.table) for intuitive import of text-delimited and fixed-width file formats, and [**readxl**](https://github.com/hadley/readxl) for reading from Excel workbooks.

## Supported file formats ##

**rio** supports a variety of different file formats for import and export.

| Format | Import | Export |
| ------ | ------ | ------ |
| Tab-separated data (.tsv) | Yes | Yes |
| Comma-separated data (.csv) | Yes | Yes |
| Pipe-separated data (.psv) | Yes | Yes |
| Fixed-width format data (.fwf) | Yes | Yes |
| Serialized R objects (.rds) | Yes | Yes |
| Saved R objects (.RData) | Yes | Yes |
| JSON (.json) | Yes | Yes |
| Stata (.dta) | Yes | Yes |
| SPSS and SPSS portable | Yes (.sav and .por) | Yes (.sav only) |
| "XBASE" database files (.dbf) | Yes | Yes |
| Excel (.xls) | Yes |  |
| Excel (.xlsx) | Yes | Yes |
| Weka Attribute-Relation File Format (.arff) | Yes | Yes |
| R syntax (.R) | Yes | Yes |
| Shallow XML documents (.xml) | Yes | Yes |
| SAS and SAS XPORT | Yes (.sas7bdat and .xpt) |  |
| Minitab (.mtp) | Yes |  |
| Epiinfo (.rec) | Yes |  |
| Systat (.syd) | Yes |  |
| Data Interchange Format (.dif) | Yes |  |
| OpenDocument Spreadsheet  (.ods) | Yes |  |
| Fortran data (no recognized extension) | Yes |  |
| Clipboard (default is tsv) | Yes (Mac and Windows) | Yes (Mac and Windows) |

Additionally, any format that is not supported by **rio** but that has a known R implementation will produce an informative error message pointing to a package and import or export function. Unrecognized formats will yield a simple "Unrecognized file format" error.

## Package Installation ##

The package is available on [CRAN](http://cran.r-project.org/web/packages/rio/) and can be installed directly in R using:

```R
install.packages("rio")
```

The latest development version on GitHub can be installed using **devtools**:

```R
if(!require("devtools")){
    install.packages("devtools")
    library("devtools")
}
install_github("leeper/rio")
```

[![Build Status](https://travis-ci.org/leeper/rio.png?branch=master)](https://travis-ci.org/leeper/rio)
![Downloads](http://cranlogs.r-pkg.org/badges/rio)

## Examples ##

Because **rio** is meant to streamline data I/O, the package is extremely easy to use. Here are some examples of reading, writing, and converting data files.

### Export ###

Exporting data is handled with one function, `export`:


```r
library("rio")

export(mtcars, "mtcars.csv") # comma-separated values
export(mtcars, "mtcars.rds") # R serialized
export(mtcars, "mtcars.sav") # SPSS
```

### Import ###

Importing data is handled with one function, `import`:


```r
x <- import("mtcars.csv")
y <- import("mtcars.rds")
z <- import("mtcars.sav")

# confirm data match
all.equal(x, y, check.attributes = FALSE)
```

```
## [1] TRUE
```

```r
all.equal(x, z, check.attributes = FALSE)
```

```
## [1] TRUE
```

Note: Because of inconsistencies across underlying packages, the data.frame returned by `import` might vary slightly (in variable classes and attributes) depending on file type.

### Convert ###

The `convert` function links `import` and `export` by constructing a dataframe from the imported file and immediately writing it back to disk. `convert` invisibly returns the file name of the exported file, so that it can be used to programmatically access the new file.


```r
convert("mtcars.sav", "mtcars.dta")
```

It is also possible to use **rio** on the command-line by calling `Rscript` with the `-e` (expression) argument. For example, to convert a file from Stata (.dta) to comma-separated values (.csv), simply do the following:

```
Rscript -e "rio::convert('iris.dta', 'iris.csv')"
```



