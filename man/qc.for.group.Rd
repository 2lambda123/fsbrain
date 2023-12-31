% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/seg_stats.R
\name{qc.for.group}
\alias{qc.for.group}
\title{Perform data quality check based on computed region stats.}
\usage{
qc.for.group(subjects_dir, subjects_list, measure, atlas, hemi = "both", ...)
}
\arguments{
\item{subjects_dir}{string. The FreeSurfer SUBJECTS_DIR, i.e., a directory containing the data for all your subjects, each in a subdir named after the subject identifier.}

\item{subjects_list}{string vector. A vector of subject identifiers that match the directory names within subjects_dir.}

\item{measure}{string. Name of the vertex-wise measure of morphometry data file. E.g., "area" or "thickness". Used to construct the name of the morphometry file to be loaded.}

\item{atlas}{string. The atlas name. E.g., "aparc", "aparc.2009s", or "aparc.DKTatlas". Used to construct the name of the annotation file to be loaded.}

\item{hemi}{string, one of 'lh', 'rh', 'split', or 'both'. The hemisphere name. Used to construct the names of the annotation and morphometry data files to be loaded. If set to 'both', combined data for 'lh' and 'rh' will be used. If 'split', the data for hte two hemispheres will go into seprate columns, with column names having 'lh_' and 'rh_' prefixes.}

\item{...}{parameters passed to \code{\link[fsbrain]{qc.from.regionwise.df}}.}
}
\value{
qc result as a hemilist, each entry contains a named list as returned by \code{\link[fsbrain]{qc.from.regionwise.df}}.
}
\description{
Determine subjects that potentially failed segmentation, based on region-wise morphometry data. The stats can be computed from any kind of data, but something like area or volume most likely works best. The stats are based on the mean of the region values, so the measure should at least roughly follow a normal distribution.
}
\seealso{
Other quality check functions: 
\code{\link{qc.from.regionwise.df}()},
\code{\link{qc.from.segstats.table}()}
}
\concept{quality check functions}
