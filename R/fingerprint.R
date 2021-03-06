#' Tool: fingerprint
#' 
#' Function which creates a unique fingerprint for a madrat function based on
#' the code of the function itself, of all other madrat functions which feed
#' this function and of all source folders involved in the process.
#' The fingerprint can serve as an indication whether the workflow for the given
#' function has been most likely changed, or not. If all involved source folders
#' and the code of all involved functions remains the same, also the fingerprint
#' will stay the same, otherwise it will change. Hence, it can be used as an
#' indication whether calculations needs to be redone or not.
#' It is used to figure out whether a cache file can be used for further
#' calculations, or whether the calculation should be redone.
#' 
#' @note For a better performance not the files in a folder itself are hashed
#' but the last modified dates of these files.
#' As the fingerprint function only takes madrat-based functions into account
#' (e.g. read-functions or calc-functions), but does ignore all other functions
#' there might be instances in which the workflow actually would lead to 
#' other numbers but the fingerprint stays the same. In a similar fashion it is
#' possible that the fingerprint changes even so the workflow stayed the same 
#' (as the dependencies are sometimes overestimated).
#' 
#' @param name Name of the function to be analyzed
#' @param details Boolean indicating whether additional details in form
#' of an attribute with underlying hash information should be added or not
#' @param graph A madrat graph as returned by \code{\link{getMadratGraph}}. 
#' Will be created with \code{\link{getMadratGraph}} if not provided.
#' @param ... Additional arguments for \code{\link{getMadratGraph}} in case
#' that no graph is provided (otherwise ignored)
#' @return A md5-based fingerprint of all provided sources
#' @author Jan Philipp Dietrich
#' @seealso \code{\link{readSource}}
#' @examples
#' madrat:::fingerprint("toolGetMapping", package="madrat")
#' @importFrom digest digest

fingerprint <- function(name, details=FALSE, graph = NULL, ...) {
  d <- getDependencies(name, direction = "in", self = TRUE, graph = graph, ...)

  fpfu <- d$hash[order(d$call)]
  names(fpfu) <- d$call[order(d$call)]
  
  # handle special requests via flags
  .tmp <- function(x) return(sort(sub(":+",":::",x)))
  ignore  <- .tmp(attr(d,"flags")$ignore)
  monitor <- .tmp(attr(d,"flags")$monitor)
  # if conflicting information is giving (monitor and ignore at the same time,
  # prioritize monitor request)
  ignore <- setdiff(ignore,monitor)
  # add calls from the monitor list which are not already monitored
  fpmo <- fingerprintCall(setdiff(monitor,names(fpfu)))
  # ignore functions mentioned in the ignore list
  fpfu <- fpfu[setdiff(names(fpfu),ignore)]
  sources <- substring(d$func[d$type == "read"], 5) 
  if (length(sources) > 0) sources <- paste0(getConfig("sourcefolder"),"/",sort(sources))
  fpfo <- fingerprintFiles(sources, use.mtime = TRUE)
  fpsf <- fingerprintFiles(attr(d, "mappings"), use.mtime = FALSE)
  fp <- c(fpfu, fpfo, fpsf, fpmo)
  out <- digest(unname(fp), algo = getConfig("hash"))
  if (details) {
    attr(out,"details") <- fp
    vcat(3,"hash components (",out,"):", show_prefix = FALSE)
    for (n in names(fp)) {
      vcat(3,"  ",fp[n]," | ",n, show_prefix = FALSE)
    }
  }
  return(out)
}

fingerprintCall <- function(name) {
  .tmp <- function(x) {
    f <- try(eval(parse(text = x)), silent = TRUE)
    if ("try-error" %in% class(f)) return(NULL)
    return(digest(paste(deparse(f), collapse = " "), algo = getConfig("hash")))
  }
  return(unlist(sapply(name, .tmp)))
}

fingerprintFiles <- function(paths, use.mtime) {
  if (length(paths) == 0) return(NULL)
  paths <- paths[file.exists(paths)]
  if (length(paths) == 0) return(NULL)
  .tmp <- function(f, use.mtime) {
    if (dir.exists(f)) f <- sort(list.files(f,recursive = TRUE, full.names = TRUE))
    if (use.mtime) f <- file.mtime(f)
    return(digest(f, algo = getConfig("hash"), file = !use.mtime))
  }
  out <- sapply(paths, .tmp, use.mtime = use.mtime)
  names(out) <- basename(names(out))
  return(out)
}
