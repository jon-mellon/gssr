#' @importFrom curl curl_download
NULL

#' @importFrom tibble tibble
NULL

#' @importFrom fs file_copy path
NULL

#' @importFrom haven read_stata
NULL

#' @importFrom magrittr %>%
#' @export
magrittr::`%>%`


#' @keywords internal
"_PACKAGE"

# The following block is used by usethis to automatically manage
# roxygen namespace tags. Modify with care!
## usethis namespace: start
## usethis namespace: end
NULL


#' @title fmt_nc
#' @description Format fmt_nc in df
#' @param x df
#' @return formatted string
#' @details use in fn documentation
#' @examples
#' \dontrun{
#' if(interactive()){
#'  #EXAMPLE1
#'  }
#' }
#' @rdname fmt_nc
#' @author Kieran Healy
fmt_nc <- function(x){
  prettyNum(ncol(x), big.mark=",", scientific=FALSE)
}


#' @title fmt_nr
#' @description Format fmt_nr in df
#' @param x df
#' @return formatted string
#' @details use in fn documentation
#' @examples
#' \dontrun{
#' if(interactive()){
#'  #EXAMPLE1
#'  }
#' }
#' @author Kieran Healy
fmt_nr <- function(x){
  prettyNum(nrow(x), big.mark=",", scientific=FALSE)
}


##' Get marginal summaries for a GSS variable or variables
##'
##' Codebook summaries from the \code{gss_doc} or \code{gss_panel_docw} objects
##'
##' @title Get marginal summaries for a GSS variable or variables
##' @param varnames The (categorical) variable or variables you want
##'     to see marginals for. Can be a character string or a character
##'     vector.
##' @param data The codebook data frame, by default \code{gss_doc}, or alternatively the wide panel documentation in \code{gss_panel_docw}.
##' @param margin Which margin. Not needed for \code{gss_doc}, but one of \code{marginals_1}, \code{marginals_2}, or \code{marginals_2} when \code{data} is \code{gss_panel_docw}.
##' @return A tibble of marginal distributions from the GSS codebook
##' @author Kieran Healy
##' @examples
##' \donttest{
##' data(gss_doc)
##' gss_get_marginals(varnames = "race")
##'
##' gss_get_marginals(varnames = c("race", "gender", "fefam"))
##' }
##' @export
gss_get_marginals <- function(varnames = "id", data = gss_doc, margin = marginals) {
  dplyr::filter(data, id %in% varnames) %>%
    dplyr::select(id, {{ margin }}) %>%
    dplyr::rename(variable = id) %>%
    tidyr::unnest(cols = c({{ margin }})) %>%
    dplyr::mutate(n = stringr::str_remove_all(n, ","),
                  n = as.integer(n))
  }

##' Property information for a GSS variable or variables
##'
##' Returns the properties of a GSS variable as given in the codebook,
##'     typically the Data Type, Missing Data Codes, and Record/Column
##'     location.
##'
##' @title Property information for a GSS variable or variables
##' @param varnames The variable or variables you want
##'     to see properties for. Can be a character string or a character
##'     vector.
##' @param data The codebook data frame, by default \code{gss_doc}
##' @param props Which properties. Not needed for \code{gss_doc}, but one of \code{properties_1}, \code{properties_2}, or \code{properties_3} when \code{data} is \code{gss_panel_docw}.
##' @return A tibble of the properties for each variable
##' @author Kieran Healy
##' @examples
##' \donttest{
##' data(gss_doc)
##' gss_get_props(varnames = "age")
##'
##' gss_get_props(varnames = c("age", "race", "fefam"))
##' }
##' @export
gss_get_props <- function(varnames = "id", data = gss_doc, props = properties) {
  dplyr::filter(data, id %in% varnames) %>%
    dplyr::select(id, {{ props }}) %>%
    dplyr::rename(variable = id) %>%
    tidyr::unnest(cols = c({{ props }}))
}

#' Get whether a question was asked
#'
#' @param x The GSS variable being assessed
#'
#' @return TRUE or FALSE depending on whether it passes the test
#'
#' @examples
#' # See gss_which_years()
get_asked <- function(x) {
  ifelse(length(unique(x)) == 1, FALSE, TRUE)
}


#' What years was a particular question asked in the GSS?
#'
#' Use `gss_get_years()` to see which years a particular question was
#' asked in the GSS.
#'
#' @param data A tibble of data, usually gss_all
#' @param variable The variable or variables we want to check. Provide variables in tidyselect style, i.e. unquoted, and for multiple variables enclose unquoted in c()
#'
#' @return A tibble showing whether the question or questions were asked in each of the GSS years
#' @export
#'
#' @examples
#' \donttest{
#' data(gss_all)
#' gss_all %>%
#'   gss_which_years(fefam)
#'
#' gss_all %>%
#'   gss_which_years(c(industry, indus80, wrkgovt, commute))
#' }
gss_which_years <- function(data, variable) {
  data %>%
    dplyr::select(year, {{ variable }}) %>%
    dplyr::group_by(year) %>%
    dplyr::summarize(dplyr::across(dplyr::everything(), get_asked), .groups = "drop")
}



#' Download GSS data file for a single year from NORC
#'
#' Use `gss_get_yr()` to get GSS data for a single year from
#' NORC's GSS website (where it is available as a zipped Stata file)
#' and put it directly into a tibble.
#'
#' @param year The desired GSS survey year, as a number (i.e., not in quotes). Defaults to 2021.
#' @param url Location of the file. Defaults to the current NORC URL
#' @param fname Non-year filename component. Defaults to '_stata'. Usually should not be changed.
#' @param ext File name extension. Defaults to 'zip'. Usually should not be changed.
#' @param dest If `save_file` is "y", the directory to put the file in. Defaults to `data-raw` in current directory.
#' @param save_file Save the data file as well as loading it as an object. Defaults to 'n'.
#'
#' @return A tibble with the requested year's GSS data.
#' @export
#'
#' @examples
##' \donttest{
##' gss80 <- gss_get_yr(1980)
##' }

gss_get_yr <- function(year = 2021,
                       url = "http://www.gss.norc.org/documents/stata/",
                       fname = "_stata",
                       ext = "zip",
                       dest = "data-raw/",
                       save_file = c("n", "y")) {

  year <- match.arg(as.character(year),
                    choices = as.character(c(1972:1978, 1980, 1982:1991,
                                             1993, seq(1994, 2018, 2), 2021)))
  save_file <- match.arg(save_file)

  local_fname <- paste0(year, fname)
  target <- paste0(url, year, fname, ".", ext)
  message("Fetching: ", target)

  destination <- fs::path(here::here("data-raw/"), local_fname, ext = ext)

  tf <- tempfile(fileext = ext)
  curl_download(target, tf)

  switch(save_file,
         y = fs::file_copy(tf, destination),
         n = NULL)

  haven::read_stata(tf)

}

