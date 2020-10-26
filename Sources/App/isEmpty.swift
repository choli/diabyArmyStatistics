import Leaf

struct IsEmptyTag: LeafTag {

    static let name = "isEmpty"

    func render(_ ctx: LeafContext) throws -> LeafData {
        guard let items = ctx.parameters.first?.array else {
            throw "unable to get parameter key"
        }
        return .bool(items.isEmpty)
    }
}
