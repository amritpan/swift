//===--- ConstraintTest.cpp ---------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#include "SemaFixture.h"
#include "llvm/ADT/ilist.h"
#include "llvm/ADT/ilist_node.h"

using namespace swift;
using namespace swift::unittest;

TEST_F(SemaTest, TestConstraint) {
  
  // Create a type with copy constructor
class A: public llvm::ilist_node<A> {
  public:
    int n;
    A(int n = 1) : n(n) { } // default constructor
    A(const A &a) : n(a.n) {
      assert(false && "ilist const copy ctor called");
    }
    A &operator=(A const& a) {
      assert(false && "ilist copy assign called");
    }
    A(A &&a) : n{a.n} {
      assert(false && "ilist move ctor called");
      a.n = 0;
    }
    A &operator=(A &&a) {
      assert(false && "ilist move assign called");
      return *this;
    }
  };

  // Allocate object using new, and add it to ilist
//  auto newA = new A;
//  llvm::ilist<A> ListA;
//  ListA.push_back(newA);
//
//  // Check whether back() returns exactly the same pointer
//  if (&ListA.back() == newA) {
//    assert(false && "&ListA.back() != newA");
//  }

  class B: public virtual A {};
    
    auto newB = new B;
    llvm::ilist<A> ListA;
    ListA.push_back(newB);
    
    if (&ListA.back() == newB) {
      assert(false && "&ListA.back() != newB");
    }

}
