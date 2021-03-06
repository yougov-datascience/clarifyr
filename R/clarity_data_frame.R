#' Return entire clarity object as tibble.
#'
#' Converts the lowest geographic level (typically Precinct) of a
#' \code{clarity_xml} object into a long, 'tidy' dataframe.
#'
#' @param x an object of class \code{clarity_xml}
#' @param ... arguments passed to as.data.frame
#'
#' @return a data frame, with the columns precinct, votes, votetype,
#' candidate, race
#'
#' @importFrom xml2 xml_children xml_find_all xml_attr xml_parents xml_text
#' @importFrom purrr map_dfr
#' @importFrom tibble tibble
#' @importFrom dplyr mutate left_join
#' @export
as.data.frame.clarity_xml <- function(x, ...) {

    co <- xml2::xml_find_all(x, "Contest")
    ts <- xml2::xml_text(xml2::xml_find_all(x, "Timestamp"))
    fd <- purrr::map_dfr(co, function(y) {
        ch <- xml2::xml_find_all(y, "Choice")
        cd <- purrr::map_dfr(ch, function(z) {
            vt <- xml2::xml_find_all(z, "VoteType")
            vd <- purrr::map_dfr(vt, function(a) {
                pt <- xml2::xml_find_all(a, "Precinct")
                tibble::tibble(
                    precinct = xml2::xml_attr(pt, "name"),
                    votes = xml2::xml_attr(pt, "votes"),
                    votetype = xml2::xml_attr(a, "name")
                )
            })
            vd$candidate <- xml2::xml_attr(z, "text")
            vd$party <- xml2::xml_attr(z, "party")
            vd
        })
        cd$race <- xml2::xml_attr(y, "text")
        cd
    })

    # Extract ballots cast from VoterTurnout by precinct
    ballots_cast <- data.frame(
        precinct = xml_attr(
            xml_find_all(x, "VoterTurnout//Precincts/Precinct"), "name"),
        ballots_cast =  as.numeric(
            xml_attr(
                xml_find_all(x, "VoterTurnout//Precincts/Precinct"), "ballotsCast")
        ),
        stringsAsFactors = F
    )

    fd <- dplyr::left_join(fd, ballots_cast, by = "precinct")
    # Timestamp as text (format could vary by state)
    fd$last_updated <- ts

    as.data.frame(fd, ...)
}
