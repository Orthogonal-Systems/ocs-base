##################################################################################
# Modfied version of Matthias Kleemann's cmake-avr project:
# github.com/mkleemann/cmake-avr
#
# Modified by: Matthew Ebert <mfe5003@gmail.com>
# 
# Original license is below
##################################################################################

##################################################################################
# "THE ANY BEVERAGE-WARE LICENSE" (Revision 42 - based on beer-ware
# license):
# <dev@layer128.net> wrote this file. As long as you retain this notice
# you can do whatever you want with this stuff. If we meet some day, and
# you think this stuff is worth it, you can buy me a be(ve)er(age) in
# return. (I don't like beer much.)
#
# Matthias Kleemann
##################################################################################

################################################################################
### Options
option(WITH_MCU "Add the mCU type to the target filename." OFF)#ON)

################################################################################
### avr toolchain executables
SET(AVR_CC avr-gcc)
SET(AVR_CXX avr-g++)
SET(AVR_OBJCOPY avr-objcopy)
SET(AVR_SIZE_TOOL avr-size)
SET(AVR_OBJDUMP avr-objdump)


################################################################################
### define system variables
SET(CMAKE_SYSTEM_NAME Generic)  # target (mcu) system
SET(CMAKE_SYSTEM_PROCESSOR avr) # target (mcu) processor
SET(CMAKE_C_COMPILER ${AVR_CC})
SET(CMAKE_CXX_COMPILER ${AVR_CXX})

################################################################################
### default tool paths
IF(NOT AVR_UPLOADTOOL)
  SET(
    AVR_UPLOADTOOL avrdude
    CACHE STRING "Set default upload tool: avrdude"
  )
  SET(AVR_UPLOADTOOL_STAT [DEFAULT])
  find_program(AVR_UPLOADTOOL avrdude)
endif(NOT AVR_UPLOADTOOL)

IF(NOT AVR_UPLOADTOOL_PORT)
  SET(
    AVR_UPLOADTOOL_PORT /dev/ttyACM*
    CACHE STRING "Set default upload tool port: ttyACM*"
  )
  SET(AVR_UPLOADTOOL_PORT_STAT [DEFAULT])
endif(NOT AVR_UPLOADTOOL_PORT)

IF(NOT AVR_PROGRAMMER)
  SET(
    AVR_PROGRAMMER arduino#avrispmkII
    CACHE STRING "Set default programmer hardware model: arduino"
  )
  SET(AVR_PROGRAMMER_STAT [DEFAULT])
endif(NOT AVR_PROGRAMMER)

IF(NOT AVR_SIZE_ARGS)
  IF(APPLE)
    set(AVR_SIZE_ARGS -B)
  ELSE(APPLE)
    set(AVR_SIZE_ARGS -C;--mcu=${AVR_MCU})
  ENDIF(APPLE)
ENDIF(NOT AVR_SIZE_ARGS)

################################################################################
### MCU and fuses
IF(NOT AVR_MCU)
  SET(AVR_MCU atmega328p)
  SET(AVR_MCU_STAT [DEFAULT])
ENDIF(NOT AVR_MCU)
IF(NOT F_CPU)
  SET(F_CPU "16000000L")  # Hz
  SET(F_CPU_STAT [DEFAULT])
ENDIF(NOT F_CPU)
IF(NOT AVR_H_FUSE)
  SET(AVR_H_FUSE 0xff)
  SET(AVR_H_FUSE_STAT [DEFAULT])
ENDIF(NOT AVR_H_FUSE)
IF(NOT AVR_L_FUSE)
  SET(AVR_L_FUSE 0xde)
  SET(AVR_L_FUSE_STAT [DEFAULT])
ENDIF(NOT AVR_L_FUSE)
IF(NOT AVR_E_FUSE)
  SET(AVR_E_FUSE 0x05) # for arduino bootloader only I think
  SET(AVR_E_FUSE_STAT [DEFAULT])
ENDIF(NOT AVR_E_FUSE)

### if we are appending the mcu to the filename set that here
IF(WITH_MCU)
  SET(MCU_TYPE_FOR_FILENAME "-${AVR_MCU}")
ELSE(WITH_MCU)
  SET(MCU_TYPE_FOR_FILENAME "")
ENDIF(WITH_MCU)

################################################################################
### check build types and default to Release
IF(NOT ((CMAKE_BUILD_TYPE MATCHES Release) OR
  (CMAKE_BUILD_TYPE MATCHES RelWithDebInfo) OR
  (CMAKE_BUILD_TYPE MATCHES Debug) OR
  (CMAKE_BUILD_TYPE MATCHES MinSizeRel))
)
  SET(
    CMAKE_BUILD_TYPE Release
    CACHE STRING "Choose cmake build type: Debug Release RelWithDebInfo MinSizeRel"
    FORCE
  )
ENDIF(NOT ((CMAKE_BUILD_TYPE MATCHES Release) OR
  (CMAKE_BUILD_TYPE MATCHES RelWithDebInfo) OR
  (CMAKE_BUILD_TYPE MATCHES Debug) OR
  (CMAKE_BUILD_TYPE MATCHES MinSizeRel))
)

#### Linker flags
#### TODO: figure out a way to remove the rdynamic flag without clobbering
set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")   # remove -rdynamic for C
set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "") # remove -rdynamic for CXX

#### version of the libraries we are using
SET(ARDUINO_VERSION "105")

##### compiler options
#SET(CSTANDARD "-std=gnu99")
#SET(CXXSTANDARD "-std=gnu++11")
#SET(COPT "-Os")
##SET(CINCS "-I${ArduinoCode_SOURCE_DIR}/libarduinocore")
#add_definitions("-gstabs")
#add_definitions(-DARDUINO=${ARDUINO_VERSION})
#add_definitions("-mmcu=${MCU}")
#add_definitions(-DF_CPU=${F_CPU})
#add_definitions("-Wall -Wstrict-prototypes")
#
#SET(CFLAGS "${CMCU} ${COPT} ${CSTANDARD}")
#SET(CXXFLAGS "${CMCU} ${COPT} ${CXXSTANDARD}")
#
#SET(CMAKE_C_FLAGS  ${CFLAGS})
#SET(CMAKE_CXX_FLAGS ${CXXFLAGS})

##########################################################################
# add_avr_executable
# - IN_VAR: EXECUTABLE_NAME
#
# Creates targets and dependencies for AVR toolchain, building an
# executable. Calls add_executable with ELF file as target name, so
# any link dependencies need to be using that target, e.g. for
# target_link_libraries(<EXECUTABLE_NAME>-${AVR_MCU}.elf ...).
##########################################################################
function(add_avr_executable EXECUTABLE_NAME)
   if(NOT ARGN)
      message(FATAL_ERROR "No source files given for ${EXECUTABLE_NAME}.")
   endif(NOT ARGN)

   # set file names
   set(elf_file ${EXECUTABLE_NAME}${MCU_TYPE_FOR_FILENAME}.elf)
   set(hex_file ${EXECUTABLE_NAME}${MCU_TYPE_FOR_FILENAME}.hex)
   set(map_file ${EXECUTABLE_NAME}${MCU_TYPE_FOR_FILENAME}.map)
   set(eeprom_image ${EXECUTABLE_NAME}${MCU_TYPE_FOR_FILENAME}-eeprom.hex)

   # elf file
   add_executable(${elf_file} EXCLUDE_FROM_ALL ${ARGN})

   # set file paths
   get_target_property(
      BIN_DIR
      ${elf_file}
      RUNTIME_OUTPUT_DIRECTORY
   )
   set(elf_fp ${BIN_DIR}/${elf_file})
   set(hex_fp ${BIN_DIR}/${hex_file})

   set_target_properties(
      ${elf_file}
      PROPERTIES
         COMPILE_FLAGS "-mmcu=${AVR_MCU}"
         LINK_FLAGS "-mmcu=${AVR_MCU} -Wl,--gc-sections -mrelax -Wl,-Map,${map_file}"
   )

   add_custom_command(
      OUTPUT ${hex_file}
      COMMAND
         ${AVR_OBJCOPY} -j .text -j .data -O ihex ${elf_fp} ${hex_fp}
      COMMAND
         ${AVR_SIZE_TOOL} ${AVR_SIZE_ARGS} ${elf_fp}
      DEPENDS ${elf_file}
   )

   # eeprom
   add_custom_command(
      OUTPUT ${eeprom_image}
      COMMAND
         ${AVR_OBJCOPY} -j .eeprom --set-section-flags=.eeprom=alloc,load
            --change-section-lma .eeprom=0 --no-change-warnings
            -O ihex ${elf_fp} ${eeprom_image}
      DEPENDS ${elf_file}
   )

   add_custom_target(
      ${EXECUTABLE_NAME}
      ALL
      DEPENDS ${hex_file} ${eeprom_image}
   )

   set_target_properties(
      ${EXECUTABLE_NAME}
      PROPERTIES
         OUTPUT_NAME "${elf_file}"
   )

   # clean
   get_directory_property(clean_files ADDITIONAL_MAKE_CLEAN_FILES)
   set_directory_properties(
      PROPERTIES
         ADDITIONAL_MAKE_CLEAN_FILES "${map_file}"
   )

   # upload - with avrdude
   add_custom_target(
      upload_${EXECUTABLE_NAME}
      ${AVR_UPLOADTOOL} -p ${AVR_MCU} -c ${AVR_PROGRAMMER} ${AVR_UPLOADTOOL_OPTIONS}
         -U flash:w:${hex_fp}
         -P ${AVR_UPLOADTOOL_PORT}
         -D # for VMEmega upload
      DEPENDS ${hex_file}
      COMMENT "Uploading ${hex_fp} to ${AVR_MCU} using ${AVR_PROGRAMMER}"
   )

   # upload eeprom only - with avrdude
   # see also bug http://savannah.nongnu.org/bugs/?40142
   add_custom_target(
      upload_eeprom_${EXECUTABLE_NAME}
      ${AVR_UPLOADTOOL} -p ${AVR_MCU} -c ${AVR_PROGRAMMER} ${AVR_UPLOADTOOL_OPTIONS}
         -U eeprom:w:${eeprom_image}
         -P ${AVR_UPLOADTOOL_PORT}
      DEPENDS ${eeprom_image}
      COMMENT "Uploading ${eeprom_image} to ${AVR_MCU} using ${AVR_PROGRAMMER}"
   )

   # disassemble
   add_custom_target(
      disassemble_${EXECUTABLE_NAME}
      ${AVR_OBJDUMP} -h -S ${elf_fp} > ${BIN_DIR}/${EXECUTABLE_NAME}.lst
      DEPENDS ${elf_file}
   )

endfunction(add_avr_executable)

##########################################################################
# add_avr_library
# - IN_VAR: LIBRARY_NAME
#
# Calls add_library with an optionally concatenated name
# <LIBRARY_NAME>${MCU_TYPE_FOR_FILENAME}.
# This needs to be used for linking against the library, e.g. calling
# target_link_libraries(...).
##########################################################################
function(add_avr_library LIBRARY_NAME)
   if(NOT ARGN)
      message(FATAL_ERROR "No source files given for ${LIBRARY_NAME}.")
   endif(NOT ARGN)

   set(lib_file ${LIBRARY_NAME}${MCU_TYPE_FOR_FILENAME})

   add_library(${lib_file} STATIC ${ARGN})

   set_target_properties(
      ${lib_file}
      PROPERTIES
         COMPILE_FLAGS "-mmcu=${AVR_MCU}"
         OUTPUT_NAME "${lib_file}"
   )

   if(NOT TARGET ${LIBRARY_NAME})
      add_custom_target(
         ${LIBRARY_NAME}
         ALL
         DEPENDS ${lib_file}
      )

      set_target_properties(
         ${LIBRARY_NAME}
         PROPERTIES
            OUTPUT_NAME "${lib_file}"
      )
   endif(NOT TARGET ${LIBRARY_NAME})

   #message(STATUS "LIBRARY_NAME: ${LIBRARY_NAME}")
   #message(STATUS "lib_file: ${lib_file}")
endfunction(add_avr_library)

##########################################################################
# avr_target_link_libraries
# - IN_VAR: EXECUTABLE_TARGET
# - ARGN  : targets and files to link to
#
# Calls target_link_libraries with AVR target names (concatenation,
# extensions and so on.
##########################################################################
function(avr_target_link_libraries EXECUTABLE_TARGET)
   if(NOT ARGN)
      message(FATAL_ERROR "Nothing to link to ${EXECUTABLE_TARGET}.")
   endif(NOT ARGN)

   get_target_property(TARGET_LIST ${EXECUTABLE_TARGET} OUTPUT_NAME)

   foreach(TGT ${ARGN})
      if(TARGET ${TGT})
         get_target_property(ARG_NAME ${TGT} OUTPUT_NAME)
         list(APPEND TARGET_LIST ${ARG_NAME})
      else(TARGET ${TGT})
         list(APPEND NON_TARGET_LIST ${TGT})
      endif(TARGET ${TGT})
   endforeach(TGT ${ARGN})

   #message(STATUS "TARGET_LIST: ${TARGET_LIST}")
   #message(STATUS "NON_TARGET_LIST: ${NON_TARGET_LIST}")

   target_link_libraries(${TARGET_LIST} ${NON_TARGET_LIST})
endfunction(avr_target_link_libraries EXECUTABLE_TARGET)
