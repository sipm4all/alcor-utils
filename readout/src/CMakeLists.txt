### @author: Roberto Preghenella
### @email: preghenella@bo.infn.it

include_directories(${uHAL_INCLUDE_DIR} ${ROOT_INCLUDE_DIR})

add_executable(readout readout.cc)
target_link_libraries(readout ${Boost_LIBRARIES} ${uHAL_LIBRARIES} ${uHAL_LOG_LIBRARIES})
install(TARGETS readout RUNTIME DESTINATION bin)

add_executable(nano-readout nano-readout.cc)
target_link_libraries(nano-readout ${Boost_LIBRARIES} ${uHAL_LIBRARIES} ${uHAL_LOG_LIBRARIES} rt)
install(TARGETS nano-readout RUNTIME DESTINATION bin)

add_executable(ctrl-readout ctrl-readout.cc)
target_link_libraries(ctrl-readout ${Boost_LIBRARIES} ${uHAL_LIBRARIES} ${uHAL_LOG_LIBRARIES} rt)
install(TARGETS ctrl-readout RUNTIME DESTINATION bin)

add_executable(ureadout ureadout.cc)
target_link_libraries(ureadout ${Boost_LIBRARIES} ${uHAL_LIBRARIES} ${uHAL_LOG_LIBRARIES})
install(TARGETS ureadout RUNTIME DESTINATION bin)

add_executable(simple-readout simple-readout.cc)
target_link_libraries(simple-readout ${Boost_LIBRARIES} ${uHAL_LIBRARIES} ${uHAL_LOG_LIBRARIES})
install(TARGETS simple-readout RUNTIME DESTINATION bin)

add_executable(deep-reset deep-reset.cc)
target_link_libraries(deep-reset ${Boost_LIBRARIES} ${uHAL_LIBRARIES} ${uHAL_LOG_LIBRARIES})
install(TARGETS deep-reset RUNTIME DESTINATION bin)

add_executable(register register.cc)
target_link_libraries(register ${Boost_LIBRARIES} ${uHAL_LIBRARIES} ${uHAL_LOG_LIBRARIES})
install(TARGETS register RUNTIME DESTINATION bin)

add_executable(block block.cc)
target_link_libraries(block ${Boost_LIBRARIES} ${uHAL_LIBRARIES} ${uHAL_LOG_LIBRARIES})
install(TARGETS block RUNTIME DESTINATION bin)

add_executable(alcor_register alcor_register.cc)
target_link_libraries(alcor_register ${Boost_LIBRARIES} ${uHAL_LIBRARIES} ${uHAL_LOG_LIBRARIES})
install(TARGETS alcor_register RUNTIME DESTINATION bin)

add_executable(scan_thr scan_thr.cc)
target_link_libraries(scan_thr ${Boost_LIBRARIES} ${uHAL_LIBRARIES} ${uHAL_LOG_LIBRARIES})
install(TARGETS scan_thr RUNTIME DESTINATION bin)

add_executable(rate rate.cc)
target_link_libraries(rate ${Boost_LIBRARIES} ${uHAL_LIBRARIES} ${uHAL_LOG_LIBRARIES})
install(TARGETS rate RUNTIME DESTINATION bin)

add_executable(decoder decoder.cc)
target_link_libraries(decoder ${Boost_LIBRARIES} ${uHAL_LIBRARIES} ${uHAL_LOG_LIBRARIES} ${ROOT_LIBS})
install(TARGETS decoder RUNTIME DESTINATION bin)
