find_compress <- function(f) {
    if (grepl("zip$", f)) {
        file <- sub("\\.zip$", "", f)
        compress <- "zip"
    } else if (grepl("tar\\.gz$", f)) {
        file <- sub("\\.tar\\.gz$", "", f)
        compress <- "tar"
    } else if (grepl("tar$", f)) {
        file <- sub("\\.tar$", "", f)
        compress <- "tar"
    } else {
        file <- f
        compress <- NA_character_
    }
    return(list(file = file, compress = compress))
}

compress_out <- function(cfile, filename, type = c("zip", "tar", "gzip", "bzip2", "xz")) {
    type <- ext <- match.arg(type)
    if (ext %in% c("gzip", "bzip2", "xz")) {
        ext <- paste0("tar")
    }
    if (missing(cfile)) {
        cfile <- paste0(filename, ".", ext)
        cfile2 <- paste0(basename(filename), ".", ext)
    } else {
        cfile2 <- basename(cfile)
    }
    filename <- normalizePath(filename)
    tmp <- tempfile()
    dir.create(tmp)
    on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
    file.copy(from = filename, to = file.path(tmp, basename(filename)), overwrite = TRUE)
    wd <- getwd()
    on.exit(setwd(wd), add = TRUE)
    setwd(tmp)
    if (type == "zip") {
        o <- zip(cfile2, files = basename(filename))
    } else {
        if (type == "tar") {
            type <- "none"
        }
        o <- tar(cfile2, files = basename(filename), compression = type)
    }
    setwd(wd)
    if (o != 0) {
        stop(sprintf("File compression failed for %s!", cfile))
    }
    file.copy(from = file.path(tmp, cfile2), to = cfile, overwrite = TRUE)
    unlink(file.path(tmp, cfile2))
    return(cfile)
}


parse_zip <- function(file, which, ...) {
    d <- tempfile()
    dir.create(d)
    file_list <- utils::unzip(file, list = TRUE)
    if (missing(which)) {
        which <- 1
        if (nrow(file_list) > 1) {
            warning(sprintf("Zip archive contains multiple files. Attempting first file."))
        }
    }
    if (is.numeric(which)) {
        utils::unzip(file, files = file_list$Name[which], exdir = d)
        file.path(d, file_list$Name[which])
    } else {
        if (substring(which, 1,1) != "^") {
            which2 <- paste0("^", which)
        }
        utils::unzip(file, files = file_list$Name[grep(which2, file_list$Name)[1]], exdir = d)
        file.path(d, which)
    }
}

parse_tar <- function(file, which, ...) {
    d <- tempfile()
    dir.create(d)
    on.exit(unlink(d))
    file_list <- utils::untar(file, list = TRUE)
    if (missing(which)) {
        which <- 1
        if (length(file_list) > 1) {
            warning(sprintf("Tar archive contains multiple files. Attempting first file."))
        }
    }
    if (is.numeric(which)) {
        utils::untar(file, files = file_list[which], exdir = d)
        file.path(d, file_list[which])
    } else {
        if (substring(which, 1,1) != "^") {
            which2 <- paste0("^", which)
        }
        utils::untar(file, files = file_list[grep(which2, file_list)[1]], exdir = d)
        file.path(d, which)
    }
}
