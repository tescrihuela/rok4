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

# Utility rule file for generate-Rok4Server-en-po.

# Include the progress variables for this target.
include rok4/po/CMakeFiles/generate-Rok4Server-en-po.dir/progress.make

rok4/po/CMakeFiles/generate-Rok4Server-en-po: ../rok4/po/en.po

../rok4/po/en.po: ../rok4/po/Rok4Server.pot
	$(CMAKE_COMMAND) -E cmake_progress_report /rok4-tobuild/build/CMakeFiles $(CMAKE_PROGRESS_1)
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold "Generating ../../../rok4/po/en.po"
	cd /rok4-tobuild/build/rok4/po && /usr/bin/msgmerge --lang=en /rok4-tobuild/rok4/po/en.po /rok4-tobuild/rok4/po/Rok4Server.pot -o /rok4-tobuild/rok4/po/en.po.new
	cd /rok4-tobuild/build/rok4/po && mv /rok4-tobuild/rok4/po/en.po.new /rok4-tobuild/rok4/po/en.po

../rok4/po/Rok4Server.pot: ../rok4/po/../CapabilitiesBuilder.cpp
../rok4/po/Rok4Server.pot: ../rok4/po/../ConfLoader.cpp
../rok4/po/Rok4Server.pot: ../rok4/po/../ConfLoader.h
../rok4/po/Rok4Server.pot: ../rok4/po/../Layer.cpp
../rok4/po/Rok4Server.pot: ../rok4/po/../Layer.h
../rok4/po/Rok4Server.pot: ../rok4/po/../LegendURL.cpp
../rok4/po/Rok4Server.pot: ../rok4/po/../LegendURL.h
../rok4/po/Rok4Server.pot: ../rok4/po/../Level.cpp
../rok4/po/Rok4Server.pot: ../rok4/po/../Level.h
../rok4/po/Rok4Server.pot: ../rok4/po/../main.cpp
../rok4/po/Rok4Server.pot: ../rok4/po/../Message.cpp
../rok4/po/Rok4Server.pot: ../rok4/po/../Message.h
../rok4/po/Rok4Server.pot: ../rok4/po/../MetadataURL.cpp
../rok4/po/Rok4Server.pot: ../rok4/po/../MetadataURL.h
../rok4/po/Rok4Server.pot: ../rok4/po/../Pyramid.cpp
../rok4/po/Rok4Server.pot: ../rok4/po/../Pyramid.h
../rok4/po/Rok4Server.pot: ../rok4/po/../Request.cpp
../rok4/po/Rok4Server.pot: ../rok4/po/../Request.h
../rok4/po/Rok4Server.pot: ../rok4/po/../ResourceLocator.cpp
../rok4/po/Rok4Server.pot: ../rok4/po/../ResourceLocator.h
../rok4/po/Rok4Server.pot: ../rok4/po/../ResponseSender.cpp
../rok4/po/Rok4Server.pot: ../rok4/po/../ResponseSender.h
../rok4/po/Rok4Server.pot: ../rok4/po/../Rok4Api.cpp
../rok4/po/Rok4Server.pot: ../rok4/po/../Rok4Api.h
../rok4/po/Rok4Server.pot: ../rok4/po/../Rok4Server.cpp
../rok4/po/Rok4Server.pot: ../rok4/po/../Rok4Server.h
../rok4/po/Rok4Server.pot: ../rok4/po/../ServiceException.cpp
../rok4/po/Rok4Server.pot: ../rok4/po/../ServiceException.h
../rok4/po/Rok4Server.pot: ../rok4/po/../ServicesConf.h
../rok4/po/Rok4Server.pot: ../rok4/po/../Style.cpp
../rok4/po/Rok4Server.pot: ../rok4/po/../Style.h
../rok4/po/Rok4Server.pot: ../rok4/po/../TileMatrix.cpp
../rok4/po/Rok4Server.pot: ../rok4/po/../TileMatrix.h
../rok4/po/Rok4Server.pot: ../rok4/po/../TileMatrixSet.cpp
../rok4/po/Rok4Server.pot: ../rok4/po/../TileMatrixSet.h
../rok4/po/Rok4Server.pot: ../rok4/po/POTFILES.in
	$(CMAKE_COMMAND) -E cmake_progress_report /rok4-tobuild/build/CMakeFiles $(CMAKE_PROGRESS_2)
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold "Generating ../../../rok4/po/Rok4Server.pot"
	cd /rok4-tobuild/rok4/po && /usr/bin/xgettext --keyword=_ --flag=_:1:pass-c-format --keyword=N_ --flag=N_:1:pass-c-format --flag=autosprintf:1:c-format --from-code utf-8 -o /rok4-tobuild/rok4/po/Rok4Server.pot --default-domain=Rok4Server --add-comments=TRANSLATORS: --copyright-holder=IGN --msgid-bugs-address="geop_services@geoportail.fr" --directory=.. --files-from=/rok4-tobuild/build/rok4/po/POTFILES --package-version= --package-name=Rok4

generate-Rok4Server-en-po: rok4/po/CMakeFiles/generate-Rok4Server-en-po
generate-Rok4Server-en-po: ../rok4/po/en.po
generate-Rok4Server-en-po: ../rok4/po/Rok4Server.pot
generate-Rok4Server-en-po: rok4/po/CMakeFiles/generate-Rok4Server-en-po.dir/build.make
.PHONY : generate-Rok4Server-en-po

# Rule to build all files generated by this target.
rok4/po/CMakeFiles/generate-Rok4Server-en-po.dir/build: generate-Rok4Server-en-po
.PHONY : rok4/po/CMakeFiles/generate-Rok4Server-en-po.dir/build

rok4/po/CMakeFiles/generate-Rok4Server-en-po.dir/clean:
.PHONY : rok4/po/CMakeFiles/generate-Rok4Server-en-po.dir/clean

rok4/po/CMakeFiles/generate-Rok4Server-en-po.dir/depend:
	cd /rok4-tobuild/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /rok4-tobuild /rok4-tobuild/rok4/po /rok4-tobuild/build /rok4-tobuild/build/rok4/po /rok4-tobuild/build/rok4/po/CMakeFiles/generate-Rok4Server-en-po.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : rok4/po/CMakeFiles/generate-Rok4Server-en-po.dir/depend

