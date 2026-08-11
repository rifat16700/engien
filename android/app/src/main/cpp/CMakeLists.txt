cmake_minimum_required(VERSION 3.10.2)

project("custom_tgcalls")

# Define the path to the prebuilt WebRTC shared libraries
set(WEBRTC_LIB_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libs/webrtc/jni/${ANDROID_ABI})

# Add the prebuilt WebRTC shared library
add_library(webrtc SHARED IMPORTED)
set_target_properties(webrtc PROPERTIES IMPORTED_LOCATION ${WEBRTC_LIB_DIR}/libjingle_peerconnection_so.so)

# Include tgcalls source files (this assumes the fetch script has cloned it into the tgcalls directory)
file(GLOB_RECURSE TGCALLS_SRC "tgcalls/tgcalls/*.cpp" "tgcalls/tgcalls/*.c")

# Create our custom shared library containing the JNI wrapper and tgcalls source
add_library(
        custom_tgcalls
        SHARED
        tgcalls_jni.cpp
)

# Search for Android standard logging library
find_library(log-lib log)
find_library(android-lib android)

# Include directories for headers
target_include_directories(custom_tgcalls PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/tgcalls
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

# Link the custom library against WebRTC and Android libraries
target_link_libraries(
        custom_tgcalls
        webrtc
        ${log-lib}
        ${android-lib}
)

# Set compile features
target_compile_features(custom_tgcalls PUBLIC cxx_std_17)
