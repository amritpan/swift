// RUN: %target-run-simple-swift | %FileCheck %s

// REQUIRES: executable_test

// UNSUPPORTED: use_os_stdlib
// UNSUPPORTED: back_deployment_runtime

class MyLabel {
  var text = "label"
  static var isVisible = true
  func x(val value: Int) -> Int { return value }
  static func y(val value: Int) -> Int { return value }
}

class Controller {
  
  fileprivate let label = MyLabel()
  fileprivate var secondLabel: MyLabel? = MyLabel()
  public var thirdLabel: MyLabel? = MyLabel()
  fileprivate var fourthLabel: MyLabel.Type? { return MyLabel.self }
  public var fifthLabel: MyLabel.Type? { return MyLabel.self }
  
  subscript(string: String) -> String {
    get {
      ""
    }
    set {
      
    }
  }
  
  subscript(int int: Int, str str: String, otherInt: Int) -> Int {
    get {
      0
    }
    set {
      
    }
  }
  
  subscript() -> Int {
    0
  }
  
  subscript<T>(array: [T]) -> T? {
    array.first
  }

  subscript<T, U>(array: [T], array2: [U]) -> T? {
    array.first
  }

  subscript<T>(array array: [T]) -> T? {
    array.first
  }

  subscript<T, U>(array array: [T], array2 array2: [U]) -> T? {
    array.first
  }
}

struct S {
  var a: Int
  static let b: Double = 100.0
}

struct Container<V> {
  var v : V
  init(_ v: V) {
    self.v = v
  }
  func useKeyPath<V2: AnyObject>(_ keyPath: KeyPath<V, V2>) -> String {
    return (v[keyPath: keyPath] as! MyLabel).text
  }
  func invokeKeyPathMethod<V2, R>(
      _ keyPath: KeyPath<V, V2>,
      method: KeyPath<V2, (Int) -> R>,
      arg: Int
    ) -> R {
      let instance = v[keyPath: keyPath]
      return instance[keyPath: method](arg)
    }
}

extension Container where V: Controller {
  func test() -> String {
    return useKeyPath(\.label)
  }
  func testKeyPathMethod() -> Int {
    let result = invokeKeyPathMethod(\.label, method: \MyLabel.x(val:), arg: 10)
    print(result)
    return result
  }
}

// CHECK: label
print(Container(Controller()).test())
// CHECK: 10
print(Container(Controller()).testKeyPathMethod())

struct MetatypeContainer<V> {
  var v : V.Type
  init(_ v: V.Type) {
    self.v = v
  }
  func useMetatypeKeyPath() -> Bool {
    if let labelType = v as? MyLabel.Type {
      return labelType.isVisible
    }
    return false
  }
  func getKeyPathMethodVal() -> Int {
    if let labelType = v as? MyLabel.Type {
      return labelType.y(val: 20)
    }
    return 0
  }
}

// CHECK: true
print(MetatypeContainer(MyLabel.self).useMetatypeKeyPath())
// CHECK: 20
print(MetatypeContainer(MyLabel.self).getKeyPathMethodVal())

public class GenericController<U> {
  init(_ u: U) {
    self.u = u
  }

  var u : U
  fileprivate let label = MyLabel()
}

public func generic_class_constrained_keypath<U, V>(_ c: V) where V : GenericController<U> {
  let kp = \V.label
  print(kp)
  print(c[keyPath: kp].text)
}

// CHECK: GenericController<Int>.label
// CHECK: label
generic_class_constrained_keypath(GenericController(5))

// CHECK: {{\\Controller\.secondLabel!\.text|\\Controller\.<computed 0x.* \(Optional<MyLabel>\)>!\.<computed 0x.* \(String\)>}}
print(\Controller.secondLabel!.text)

// CHECK: {{\\Controller\.subscript\(_: String\)|\\Controller\.<computed 0x.* \(String\)>}}
print(\Controller["abc"])
// CHECK: \S.a
print(\S.a)
// CHECK: {{\\Controller\.subscript\(int: Int, str: String, _: Int\)|\\Controller\.<computed 0x.* \(Int\)>}}
print(\Controller[int: 0, str: "", 0])
// CHECK: {{\\Controller\.thirdLabel|\\Controller\.<computed 0x.* \(Optional<MyLabel>\)>}}
print(\Controller.thirdLabel)
// CHECK: {{\\Controller\.subscript\(\)|\\Controller\.<computed 0x.* \(Int\)>}}
print(\Controller.[])
// CHECK: \Controller.self
print(\Controller.self)

// Subscripts with dependent generic types don't produce good output currently,
// so we're just checking to make sure they don't crash.
// CHECK: \Controller.
print(\Controller[[42]])
// CHECK: Controller.
print(\Controller[[42], [42]])
// CHECK: \Controller.
print(\Controller[array: [42]])
// CHECK: \Controller.
print(\Controller[array: [42], array2: [42]])

// CHECK: {{\\Controller\.(fourthLabel|<computed .* \(Optional<MyLabel\.Type>\)>)!\.<computed .* \(Bool\)>}}
print(\Controller.fourthLabel!.isVisible)

// CHECK: \S.Type.<computed {{.*}} (Double)>
print(\S.Type.b)
// CHECK: {{\\Controller\.(fifthLabel|<computed .* \(Optional<MyLabel\.Type>\)>)\?\.<computed .* \(Bool\)>?}}
print(\Controller.fifthLabel?.isVisible)


do {
  struct S {
    var i: Int
  }

  func test<T, U>(v: T, _ kp: any KeyPath<T, U> & Sendable) {
    print(v[keyPath: kp])
  }

  // CHECK: 42
  test(v: S(i: 42), \.i)
}

do {
  @dynamicMemberLookup
  struct Test<T> {
    var obj: T

    subscript<U>(dynamicMember member: KeyPath<T, U> & Sendable) -> U {
      get { obj[keyPath: member] }
    }
  }

  // CHECK: 5
  print(Test(obj: "Hello").utf8.count)
}

do {
  struct S1: Hashable {}
  struct S2 {
    subscript(param: S1) -> String { "Subscript with private type" }
  }

  let kp = \S2[S1()]
  // CHECK: Subscript with private type
  print(S2()[keyPath: kp])
  // CHECK: {{\\S2\.subscript\(_: S1 #[0-9]+\)|\S2\.<computed 0x.* \(String\)>}}
  print(kp)
}

do {
  struct Weekday {
      static let day = "Monday"
  }
  
  @dynamicMemberLookup
  struct StaticExample<T> {
      subscript<U>(dynamicMember keyPath: KeyPath<T.Type, U>) -> U {
          return T.self[keyPath: keyPath]
      }
  }
  // CHECK: true
  print(StaticExample<MyLabel>().isVisible)
}

do {
  @dynamicMemberLookup
  struct InstanceDynamicMemberLookup<T> {
      var obj: T
      
      subscript<U>(dynamicMember member: KeyPath<T, (Int) -> U>) -> (Int) -> U {
          get { obj[keyPath: member] }
      }
  }

  // CHECK: 50
  let instanceDynamicLookup = InstanceDynamicMemberLookup(obj: MyLabel())
  print(instanceDynamicLookup.x(50))
}

do {
  @dynamicMemberLookup
  struct StaticDynamicMemberLookup<T> {
      subscript<U>(dynamicMember keyPath: KeyPath<T.Type, (Int) -> U>) -> (Int) -> U {
          return T.self[keyPath: keyPath]
      }
  }

  // CHECK: 60
  let staticDynamicLookup = StaticDynamicMemberLookup<MyLabel>()
  print(staticDynamicLookup.y(60))
}
