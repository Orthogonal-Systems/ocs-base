cmake_minimum_required(VERSION 2.8)
project (SOFTWARESERIAL)
 
include(${ARDUINO_SETTINGS_FILE})

set (PROJECT_INCLUDE_DIR ${PROJECT_SOURCE_DIR}/include)
set (PROJECT_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src)
 
file(GLOB SOFTWARESERIAL_SRCS ${PROJECT_SOURCE_DIR}/*.cpp ${PROJECT_SOURCE_DIR}/*.c)
 
### need to include if arduino based library
include_directories(${CMAKE_SOURCE_DIR}/libarduinocore)
LINK_DIRECTORIES(${CMAKE_SOURCE_DIR}/libarduinocore)

link_libraries(ARDUINO)
###

include_directories("${PROJECT_BINARY_DIR}")
include_directories("${PROJECT_INCLUDE_DIR}")
 
add_avr_library(${PROJECT_NAME} STATIC ${SOFTWARESERIAL_SRCS})
