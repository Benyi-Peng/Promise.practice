//
//  ViewController.m
//  promise.practise
//
//  Created by oe on 2018/6/22.
//  Copyright © 2018年 oe. All rights reserved.
//

#import "ViewController.h"

#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/PromiseKit-Swift.h>


@interface ViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray<NSString *> *data1;
@property (strong, nonatomic) NSArray<NSString *> *data2;
@property (strong, nonatomic) NSArray<NSString *> *data3;
@end

@implementation ViewController

- (NSArray *)d1 {
    return @[@"wash face", @"wash teeth", @"eat breakfast"];
}

- (NSArray *)d2 {
    return @[@"read book", @"do homework", @"relax"];
}

- (NSArray *)d3 {
    return @[@"play with dog", @"play video game", @"watch movie"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _data1 = [NSArray array];
    _data2 = [NSArray array];
    _data3 = [NSArray array];
    [self getTasks1];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

- (AnyPromise *)getTasks1 {
    return [AnyPromise promiseWithAdapterBlock:^(PMKAdapter  _Nonnull adapter) {
        NSString *urlStr = @"https://httpbin.org/post";
        urlStr = [urlStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSURL *url = [NSURL URLWithString:urlStr];
        
        NSDictionary *para = @{@"task":[self d1]};
        NSData *paraData = [NSJSONSerialization dataWithJSONObject:para options:0 error:nil];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"POST";
        request.HTTPBody = paraData;
        
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
                    NSLog(@"dict : %@", dict);
                    
                    if ([dict[@"args"] valueForKey:@"greet1"] &&
                        [dict[@"args"] valueForKey:@"greet2"] &&
                        [dict[@"args"] valueForKey:@"name"]) {
                        NSString *name = [dict[@"args"] valueForKey:@"name"];
                        // resolve 了一个字符串(name)，下个打招呼要用到
                        adapter(name, nil);
                        dispatch_async(dispatch_get_main_queue(), ^{

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
//                            self.greet3.text = [NSString stringWithFormat:@"%@, %@", name, greet];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data1.count + _data2.count + _data3.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell1"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell1"];
    }
    if (indexPath.row < _data1.count) {
        cell.textLabel.text = _data1[indexPath.row];
    } else if (indexPath.row < _data1.count + _data2.count) {
        cell.textLabel.text = _data2[indexPath.row - _data1.count];
    } else if (indexPath.row < _data1.count + _data2.count + _data3.count) {
        cell.textLabel.text = _data3[indexPath.row - _data1.count - _data2.count];
    }
    return cell;
}

@end
