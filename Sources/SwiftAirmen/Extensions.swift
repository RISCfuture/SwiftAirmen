import Foundation

extension Sequence {
    func indexed<T>(by key: (Element) -> T,
                    onDuplicateKey: OnDuplicateKeyAction<Element> = .abort) -> Dictionary<T, Element> {
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
