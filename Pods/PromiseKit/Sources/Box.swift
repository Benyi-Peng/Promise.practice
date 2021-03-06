import Dispatch

enum Sealant<R> {
    case pending(Handlers<R>)
    case resolved(R)
}

class Handlers<R> {
    var bodies: [(R) -> Void] = []
    func append(_ item: @escaping(R) -> Void) { bodies.append(item) }
}

/// - Remark: not protocol ∵ http://www.russbishop.net/swift-associated-types-cont
class Box<T> {
    func inspect() -> Sealant<T> { fatalError() }
    func inspect(_: (Sealant<T>) -> Void) { fatalError() }
    func seal(_: T) {}
}

class SealedBox<T>: Box<T> {
    let value: T

    init(value: T) {
        self.value = value
    }

    override func inspect() -> Sealant<T> {
        return .resolved(value)
    }
}

class EmptyBox<T>: Box<T> {
    private var sealant = Sealant<T>.pending(.init())
    private let barrier = DispatchQueue(label: "org.promisekit.barrier", attributes: .concurrent)

    override func seal(_ value: T) {
        
        /*
         box.sealant
         如果是已决(resolved)，什么都不干
         如果是未决(pending)，则将 未决状态下pipe进来的闭包全部执行一次, 并将自己的 sealant 的状态改为 已决。
         */
        
        var handlers: Handlers<T>!
        barrier.sync(flags: .barrier) {
            guard case .pending(let _handlers) = self.sealant else {
                return  // already fulfilled!
            }
            handlers = _handlers
            self.sealant = .resolved(value)
        }

        //FIXME we are resolved so should `pipe(to:)` be called at this instant, “thens are called in order” would be invalid
        //NOTE we don’t do this in the above `sync` because that could potentially deadlock
        //THOUGH since `then` etc. typically invoke after a run-loop cycle, this issue is somewhat less severe

        if let handlers = handlers {
            handlers.bodies.forEach{ $0(value) }
        }

        //TODO solution is an unfortunate third state “sealed” where then's get added
        // to a separate handler pool for that state
        // any other solution has potential races
    }

    override func inspect() -> Sealant<T> {
        /*
         获取当前的 sealant 的状态 
         */
        var rv: Sealant<T>!
        barrier.sync {
            rv = self.sealant
        }
        return rv
    }

    override func inspect(_ body: (Sealant<T>) -> Void) {
        /*
         把box的 sealant 传递给外界去操作 。代码看起来挺怪异，但
         是作用就是把 box.sealant 传给 body 闭包去做一些操作，仅此而已。
         */
        var sealed = false
        barrier.sync(flags: .barrier) {
            switch sealant {
            case .pending:
                // body will append to handlers, so we must stay barrier’d
                body(sealant)
            case .resolved:
                sealed = true
            }
        }
        if sealed {
            // we do this outside the barrier to prevent potential deadlocks
            // it's safe because we never transition away from this state
            body(sealant)
        }
    }
}


extension Optional where Wrapped: DispatchQueue {
    func async(_ body: @escaping() -> Void) {
        switch self {
        case .none:
            body()
        case .some(let q):
            q.async(execute: body)
        }
    }
}
