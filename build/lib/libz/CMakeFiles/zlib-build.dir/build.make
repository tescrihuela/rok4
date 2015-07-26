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

# Utility rule file for zlib-build.

# Include the progress variables for this target.
include lib/libz/CMakeFiles/zlib-build.dir/progress.make

lib/libz/CMakeFiles/zlib-build: lib/libz/install/lib/libz.a

lib/libz/install/lib/libz.a: lib/libz/src/configure
	$(CMAKE_COMMAND) -E cmake_progress_report /rok4-tobuild/build/CMakeFiles $(CMAKE_PROGRESS_1)
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold "Generating install/lib/libz.a"
	cd /rok4-tobuild/build/lib/libz/src && CFLAGS=-O3 ./configure --static --prefix=/rok4-tobuild/build/lib/libz/install
	cd /rok4-tobuild/build/lib/libz/src && make
	cd /rok4-tobuild/build/lib/libz/src && make install

lib/libz/src/configure:
	$(CMAKE_COMMAND) -E cmake_progress_report /rok4-tobuild/build/CMakeFiles $(CMAKE_PROGRESS_2)
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold "Generating src/configure"
	cd /rok4-tobuild/build/lib/libz && mkdir -p src
	cd /rok4-tobuild/build/lib/libz && cp -f -r -l /rok4-tobuild/lib/libz/zlib-1.2.5/* src

zlib-build: lib/libz/CMakeFiles/zlib-build
zlib-build: lib/libz/install/lib/libz.a
zlib-build: lib/libz/src/configure
zlib-build: lib/libz/CMakeFiles/zlib-build.dir/build.make
.PHONY : zlib-build

# Rule to build all files generated by this target.
lib/libz/CMakeFiles/zlib-build.dir/build: zlib-build
.PHONY : lib/libz/CMakeFiles/zlib-build.dir/build

lib/libz/CMakeFiles/zlib-build.dir/clean:
	cd /rok4-tobuild/build/lib/libz && $(CMAKE_COMMAND) -P CMakeFiles/zlib-build.dir/cmake_clean.cmake
.PHONY : lib/libz/CMakeFiles/zlib-build.dir/clean

lib/libz/CMakeFiles/zlib-build.dir/depend:
	cd /rok4-tobuild/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /rok4-tobuild /rok4-tobuild/lib/libz /rok4-tobuild/build /rok4-tobuild/build/lib/libz /rok4-tobuild/build/lib/libz/CMakeFiles/zlib-build.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : lib/libz/CMakeFiles/zlib-build.dir/depend

