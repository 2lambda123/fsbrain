% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/geodesic.R
\name{geodesic.circles}
\alias{geodesic.circles}
\title{Compute geodesic circles and ball stats for given vertices.}
\usage{
geodesic.circles(surface, vertices = NULL, scale = 5)
}
\arguments{
\item{surface}{an \code{rgl::tmesh3d} or \code{freesurferformats::fs.surface} instance. Can be a character string, which will be loaded as a surface file if it exists.}

\item{vertices}{positive integer vector, the vertex indices for which to compute the stats. If NULL, it is computed for all vertices.}

\item{scale}{double, surface area to be covered by patch in percent}
}
\description{
Compute geodesic circles and ball stats for given vertices.
}
\note{
This takes a while for large meshes, try it with single vertices or with a surface like fsaverage3 if you want it for all vertices. This requires the optional dependency package 'pracma'.
}
\examples{
\dontrun{
  sjd = fsaverage.path(TRUE);
  surface = subject.surface(sjd, 'fsaverage3', hemi='lh');
  gc = geodesic.circles(surface);
  vis.data.on.subject(sjd, 'fsaverage3', morph_data_lh = gc$radius);
  vis.data.on.subject(sjd, 'fsaverage3', morph_data_lh = gc$perimeter);
}

}
\keyword{interal}
