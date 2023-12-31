% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/geodesic.R
\name{geod.patches.color.overlay.singlehemi}
\alias{geod.patches.color.overlay.singlehemi}
\title{Generate color overlay from geodesic patches around several vertices for a single hemi.}
\usage{
geod.patches.color.overlay.singlehemi(
  mesh,
  vertex,
  color = "#FF0000",
  bg_color = "#FEFEFE",
  ...
)
}
\arguments{
\item{mesh}{a single \code{fs.surface} instance.}

\item{vertex}{positive integer (or vector of the latter), the index of the source vertex in the mesh. If a vector, the neighborhoods for all vertices will be computed separately.}

\item{color}{single color string like \code{'#FF0000'} or vector of such strings. If a vector, the length should match the number of vertices in parameter 'vertex'.}

\item{bg_color}{character string, the background color.}

\item{...}{extra arguments passed to \code{geod.vert.neighborhood}.}
}
\description{
Generate color overlay from geodesic patches around several vertices for a single hemi.
}
\keyword{internal}
