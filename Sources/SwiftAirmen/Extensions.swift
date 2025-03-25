import Foundation

extension Sequence {
    func indexed<T>(by key: (Element) -> T,
                    onDuplicateKey: OnDuplicateKeyAction<Element> = .abort) -> [T: Element] {
        reduce(into: [:]) { dict, element in
            let k = key(element)
            if dict.keys.contains(k) {
                switch onDuplicateKey {
                    case .overwrite: dict[k] = element
                    case .discard: break
                    case .abort: fatalError(".indexed() found duplicate key “\(k)”")
                    case let .merge(handler): dict[k] = handler(dict[k]!, element)
                }
            } else {
                dict[k] = element
            }
        }
    }
}

enum OnDuplicateKeyAction<Element> {
    case overwrite
    case discard
    case abort
    case merge(handler: (Element, Element) -> Element)
}

extension Optional {
    func orThrow(error: Error) throws -> Wrapped {
        if let self { return self }
        throw error
    }
}

func zipOptionals<each T>(_ values: repeat (each T)?) -> (repeat each T)? {
    for case nil in repeat (each values) {
        return nil
    }
    return (repeat (each values)!)
}
