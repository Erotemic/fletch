set(allOk True)
set(errorMessage)

option(AUTO_ENABLE_CAFFE2_DEPENDENCY "Automatically turn on all caffe dependencies if caffe is enabled" OFF)
if(fletch_ENABLE_Caffe2 AND AUTO_ENABLE_CAFFE2_DEPENDENCY)
  #Snappy is needed by LevelDB and ZLib is needed by HDF5
  if(WIN32)
    set(dependency Boost GFlags GLog ZLib OpenCV HDF5)
  else()
    set(dependency Boost GFlags GLog Snappy LevelDB LMDB OpenCV Protobuf)
  endif()

  if(NOT APPLE AND NOT WIN32)
    list(APPEND dependency OpenBLAS)
  endif()

  set(OneWasOff FALSE)

  foreach (_var IN LISTS dependency)
    get_property(currentHelpString CACHE "fletch_ENABLE_${_var}" PROPERTY HELPSTRING)
    set(fletch_ENABLE_${_var} ON CACHE BOOL ${currentHelpString} FORCE)
    if(NOT TARGET ${_var})
      include(External_${_var})
    endif()
  endforeach()
endif()

function(addCaffe2Dendency depend version)
  if(NOT fletch_ENABLE_${depend} )
    find_package(${depend} ${version} QUIET)
    string(TOUPPER "${depend}" dependency_name_upper)
    if(NOT ${depend}_FOUND AND NOT ${dependency_name_upper}_FOUND)
      message("${depend} is needed")
      set(allOk False PARENT_SCOPE)
      return()
    endif()
    message("Warning: Using system library for ${depend}")
  else() #need to make sure library is built before caffe
    set(Caffe2_DEPENDS ${Caffe2_DEPENDS} ${depend} PARENT_SCOPE)
  endif()
  add_package_dependency(
    PACKAGE Caffe2
    PACKAGE_DEPENDENCY ${depend}
    PACKAGE_DEPENDENCY_ALIAS ${depend}
    )
endfunction()

# Check for dependencies.
#if(NOT WIN32) # Win32 build takes care of most dependencies automatically
#  addCaffe2Dendency(LevelDB "")
#  addCaffe2Dendency(LMDB "")
#  if(NOT APPLE)
#    addCaffe2Dendency(OpenBLAS "")
#  endif()
#  addCaffe2Dendency(Protobuf "")
#endif()
addCaffe2Dendency(Boost 1.46)
addCaffe2Dendency(GFlags "")
addCaffe2Dendency(GLog "")
addCaffe2Dendency(OpenCV "")

if(NOT allOk)
  message(FATAL_ERROR "Missing dependency(ies).")
endif()

# Set paths which Caffe2 requires for protobuf and opencv

set( CAFFE2_PROTOBUF_ARGS )

if(fletch_ENABLE_Protobuf)
  get_system_library_name( protobuf protobuf_libname )
  get_system_library_name( protobuf-lite protobuf-lite_libname )
  get_system_library_name( protoc protoc_libname )

  set( CAFFE2_PROTOBUF_ARGS
    -DPROTOBUF_INCLUDE_DIR:PATH=${fletch_BUILD_INSTALL_PREFIX}/include
    -DPROTOBUF_LIBRARY:PATH=${fletch_BUILD_INSTALL_PREFIX}/lib/${protobuf_libname}
    -DPROTOBUF_LIBRARY_DEBUG:PATH=${fletch_BUILD_INSTALL_PREFIX}/lib/${protobuf_libname}
    -DPROTOBUF_LITE_LIBRARY:PATH=${fletch_BUILD_INSTALL_PREFIX}/lib/${protobuf-lite_libname}
    -DPROTOBUF_LITE_LIBRARY_DEBUG:PATH=${fletch_BUILD_INSTALL_PREFIX}/lib/${protobuf-lite_libname}
    -DPROTOBUF_PROTOC_EXECUTABLE:PATH=${fletch_BUILD_INSTALL_PREFIX}/bin/protoc
    -DPROTOBUF_PROTOC_LIBRARY:PATH=${fletch_BUILD_INSTALL_PREFIX}/lib/${protoc_libname}
    -DPROTOBUF_PROTOC_LIBRARY_DEBUG:PATH=${fletch_BUILD_INSTALL_PREFIX}/lib/${protoc_libname}
    )
else()
  set( CAFFE2_PROTOBUF_ARGS
    -DPROTOBUF_INCLUDE_DIR:PATH=${PROTOBUF_INCLUDE_DIR}
    -DPROTOBUF_LIBRARY:PATH=${PROTOBUF_LIBRARY}
    -DPROTOBUF_LIBRARY_DEBUG:PATH=${PROTOBUF_LIBRARY_DEBUG}
    -DPROTOBUF_LITE_LIBRARY:PATH=${PROTOBUF_LITE_LIBRARY}
    -DPROTOBUF_LITE_LIBRARY_DEBUG:PATH=${PROTOBUF_LITE_LIBRARY_DEBUG}
    -DPROTOBUF_PROTOC_EXECUTABLE:PATH=${PROTOBUF_PROTOC_EXECUTABLE}
    -DPROTOBUF_PROTOC_LIBRARY:PATH=${PROTOBUF_PROTOC_LIBRARY}
    -DPROTOBUF_PROTOC_LIBRARY_DEBUG:PATH=${PROTOBUF_PROTOC_LIBRARY_DEBUG}
  )
endif()

if(fletch_ENABLE_OpenCV)
  set( CAFFE2_OPENCV_ARGS
    -DUSE_OPENCV:BOOL=${fletch_ENABLE_OpenCV}
    -DOpenCV_DIR:PATH=${fletch_BUILD_PREFIX}/src/OpenCV-build
    -DOpenCV_LIB_PATH:PATH=${OpenCV_ROOT}/lib
    )
else()
  set( CAFFE2_OPENCV_ARGS
    -DUSE_OPENCV:BOOL=${fletch_ENABLE_OpenCV}
  )
endif()

if(fletch_ENABLE_LMDB)
  get_system_library_name( lmdb lmdb_libname )

  set( CAFFE2_LMDB_ARGS
    -DLMDB_INCLUDE_DIR:PATH=${fletch_BUILD_INSTALL_PREFIX}/include
    -DLMDB_LIBRARIES:PATH=${fletch_BUILD_INSTALL_PREFIX}/lib/${lmdb_libname}
    )
else()
  set( CAFFE2_LMDB_ARGS
    -DLMDB_INCLUDE_DIR:PATH=${LMDB_INCLUDE_DIR}
    -DLMDB_LIBRARIES:PATH=${LMDB_LIBRARY}
    )
endif()

if(fletch_ENABLE_LevelDB)
  get_system_library_name( leveldb leveldb_libname )
  # NOTE: Caffe2 currently has LevelDB_INCLUDE instead of the normal LevelDB_INCLUDE_DIR
  set( CAFFE2_LevelDB_ARGS
    -DLevelDB_INCLUDE:PATH=${fletch_BUILD_INSTALL_PREFIX}/include
    -DLevelDB_LIBRARY:PATH=${fletch_BUILD_INSTALL_PREFIX}/lib/${leveldb_libname}
    )
else()
  set( CAFFE2_LevelDB_ARGS
    -DLevelDB_INCLUDE:PATH=${LevelDB_INCLUDE_DIR}
    -DLevelDB_LIBRARY:PATH=${LevelDB_LIBRARY}
    )
endif()

if(fletch_ENABLE_GLog)
  get_system_library_name( glog glog_libname )

  set( CAFFE2_GLog_ARGS
    -DGLOG_INCLUDE_DIR:PATH=${fletch_BUILD_INSTALL_PREFIX}/include
    -DGLOG_LIBRARY:PATH=${fletch_BUILD_INSTALL_PREFIX}/lib/${glog_libname}
    )
else()
  set( CAFFE2_GLog_ARGS
    -DGLOG_INCLUDE_DIR:PATH=${GLog_INCLUDE_DIR}
    -DGLOG_LIBRARY:FILEPATH=${GLog_LIBRARY}
    )
endif()

if(fletch_ENABLE_GFlags)
  get_system_library_name( gflags gflags_libname )

  set( CAFFE2_GFlags_ARGS
    -DGFLAGS_INCLUDE_DIR:PATH=${fletch_BUILD_INSTALL_PREFIX}/include
    -DGFLAGS_LIBRARY:PATH=${fletch_BUILD_INSTALL_PREFIX}/lib/${gflags_libname}
    )
else()
  set( CAFFE2_GFlags_ARGS -DGFLAGS_ROOT_DIR:PATH=${GFlags_DIR})
endif()

if(fletch_BUILD_WITH_PYTHON AND fletch_ENABLE_Boost)
  if(Boost_Do_BCP_Name_Mangling)
    message(FATAL_ERROR "Cannot have Boost mangling enabled and use pycaffe.")
  endif()
  find_package(NumPy 1.7 REQUIRED)
  set(PYTHON_ARGS
      -DBUILD_PYTHON:BOOL=ON
      -DPYTHON_EXECUTABLE=${PYTHON_EXECUTABLE}
      -DPYTHON_LIBRARY=${PYTHON_LIBRARY}
      -DPYTHON_INCLUDE_DIR=${PYTHON_INCLUDE_DIR}
      -DNUMPY_INCLUDE_DIR=${NUMPY_INCLUDE_DIR}
      -DNUMPY_VERSION=${NUMPY_VERSION}
      )
else()
  set(PYTHON_ARGS -DBUILD_PYTHON:BOOL=OFF)
endif()

if(fletch_ENABLE_OpenBLAS)
  get_system_library_name(openblas openblas_libname)
  set(CAFFE2_OPENBLAS_ARGS "-DOpenBLAS_INCLUDE_DIR=${OpenBLAS_ROOT}/include"
    "-DOpenBLAS_LIB=${OpenBLAS_ROOT}/lib/${openblas_libname}")
else()
  set(CAFFE2_OPENBLAS_ARGS "-DOpenBLAS_INCLUDE_DIR=${OpenBLAS_INCLUDE_DIR}"
    "-DOpenBLAS_LIB=${OpenBLAS_LIBRARY}")
endif()

if(fletch_BUILD_WITH_CUDA)
  format_passdowns("CUDA" CUDA_BUILD_FLAGS)
  set( CAFFE2_GPU_ARGS
    ${CUDA_BUILD_FLAGS}
    -DUSE_CUDA:BOOL=On
    )
  if(fletch_BUILD_WITH_CUDNN)
    format_passdowns("CUDNN" CUDNN_BUILD_FLAGS)
    set(CAFFE2_CUDNN_ARGS
      -D CUDNN_LIBRARY=${CUDNN_LIBRARIES}
      -D CUDNN_ROOT_DIR=${CUDNN_TOOLKIT_ROOT_DIR}
      ${CUDNN_BUILD_FLAGS}
      #-DUSE_CUDNN:BOOL=ON
    )
    set( CAFFE2_GPU_ARGS ${CAFFE2_GPU_ARGS} ${CAFFE2_CUDNN_ARGS})
  else()
    set( CAFFE2_GPU_ARGS
      ${CAFFE2_GPU_ARGS}
      #-DUSE_CUDNN:BOOL=OFF
    )
  endif()
else()
  set( CAFFE2_GPU_ARGS
    #-DCPU_ONLY:BOOL=ON
    #-DUSE_CUDNN:BOOL=OFF
    )
endif()


set (Caffe2_PATCH_DIR "${fletch_SOURCE_DIR}/Patches/Caffe2/${Caffe2_version}")
if (EXISTS ${Caffe2_PATCH_DIR})
  set(
    Caffe2_PATCH_COMMAND ${CMAKE_COMMAND}
    -DCaffe2_patch=${Caffe2_PATCH_DIR}
    -DCaffe2_source=${fletch_BUILD_PREFIX}/src/Caffe2
    -P ${Caffe2_PATCH_DIR}/Patch.cmake
    )
else()
  set(Caffe2_PATCH_COMMAND "")
endif()


# Main build and install command
if(WIN32)
ExternalProject_Add(Caffe2
  DEPENDS ${Caffe2_DEPENDS}
  URL ${Caffe2_url}
  URL_MD5 ${Caffe2_md5}
  PREFIX ${fletch_BUILD_PREFIX}
  DOWNLOAD_DIR ${fletch_DOWNLOAD_DIR}
  INSTALL_DIR ${fletch_BUILD_INSTALL_PREFIX}

  PATCH_COMMAND ${Caffe2_PATCH_COMMAND}

  CMAKE_COMMAND
  CMAKE_GENERATOR ${gen}
  CMAKE_ARGS
    ${COMMON_CMAKE_ARGS}
    -DCMAKE_CXX_COMPILER:PATH=${CMAKE_CXX_COMPILER}
    -DCMAKE_C_COMPILER:PATH=${CMAKE_C_COMPILER}
    -DBOOST_ROOT:PATH=${BOOST_ROOT}
    -DBoost_USE_STATIC_LIBS:BOOL=OFF
    -DBLAS:STRING=OpenBLAS
    -DBUILD_SHARED_LIBS:BOOL=ON
    ${CAFFE2_OPENCV_ARGS}
    ${PYTHON_ARGS}
    ${CAFFE2_GPU_ARGS}
)
else()
ExternalProject_Add(Caffe2
  DEPENDS ${Caffe2_DEPENDS}
  URL ${Caffe2_url}
  URL_MD5 ${Caffe2_md5}
  PREFIX ${fletch_BUILD_PREFIX}
  DOWNLOAD_DIR ${fletch_DOWNLOAD_DIR}
  INSTALL_DIR ${fletch_BUILD_INSTALL_PREFIX}
  CMAKE_COMMAND
  CMAKE_GENERATOR ${gen}
  CMAKE_ARGS
    ${COMMON_CMAKE_ARGS}
    -DCMAKE_CXX_COMPILER:PATH=${CMAKE_CXX_COMPILER}
    -DCMAKE_C_COMPILER:PATH=${CMAKE_C_COMPILER}
    -DBOOST_ROOT:PATH=${BOOST_ROOT}
    -DBLAS:STRING=OpenBLAS
    -DBUILD_TEST:BOOL=OFF
    #PATCH_COMMAND ${Caffe2_PATCH_COMMAND}
    #NCCL_ROOT_DIR="https://github.com/NVIDIA/nccl/archive/v1.3.4-1.zip"
    #CUB_URL=https://github.com/NVlabs/cub/archive/v1.8.0.zip
    -DUSE_NCCL:BOOL=OFF
    -DUSE_GLOO:BOOL=OFF
    -DUSE_MPI:BOOL=OFF
    -DUSE_METAL:BOOL=OFF
    -DUSE_ROCKSDB:BOOL=OFF
    -DUSE_MOBILE_OPENGL:BOOL=OFF
    -DUSE_NNPACK:BOOL=OFF
    ${PYTHON_ARGS}
    ${CAFFE2_PROTOBUF_ARGS}
    ${CAFFE2_OPENCV_ARGS}
    ${CAFFE2_LMDB_ARGS}
    ${CAFFE2_LevelDB_ARGS}
    ${CAFFE2_GLog_ARGS}
    ${CAFFE2_GFlags_ARGS}
    ${CAFFE2_OPENBLAS_ARGS}
    ${CAFFE2_GPU_ARGS}
  )
endif()

fletch_external_project_force_install(PACKAGE Caffe2)

set(Caffe2_ROOT ${fletch_BUILD_INSTALL_PREFIX} CACHE STRING "")

file(APPEND ${fletch_CONFIG_INPUT} "
########################################
# Caffe2
########################################
set(Caffe2_ROOT    \${fletch_ROOT})
")
