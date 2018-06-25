# Promise.practice

# OC

## AnyPromise

### 从AnyPromise的初始化讲起

AnyPromise一共有六种初始化方法
```objc
+ (instancetype)promiseWithAdapterBlock:(void (^)(PMKAdapter adapter))block;
+ (instancetype)promiseWithIntegerAdapterBlock:(void (^)(PMKIntegerAdapter adapter))block;
+ (instancetype)promiseWithBooleanAdapterBlock:(void (^)(PMKBooleanAdapter adapter))block;
```


