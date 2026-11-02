# print methods / prints ggseg_data_cortical with sf and vertices

    Code
      print(data)
    Message
      
      -- ggseg_data_cortical --
      
      2D (ggseg): 1 labels (sf), views: lateral
      3D (ggseg3d): vertex indices
    Output
             label  vertices
      1 lh_frontal <int [3]>

# print methods / prints ggseg_data_subcortical with sf and meshes

    Code
      print(data)
    Message
      
      -- ggseg_data_subcortical --
      
      2D (ggseg): 1 labels (sf), views: axial
      3D (ggseg3d): meshes
    Output
              label vertices faces
      1 hippocampus       10     3

# print methods / prints ggseg_data_tract with centerlines

    Code
      print(data)
    Message
      
      -- ggseg_data_tract --
      
      3D (ggseg3d): 1 centerlines (10 points)

# print methods / prints ggseg_data_cortical without sf

    Code
      print(data)
    Message
      
      -- ggseg_data_cortical --
      
      3D (ggseg3d): vertex indices
    Output
             label  vertices
      1 lh_frontal <int [3]>

# print methods / summarises brain_polygons geometry in the 2D view listing

    Code
      print(data)
    Message
      
      -- ggseg_data_cortical --
      
      2D (ggseg): 1 labels (polygons), views: lateral

# print methods / prints ggseg_data_subcortical without sf

    Code
      print(data)
    Message
      
      -- ggseg_data_subcortical --
      
      3D (ggseg3d): meshes
    Output
              label vertices faces
      1 hippocampus       10     3

# print methods / prints ggseg_data_cerebellar with sf and vertices

    Code
      print(data)
    Message
      
      -- ggseg_data_cerebellar --
      
      2D (ggseg): 1 labels (sf), views: flatmap
      3D (ggseg3d): vertex indices into the "suit" surface
    Output
            label   vertices
      1 left_I-IV <int [10]>

# print methods / prints the deep nuclei a cerebellar atlas carries as meshes

    Code
      print(data)
    Message
      
      -- ggseg_data_cerebellar --
      
      3D (ggseg3d): vertex indices into the "suit" surface
    Output
            label   vertices
      1 left_I-IV <int [10]>
    Message
      3D (ggseg3d): meshes
    Output
               label vertices faces
      1 left_dentate        3     1

# print methods / names the surface it was told about, not the one it assumes

    Code
      print(data)
    Message
      
      -- ggseg_data_cerebellar --
      
      3D (ggseg3d): vertex indices into the "hippunfold" surface
    Output
            label   vertices
      1 left_I-IV <int [10]>

# print methods / prints ggseg_data_cerebellar without vertices

    Code
      print(data)
    Message
      
      -- ggseg_data_cerebellar --
      
      2D (ggseg): 1 labels (sf), views: flatmap

# print methods / prints ggseg_data_tract with sf and centerlines

    Code
      print(data)
    Message
      
      -- ggseg_data_tract --
      
      2D (ggseg): 1 labels (sf), views: sagittal
      3D (ggseg3d): 1 centerlines (10 points)

