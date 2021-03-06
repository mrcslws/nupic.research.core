# -----------------------------------------------------------------------------
# Numenta Platform for Intelligent Computing (NuPIC)
# Copyright (C) 2016, Numenta, Inc.  Unless you have purchased from
# Numenta, Inc. a separate commercial license for this software code, the
# following terms and conditions apply:
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero Public License version 3 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Affero Public License for more details.
#
# You should have received a copy of the GNU Affero Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# http://numenta.org/licenses/
# -----------------------------------------------------------------------------

# Combine multiple Unix static libraries into a single static library.
#
# This script is intended to be invoked via `${CMAKE_COMMAND} -DLIB_TARGET= ...`.
#
# ARGS:
#
#   LIB_TARGET: target name of resulting static library (passed to add_library)
#   TARGET_LOCATION: Full path to the target library
#   SRC_LIB_LOCATIONS: List of source static library paths
#   LIST_SEPARATOR: separator string that separates paths in
#     SRC_LIB_LOCATIONS; NOTE with cmake 2.8.11+, caller could use the generator
#     "$<SEMICOLON>" in SRC_LIB_LOCATIONS, and this arg would be unnecessary.
#   BINARY_DIR: The value of ${CMAKE_CURRENT_BINARY_DIR} from caller
#   CMAKE_AR: The value of ${CMAKE_AR} from caller

function(COMBINE_UNIX_ARCHIVES
         LIB_TARGET
         TARGET_LOCATION
         SRC_LIB_LOCATIONS
         LIST_SEPARATOR
         BINARY_DIR
         CMAKE_AR)

  message(STATUS
          "COMBINE_UNIX_ARCHIVES("
          "  LIB_TARGET=${LIB_TARGET}, "
          "  TARGET_LOCATION=${TARGET_LOCATION}, "
          "  SRC_LIB_LOCATIONS=${SRC_LIB_LOCATIONS}, "
          "  LIST_SEPARATOR=${LIST_SEPARATOR}, "
          "  BINARY_DIR=${BINARY_DIR}, "
          "  CMAKE_AR=${CMAKE_AR})")

  string(REPLACE ${LIST_SEPARATOR} ";"
         SRC_LIB_LOCATIONS "${SRC_LIB_LOCATIONS}")

  set(scratch_dir ${BINARY_DIR}/combine_unix_archives_${LIB_TARGET})
  file(MAKE_DIRECTORY ${scratch_dir})

  # Extract archives into individual directories to avoid object file collisions
  set(all_object_locations)
  foreach(lib ${SRC_LIB_LOCATIONS})
    message(STATUS "COMBINE_UNIX_ARCHIVES: LIB_TARGET=${LIB_TARGET}, src-lib=${lib}")
    # Create working directory for current source lib
    get_filename_component(basename ${lib} NAME)
    set(working_dir ${scratch_dir}/${basename}.dir)
    file(MAKE_DIRECTORY ${working_dir})

    # Extract objects from current source lib
    execute_process(COMMAND ${CMAKE_AR} -x ${lib}
                    WORKING_DIRECTORY ${working_dir})

    # Accumulate objects
    file(GLOB_RECURSE objects "${working_dir}/*")
    list(APPEND all_object_locations ${objects})
  endforeach()

  # Generate the target static library from all source objects
  file(TO_NATIVE_PATH ${TARGET_LOCATION} TARGET_LOCATION)
  execute_process(COMMAND ${CMAKE_AR} rcs ${TARGET_LOCATION} ${all_object_locations})

  # Remove scratch directory
  file(REMOVE_RECURSE ${scratch_dir})
endfunction(COMBINE_UNIX_ARCHIVES)


combine_unix_archives(${LIB_TARGET}
                      ${TARGET_LOCATION}
                      "${SRC_LIB_LOCATIONS}"
                      ${LIST_SEPARATOR}
                      ${BINARY_DIR}
                      ${CMAKE_AR})
