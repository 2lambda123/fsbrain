% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/spatial.R
\name{rotation.matrix.for.axis.rot}
\alias{rotation.matrix.for.axis.rot}
\title{Get rotation matrix for a 3D rotation around an axis.}
\usage{
rotation.matrix.for.axis.rot(angle_rad, x, y, z, with_trans = TRUE)
}
\arguments{
\item{angle_rad}{doule, the angle in radians}

\item{x}{rotation axis}

\item{y}{rotation axis}

\item{z}{rotation axis}

\item{with_trans}{logical, whether to extend the 3x3 rotation matrix to a 4x4 rotation and tranlsation matrix.}
}
\value{
a 3x3 or 4x4 double matrix
}
\description{
Get rotation matrix for a 3D rotation around an axis.
}
\keyword{internal}
