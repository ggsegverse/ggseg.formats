#' Desikan-Killiany Cortical Atlas
#'
#' Returns the Desikan-Killiany cortical parcellation atlas with 34 regions
#' per hemisphere (68 total) on the cortical surface.
#'
#' This atlas is based on the FreeSurfer `aparc` annotation and is one of the
#' most widely used cortical parcellations in neuroimaging research.
#'
#' The atlas works with both ggseg (2D polygon plots) and ggseg3d (3D mesh
#' visualizations) from a single object.
#'
#' @template core
#' @return A `ggseg_atlas` object with components:
#' \describe{
#'   \item{atlas}{Character. Atlas name ("dk")}
#'   \item{type}{Character. Atlas type ("cortical")}
#'   \item{palette}{Named character vector of colours for each region}
#'   \item{data}{A `ggseg_data_cortical` object containing:
#'     \describe{
#'       \item{vertices}{Data frame with `label` and `vertices` columns}
#'       \item{sf}{Simple features data frame for 2D rendering}
#'     }
#'   }
#' }
#'
#' @section Regions:
#' The atlas contains 34 regions per hemisphere including:
#' banks of superior temporal sulcus, caudal anterior cingulate,
#' caudal middle frontal, cuneus, entorhinal, fusiform, inferior parietal,
#' inferior temporal, isthmus cingulate, lateral occipital,
#' lateral orbitofrontal, lingual, medial orbitofrontal, middle temporal,
#' parahippocampal, paracentral, pars opercularis, pars orbitalis,
#' pars triangularis, pericalcarine, postcentral, posterior cingulate,
#' precentral, precuneus, rostral anterior cingulate, rostral middle frontal,
#' superior frontal, superior parietal, superior temporal, supramarginal,
#' frontal pole, temporal pole, transverse temporal, and insula.
#'
#' @references
#' Desikan RS, Segonne F, Fischl B, et al. (2006).
#' An automated labeling system for subdividing the human cerebral cortex
#' on MRI scans into gyral based regions of interest.
#' NeuroImage, 31(3):968-980.
#' \doi{10.1016/j.neuroimage.2006.01.021}
#'
#' Fischl B, van der Kouwe A, Destrieux C, et al. (2004).
#' Automatically parcellating the human cerebral cortex.
#' Cerebral Cortex, 14(1):11-22.
#' \doi{10.1093/cercor/bhg087}
#'
#' @seealso
#' [aseg()] for subcortical structures,
#' [ggseg_atlas()] for the atlas class constructor
#'
#' @family ggseg_atlases
#' @family cortical_atlases
#' @export
#' @examples
#' dk()
#' plot(dk())
#' atlas_regions(dk())
#' atlas_labels(dk())
dk <- function() .dk_atlas # nolint [object_usage_linter]


#' FreeSurfer Automatic Subcortical Segmentation Atlas
#'
#' Returns the FreeSurfer automatic subcortical segmentation (aseg) atlas
#' containing deep brain structures including the thalamus, caudate, putamen,
#' pallidum, hippocampus, amygdala, accumbens, and ventricles.
#'
#' This atlas is derived from FreeSurfer's `aseg.mgz` volumetric segmentation.
#' It works with both ggseg (2D slice views) and ggseg3d (3D mesh
#' visualizations) from a single object.
#'
#' @template core
#' @return A `ggseg_atlas` object with components:
#' \describe{
#'   \item{atlas}{Character. Atlas name ("aseg")}
#'   \item{type}{Character. Atlas type ("subcortical")}
#'   \item{palette}{Named character vector of colours for each region}
#'   \item{data}{A `ggseg_data_subcortical` object containing:
#'     \describe{
#'       \item{meshes}{Data frame with `label` and `mesh` columns}
#'       \item{sf}{Simple features data frame for 2D rendering}
#'     }
#'   }
#' }
#'
#' @section Structures:
#' The atlas contains bilateral structures:
#' \itemize{
#'   \item Thalamus
#'   \item Caudate
#'   \item Putamen
#'   \item Pallidum (globus pallidus)
#'   \item Hippocampus
#'   \item Amygdala
#'   \item Accumbens (nucleus accumbens)
#'   \item Ventral diencephalon
#' }
#'
#' Plus midline and ventricular structures:
#' \itemize{
#'   \item Lateral ventricles
#'   \item Third ventricle
#'   \item Fourth ventricle
#'   \item Brain stem
#'   \item Cerebellar cortex
#'   \item Cerebellar white matter
#' }
#'
#' @references
#' Fischl B, Salat DH, Busa E, et al. (2002).
#' Whole brain segmentation: automated labeling of neuroanatomical
#' structures in the human brain.
#' Neuron, 33(3):341-355.
#' \doi{10.1016/S0896-6273(02)00569-X}
#'
#' @seealso
#' [dk()] for cortical parcellation,
#' [ggseg_atlas()] for the atlas class constructor
#'
#' @family ggseg_atlases
#' @family subcortical_atlases
#' @export
#' @examples
#' aseg()
#' plot(aseg())
#' atlas_regions(aseg())
aseg <- function() .aseg_atlas # nolint [object_usage_linter]


#' TRACULA White Matter Tract Atlas
#'
#' Returns the TRACULA (TRActs Constrained by UnderLying Anatomy) white matter
#' bundle atlas in MNI space.
#'
#' This atlas contains major white matter tracts reconstructed from diffusion
#' MRI using FreeSurfer's TRACULA training data. It works with both ggseg
#' (2D slice projections) and ggseg3d (3D tube mesh visualizations).
#'
#' @template core
#' @return A `ggseg_atlas` object with components:
#' \describe{
#'   \item{atlas}{Character. Atlas name ("tracula")}
#'   \item{type}{Character. Atlas type ("tract")}
#'   \item{palette}{Named character vector of colours for each tract}
#'   \item{data}{A `ggseg_data_tract` object containing:
#'     \describe{
#'       \item{centerlines}{List of centerline matrices per tract}
#'       \item{sf}{Simple features data frame for 2D rendering}
#'     }
#'   }
#' }
#'
#' @references
#' Yendiki A, Panneck P, Srinivasan P, et al. (2011).
#' Automated probabilistic reconstruction of white-matter pathways in
#' health and disease using an atlas of the underlying anatomy.
#' Frontiers in Neuroinformatics, 5:23.
#' \doi{10.3389/fninf.2011.00023}
#'
#' @seealso
#' [dk()] for cortical parcellation,
#' [aseg()] for subcortical structures,
#' [ggseg_atlas()] for the atlas class constructor
#'
#' @section Tract labels:
#' `label` is the name FreeSurfer's TRACULA writes its per-pathway outputs
#' under, including the trailing `.bbr.prep` (for example `lh.af.bbr.prep`), so
#' a table of TRACULA output joins to the atlas as it comes. `label_short` is
#' the same identifier with the suffix stripped -- the name
#' `FreeSurferColorLUT.txt` gives the pathway at ids 5100-5399.
#'
#' @family ggseg_atlases
#' @family tract_atlases
#' @export
#' @examples
#' tracula()
#' plot(tracula())
#' atlas_regions(tracula())
tracula <- function() .tracula_atlas # nolint [object_usage_linter]


#' SUIT Cerebellar Lobular Atlas
#'
#' Returns the SUIT cerebellar parcellation (Diedrichsen et al., 2009): the
#' cerebellar cortex split into anatomical lobules plus the deep nuclei
#' (dentate, interposed, fastigial).
#'
#' Surface lobules carry vertex indices into the shared SUIT cerebellar mesh
#' (see [get_cerebellar_mesh()]); deep nuclei carry individual 3D meshes. The
#' 2D geometry is stored in the sf-optional polygon (`geom`) representation, so
#' the atlas renders with ggseg without requiring sf installed.
#'
#' @template core
#' @return A `ggseg_atlas` object with components:
#' \describe{
#'   \item{atlas}{Character. Atlas name ("suit")}
#'   \item{type}{Character. Atlas type ("cerebellar")}
#'   \item{palette}{Named character vector of colours for each region}
#'   \item{data}{A `ggseg_data_cerebellar` object containing:
#'     \describe{
#'       \item{geom}{A `brain_polygons` table for 2D rendering}
#'       \item{vertices}{Vertex indices for surface lobules}
#'       \item{meshes}{Per-structure 3D meshes for the deep nuclei}
#'     }
#'   }
#' }
#'
#' @references
#' Diedrichsen J, Balsters JH, Flavell J, et al. (2009).
#' A probabilistic MR atlas of the human cerebellum.
#' NeuroImage, 46(1):39-46.
#' \doi{10.1016/j.neuroimage.2009.01.045}
#'
#' @seealso
#' [dk()] for cortical parcellation,
#' [aseg()] for subcortical structures,
#' [tracula()] for white-matter tracts,
#' [ggseg_atlas()] for the atlas class constructor
#'
#' @family ggseg_atlases
#' @family cerebellar_atlases
#' @export
#' @examples
#' suit()
#' atlas_regions(suit())
#' atlas_geometry_type(suit())
suit <- function() .suit_atlas # nolint [object_usage_linter]
