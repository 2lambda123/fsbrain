% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/helpers.R
\name{colors.are.grayscale}
\alias{colors.are.grayscale}
\title{Check for the given color strings whether they represent gray scale colors.}
\usage{
colors.are.grayscale(col_strings, accept_col_names = TRUE)
}
\arguments{
\item{col_strings}{vector of RGB(A) color strings, like \code{c("#FFFFFF", ("#FF00FF"))}.}

\item{accept_col_names}{logical, whether to accept color names like 'white'. Disables all sanity checks.}
}
\value{
logical vector
}
\description{
Check for the given color strings whether they represent gray scale colors.
}
\examples{
colors.are.grayscale(c("#FFFFFF", "#FF00FF"));
all((colors.are.grayscale(c("#FFFFFF00", "#ABABABAB"))));

}
