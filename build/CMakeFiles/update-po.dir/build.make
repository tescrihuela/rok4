# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 2.8

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:

# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list

# Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /rok4-tobuild

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /rok4-tobuild/build

# Utility rule file for update-po.

# Include the progress variables for this target.
include CMakeFiles/update-po.dir/progress.make

CMakeFiles/update-po:

update-po: CMakeFiles/update-po
update-po: CMakeFiles/update-po.dir/build.make
.PHONY : update-po

# Rule to build all files generated by this target.
CMakeFiles/update-po.dir/build: update-po
.PHONY : CMakeFiles/update-po.dir/build

CMakeFiles/update-po.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/update-po.dir/cmake_clean.cmake
.PHONY : CMakeFiles/update-po.dir/clean

CMakeFiles/update-po.dir/depend:
	cd /rok4-tobuild/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /rok4-tobuild /rok4-tobuild /rok4-tobuild/build /rok4-tobuild/build /rok4-tobuild/build/CMakeFiles/update-po.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/update-po.dir/depend

