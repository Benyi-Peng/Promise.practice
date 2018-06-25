//
//  ViewController.m
//  promise.practise
//
//  Created by oe on 2018/6/22.
//  Copyright © 2018年 oe. All rights reserved.
//

#import "ViewController.h"

#import <PromiseKit/PromiseKit.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *greet1;
@property (weak, nonatomic) IBOutlet UILabel *greet2;
@property (weak, nonatomic) IBOutlet UILabel *greet3;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [[self getFirstGreet] then:^(id x){
//
//    }];
//    [self getGreeting].then(^(NSString *name){
//        [self getSecondPeople:name];
////        return [NSError errorWithDomain:@"First stage error" code:100 userInfo:@{@"msg":@"You stupid."}];
//        return nil;
//    }).then(^(){
//        NSLog(@"The second stage ...");
//    }).catch(^(NSError *error){
//        NSLog(@"error :%@", error);
//    });
    
//    AnyPromise *p = [[self getFirstGreet] then](@1);
//    [[[self getFirstGreet] then](@"Any thing...") then];
//    [self getFirstGreet].then(@1).then(@2).then(@3);
    
    
    [AnyPromise promiseWithResolverBlock:^(PMKResolver _Nonnull resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            sleep(3);
            resolve(@"First");
        });
    }].thenOn(dispatch_get_global_queue(0, 0) ,^(NSString *str){
        sleep(3);
        NSLog(@"then1 : %@", str);
        return @"Second";
    }).thenOn(dispatch_get_global_queue(0, 0) ,^(NSString *str){
        sleep(3);
        NSLog(@"then2 : %@", str);
        return @"Third";
    }).thenOn(dispatch_get_global_queue(0, 0) ,^(NSString *str){
        sleep(3);
        NSLog(@"then3 : %@", str);
        return @"Forth";
    }).then(^(NSString *str){
        NSLog(@"then4 : %@", str);
        return 0 ? @"Fifth" : [NSError errorWithDomain:@"THEN4 ERROR" code:-1 userInfo:nil];
    }).then(^(NSString *str){
        NSLog(@"then5 : %@", str);
        return @"Sixth";
    }).catch(^(NSError *err){
        NSLog(@"Error : %@", err);
    });
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

- (AnyPromise *)testSome {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolver) {
        /* 关键看sth是不是一个promise */
    }];
}

- (AnyPromise *)getGreeting {
    return [AnyPromise promiseWithAdapterBlock:^(PMKAdapter  _Nonnull adapter) {
        NSString *greet1 = @"Hey!";
        NSString *greet2 = @"Good morning!";
        NSString *name = @"Mr. XXX";
        NSString *urlStr = [NSString stringWithFormat:@"https://httpbin.org/post?greet1=%@&greet2=%@&name=%@", greet1, greet2, name];
        urlStr = [urlStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSURL *url = [NSURL URLWithString:urlStr];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"POST";
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                adapter(nil, error);
            } else {
                NSError *parseError;
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&parseError];
                if (parseError) {
                    adapter(nil, parseError);
                } else {
                    if ([dict[@"args"] valueForKey:@"greet1"] && [dict[@"args"] valueForKey:@"greet2"] && [dict[@"args"] valueForKey:@"name"]) {
                        NSString *name = [dict[@"args"] valueForKey:@"name"];
                        // resolve 了一个字符串(name)，下个打招呼要用到
                        adapter(name, nil);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.greet1.text = [NSString stringWithFormat:@"%@", [dict[@"args"] valueForKey:@"greet1"]];
                            self.greet2.text = [NSString stringWithFormat:@"%@", [dict[@"args"] valueForKey:@"greet2"]];
                        });
                    } else {
                        NSError *e = [[NSError alloc] initWithDomain:@"[Weather]Cannot find key." code:0 userInfo:nil];
                        adapter(nil, e);
                    }
                }
            }
        }];
        [task resume];
    }];
}

- (AnyPromise *)getSecondPeople:(NSString *)name {
    return [AnyPromise promiseWithAdapterBlock:^(PMKAdapter  _Nonnull adapter) {
        NSString *greet3 = @"you look great!";
        NSString *urlStr = [NSString stringWithFormat:@"https://httpbin.org/post?greet3=%@", greet3];
        urlStr = [urlStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSURL *url = [NSURL URLWithString:urlStr];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"POST";
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                adapter(nil, error);
            } else {
                NSError *parseError;
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&parseError];
                if (parseError) {
                    adapter(nil, parseError);
                } else {
                    NSString *greet = [dict[@"args"] valueForKey:@"greet3"];
                    if (name) {
                        adapter(nil, nil);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.greet3.text = [NSString stringWithFormat:@"%@, %@", name, greet];
                        });
                    } else {
                        NSError *e = [[NSError alloc] initWithDomain:@"[Weather]Cannot find key." code:0 userInfo:nil];
                        adapter(nil, e);
                    }
                }
            }
        }];
        [task resume];
    }];
}



@end
