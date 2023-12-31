% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fsdir_abstraction_group.R
\name{group.morph.standard.sf}
\alias{group.morph.standard.sf}
\title{Read combined data for a group from a single file.}
\usage{
group.morph.standard.sf(filepath, df = TRUE)
}
\arguments{
\item{filepath}{character string, path to a file in MGH or MGZ format}

\item{df}{logical, whether to return a data.frame, like \code{group.morph.standard}. If FALSE, the raw 4d matrix is returned.}
}
\value{
dataframe or 4d matrix, the morph data. See parameter 'df' for details.
}
\description{
Read morphometry data for a group from a matrix in a single MGH or MGZ file.
}
\note{
The file has typically been generated by running \code{mris_preproc} and/or \code{mri_surf2surf} on the command line, or written from R using \code{\link{write.group.morph.standard.sf}}. The file contains no information on the subject identifiers, you need to know the subjects and their order in the file. Same goes for the hemisphere.
}
\seealso{
\code{\link[fsbrain]{write.group.morph.standard.mf}} to write the data to one file per hemi per subject instead. If you have created the input data file in FreeSurfer based on an FSGD file, you can read the subject identifiers from that FSGD file using \code{\link{read.md.subjects.from.fsgd}}.
}
