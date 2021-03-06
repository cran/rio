#' @importFrom data.table fread
import_delim <-  
  function(file, which = 1, fread = TRUE, sep = "auto", 
           header = "auto", stringsAsFactors = FALSE, data.table = FALSE, ...) {
    if (isTRUE(fread) & !inherits(file, "connection")) {
      arg_reconcile(data.table::fread, input = file, sep = sep, header = header,
                    stringsAsFactors = stringsAsFactors, 
                    data.table = data.table, ..., .docall = TRUE)
    } else {
      if (isTRUE(fread) & inherits(file, "connection")) {
        message("data.table::fread() does not support reading from connections. Using utils::read.table() instead.")
      }
      if (missing(sep) || is.null(sep) || sep == "auto") {
        if (inherits(file, "rio_csv")) {
          sep <- ","
        } else if (inherits(file, "rio_csv2")) {
          sep <- ";"
        } else if (inherits(file, "rio_psv")) {
          sep <- "|"
        } else {
          sep <- "\t"
        }
      }
      if (missing(header) || is.null(header) || header == "auto") {
        header <- TRUE
      }
      arg_reconcile(utils::read.table, file=file, sep=sep, header=header, 
                    stringsAsFactors = stringsAsFactors, ..., .docall = TRUE)
    }
  }


#' @export
.import.rio_dat <- function(file, which = 1, ...) {
    message(sprintf("Ambiguous file format ('.dat'), but attempting 'data.table::fread(\"%s\")'", file))
    import_delim(file = file, ...)
}

#' @export
.import.rio_tsv <- function(file, sep = "auto", which = 1, fread = TRUE, dec = if (sep %in% c("\t", "auto")) "." else ",", ...) {
    import_delim(file = file, sep = sep, fread = fread, dec = dec, ...)
}

#' @export
.import.rio_txt <- function(file, sep = "auto", which = 1, fread = TRUE, dec = if (sep %in% c(",", "auto")) "." else ",", ...) {
    import_delim(file = file, sep = sep, fread = fread, dec = dec, ...)
}

#' @export
.import.rio_csv <- function(file, sep = ",", which = 1, fread = TRUE, dec = if (sep %in% c(",", "auto")) "." else ",", ...) {
    import_delim(file = file, sep = if (sep == ",") "auto" else sep, fread = fread, dec = dec, ...)
}

#' @export
.import.rio_csv2 <- function(file, sep = ";", which = 1, fread = TRUE, dec = if (sep %in% c(";", "auto")) "," else ".", ...) {
    import_delim(file = file, sep = if (sep == ";") "auto" else sep, fread = fread, dec = dec, ...)
}

#' @export
.import.rio_csvy <- function(file, sep = ",", which = 1, fread = TRUE, dec = if (sep %in% c(",", "auto")) "." else ",", yaml = TRUE, ...) {
    import_delim(file = file, sep = if (sep == ",") "auto" else sep, fread = fread, dec = dec, yaml = yaml, ...)
}

#' @export
.import.rio_psv <- function(file, sep = "|", which = 1, fread = TRUE, dec = if (sep %in% c("|", "auto")) "." else ",", ...) {
    import_delim(file = file, sep = if (sep == "|") "auto" else sep, fread = fread, dec = dec, ...)
}

#' @importFrom utils read.fwf
#' @export
.import.rio_fwf <- 
function(file, 
         which = 1, 
         widths, 
         header = FALSE, 
         col.names, 
         comment = "#",
         readr = FALSE, 
         progress = getOption("verbose", FALSE), 
         ...) {
    if (missing(widths)) {
      stop("Import of fixed-width format data requires a 'widths' argument. See ? read.fwf().")
    }
    a <- list(...)
    if (isTRUE(readr)) {
        requireNamespace("readr")
        if (is.null(widths)) {
            if (!missing(col.names)) {
                widths <- readr::fwf_empty(file = file, col_names = col.names)
            } else {
                widths <- readr::fwf_empty(file = file)
            }
            readr::read_fwf(file = file, col_positions = widths, progress = progress, comment = comment, ...)
        } else if (is.numeric(widths)) {
            if (any(widths < 0)) {
                if (!"col_types" %in% names(a)) {
                    col_types <- rep("?", length(widths))
                    col_types[widths < 0] <- "?"
                    col_types <- paste0(col_types, collapse = "")
                }
                if (!missing(col.names)) {
                    widths <- readr::fwf_widths(abs(widths), col_names = col.names)
                } else {
                    widths <- readr::fwf_widths(abs(widths))
                }
                readr::read_fwf(file = file, col_positions = widths, 
                                col_types = col_types, progress = progress, 
                                comment = comment, ...)
            } else {
                if (!missing(col.names)) {
                    widths <- readr::fwf_widths(abs(widths), col_names = col.names)
                } else {
                    widths <- readr::fwf_widths(abs(widths))
                }
                readr::read_fwf(file = file, col_positions = widths, progress = progress, comment = comment, ...)
            }
        } else if (is.list(widths)) {
            if (!c("begin", "end") %in% names(widths)) {
                if (!missing(col.names)) {
                    widths <- readr::fwf_widths(widths, col_names = col.names)
                } else {
                    widths <- readr::fwf_widths(widths)
                }
            }
            readr::read_fwf(file = file, col_positions = widths, progress = progress, comment = comment, ...)
        }
    } else {
        if (!missing(col.names)) {
            read.fwf2(file = file, widths = widths, header = header, col.names = col.names, ...)
        } else {
            read.fwf2(file = file, widths = widths, header = header, ...)
        }
    }
}

#' @export
.import.rio_r <- function(file, which = 1, ...) {
    dget(file = file, ...)
}

#' @export
.import.rio_dump <- function(file, which = 1, envir = new.env(), ...) {
    source(file = file, local = envir)
    if (length(list(...)) > 0) {
      warning("File imported using load. Arguments to '...' ignored.")
    }
    if (missing(which)) {
        if (length(ls(envir)) > 1) {
            warning("Dump file contains multiple objects. Returning first object.")
        }
        which <- 1
    }
    if (is.numeric(which)) {
        get(ls(envir)[which], envir)
    } else {
        get(ls(envir)[grep(which, ls(envir))[1]], envir)
    }
}

#' @export
.import.rio_rds <- function(file, which = 1, ...) {
  if (length(list(...))>0) {
    warning("File imported using readRDS. Arguments to '...' ignored.")
  }
  readRDS(file = file)
}

#' @export
.import.rio_rdata <- function(file, which = 1, envir = new.env(), ...) {
    load(file = file, envir = envir)
    if (length(list(...)) > 0) {
      warning("File imported using load. Arguments to '...' ignored.")
    }
    if (missing(which)) {
        if (length(ls(envir)) > 1) {
            warning("Rdata file contains multiple objects. Returning first object.")
        }
        which <- 1
    }
    if (is.numeric(which)) {
        get(ls(envir)[which], envir)
    } else {
        get(ls(envir)[grep(which, ls(envir))[1]], envir)
    }
}

#' @export
.import.rio_rda <- .import.rio_rdata

#' @export
.import.rio_feather <- function(file, which = 1, ...) {
    requireNamespace("feather")
    feather::read_feather(path = file)
}

#' @export
.import.rio_fst <- function(file, which = 1, ...) {
    requireNamespace("fst")
    fst::read.fst(path = file, ...)
}

#' @export
.import.rio_matlab <- function(file, which = 1, ...) {
    requireNamespace("rmatio")
    rmatio::read.mat(filename = file)
}

#' @importFrom foreign read.dta
#' @importFrom haven read_dta
#' @export
.import.rio_dta <- function(file, haven = TRUE,
                               convert.factors = FALSE,...) {
  if (isTRUE(haven)) {
    arg_reconcile(haven::read_dta, file = file, ..., .docall = TRUE,
                  .finish = standardize_attributes)
  } else {
    out <- arg_reconcile(foreign::read.dta, file = file,
                         convert.factors = convert.factors, ..., .docall = TRUE)
    attr(out, "expansion.fields") <- NULL
    attr(out, "time.stamp") <- NULL
    standardize_attributes(out)
  }
}

#' @importFrom foreign read.dbf
#' @export
.import.rio_dbf <- function(file, which = 1, as.is = TRUE, ...) {
    foreign::read.dbf(file = file, as.is = as.is)
}

#' @importFrom utils read.DIF
#' @export
.import.rio_dif <- function(file, which = 1, ...) {
    utils::read.DIF(file = file, ...)
}

#' @importFrom haven read_sav
#' @importFrom foreign read.spss
#' @export
.import.rio_sav <- function(file, which = 1, haven = TRUE, to.data.frame = TRUE, use.value.labels = FALSE, ...) {
    if (isTRUE(haven)) {
        standardize_attributes(haven::read_sav(file = file))
    } else {
        standardize_attributes(foreign::read.spss(file = file, to.data.frame = to.data.frame,
                                         use.value.labels = use.value.labels, ...))
    }
}

#' @importFrom haven read_sav
#' @export
.import.rio_zsav <- function(file, which = 1, ...) {
    standardize_attributes(haven::read_sav(file = file))
}

#' @importFrom haven read_por
#' @export
.import.rio_spss <- function(file, which = 1, ...) {
    standardize_attributes(haven::read_por(file = file))
}

#' @importFrom haven read_sas
#' @export
.import.rio_sas7bdat <- function(file, which = 1, column.labels = FALSE, ...) {
    standardize_attributes(haven::read_sas(data_file = file, ...))
}

#' @importFrom foreign read.xport
#' @importFrom haven read_xpt
#' @export
.import.rio_xpt <- function(file, which = 1, haven = TRUE, ...) {
    if (isTRUE(haven)) {
        standardize_attributes(haven::read_xpt(file = file, ...))
    } else {
        foreign::read.xport(file = file)
    }
}

#' @importFrom foreign read.mtp
#' @export
.import.rio_mtp <- function(file, which = 1, ...) {
    foreign::read.mtp(file = file, ...)
}

#' @importFrom foreign read.systat
#' @export
.import.rio_syd <- function(file, which = 1, ...) {
    foreign::read.systat(file = file, to.data.frame = TRUE, ...)
}

#' @export
.import.rio_json <- function(file, which = 1, ...) {
    requireNamespace("jsonlite")
    jsonlite::fromJSON(txt = file, ...)
}

#' @importFrom foreign read.epiinfo
#' @export
.import.rio_rec <- function(file, which = 1, ...) {
    foreign::read.epiinfo(file = file, ...)
}

#' @importFrom foreign read.arff
#' @export
.import.rio_arff <- function(file, which = 1, ...) {
    foreign::read.arff(file = file)
}

#' @importFrom readxl read_xls
#' @export
.import.rio_xls <- function(file, which = 1, ...) {
  requireNamespace("readxl")
  arg_reconcile(read_xls, path = file, ..., sheet = which,
                .docall = TRUE,
                .remap = c(colNames = 'col_names', na.strings = 'na'))
}

#' @importFrom readxl read_xlsx
#' @importFrom openxlsx read.xlsx
#' @export
.import.rio_xlsx <- function(file, which = 1, readxl = TRUE, ...) {
    if (isTRUE(readxl)) {
        requireNamespace("readxl")
        arg_reconcile(read_xlsx, path = file, ..., sheet = which,
                      .docall = TRUE,
                      .remap = c(colNames = 'col_names', na.strings = 'na'))
    } else {
        requireNamespace("openxlsx")
        arg_reconcile(read.xlsx, xlsxFile = file, ..., sheet = which,
        .docall = TRUE,
        .remap = c(col_names = 'colNames', na = 'na.strings'))
    }
}

#' @importFrom utils read.fortran
#' @export
.import.rio_fortran <- function(file, which = 1, style, ...) {
    if (missing(style)) {
        stop("Import of Fortran format data requires a 'style' argument. See ? utils::read.fortran().")
    }
    utils::read.fortran(file = file, format = style, ...)
}

#' @export
.import.rio_ods <- function(file, which = 1, header = TRUE, ...) {
    requireNamespace("readODS")
    "read_ods" <- readODS::read_ods
    a <- list(...)
    if ("sheet" %in% names(a)) {
        which <- a[["sheet"]]
        a[["sheet"]] <- NULL
    }
    if ("col_names" %in% names(a)) {
        header <- a[["col_names"]]
        a[["col_names"]] <- NULL
    }
    frml <- formals(readODS::read_ods)
    unused <- setdiff(names(a), names(frml))
    if ("path" %in% names(a)) {
        unused <- c(unused, 'path')
        a[["path"]] <- NULL
    }
    if (length(unused)>0) {
        warning("The following arguments were ignored for read_ods:\n",
                paste(unused, collapse = ', '))
    }
    a <- a[intersect(names(a), names(frml))]
    do.call("read_ods",
            c(list(path = file, sheet = which, col_names = header),a))
}

#' @importFrom utils type.convert
#' @export
.import.rio_xml <- function(file, which = 1, stringsAsFactors = FALSE, ...) {
    requireNamespace("xml2")
    x <- xml2::as_list(xml2::read_xml(unclass(file)))[[1L]]
    d <- do.call("rbind", c(lapply(x, unlist)))
    row.names(d) <- 1:nrow(d)
    d <- as.data.frame(d, stringsAsFactors = stringsAsFactors)
    tc2 <- function(x) {
        out <- utils::type.convert(x)
        if (is.factor(out)) {
            x
        } else {
            out
        }
    }
    if (!isTRUE(stringsAsFactors)) {
        d[] <- lapply(d, tc2)
    } else {
        d[] <- lapply(d, utils::type.convert)
    }
    d
}

# This is a helper function for .import.rio_html
extract_html_row <- function(x, empty_value) {
  # Both <th> and <td> are valid for table data, and <th> may be used when
  # there is an accented element (e.g. the first row of the table)
  to_extract <- x[names(x) %in% c("th", "td")]
  # Insert a value into cells that eventually will become empty cells (or they
  # will be dropped and the table will not be generated).  Note that this more
  # complex code for finding the length is required because of html like
  # <td><br/></td>
  unlist_length <-
    sapply(
      lapply(to_extract, unlist),
      length
    )
  to_extract[unlist_length == 0] <- list(empty_value)
  unlist(to_extract)
}

#' @importFrom utils type.convert
#' @export
.import.rio_html <- function(file, which = 1, stringsAsFactors = FALSE, ..., empty_value = "") {
    # find all tables
    tables <- xml2::xml_find_all(xml2::read_html(unclass(file)), ".//table")
    if (which > length(tables)) {
        stop(paste0("Requested table exceeds number of tables found in file (", length(tables),")!"))
    }
    x <- xml2::as_list(tables[[which]])
    if ("tbody" %in% names(x)) {
        # Note that "tbody" may be specified multiple times in a valid html table
        x <- unlist(x[names(x) %in% "tbody"], recursive=FALSE)
    }
    # loop row-wise over the table and then rbind()
    ## check for table header to use as column names
    col_names <- NULL
    if ("th" %in% names(x[[1]])) {
      col_names <- extract_html_row(x[[1]], empty_value=empty_value)
      # Drop the first row since column names have already been extracted from it.
      x <- x[-1]
    }
    out <- do.call("rbind", lapply(x, extract_html_row, empty_value=empty_value))
    colnames(out) <-
      if (is.null(col_names)) {
        paste0("V", seq_len(ncol(out)))
      } else {
        col_names
      }
    out <- as.data.frame(out, ..., stringsAsFactors = stringsAsFactors)
    # set row names
    rownames(out) <- 1:nrow(out)
    # type.convert() to numeric, etc.
    out[] <- lapply(out, utils::type.convert, as.is = TRUE)
    out
}

#' @export
.import.rio_yml <- function(file, which = 1, stringsAsFactors = FALSE, ...) {
    requireNamespace("yaml")
    as.data.frame(yaml::read_yaml(file, ...), stringsAsFactors = stringsAsFactors)
}

#' @export
.import.rio_eviews <- function(file, which = 1, ...) {
    requireNamespace("hexView")
    hexView::readEViews(file, ...)
}

#' @export
.import.rio_clipboard <- function(file = "clipboard", which = 1, header = TRUE, sep = "\t", ...) {
    requireNamespace("clipr")
    clipr::read_clip_tbl(x = clipr::read_clip(), header = header, sep = sep, ...)
}

#' @export
.import.rio_pzfx <- function(file, which=1, ...) {
    requireNamespace("pzfx")
    pzfx::read_pzfx(path=file, table=which, ...)
}

#' @export
.import.rio_parquet <- function(file, which = 1, as_data_frame = TRUE, ...) {
    requireNamespace("arrow")
    arrow::read_parquet(file = file, as_data_frame = TRUE, ...)
}
