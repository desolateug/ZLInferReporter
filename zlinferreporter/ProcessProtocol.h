//
//  ProcessProtocol.h
//  InferReporter
//
//  Created by zlj on 2019/11/7.
//  Copyright © 2019 zlj. All rights reserved.
//
#import <Foundation/Foundation.h>

#ifndef ProcessProtocol_h
#define ProcessProtocol_h

@protocol ProcessProtocol <NSObject>

+ (instancetype)processor;

- (void)processWithParams:(NSArray *)params;

@end

#endif /* ProcessProtocol_h */
