//
//  main.m
//  InferReporter
//
//  Created by zlj on 2019/9/24.
//  Copyright © 2019 zlj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Configuration.h"
#import "BugsProcessor.h"
#import "ReportProcessor.h"

void helpLog() {
    printf("\033[1;4;30m");
    printf("Usage:\n");
    printf("\033[0m\033[32m");
    printf("\t$ zlinferreporter COMMAND file\n");
    
    printf("\033[0m\033[1;4;30m");
    printf("\nCommands:\n");
    printf("\033[0m\t");
    printf("\033[0m\033[34m");
    printf("+ bugs-format\n");
    printf("\033[0m\t");
    printf("\033[0m\033[34m");
    printf("+ report-format\n\n");
    
    printf("\033[0m\033[1;4;30m");
    printf("Options:\n");
    printf("\033[0m\t");
    printf("\033[0m\033[34m");
    printf("--support-types type1,type2\n");
    printf("\033[0m\t");
    printf("\033[0m\033[34m");
    printf("--pod-schemes scheme1,scheme2\n");
    
    printf("\n\033[0m");
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc <= 1) {
            helpLog();
            exit(1);
        }
        
        dispatch_group_t group = dispatch_group_create();
        
        int index = 1;
        while (index < argc) {
            Class<ProcessProtocol> programClass;
            BOOL delay = NO;
            NSString *program = [NSString stringWithCString:argv[index] encoding:NSUTF8StringEncoding];
            if ([program isEqualToString:@"--support-types"]) {
                programClass = Configuration.class;
            } else if ([program isEqualToString:@"--pod-schemes"]) {
                programClass = Configuration.class;
            } else if ([program isEqualToString:@"bugs-format"]) {
                delay = YES;
                programClass = BugsProcessor.class;
            } else if ([program isEqualToString:@"report-format"]) {
                delay = YES;
                programClass = ReportProcessor.class;
            } else {
                helpLog();
                exit(1);
            }
            
            if (index + 1 >= argc) {
                printf("params error\n");
                exit(1);
            }

            NSString *param = [NSString stringWithCString:argv[index+1] encoding:NSUTF8StringEncoding];
            NSArray *params = @[program, param];
            if (delay) {
                dispatch_group_enter(group);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [[programClass processor] processWithParams:params];
                    dispatch_group_leave(group);
                });
            } else {
                [[programClass processor] processWithParams:params];
            }
            
            index += 2;
        }
        
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        
    }
    return 0;
}
