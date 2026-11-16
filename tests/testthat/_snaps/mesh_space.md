# print.mesh_space() / prints an anatomical record

    Code
      print(mesh_space("fsaverage5", "left", anatomical = TRUE, to_mni305 = identity_affine(),
      surface = "pial", source = "FreeSurfer 7.4.1 fsaverage5"))
    Message
      <mesh_space> (v1)
      * vertex space: "fsaverage5"
      * hemisphere: "left"
      * anatomical, mapped to MNI305
      * units: "mm"
      * surface: "pial"
      * source: FreeSurfer 7.4.1 fsaverage5

# print.mesh_space() / prints a non-anatomical record

    Code
      print(mesh_space("fsaverage5", "right", anatomical = FALSE))
    Message
      <mesh_space> (v1)
      * vertex space: "fsaverage5"
      * hemisphere: "right"
      * not anatomical, no MNI305 mapping
      * units: "mm"

