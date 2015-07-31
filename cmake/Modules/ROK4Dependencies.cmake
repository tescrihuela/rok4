if(ROK4DEPENDENCIES_FOUND)
  #message(STATUS "Dependencies already found")
  return()
endif(ROK4DEPENDENCIES_FOUND)

set(ROK4DEPENDENCIES_FOUND TRUE BOOL)

if(NOT TARGET thread)
  find_package(Threads REQUIRED)
  if(NOT CMAKE_USE_PTHREADS_INIT)
    message(FATAL_ERROR "Need the PThread library")
  endif(NOT CMAKE_USE_PTHREADS_INIT)
  add_library(thread STATIC IMPORTED)
  set_property(TARGET thread PROPERTY IMPORTED_LOCATION ${CMAKE_THREAD_LIBS_INIT})
endif(NOT TARGET thread)

if(UNITTEST)
  if(NOT TARGET cppunit)
  find_package(CppUnit)
    if(CPPUNIT_FOUND)
      add_library(cppunit SHARED IMPORTED)
      set_property(TARGET cppunit PROPERTY IMPORTED_LOCATION ${CPPUNIT_LIBRARY})
    else(CPPUNIT_FOUND)
      if(BUILD_DEPENDENCIES)
        message(STATUS "Building libCppUnit")
        if(NOT TARGET cppunit)
          add_library(cppunit SHARED IMPORTED)
        endif(NOT TARGET cppunit)
        add_subdirectory(${ROK4LIBSDIR}/libcppunit)
      endif(BUILD_DEPENDENCIES)
    endif(CPPUNIT_FOUND)
  endif(NOT TARGET cppunit)
endif(UNITTEST)

if(NOT TARGET fcgi)
find_package(Fcgi)
if(FCGI_FOUND)
  add_library(fcgi STATIC IMPORTED)
  set_property(TARGET fcgi PROPERTY IMPORTED_LOCATION ${FCGI_LIBRARY})
else(FCGI_FOUND)
  if(BUILD_DEPENDENCIES)
    message(STATUS "Building libFCGI")
    add_subdirectory(${ROK4LIBSDIR}/libfcgi)
  endif(BUILD_DEPENDENCIES)
endif(FCGI_FOUND)
endif(NOT TARGET fcgi)

if(NOT TARGET jpeg)
find_package(Jpeg)
if(JPEG_FOUND)
  add_library(jpeg STATIC IMPORTED)
  set_property(TARGET jpeg PROPERTY IMPORTED_LOCATION ${JPEG_LIBRARY})
else(JPEG_FOUND)
  if(BUILD_DEPENDENCIES)
    message(STATUS "Building libJpeg")
    if(NOT TARGET jpeg)
      add_library(jpeg STATIC IMPORTED)
    endif(NOT TARGET jpeg)
    add_subdirectory(${ROK4LIBSDIR}/libjpeg)
  endif(BUILD_DEPENDENCIES)
endif(JPEG_FOUND)
endif(NOT TARGET jpeg)

if(NOT TARGET proj)
find_package(Proj)
if(PROJ_FOUND)
  add_library(proj STATIC IMPORTED)
  set_property(TARGET proj PROPERTY IMPORTED_LOCATION ${PROJ_LIBRARY})
else(PROJ_FOUND)
  if(BUILD_DEPENDENCIES)
    message(STATUS "Building libproj")
    if(NOT TARGET proj)
      add_library(proj STATIC IMPORTED)
    endif(NOT TARGET proj)
    add_subdirectory(${ROK4LIBSDIR}/libproj)
  endif(BUILD_DEPENDENCIES)
endif(PROJ_FOUND)
endif(NOT TARGET proj)

if(NOT TARGET tinyxml)
find_package(TinyXML)
if(TINYXML_FOUND)
  add_library(tinyxml STATIC IMPORTED)
  set_property(TARGET tinyxml PROPERTY IMPORTED_LOCATION ${TINYXML_LIBRARY})
else(TINYXML_FOUND)
  if(BUILD_DEPENDENCIES)
    message(STATUS "Building libTinyXML")
    add_subdirectory(${ROK4LIBSDIR}/libtinyxml)
  endif(BUILD_DEPENDENCIES)
endif(TINYXML_FOUND)
endif(NOT TARGET tinyxml)

if(NOT TARGET lzw)
find_package(LZW)
if(LZW_FOUND)
  add_library(lzw STATIC IMPORTED)
  set_property(TARGET lzw PROPERTY IMPORTED_LOCATION ${LZW_LIBRARY})
else(LZW_FOUND)
  if(BUILD_DEPENDENCIES)
    message(STATUS "Building LZW")
    add_subdirectory(${ROK4LIBSDIR}/liblzw)
  endif(BUILD_DEPENDENCIES)
endif(LZW_FOUND)
endif(NOT TARGET lzw)

if(NOT TARGET pkb)
find_package(PKB)
if(PKB_FOUND)
  add_library(pkb STATIC IMPORTED)
  set_property(TARGET pkb PROPERTY IMPORTED_LOCATION ${PKB_LIBRARY})
else(PKB_FOUND)
  if(BUILD_DEPENDENCIES)
    message(STATUS "Building PKB")
    add_subdirectory(${ROK4LIBSDIR}/libpkb)
  endif(BUILD_DEPENDENCIES)
endif(PKB_FOUND)
endif(NOT TARGET pkb)

if(NOT TARGET zlib)
find_package(Zlib)
if(ZLIB_FOUND)
  add_library(zlib STATIC IMPORTED)
  set_property(TARGET zlib PROPERTY IMPORTED_LOCATION ${ZLIB_LIBRARY})
else(ZLIB_FOUND)
  if(BUILD_DEPENDENCIES)
    message(STATUS "Building LibZ")
      if(NOT TARGET zlib)
        add_library(zlib STATIC IMPORTED)
      endif(NOT TARGET zlib)
    add_subdirectory(${ROK4LIBSDIR}/libz)
  endif(BUILD_DEPENDENCIES)
endif(ZLIB_FOUND)
endif(NOT TARGET zlib)

if(NOT TARGET tiff)
find_package(TIFF)
if(TIFF_FOUND)
  add_library(tiff STATIC IMPORTED)
  set_property(TARGET tiff PROPERTY IMPORTED_LOCATION ${TIFF_LIBRARY})
else(TIFF_FOUND)
  if(BUILD_DEPENDENCIES)
    message(STATUS "Building libTIFF")
    if(NOT TARGET tiff)
      add_library(tiff STATIC IMPORTED)
    endif(NOT TARGET tiff)

    add_subdirectory(${ROK4LIBSDIR}/libtiff)
  endif(BUILD_DEPENDENCIES)
endif(TIFF_FOUND)
endif(NOT TARGET tiff)

if(NOT TARGET logger)
find_package(Logger)
if(LOGGER_FOUND)
  add_library(logger STATIC IMPORTED)
  set_property(TARGET logger PROPERTY IMPORTED_LOCATION ${LOGGER_LIBRARY})
else(LOGGER_FOUND)
  if(BUILD_DEPENDENCIES)
    message(STATUS "Building libLogger")
    add_subdirectory(${ROK4LIBSDIR}/liblogger)
  endif(BUILD_DEPENDENCIES)
endif(LOGGER_FOUND)
endif(NOT TARGET logger)

if(NOT TARGET png)
find_package(PNG)
if(PNG_FOUND)
  add_library(png STATIC IMPORTED)
  set_property(TARGET png PROPERTY IMPORTED_LOCATION ${PNG_LIBRARY})
else(PNG_FOUND)
  if(BUILD_DEPENDENCIES)
    message(STATUS "Building libPNG")
    add_subdirectory(${ROK4LIBSDIR}/libpng)
  endif(BUILD_DEPENDENCIES)  
endif(PNG_FOUND)
endif(NOT TARGET png)

if(NOT TARGET curl)
find_package(CURL)
if(CURL_FOUND)
  add_library(curl STATIC IMPORTED)
  set_property(TARGET curl PROPERTY IMPORTED_LOCATION ${CURL_LIBRARY})
else(CURL_FOUND)
  if(BUILD_DEPENDENCIES)
    message(STATUS "Building libCurl")
    add_subdirectory(${ROK4LIBSDIR}/libCurl)
    add_library(curl STATIC IMPORTED)
    set_property(TARGET curl PROPERTY IMPORTED_LOCATION ${CURL_LIBRARY})
  endif(BUILD_DEPENDENCIES)  
endif(CURL_FOUND)
endif(NOT TARGET curl)

IF(KDU_USE)
    if(NOT TARGET jpeg2000)
        find_package(KAKADU)
        if(KAKADU_FOUND)
          set(JPEG2000_FOUND TRUE)
          add_library(jpeg2000 STATIC IMPORTED)
          set_property(TARGET jpeg2000 PROPERTY IMPORTED_LOCATION ${KAKADU_LIBRARY_1})
          add_library(jpeg2000_plus STATIC IMPORTED)
          set_property(TARGET jpeg2000_plus PROPERTY IMPORTED_LOCATION ${KAKADU_LIBRARY_2})
          message(STATUS "    Kakadu's headers' directory : ${JPEG2000_INCLUDE_DIR}")
          message(STATUS "    'libkdu_aux.a' directory : ${KAKADU_LIBRARY_1}")
          message(STATUS "    'libkdu.a' directory : ${KAKADU_LIBRARY_2}")
        else(KAKADU_FOUND)
          message(FATAL_ERROR "Cannot find extern library Kakadu")
        endif(KAKADU_FOUND)
    endif(NOT TARGET jpeg2000)
ELSE(KDU_USE)
    if(NOT TARGET jpeg2000)
    find_package(OPENJPEG)
    if(OPENJPEG_FOUND)
      add_library(jpeg2000 STATIC IMPORTED)
      set_property(TARGET jpeg2000 PROPERTY IMPORTED_LOCATION ${OPENJPEG_LIBRARY})
    else(OPENJPEG_FOUND)
      if(BUILD_DEPENDENCIES)
        set(JPEG2000_FOUND TRUE)
        message(STATUS "Building libOPENJPEG")
        add_subdirectory(${ROK4LIBSDIR}/libopenjpeg)
      endif(BUILD_DEPENDENCIES)
    endif(OPENJPEG_FOUND)
    endif(NOT TARGET jpeg2000)
ENDIF(KDU_USE)

if(NOT TARGET image)
find_package(Image)
if(IMAGE_FOUND)
  add_library(image STATIC IMPORTED)
  set_property(TARGET image PROPERTY IMPORTED_LOCATION ${IMAGE_LIBRARY})
else(IMAGE_FOUND)
  if(BUILD_DEPENDENCIES)
    set(IMAGE_FOUND TRUE)
    message(STATUS "Building libImage")
    add_subdirectory(${ROK4LIBSDIR}/libimage)
  endif(BUILD_DEPENDENCIES)
endif(IMAGE_FOUND)
endif(NOT TARGET image)

add_subdirectory(${ROK4LIBSDIR}/libxerces)

#Gettext Support

set(GettextTranslate_ALL FALSE)
set(GettextTranslate_GMO_BINARY TRUE)
include(GettextTranslate)

set(ROK4DEPENDENCIES_FOUND TRUE BOOL)

