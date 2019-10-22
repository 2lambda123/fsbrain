#' @title Aggregate morphometry data over brain atlas regions for a subject.
#'
#' @description Aggregate morphometry data over brain atlas regions, e.g., compute the mean thickness value over all regions in an atlas.
#'
#' @param vertex_morph_data, numeric vector. The morphometry data, one value per vertex. The morphometry data are typically loaded from an MGZ or curv format file with the read.fs.curv or read.fs.mgh functions.
#'
#' @param vertex_label_names, string vector. The region names for the vertices, one string per vertex. The region names are typically loaded from an annotation file with the read.fs.annot function.
#'
#' @param agg_fun, function. An R function that aggregates data, typically max, mean, min or something similar. Note: this is NOT a string, put the function name without quotes. Defaults to mean.
#'
#' @param requested_label_names, string vector. The label (or region) names that you want to occur in the output. If not specified, all region names which occur in the data are used. If given, and one of the requested names does NOT occur in the data, it will occur in the output with aggregation value NaN. If given, and one of the names from the data does NOT occur in the requested list, it will NOT occur in the output. So if you specify this, the output dataframe will contain a row for a region if and only if it is in the requested list.
#'
#' @return dataframe with aggregated values for all regions, with 2 columns and n rows, where n is the number of effective regions. The columns are: "region": string, contains the region name. "aggregated": numeric, contains the result of applying agg_fun to the morphometry data in that region.
#'
#' @family aggregation functions
#' @family atlas functions
#'
#' @export
subject.atlas.agg <- function(vertex_morph_data, vertex_label_names, agg_fun = mean, requested_label_names = c()) {

  if (length(vertex_morph_data) != length(vertex_label_names)) {
      stop(sprintf("Data mismatch: Received morphometry data for %d vertices, but %d labels. Counts must match.\n", length(vertex_morph_data), length(vertex_label_names)));
  }

  if (!length(requested_label_names)) {
      requested_label_names = unique(vertex_label_names);
      did_request_regions = FALSE;
  } else {
      did_request_regions = TRUE;
  }

  df = data.frame("vertex_morph_data"=vertex_morph_data, "vertex_label_names"=vertex_label_names);
  agg = stats::aggregate(df$vertex_morph_data, by=list(df$vertex_label_names), FUN=agg_fun, drop = FALSE);
  colnames(agg) = c("region", "aggregated");

  if (did_request_regions) {
      # Add explicitely requested regions for which no data was found as rows to the dataframe (with aggregation value NA).
      for(possible_region in requested_label_names) {
          if(! possible_region %in% agg$region) {
              agg<-rbind(agg, data.frame("region"=possible_region, "aggregated"=NaN))
          }
      }

      # Delete data for regions which are not in the list of requested region names.
      agg = agg[ (agg$region %in% requested_label_names), ];
  }

  return(agg);
}



#' @title Aggregate native space morphometry data over brain atlas regions and subjects for a group of subjects.
#'
#' @description Aggregate native space morphometry data over brain atlas regions, e.g., compute the mean thickness value over all regions in an atlas for all subjects. Try visualizing the results, e.g.,:
#'
#'    molten=melt(agg, id=c('subject'));
#'    ggplot(data=molten, aes(x=variable, y=value, group=subject)) + geom_point() + geom_line() + theme(axis.text.x = element_text(angle = 90, hjust = 1));
#'
#'
#' @param subjects_dir, string. The FreeSurfer SUBJECTS_DIR, i.e., a directory containing the data for all your subjects, each in a subdir named after the subject identifier.
#'
#' @param subjects_list, string vector. A vector of subject identifiers that match the directory names within subjects_dir.
#'
#' @param measure, string. Name of the vertex-wise measure of morphometry data file. E.g., "area" or "thickness". Used to construct the name of the morphometry file to be loaded.
#'
#' @param hemi, string, one of 'lh', 'rh', or 'both'. The hemisphere name. Used to construct the names of the annotation and morphometry data files to be loaded. If set to 'both', combined data for 'lh' and 'rh' will be used.
#'
#' @param atlas, string. The atlas name. E.g., "aparc", "aparc.2009s", or "aparc.DKTatlas". Used to construct the name of the annotation file to be loaded.
#'
#' @param agg_fun, function. An R function that aggregates data, typically max, mean, min or something similar. Note: this is NOT a string, put the function name without quotes. Defaults to mean.
#'
#' @param cache_file, string or NULL. If given, it is interpreted as path of a file, and the data will be cached in the file cache_file in RData format. If the file does not exist yet, the function will run and cache the data in the file. If the file exists, the function will load the data from the file instead of running. The filename should end in '.RData', but that is not enforced or checked in any way. WARNING: If cached data is returned, all parameters passed to this function (with the exception of 'cache_file') are ignored! Whether the cached data is for another subjects_list or hemi is NOT checked! You have to ensure this yourself, by using different filenames. Defaults to NULL.
#'
#' @return dataframe with aggregated values for all regions and subjects, with n columns and m rows, where n is the number of subjects and m is the number of regions.
#'
#' @family aggregation functions
#' @family atlas functions
#'
#' @export
group.agg.atlas.native <- function(subjects_dir, subjects_list, measure, hemi, atlas, agg_fun = mean, cache_file=NULL) {

    if(! is.null(cache_file)) {
      if(file.exists(cache_file)) {
        e <- new.env();
        object_names = load(cache_file, envir = e);
        var_to_restore = "agg_res_df_nt";
        if(var_to_restore %in% object_names) {
          message(sprintf("group.agg.atlas.native(): Returning cached value from file '%s'. Parameters passed to this function were ignored.\n", cache_file));
          return(e[[var_to_restore]]);
        } else {
          warning(sprintf("Expected object '%s' not in rdata file '%s'.\n", var_to_restore, cache_file));
        }
      }
    }

    if(!(hemi %in% c("lh", "rh", "both"))) {
        stop(sprintf("Parameter 'hemi' must be one of 'lh', 'rh' or 'both' but is '%s'.\n", hemi));
    }

    if (! dir.exists(subjects_dir)) {
        stop(sprintf("Subjects directory '%s' does not exist or cannot be accessed.\n", subjects_dir));
    }

    agg_all_subjects = data.frame()
    for (subject_id in subjects_list) {

        morph_data = subject.morph.native(subjects_dir, subject_id, measure, hemi);
        annot = subject.annot(subjects_dir, subject_id, hemi, atlas);

        if (length(morph_data) != length(annot$label_names)) {
          stop(sprintf("Data mismatch for subject '%s' native space morphometry measure '%s' hemi '%s': Received morphometry data for %d vertices, but %d labels from atlas '%s' annotation. Counts must match.\n", subject_id, measure, hemi, length(morph_data), length(annot$label_names), atlas));
        }

        subject_agg = subject.atlas.agg(morph_data, annot$label_names, agg_fun=agg_fun, requested_label_names = annot$colortable$struct_names);
        subject_agg$subject = subject_id;

        if(nrow(agg_all_subjects) > 0) {
          agg_all_subjects = rbind(agg_all_subjects, subject_agg);
        } else {
          agg_all_subjects = subject_agg;
        }
    }
    agg_res = reshape::cast(agg_all_subjects, subject~region, value='aggregated');
    rownames(agg_res) = subjects_list;
    agg_res_df_nt = as.data.frame(agg_res);

    if(! is.null(cache_file)) {
      message(sprintf("group.agg.atlas.standard(): Caching return value in file '%s'.\n", cache_file));
      save(agg_res_df_nt, file = cache_file);
    }

    return(agg_res_df_nt);
}



#' @title Aggregate standard space morphometry data over brain atlas regions and subjects for a group of subjects.
#'
#' @description Aggregate standard space morphometry data over brain atlas regions, e.g., compute the mean thickness value over all regions in an atlas for all subjects. Try visualizing the results, e.g.,:
#'
#'    molten=melt(agg, id=c('subject'));
#'    ggplot(data=molten, aes(x=variable, y=value, group=subject)) + geom_point() + geom_line() + theme(axis.text.x = element_text(angle = 90, hjust = 1));
#'
#'
#' @param subjects_dir, string. The FreeSurfer SUBJECTS_DIR, i.e., a directory containing the data for all your subjects, each in a subdir named after the subject identifier.
#'
#' @param subjects_list, string vector. A vector of subject identifiers that match the directory names within subjects_dir.
#'
#' @param measure, string. Name of the vertex-wise measure of morphometry data file. E.g., "area" or "thickness". Used to construct the name of the morphometry file to be loaded.
#'
#' @param hemi, string, one of 'lh', 'rh', or 'both'. The hemisphere name. Used to construct the names of the annotation and morphometry data files to be loaded. If set to 'both', combined data for 'lh' and 'rh' will be used.
#'
#' @param atlas, string. The atlas name. E.g., "aparc", "aparc.2009s", or "aparc.DKTatlas". Used to construct the name of the annotation file to be loaded.
#'
#' @param fwhm, string. The smoothing setting which was applied when mapping data to the template subject. Usually one of '0', '5', '10', '15', '20', or '25'.
#'
#' @param agg_fun, function. An R function that aggregates data, typically max, mean, min or something similar. Note: this is NOT a string, put the function name without quotes. Defaults to mean.
#'
#' @param template_subject, string. The template subject name. Defaults to 'fsaverage'. Must have its data in subjects_dir.
#'
#' @param cache_file, string or NULL. If given, it is interpreted as path of a file, and the data will be cached in the file cache_file in RData format. If the file does not exist yet, the function will run and cache the data in the file. If the file exists, the function will load the data from the file instead of running. The filename should end in '.RData', but that is not enforced or checked in any way. WARNING: If cached data is returned, all parameters passed to this function (with the exception of 'cache_file') are ignored! Whether the cached data is for another subjects_list or hemi is NOT checked! You have to ensure this yourself, by using different filenames. Defaults to NULL.
#'
#' @return dataframe with aggregated values for all regions and subjects, with n columns and m rows, where n is the number of subjects and m is the number of regions.
#'
#' @family aggregation functions
#' @family atlas functions
#'
#' @export
group.agg.atlas.standard <- function(subjects_dir, subjects_list, measure, hemi, atlas, fwhm, agg_fun = mean, template_subject='fsaverage', cache_file=NULL) {

  if(! is.null(cache_file)) {
    if(file.exists(cache_file)) {
      e <- new.env();
      object_names = load(cache_file, envir = e);
      var_to_restore = "agg_res_df_std";
      if(var_to_restore %in% object_names) {
        message(sprintf("group.agg.atlas.standard(): Returning cached value from file '%s'. Parameters passed to this function were ignored.\n", cache_file));
        return(e[[var_to_restore]]);
      } else {
        warning(sprintf("Expected object '%s' not in rdata file '%s'.\n", var_to_restore, cache_file));
      }
    }
  }

  if(!(hemi %in% c("lh", "rh", "both"))) {
    stop(sprintf("Parameter 'hemi' must be one of 'lh', 'rh' or 'both' but is '%s'.\n", hemi));
  }

  if (! dir.exists(subjects_dir)) {
    stop(sprintf("Subjects directory '%s' does not exist or cannot be accessed.\n", subjects_dir));
  }

  if (typeof(fwhm) != "character") {
    stop(sprintf("Parameter 'fwhm' must be of type 'character', but is '%s'.\n", typeof(fwhm)));
  }

  annot = subject.annot(subjects_dir, template_subject, hemi, atlas);
  agg_all_subjects = data.frame()
  for (subject_id in subjects_list) {
    morph_data = subject.morph.standard(subjects_dir, subject_id, measure, hemi, fwhm=fwhm);

    if (length(morph_data) != length(annot$label_names)) {
      stop(sprintf("Data mismatch for subject '%s' standard space morphometry measure '%s' hemi '%s': Received morphometry data for %d vertices, but %d labels from atlas '%s' annotation for template subject '%s'. Counts must match.\n", subject_id, measure, hemi, length(morph_data), length(annot$label_names), atlas, template_subject));
    }

    subject_agg = subject.atlas.agg(morph_data, annot$label_names, agg_fun=agg_fun, requested_label_names = annot$colortable$struct_names);
    subject_agg$subject = subject_id;

    if(nrow(agg_all_subjects) > 0) {
      agg_all_subjects = rbind(agg_all_subjects, subject_agg);
    } else {
      agg_all_subjects = subject_agg;
    }
  }
  agg_res = reshape::cast(agg_all_subjects, subject~region, value='aggregated');
  rownames(agg_res) = subjects_list;
  agg_res_df_std = as.data.frame(agg_res);

  if(! is.null(cache_file)) {
    message(sprintf("group.agg.atlas.standard(): Caching return value in file '%s'.\n", cache_file));
    save(agg_res_df_std, file = cache_file);
  }

  return(agg_res_df_std);
}



#' @title Create a named value list from a dataframe.
#'
#' @description Given the result of the group.agg.atlas.native() function, extract a named region value list (typically for use with the spread.values.over.annot() function) for a single subject.
#'
#' @param agg_res, a dataframe. The result of calling group.agg.atlas.native().
#'
#' @param subject_id, string. A subject identifier, must occur in the subject column of the dataframe agg_res.
#'
#' @return region_value_list, named list of strings. Each name must is a region name from the annotation, and the value is a scalar that resulting from aggregating the morphometry data for that region and subject.
#'
#' @keywords internal
fs.value.list.from.agg.res <- function(agg_res, subject_id) {
  value_list_by_region = subset(agg_res, agg_res$subject==subject_id, drop=TRUE);
  names(value_list_by_region) = colnames(agg_res);
  value_list_by_region$subject = NULL; # delete the subject entry
  return(value_list_by_region);
}


#' @title Spread a single value for a region to all region vertices.
#'
#' @description Given an annotation and a list of values (one per brain region), return data that has the values for each region mapped to all region vertices.
#'
#' @param annot, annotation. The result of calling fs.read.annot.
#'
#' @param region_value_list, named list of strings. Each name must be a region name from the annotation, and the value must be the value to spread to all region vertices.
#'
#' @param value_for_unlisted_regions, numeric scalar. The value to assign to vertices which are part of atlas regions that are not listed in region_value_list. Defaults to NaN.
#'
#' @param warn_on_unmatched_list_regions, logical. Whether to print a warning when a region occurs in the region_value_list that is not part of the given atlas (and the value assigned to this region is thus ignored in the output file and data). Defaults to FALSE.
#'
#' @param warn_on_unmatched_atlas_regions, logical. Whether to print a warning when a region occurs in the atlas that is not part of the given region_value_list (and thus the vertices of the region will be assigned the value 'value_for_unlisted_regions' in the output file and data). Defaults to FALSE.
#'
#' @return named list with following entries: "spread_data": a vector of length n, where n is the number of vertices in the annotation. One could write this to an MGH or curv file for visualization. "regions_not_in_annot": list of regions which are not in the annotation, but in the region_value_list. Their values were ignored.
#'
#' @family atlas functions
#'
#' @export
spread.values.over.annot <- function(annot, region_value_list, value_for_unlisted_regions=NaN, warn_on_unmatched_list_regions=FALSE, warn_on_unmatched_atlas_regions=FALSE) {
    num_verts = length(annot$vertices);
    new_data = rep(value_for_unlisted_regions, num_verts);

    ret_list=list();

    regions_not_in_annot = c();

    list_region_names = names(region_value_list);
    for (idx in seq_len(length(region_value_list))) {
      region_name = list_region_names[idx];
      region_value = region_value_list[idx];
      new_data[annot$label_names==region_name] = region_value;
      if(!(region_name %in% annot$colortable$struct_names)) {
        regions_not_in_annot = c(regions_not_in_annot, region_name);
      }
    }
    ret_list$regions_not_in_annot = regions_not_in_annot;

    if(warn_on_unmatched_list_regions && length(regions_not_in_annot) > 0) {
      warning(sprintf("spread.values.over.annot: Ignored %d regions from 'region_value_list' parameter which do not occur in 'atlas': %s\n", length(regions_not_in_annot), paste(regions_not_in_annot, collapse=", ")));
    }


    atlas_regions_not_in_list = c();
    for (atlas_region in annot$colortable$struct_names) {
      if(!(atlas_region %in% names(region_value_list))) {
        atlas_regions_not_in_list = c(atlas_regions_not_in_list, atlas_region);
      }
    }
    ret_list$atlas_regions_not_in_list = atlas_regions_not_in_list;

    if(warn_on_unmatched_atlas_regions) {
      if(length(atlas_regions_not_in_list) > 0) {
          warning(sprintf("spread.values.over.annot: Found %d regions from 'atlas' parameter which are not assigned any value in 'region_value_list' (their vertices will get default value): %s\n", length(atlas_regions_not_in_list), paste(atlas_regions_not_in_list, collapse=", ")));
      }
    }

    ret_list$spread_data = unlist(new_data);
    return(ret_list);
}



#' @title Write data aggregated over regions to morphometry file for group.
#'
#' @description Given an atlas, a subjects list and a measure, aggregate the measure over each region (e.g., mean) and write an output morphometry file in which the value for all region vertices is set to the aggregated value.
#'
#' @param subjects_dir, string. The FreeSurfer SUBJECTS_DIR, i.e., a directory containing the data for all your subjects, each in a subdir named after the subject identifier.
#'
#' @param subjects_list, string vector. A vector of subject identifiers that match the directory names within subjects_dir.
#'
#' @param measure, string. Name of the vertex-wise measure of morphometry data file. E.g., "area" or "thickness". Used to construct the name of the morphometry file to be loaded.
#'
#' @param hemi, string, one of 'lh' or 'rh'. The hemisphere name. Used to construct the names of the annotation and morphometry data files to be loaded.
#'
#' @param atlas, string. The atlas name. E.g., "aparc", "aparc.2009s", or "aparc.DKTatlas". Used to construct the name of the annotation file to be loaded.
#'
#' @param agg_fun, function. An R function that aggregates data, typically max, mean, min or something similar. Note: this is NOT a string, put the function name without quotes. Defaults to mean.
#'
#' @param outfile_morph_name, string. The measure part of the output file name. E.g., 'agg_thickness' will write the file '<subject>/surf/<hemi>.agg_thickness.mgh'. Defaults to 'agg_<measure>'.
#'
#' @param format, string. A morphometry file format. One of 'mgh', 'mgz' or 'curv.' The output file name extension will be set accordingly. Defaults to 'mgz'.
#'
#' @family output functions
#'
#' @export
write.region.aggregated <- function(subjects_dir, subjects_list, measure, hemi, atlas, agg_fun = mean, outfile_morph_name="", format="mgz") {
    if(nchar(outfile_morph_name)==0) {
      outfile_morph_name = sprintf("agg_%s", measure);  # something like 'agg_thickness'
    }

    agg_res = group.agg.atlas.native(subjects_dir, subjects_list, measure, hemi, atlas, agg_fun = agg_fun);

    for (subject_id in subjects_list) {
        region_value_list = fs.value.list.from.agg.res(agg_res, subject_id);
        write.region.values(subjects_dir, subject_id, hemi, atlas, region_value_list, outfile_morph_name, format=format);
    }
}


#' @title Write one value per atlas region for a subject.
#'
#' @description Given an atlas and a list that contains one value for each atlas region, write a morphometry file in which all region vertices are assigned the value. Can be used to plot stuff like p-values or effect sizes onto brain regions.
#'
#' @param subjects_dir, string. The FreeSurfer SUBJECTS_DIR, i.e., a directory containing the data for all your subjects, each in a subdir named after the subject identifier.
#'
#' @param subject_id, string. The subject identifier
#'
#' @param hemi, string, one of 'lh' or 'rh'. The hemisphere name. Used to construct the names of the annotation and morphometry data files to be loaded.
#'
#' @param atlas, string. The atlas name. E.g., "aparc", "aparc.2009s", or "aparc.DKTatlas". Used to construct the name of the annotation file to be loaded.
#'
#' @param region_value_list, named list. A list in which the names are atlas regions, and the values are the value to write to all vertices of that region.
#'
#' @param outfile_morph_name, string. The measure part of the output file name. E.g., 'agg_thickness' will write the file '<subject>/surf/<hemi>.agg_thickness.mgh'.
#'
#' @param format, string. A morphometry file format. One of 'mgh', 'mgz' or 'curv.' The output file name extension will be set accordingly. Defaults to 'mgz'.
#'
#' @param do_write_file, logical. Whether to write the data to a file on the disk. If FALSE, the data are only returned (and the outfile_morph_name parameter gets ignored). Default to TRUE.
#'
#' @param output_path string, path to the output directory. If omitted, defaults to the 'surf' directory of the subject (i.e., '<subjects_dir>/<subject_id>/surf/').
#'
#' @param value_for_unlisted_regions, numeric scalar. The value to assign to vertices which are part of atlas regions that are not listed in region_value_list. Defaults to NaN.
#'
#' @return a named list with the following entries: "data": a vector containing the data. "file_written": string, path to the file that was written, only exists if do_write = TRUE.
#'
#' @family output functions
#'
#' @export
write.region.values <- function(subjects_dir, subject_id, hemi, atlas, region_value_list, outfile_morph_name, format="mgz", do_write_file = TRUE, output_path = NULL, value_for_unlisted_regions=NaN) {
  outfile_morph_name = sprintf("%s%s", outfile_morph_name, freesurferformats::fs.get.morph.file.ext.for.format(format)); # append file extension
  output_file_name_no_path = sprintf("%s.%s", hemi, outfile_morph_name);

  if(is.null(output_path)) {
    morph_outfile = file.path(subjects_dir, subject_id, "surf", output_file_name_no_path);
  } else {
    morph_outfile = file.path(output_path, output_file_name_no_path);
  }

  morph_data = spread.values.over.hemi(subjects_dir, subject_id, hemi, atlas, region_value_list, value_for_unlisted_regions=value_for_unlisted_regions);

  return_list = list();
  if (do_write_file) {
    freesurferformats::write.fs.morph(morph_outfile, morph_data);
    return_list$file_written = morph_outfile;
  }

  return_list$data = morph_data;
  return(return_list);
}


#' @title Spread the values in the region_value_list and return them for one hemisphere.
#'
#' @description Given an atlas and a list that contains one value for each atlas region, create morphometry data in which all region vertices are assigned the value. Can be used to plot stuff like p-values or effect sizes onto brain regions.
#'
#' @param subjects_dir, string. The FreeSurfer SUBJECTS_DIR, i.e., a directory containing the data for all your subjects, each in a subdir named after the subject identifier.
#'
#' @param subject_id, string. The subject identifier
#'
#' @param hemi, string, one of 'lh' or 'rh'. The hemisphere name. Used to construct the names of the annotation and morphometry data files to be loaded.
#'
#' @param atlas, string. The atlas name. E.g., "aparc", "aparc.2009s", or "aparc.DKTatlas". Used to construct the name of the annotation file to be loaded.
#'
#' @param region_value_list, named list. A list in which the names are atlas regions, and the values are the value to write to all vertices of that region.
#'
#' @param value_for_unlisted_regions, numeric scalar. The value to assign to vertices which are part of atlas regions that are not listed in region_value_list. Defaults to NaN.
#'
#' @return numeric vector containing the data.
#'
#' @family atlas functions
#'
#' @export
spread.values.over.hemi <- function(subjects_dir, subject_id, hemi, atlas, region_value_list, value_for_unlisted_regions=NaN) {
  if(!(hemi %in% c("lh", "rh"))) {
    stop(sprintf("Parameter 'hemi' must be one of 'lh' or 'rh' but is '%s'.\n", hemi));
  }

  annot = subject.annot(subjects_dir, subject_id, hemi, atlas);
  spread = spread.values.over.annot(annot, region_value_list, value_for_unlisted_regions=value_for_unlisted_regions);
  morph_data = spread$spread_data;
  return(morph_data);
}

#' @title Spread the values in the region_value_list and return them for one hemisphere.
#'
#' @description Given an atlas and a list that contains one value for each atlas region, create morphometry data in which all region vertices are assigned the value. Can be used to plot stuff like p-values or effect sizes onto brain regions.
#'
#' @param subjects_dir, string. The FreeSurfer SUBJECTS_DIR, i.e., a directory containing the data for all your subjects, each in a subdir named after the subject identifier.
#'
#' @param subject_id, string. The subject identifier
#'
#' @param atlas, string. The atlas name. E.g., "aparc", "aparc.2009s", or "aparc.DKTatlas". Used to construct the name of the annotation file to be loaded.
#'
#' @param lh_region_value_list, named list. A list in which the names are atlas regions, and the values are the value to write to all vertices of that region. Applied to the left hemisphere.
#'
#' @param rh_region_value_list, named list. A list in which the names are atlas regions, and the values are the value to write to all vertices of that region. Applied to the right hemisphere.
#'
#' @param value_for_unlisted_regions, numeric scalar. The value to assign to vertices which are part of atlas regions that are not listed in region_value_list. Defaults to NaN.
#'
#' @return named list with entries 'lh' and 'rh'. Each value is a numeric vector containing the data for the respective hemisphere.
#'
#' @family atlas functions
#'
#' @export
spread.values.over.subject <- function(subjects_dir, subject_id, atlas, lh_region_value_list, rh_region_value_list, value_for_unlisted_regions=NaN) {

  if(is.null(lh_region_value_list)) {
    lh_region_value_list = list();
  }
  if(is.null(rh_region_value_list)) {
    rh_region_value_list = list();
  }

  morph_data_lh = spread.values.over.hemi(subjects_dir, subject_id, 'lh', atlas, lh_region_value_list, value_for_unlisted_regions=value_for_unlisted_regions);
  morph_data_rh = spread.values.over.hemi(subjects_dir, subject_id, 'rh', atlas, rh_region_value_list, value_for_unlisted_regions=value_for_unlisted_regions);
  return_list = list("lh"=morph_data_lh, "rh"=morph_data_rh);
  return(return_list);
}


#' @title Write one value per atlas region for a template subject.
#'
#' @description Given an atlas and a list that contains one value for each atlas region, write a morphometry file in which all region vertices are assigned the value. Can be used to plot stuff like p-values or effect sizes onto brain regions.
#'
#' @param hemi, string, one of 'lh' or 'rh'. The hemisphere name. Used to construct the names of the annotation and morphometry data files to be loaded.
#'
#' @param atlas, string. The atlas name. E.g., "aparc", "aparc.2009s", or "aparc.DKTatlas". Used to construct the name of the annotation file to be loaded.
#'
#' @param region_value_list, named list. A list in which the names are atlas regions, and the values are the value to write to all vertices of that region.
#'
#' @param output_file, string or NULL. Path of the output file, including file name and extension. The format is determined from the (absence of a) file extension. If NULL, no file will be written.
#'
#' @param template_subject string, template subject name. Defaults to 'fsaverage'.
#'
#' @param template_subjects_dir string, the path to the subjects directory containing the template subject directory. If this is NULL, the function will try to find it using the environment, see the function 'find.subjectsdir.of' for details. Defaults to NULL.
#'
#' @param show_freeview_tip logical, whether to print the freeview command on howto use the overlay to the console. (Only happens if the output_file is not NULL.)
#'
#' @param value_for_unlisted_regions, numeric scalar. The value to assign to vertices which are part of atlas regions that are not listed in region_value_list. Defaults to NaN.
#'
#' @return a named list with the following entries: "data": a vector containing the data. "file_written": string, path to the file that was written, only exists if do_write = TRUE.
#'
#' @family output functions
#'
#' @export
write.region.values.fsaverage <- function(hemi, atlas, region_value_list, output_file, template_subject='fsaverage', template_subjects_dir=NULL, show_freeview_tip=FALSE, value_for_unlisted_regions=NaN) {
  if(is.null(template_subjects_dir)) {
    ret = find.subjectsdir.of(subject_id=template_subject)
    if(ret$found) {
      subjects_dir = ret$found_at;
    } else {
      stop(sprintf("Parameter 'template_subjects_dir' is NULL and subject directory for template subject '%s' could not be found based on environment variables. Set FREESURFER_HOME and/or SUBJECTS_DIR or provide parameter 'template_subjects_dir'.", template_subject));
    }
  } else {
    subjects_dir = template_subjects_dir;
  }
  subject_id = template_subject;

  morph_data = spread.values.over.hemi(subjects_dir, subject_id, hemi, atlas, region_value_list, value_for_unlisted_regions=value_for_unlisted_regions);

  do_write_file = !is.null(output_file);
  return_list = list();
  if (do_write_file) {
    freesurferformats::write.fs.morph(output_file, morph_data);
    return_list$file_written = output_file;
    if(show_freeview_tip) {
      cat(sprintf("To visualize these region values, try:\n  freeview -f ${FREESURFER_HOME}/subjects/fsaverage/surf/%s.white:overlay=%s:overlay_method=linearopaque:overlay_threshold=0,100,percentile\n", hemi, output_file));
    }
  }
  return_list$data = morph_data;
  return(return_list);
}

#' @title Find the subject directory containing the fsaverage subject on disk.
#'
#' @description Try to find directory containing the fsaverage subject (or any other subject) by checking the environment variables FREESURFER_HOME and SUBJECTS_DIR.
#'
#' @param subject_id string, the subject id of the subject. Defaults to 'fsaverage'.
#'
#' @param mustWork logical. Whether the function should with an error stop if the directory cannot be found. If this is TRUE, the return value will be only the 'found_at' entry of the list (i.e., only the path of the subjects dir).
#'
#' @return named list with the following entries: "found": logical, whether it was found. "found_at": Only set if found=TRUE, the path to the fsaverage directory (NOT including the fsaverage dir itself). See mustWork for important information.
#'
#' @export
find.subjectsdir.of <- function(subject_id='fsaverage', mustWork=FALSE) {
  ret = list();
  ret$found = FALSE;

  fs_home=Sys.getenv("FREESURFER_HOME");
  if(nchar(fs_home) > 0) {
    guessed_path = file.path(fs_home, "subjects", subject_id);
    if(dir.exists(guessed_path)) {
        ret$found = TRUE;
        ret$found_at = file.path(fs_home, "subjects");
    }
  }

  subj_dir=Sys.getenv("SUBJECTS_DIR");
  if(nchar(subj_dir) > 0) {
    guessed_path = file.path(subj_dir, subject_id);
    if(dir.exists(guessed_path)) {
      ret$found = TRUE;
      ret$found_at = subj_dir;
    }
  }

  if(mustWork) {
    if(ret$found) {
      return(ret$found_at);
    } else {
      stop(sprintf("Could not find subjects dir containing subject '%s' and parameter 'mustWork' is TRUE. Checked for directories given by environment variables FREESURFER_HOME and SUBJECTS_DIR. Please set them by installing FreeSurfer.\n", subject_id));
    }
  }

  return(ret);
}




#'@title Merge the annotations from two hemispheres into one annot.
#
#' @param lh_annot, annot. An annotation, as returned by freesurferformats::read.fs.annot().
#'
#' @param rh_annot, annot. An annotation, as returned by freesurferformats::read.fs.annot().
#'
#' @return annot, the merged annotation.
#'
#' @keywords internal
merge.hemi.annots <- function(lh_annot, rh_annot) {
  merged_annot = list();
  merged_annot$colortable = lh_annot$colortable;        # randomly use the lh one, they must be identical for lh nad rh anyways
  merged_annot$colortable_df = lh_annot$colortable_df;  # same

  merged_annot$vertices = c(lh_annot$vertices, rh_annot$vertices);
  merged_annot$label_codes = c(lh_annot$label_codes, rh_annot$label_codes);
  merged_annot$label_names = c(lh_annot$label_names, rh_annot$label_names);
  merged_annot$hex_colors_rgb = c(lh_annot$hex_colors_rgb, rh_annot$hex_colors_rgb);
  return(merged_annot);
}


#'@title Determine atlas region names from a subject.
#'
#' @description Determine atlas region names from a subject. WARNING: Not all subjects have all regions of an atlas. You should use an average subject like fsaverage to get all regions.
#'
#' @param template_subjects_dir, string. The directory containing the dir of the template_subject. E.g., the path to FREESURFER_HOME/subjects. If NULL, env vars will be searched for candidates, and the function will fail if they are not set correctly. Defaults to NULL.
#'
#' @param template_subject, string. The subject identifier. Defaults to 'fsaverage'.
#'
#' @param hemi, string, one of 'lh' or 'rh'. The hemisphere name. Used to construct the names of the annotation and morphometry data files to be loaded. Defaults to 'lh'. Should not matter much, unless you do not have the file for one of the hemis for some reason.
#'
#' @param atlas, string. The atlas name. E.g., "aparc", "aparc.2009s", or "aparc.DKTatlas". Used to construct the name of the annotation file to be loaded.
#'
#' @return vector of strings, the region names.
#'
#' @family atlas functions
#'
#' @export
get.atlas.region.names <- function(atlas, template_subjects_dir=NULL, template_subject='fsaverage', hemi='lh') {
  if(is.null(template_subjects_dir)) {
    template_subjects_dir = find.subjectsdir.of(subject_id=template_subject, mustWork = TRUE);
  }
  annot = subject.annot(template_subjects_dir, template_subject, hemi, atlas);
  return(annot$colortable$struct_names);
}



#'@title Give suggestions for regions to ignore for an atlas.
#'
#' @description Give suggestions for regions to ignore for an atlas. These are regions for which many subjects do not have any vertices in them, or the Medial Wall and Unknown regions.
#'
#' @param atlas, string. The name of an atlas. Supported strings are 'aparc' and 'aparc.a2009s'.
#'
#' @return vector of strings, the region names.
#'
#' @family atlas functions
#'
#' @export
regions.to.ignore <- function(atlas) {
  if(atlas == "aparc") {
    return(c("unknown", "corpuscallosum"));
  } else if(atlas == "aparc.a2009s") {
    return(c("Medial_wall", "Unknown"));
  } else {
    return(c());
  }
}