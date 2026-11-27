# the published dispatch surface / is exactly the set of methods consumers may rely on

    Code
      print(surface)
    Output
                              as_ggseg_atlas                          atlas_display 
                                          "" "brain_atlas, data.frame, ggseg_atlas" 
                                  atlas_hemi                           atlas_labels 
      "brain_atlas, data.frame, ggseg_atlas" "brain_atlas, data.frame, ggseg_atlas" 
                               atlas_regions                             atlas_type 
      "brain_atlas, data.frame, ggseg_atlas"             "brain_atlas, ggseg_atlas" 

# the published dispatch surface / includes the base generics, which the generic-keyed view cannot see

    Code
      print(surface)
    Output
                                                                                                    ggseg_atlas 
      "as.data.frame, as.list, atlas_display, atlas_hemi, atlas_labels, atlas_regions, atlas_type, plot, print" 
                                                                                                    brain_atlas 
                                           "atlas_display, atlas_hemi, atlas_labels, atlas_regions, atlas_type" 
                                                                                                 brain_polygons 
                                                                                                        "print" 
                                                                                                       ggseg_sf 
                                                                                                        "print" 
                                                                                                     mesh_space 
                                                                                                        "print" 
                                                                                            ggseg_data_cortical 
                                                                                                        "print" 
                                                                                         ggseg_data_subcortical 
                                                                                                        "print" 
                                                                                          ggseg_data_cerebellar 
                                                                                                        "print" 
                                                                                               ggseg_data_tract 
                                                                                                        "print" 
                                                                                        ggseg_data_white_matter 
                                                                                                             "" 

