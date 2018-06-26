import Foundation

/**
 __AnyPromise is an implementation detail.

 Because of how ObjC/Swift compatability work we have to compose our AnyPromise
 with this internal object, however this is still part of the public interface.
 Sadly. Please don’t use it.
*/
@objc(__AnyPromise) public class __AnyPromise: NSObject {
    fileprivate let box: Box<Any?>

    @objc public init(resolver body: (@escaping (Any?) -> Void) -> Void) {
        box = EmptyBox<Any?>()
        super.init()
        // 尾随闭包的简写
        /*
         
         body(resolve: {(sth: Any?) in
         
         })
         这个尾随闭包，就是 resolve block. 是在异步业务逻辑完成的时候调用的。
         resolve block 执行的参数， 就是要reslove 的 value.
         
         resolve 一个 Promise 会发生什么？
         resolve 一个 Promise 意味着如下操作 : [Promise的初始化方法中resolve了另一个Promise, 或者在then等流程控制中，return了另一个Promise.]
         
         比如说 PromiseA resolve 了 Promise B.
         则A的尾随闭包不会在A resolve 的时候立即执行， 而是在B resolve 的时候执行。且 A 的尾随闭包的参数是 B resolve 的值，而不是B(B是A resolve 的值)。
         
         下一个Promise的业务代码真正被调用的时间点就是上一个Promise的box seal 的时候。
        */
        body {
            if let p = $0 as? AnyPromise {
                p.d.__pipe(self.box.seal)
            } else {
                self.box.seal($0)
            }
        }
    }

    /*
     尾触发
     */
    @objc public func __thenOn(_ q: DispatchQueue, execute: @escaping (Any?) -> Any?) -> AnyPromise {
        return AnyPromise(__D: __AnyPromise(resolver: { resolve in
            /*
             此处是立即调用的代码
             
             then(block)
             self.d __thenOn
             AnyPromise
             initWithResolver
             __pipe
             
             在 Promise chain 的前一个 Promise
             pipe 的这个闭包，是在上一个promise resolve 的时候调用的。
             */
            self.__pipe { obj in
                /*
                 obj 就是 上一个 promise resolve 的 value, 存储在上一个 Promise 的 box 中，
                 当上一个 Promise（也就是此处的self） resolve的时候，
                 */
                if !(obj is NSError) {
                    q.async {
                        /*
                         PMKCallVariadicBlock(block, obj)
                         */
                        resolve(execute(obj)) // == reslove(PMKCallVariadicBlock(block, obj)). block 就是 then 里面的业务逻辑 
                    }
                } else {
                    resolve(obj)
                }
            }
        }))
    }

    @objc public func __catchOn(_ q: DispatchQueue, execute: @escaping (Any?) -> Any?) -> AnyPromise {
        return AnyPromise(__D: __AnyPromise(resolver: { resolve in
            self.__pipe { obj in
                if obj is NSError {
                    q.async {
                        resolve(execute(obj))
                    }
                } else {
                    resolve(obj)
                }
            }
        }))
    }

    @objc public func __ensureOn(_ q: DispatchQueue, execute: @escaping () -> Void) -> AnyPromise {
        return AnyPromise(__D: __AnyPromise(resolver: { resolve in
            self.__pipe { obj in
                q.async {
                    execute()
                    resolve(obj)
                }
            }
        }))
    }

    /// Internal, do not use! Some behaviors undefined.
    @objc public func __pipe(_ to: @escaping (Any?) -> Void) {
        /*
         在我看来，就是调用了 to(obj) 
         */
        let to = { (obj: Any?) -> Void in
            if obj is NSError {
                to(obj)  // or we cannot determine if objects are errors in objc land
            } else {
                to(obj)
            }
        }
        /*
         如果是未决状态，接到handlers数组中，
         如果是已决状态，直接执行。
         */
        switch box.inspect() {
        case .pending:
            box.inspect {
                switch $0 {
                case .pending(let handlers):
                    handlers.append { obj in
                        to(obj)
                    }
                case .resolved(let obj):
                    to(obj)
                }
            }
        // obj 
        case .resolved(let obj):
            to(obj)
        }
    }

    @objc public var __value: Any? {
        switch box.inspect() {
        case .resolved(let obj):
            return obj
        default:
            return nil
        }
    }

    @objc public var __pending: Bool {
        switch box.inspect() {
        case .pending:
            return true
        case .resolved:
            return false
        }
    }
}

extension AnyPromise: Thenable, CatchMixin {

    /// - Returns: A new `AnyPromise` bound to a `Promise<Any>`.
    public convenience init<U: Thenable>(_ bridge: U) {
        self.init(__D: __AnyPromise(resolver: { resolve in
            bridge.pipe {
                switch $0 {
                case .rejected(let error):
                    resolve(error as NSError)
                case .fulfilled(let value):
                    resolve(value)
                }
            }
        }))
    }

    public func pipe(to body: @escaping (Result<Any?>) -> Void) {

        func fulfill() {
            // calling through to the ObjC `value` property unwraps (any) PMKManifold
            // and considering this is the Swift pipe; we want that.
            body(.fulfilled(self.value(forKey: "value")))
        }

        switch box.inspect() {
        case .pending:
            box.inspect {
                switch $0 {
                case .pending(let handlers):
                    handlers.append {
                        if let error = $0 as? Error {
                            body(.rejected(error))
                        } else {
                            fulfill()
                        }
                    }
                case .resolved(let error as Error):
                    body(.rejected(error))
                case .resolved:
                    fulfill()
                }
            }
        case .resolved(let error as Error):
            body(.rejected(error))
        case .resolved:
            fulfill()
        }
    }

    fileprivate var d: __AnyPromise {
        return value(forKey: "__d") as! __AnyPromise
    }

    var box: Box<Any?> {
        return d.box
    }

    public var result: Result<Any?>? {
        guard let value = __value else {
            return nil
        }
        if let error = value as? Error {
            return .rejected(error)
        } else {
            return .fulfilled(value)
        }
    }

    public typealias T = Any?
}


#if swift(>=3.1)
public extension Promise where T == Any? {
    convenience init(_ anyPromise: AnyPromise) {
        self.init {
            anyPromise.pipe(to: $0.resolve)
        }
    }
}
#else
extension AnyPromise {
    public func asPromise() -> Promise<Any?> {
        return Promise(.pending, resolver: { resolve in
            pipe { result in
                switch result {
                case .rejected(let error):
                    resolve.reject(error)
                case .fulfilled(let obj):
                    resolve.fulfill(obj)
                }
            }
        })
    }
}
#endif
