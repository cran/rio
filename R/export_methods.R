export_delim <- function(file, x, fwrite = lifecycle::deprecated(), sep = "\t", row.names = FALSE,
                         col.names = TRUE, append = FALSE, ...) {
    if (lifecycle::is_present(fwrite)) {
        lifecycle::deprecate_warn(when = "0.5.31", what = "export(fwrite)", details = "plain text files will always be written with `data.table::fwrite`. The parameter `fwrite` will be dropped in v2.0.0.")
    }
    .docall(data.table::fwrite, ...,
            args = list(x = x, file = file, sep = sep, row.names = row.names,
                        col.names = ifelse(append, FALSE, col.names), append = append))
}

#' @export
.export.rio_txt <- function(file, x, ...) {
    export_delim(x = x, file = file, ...)
}

#' @export
.export.rio_tsv <- function(file, x, ...) {
    export_delim(x = x, file = file, ...)
}

#' @export
.export.rio_csv <- function(file, x, sep = ",", dec = ".", ...) {
    export_delim(x = x, file = file, sep = sep, dec = dec, ...)
}

#' @export
.export.rio_csv2 <- function(file, x, sep = ";", dec = ",", ...) {
    export_delim(x = x, file = file, sep = sep, dec = dec, ...)
}

#' @export
.export.rio_csvy <- function(file, x, sep = ",", dec = ".", yaml = TRUE, ...) {
    export_delim(x = x, file = file, sep = sep, dec = dec, yaml = TRUE, ...)
}

#' @export
.export.rio_psv <- function(file, x, ...) {
    export_delim(x = x, file = file, sep = "|", ...)
}

#' @export
.export.rio_fwf <- function(file, x, verbose = getOption("verbose", FALSE), sep = "", row.names = FALSE, quote = FALSE, col.names = FALSE, digits = getOption("digits", 7), ...) {
    dat <- lapply(x, function(col) {
        if (is.character(col)) {
            col <- as.numeric(as.factor(col))
        } else if (is.factor(col)) {
            col <- as.integer(col)
        }
        if (is.integer(col)) {
            return(sprintf("%i", col))
        }
        if (is.numeric(col)) {
            decimals <- strsplit(as.character(col), ".", fixed = TRUE)
            m1 <- max(nchar(unlist(lapply(decimals, `[`, 1))), na.rm = TRUE)
            decimals_2 <- unlist(lapply(decimals, `[`, 2))
            decimals_2_nchar <- nchar(decimals_2[!is.na(decimals_2)])
            if (length(decimals_2_nchar)) {
                m2 <- max(decimals_2_nchar, na.rm = TRUE)
            } else {
                m2 <- 0
            }
            if (!is.finite(m2)) {
                m2 <- digits
            }
            return(formatC(sprintf(fmt = paste0("%0.", m2, "f"), col), width = (m1 + m2 + 1)))
        } else if (is.logical(col)) {
            return(sprintf("%i", col))
        }
    })
    dat <- do.call(cbind, dat)
    n <- nchar(dat[1, ]) + c(rep(nchar(sep), ncol(dat) - 1), 0)
    col_classes <- vapply(x, class, character(1))
    col_classes[col_classes == "factor"] <- "integer"
    dict <- cbind.data.frame(
        variable = names(n),
        class = col_classes,
        width = unname(n),
        columns = paste0(c(1, cumsum(n) + 1)[-length(n)], "-", cumsum(n)),
        stringsAsFactors = FALSE
    )
    if (isTRUE(verbose)) {
        message("Columns:")
        message(paste0(utils::capture.output(dict), collapse = "\n"))
        if (sep == "") {
            message(
                "\nRead in with:\n",
                'import("', file, '",\n',
                "       widths = c(", paste0(n, collapse = ","), "),\n",
                '       col.names = c("', paste0(names(n), collapse = '","'), '"),\n',
                '       colClasses = c("', paste0(col_classes, collapse = '","'), '"))\n',
                domain = NA
            )
        }
    }
    .write_as_utf8(paste0("#", utils::capture.output(utils::write.csv(dict, row.names = FALSE, quote = FALSE))), file = file, sep = "\n")
    .docall(utils::write.table, ...,
            args = list(x = dat, file = file, append = TRUE, row.names = row.names, sep = sep, quote = quote,
                        col.names = col.names))
}

#' @export
.export.rio_r <- function(file, x, ...) {
    .docall(dput, ..., args = list(x = x, file = file))
}

#' @export
.export.rio_dump <- function(file, x, ...) {
    dump(as.character(substitute(x)), file = file)
}

#' @export
.export.rio_rds <- function(file, x, ...) {
    .docall(saveRDS, ..., args = list(object = x, file = file))
}

#' @export
.export.rio_rdata <- function(file, x, ...) {
    if (isFALSE(is.data.frame(x)) && isFALSE(is.list(x)) && isFALSE(is.environment(x)) && isFALSE(is.character(x))) {
        stop("'x' must be a data.frame, list, or environment")
    }
    if (is.data.frame(x)) {
        return(save(x, file = file, ...))
    }
    if (is.list(x)) {
        e <- as.environment(x)
        return(save(list = names(x), file = file, envir = e, ...))
    }
    if (is.environment(x)) {
        return(save(list = ls(x), file = file, envir = x, ...))
    }
    return(save(list = x, file = file, ...)) ## characters, but is this doing what it does?
}

#' @export
.export.rio_rda <- .export.rio_rdata

#' @export
.export.rio_feather <- function(file, x, ...) {
    .docall(arrow::write_feather, ..., args = list(x = x, sink = file))
}

#' @export
.export.rio_fst <- function(file, x, ...) {
    .check_pkg_availability("fst")
    .docall(fst::write.fst, ..., args = list(x = x, path = file))
}

#' @export
.export.rio_matlab <- function(file, x, ...) {
    .check_pkg_availability("rmatio")
    .docall(rmatio::write.mat, ..., args = list(object = x, filename = file))
}

#' @export
.export.rio_sav <- function(file, x, ...) {
    x <- restore_labelled(x)
    .docall(haven::write_sav, ..., args = list(data = x, path = file))
}

#' @export
.export.rio_zsav <- function(file, x, compress = TRUE, ...) {
    x <- restore_labelled(x)
    .docall(haven::write_sav, ..., args = list(data = x, path = file, compress = compress))
}

#' @export
.export.rio_dta <- function(file, x, ...) {
    x <- restore_labelled(x)
    .docall(haven::write_dta, ..., args = list(data = x, path = file))
}

#' @export
.export.rio_sas7bdat <- function(file, x, ...) {
    x <- restore_labelled(x)
    .docall(haven::write_sas, ..., args = list(data = x, path = file))
}

#' @export
.export.rio_xpt <- function(file, x, ...) {
    x <- restore_labelled(x)
    .docall(haven::write_xpt, ..., args = list(data = x, path = file))
}

#' @export
.export.rio_dbf <- function(file, x, ...) {
    .docall(foreign::write.dbf, ..., args = list(dataframe = x, file = file))
}

#' @export
.export.rio_json <- function(file, x, ...) {
    .check_pkg_availability("jsonlite")
    .write_as_utf8(.docall(jsonlite::toJSON, ..., args = list(x = x)), file = file)
}

#' @export
.export.rio_arff <- function(file, x, ...) {
    .docall(foreign::write.arff, ..., args = list(x = x, file = file))
}

#' @export
.export.rio_xlsx <- function(file, x, ...) {
    .docall(writexl::write_xlsx, ..., args = list(x = x, path = file))
}

#' @export
.export.rio_ods <- function(file, x, ...) {
    .check_pkg_availability("readODS")
    .docall(readODS::write_ods, ..., args = list(x = x, path = file))
}

#' @export
.export.rio_fods <- function(file, x, ...) {
    .check_pkg_availability("readODS")
    .docall(readODS::write_fods, ..., args = list(x = x, path = file))
}

#' @export
.export.rio_html <- function(file, x, ...) {
    .check_pkg_availability("xml2")
    html <- xml2::read_html("<!doctype html><html><head>\n<title>R Exported Data</title>\n</head><body>\n</body>\n</html>")
    bod <- xml2::xml_children(html)[[2]]
    if (is.data.frame(x)) {
        x <- list(x)
    }
    for (i in seq_along(x)) {
        x[[i]][] <- lapply(x[[i]], as.character)

        x[[i]][] <- lapply(x[[i]], escape_xml)
        names(x[[i]]) <- escape_xml(names(x[[i]]))
        tab <- xml2::xml_add_child(bod, "table")
        # add header row
        invisible(xml2::xml_add_child(tab, xml2::read_xml(paste0(twrap(paste0(twrap(names(x[[i]]), "th"), collapse = ""), "tr"), "\n"))))
        # add data
        for (j in seq_len(nrow(x[[i]]))) {
            xml2::xml_add_child(tab, xml2::read_xml(paste0(twrap(paste0(twrap(unlist(x[[i]][j, , drop = TRUE]), "td"), collapse = ""), "tr"), "\n")))
        }
    }
    .docall(xml2::write_xml, ..., args = list(x = html, file = file))
}

#' @export
.export.rio_xml <- function(file, x, ...) {
    .check_pkg_availability("xml2")
    xml <- xml2::read_xml(paste0("<", as.character(substitute(x)), ">\n</", as.character(substitute(x)), ">\n"))
    att <- attributes(x)[!names(attributes(x)) %in% c("names", "row.names", "class")]
    for (a in seq_along(att)) {
        xml2::xml_attr(xml, names(att)[a]) <- att[[a]]
    }
    # remove illegal characters
    row.names(x) <- escape_xml(row.names(x))
    colnames(x) <- escape_xml(colnames(x), ".")
    x[] <- lapply(x, escape_xml)
    # add data
    for (i in seq_len(nrow(x))) {
        thisrow <- xml2::xml_add_child(xml, "Observation")
        xml2::xml_attr(thisrow, "row.name") <- row.names(x)[i]
        for (j in seq_along(x)) {
            xml2::xml_add_child(thisrow, xml2::read_xml(paste0(twrap(x[i, j, drop = TRUE], names(x)[j]), "\n")))
        }
    }

    .docall(xml2::write_xml, ..., args = list(x = xml, file = file))
}

#' @export
.export.rio_yml <- function(file, x, ...) {
    .check_pkg_availability("yaml")
    .docall(yaml::write_yaml, ..., args = list(x = x, file = file))
}

#' @export
.export.rio_clipboard <- function(file, x, row.names = FALSE, col.names = TRUE, sep = "\t", ...) {
    .check_pkg_availability("clipr")
    .docall(clipr::write_clip, ..., args = list(content = x, row.names = row.names, col.names = col.names, sep = sep))
}

#' @export
.export.rio_pzfx <- function(file, x, ..., row_names = FALSE) {
    .check_pkg_availability("pzfx")
    .docall(pzfx::write_pzfx, ..., args = list(x = x, path = file, row_names = row_names))
}

#' @export
.export.rio_parquet <- function(file, x, ...) {
    .docall(nanoparquet::write_parquet, ..., args = list(x = x, file = file))
}

#' @export
.export.rio_qs <- function(file, x, ...) {
    .check_pkg_availability("qs")
    .docall(qs::qsave, ..., args = list(x = x, file = file))
}
