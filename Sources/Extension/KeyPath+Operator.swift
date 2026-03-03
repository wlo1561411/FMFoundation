import Foundation

func == <Structure, Value: Equatable>(
    lhs: KeyPath<Structure, Value>,
    rhs: Value
)
    -> (Structure) -> Bool {
    { $0[keyPath: lhs] == rhs }
}

func >= <Structure, Value: Comparable>(
    lhs: KeyPath<Structure, Value>,
    rhs: Value
)
    -> (Structure) -> Bool {
    { $0[keyPath: lhs] >= rhs }
}

func <= <Structure, Value: Comparable>(
    lhs: KeyPath<Structure, Value>,
    rhs: Value
)
    -> (Structure) -> Bool {
    { $0[keyPath: lhs] <= rhs }
}

func > <Structure, Value: Comparable>(
    lhs: KeyPath<Structure, Value>,
    rhs: Value
)
    -> (Structure) -> Bool {
    { $0[keyPath: lhs] > rhs }
}

func < <Structure, Value: Comparable>(
    lhs: KeyPath<Structure, Value>,
    rhs: Value
)
    -> (Structure) -> Bool {
    { $0[keyPath: lhs] < rhs }
}

func ~= <Structure, Value: Comparable>(
    lhs: KeyPath<Structure, Value>,
    rhs: (Value, Value)
)
    -> (Structure) -> Bool {
    { $0[keyPath: lhs] >= rhs.0 && $0[keyPath: lhs] <= rhs.1 }
}

func ~= <Structure, _String: StringProtocol>(
    lhs: KeyPath<Structure, _String>,
    rhs: _String
)
    -> (Structure) -> Bool {
    { $0[keyPath: lhs].contains(rhs) }
}

func && <Structure>(
    lhs: @escaping (Structure) -> Bool,
    rhs: @escaping (Structure) -> Bool
)
    -> (Structure) -> Bool {
    { structure in lhs(structure) && rhs(structure) }
}

func || <Structure>(
    lhs: @escaping (Structure) -> Bool,
    rhs: @escaping (Structure) -> Bool
)
    -> (Structure) -> Bool {
    { structure in lhs(structure) || rhs(structure) }
}
