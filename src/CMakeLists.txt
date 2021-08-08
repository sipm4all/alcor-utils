### @author: Roberto Preghenella
### @email: preghenella@bo.infn.it

include_directories(${uHAL_INCLUDE_DIR})

add_executable(readout readout.cc)
target_link_libraries(readout ${Boost_LIBRARIES} ${uHAL_LIBRARIES})

install(TARGETS readout RUNTIME DESTINATION bin)
