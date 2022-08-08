
add_swift_unittest(swiftSemaTests
  SemaFixture.cpp
  BindingInferenceTests.cpp
  ConstraintGenerationTests.cpp
  ConstraintSimplificationTests.cpp
  UnresolvedMemberLookupTests.cpp
  PlaceholderTypeInferenceTests.cpp
  SolutionFilteringTests.cpp
  ConstraintTest.cpp)

target_link_libraries(swiftSemaTests
  PRIVATE
    swiftAST
    swiftSema
    swiftSerialization)

target_compile_definitions(swiftSemaTests PRIVATE
  SWIFTLIB_DIR=\"${SWIFTLIB_DIR}\")
