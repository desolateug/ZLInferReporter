//
//  Configuration.h
//  InferReporter
//
//  Created by zlj on 2019/11/7.
//  Copyright © 2019 zlj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ProcessProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface Configuration : NSObject <ProcessProtocol>

+ (instancetype)sharedInstance;

@property (nonatomic, strong) NSArray *supportTypes;
@property (nonatomic, strong) NSArray *podSchemes;

- (BOOL)supportType:(NSString *)type;
- (BOOL)supportPodsScheme:(NSString *)scheme;

@end

NS_ASSUME_NONNULL_END
