#' @docType package
#' @name rio
#' @title A Swiss-Army Knife for Data I/O
#' @description The aim of rio is to make data file input and output as easy as possible. [export()] and [import()] serve as a Swiss-army knife for painless data I/O for data from almost any file format by inferring the data structure from the file extension, natively reading web-based data sources, setting reasonable defaults for import and export, and relying on efficient data import and export packages. An additional convenience function, [convert()], provides a simple method for converting between file types.
#'
#' Note that some of rio's functionality is provided by \sQuote{Suggests} dependendencies, meaning they are not installed by default. Use [install_formats()] to make sure these packages are available for use.
#'
#' @examples
#' # export
#' library("datasets")
#' export(mtcars, csv_file <- tempfile(fileext = ".csv")) # comma-separated values
#' export(mtcars, rds_file <- tempfile(fileext = ".rds")) # R serialized
#' export(mtcars, sav_file <- tempfile(fileext = ".sav")) # SPSS
#'
#' # import
#' x <- import(csv_file)
#' y <- import(rds_file)
#' z <- import(sav_file)
#'
#' # convert sav (SPSS) to dta (Stata)
#' convert(sav_file, dta_file <- tempfile(fileext = ".dta"))
#'
#' # cleanup
#' unlink(c(csv_file, rds_file, sav_file, dta_file))
#'
#' @references
#'   [datamods](https://cran.r-project.org/package=datamods) provides Shiny modules for importing data via `rio`.
#'
#'   [GREA](https://github.com/Stan125/GREA) provides an RStudio add-in to import data using rio.
#' @seealso [import()], [import_list()], [export()], [export_list()], [convert()], [install_formats()]
"_PACKAGE"
