% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/hemilist.R
\name{hemilist.get.combined.data}
\alias{hemilist.get.combined.data}
\title{Get combined data of hemi list}
\usage{
hemilist.get.combined.data(hemi_list)
}
\arguments{
\item{hemi_list}{named list, can have entries 'lh' and/or 'rh', see \code{\link{hemilist}}}
}
\value{
the data combined with \code{\link{c}}, or NULL if both entries are NULL.
}
\description{
Get combined data of hemi list
}
\seealso{
Other hemilist functions: 
\code{\link{hemilist.derive.hemi}()},
\code{\link{hemilist.from.prefixed.list}()},
\code{\link{hemilist.unwrap}()},
\code{\link{hemilist.wrap}()},
\code{\link{hemilist}()},
\code{\link{is.hemilist}()}
}
\concept{hemilist functions}
