set(HELLO_SRC
  hello.cc
  main.cc
)

# add_subdirectory(../foofiles)

add_executable(hello ${HELLO_SRC})
target_link_libraries(hello foo)
