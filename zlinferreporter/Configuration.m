//
//  Configuration.m
//  InferReporter
//
//  Created by zlj on 2019/11/7.
//  Copyright © 2019 zlj. All rights reserved.
//

#import "Configuration.h"

@implementation Configuration

+ (instancetype)processor {
    return [self sharedInstance];
}

+ (instancetype)sharedInstance {
    static id sharedInstance ;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSDictionary *config;
        NSData *data = [NSData dataWithContentsOfFile:@"./zlinferreporter.config"];
        if (data) {
            config = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        }
        self.supportTypes = config[@"supportTypes"];
        if (!self.supportTypes.count) {
            self.supportTypes = @[
                @"ASSIGN_POINTER_WARNING",
                @"MEMORY_LEAK",
                @"STRONG_DELEGATE_WARNING",
                @"RETAIN_CYCLE",
                @"POINTER_TO_INTEGRAL_IMPLICIT_CAST",
                @"DEALLOCATION_MISMATCH",
            ];
        }
        
        self.podSchemes = config[@"podSchemes"];
        if (!self.podSchemes.count) {
            self.podSchemes = @[
                @"user"
            ];
        }
        NSData *supportTypesData = [NSJSONSerialization dataWithJSONObject:self.supportTypes options:NSJSONWritingPrettyPrinted error:nil];
        NSString *supportTypesString = [[NSString alloc] initWithData:supportTypesData encoding:NSUTF8StringEncoding];
        printf("supportTypes: %s\n", supportTypesString.UTF8String);
        
        NSData *podSchemesData = [NSJSONSerialization dataWithJSONObject:self.podSchemes options:NSJSONWritingPrettyPrinted error:nil];
        NSString *podSchemesString = [[NSString alloc] initWithData:podSchemesData encoding:NSUTF8StringEncoding];
        printf("podSchemes: %s\n", podSchemesString.UTF8String);
    }
    return self;
}

- (void)processWithParams:(NSArray *)params {
    NSString *program = params.firstObject;
    NSString *typeStr = [params.lastObject stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSArray *types = [typeStr componentsSeparatedByString:@","];
    if ([program isEqualToString:@"--support-types"]) {
        self.supportTypes = types;
    } else if ([program isEqualToString:@"--pod-schemes"]) {
        self.podSchemes = types;
    } else {
        printf("params error\n");
        exit(1);
    }
}

- (BOOL)supportType:(NSString *)type {
    return [self.supportTypes containsObject:type.uppercaseString];
}

- (BOOL)supportPodsScheme:(NSString *)scheme {
    for (NSString *podSchemes in self.podSchemes) {
        if ([scheme.lowercaseString containsString:podSchemes]) {
            return YES;
        }
    }
    return NO;
}

@end
