% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fsdir_abstraction_group.R
\name{group.data.to.array}
\alias{group.data.to.array}
\title{Convert group 2D data (1 vector per subject) to 4D array format.}
\usage{
group.data.to.array(data)
}
\arguments{
\item{data}{2D matrix, named list, or data.frame of group data. The data is expected to be a vector (1D) per subject, as suitable for surface based (vertex-wise) measures. Subjects in rows, per-vertex data in columns.}
}
\value{
the 4D array form of the group data. No values are changed, this is only a different data layout. In neuroimaging, the first 3 dimensions are space, and the 4th is the time/subject dimension.
}
\description{
In general, 1D morphometry data for a group can be stored in a dataframe, a named list, or already a 4D array. This function will convert the given format to 4D array format.
}
\examples{
    # create per-vertex data for 255 subjects.
    mat = matrix(rnorm(255 * 163842, 3.0, 0.5), nrow=255, ncol = 163842);
    fsbrain:::group.data.to.array(mat);

}
\keyword{internal}
