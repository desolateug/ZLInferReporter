//
//  ReportProcessor.m
//  InferReporter
//
//  Created by zlj on 2019/11/7.
//  Copyright © 2019 zlj. All rights reserved.
//

#import "ReportProcessor.h"
#import "Configuration.h"

@implementation ReportProcessor

+ (instancetype)processor {
    return [self new];
}

- (void)processWithParams:(NSArray *)params {
    NSString *file = params.lastObject;
    NSString *filename = [[file lastPathComponent] stringByDeletingPathExtension];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if (![fileManager fileExistsAtPath:file isDirectory:&isDir] || isDir) {
        printf("file path error\n");
        exit(1);
    }
    
    NSString *directory = [[file stringByDeletingLastPathComponent] stringByAppendingFormat:@"/filtered-%@", filename];
    [fileManager removeItemAtPath:directory error:nil];
    [fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSData *data = [[NSData alloc] initWithContentsOfFile:file];
    NSArray *bugs = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    NSMutableArray *filterBugs = [NSMutableArray array];
    for (NSDictionary *bug in bugs) {
        if ([[Configuration sharedInstance] supportType:bug[@"bug_type"]]) {
            [filterBugs addObject:bug];
        }
    }
    
    NSMutableDictionary *projectDict = [NSMutableDictionary dictionary];
    for (NSDictionary *bug in filterBugs) {
        NSString *firstLine = bug[@"file"];
        NSRange range1 = [firstLine rangeOfString:@"/"];
        NSInteger start = range1.location+range1.length;
        NSRange searchRange = NSMakeRange(start, firstLine.length-start);
        NSRange range2 = [firstLine rangeOfString:@"/" options:0 range:searchRange];
        NSString *project = [firstLine substringWithRange:NSMakeRange(searchRange.location, range2.location-searchRange.location)];
        if ([[Configuration sharedInstance] supportPodsScheme:project]) {
            NSMutableArray *projectArray = projectDict[project];
            if (!projectArray) {
                projectArray = [NSMutableArray array];
            }
            [projectArray addObject:bug];
            projectDict[project] = projectArray;
        }
    }
    
    // 按项目分的报告
    [projectDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray *obj, BOOL * _Nonnull stop) {
        NSString *projectDir = [directory stringByAppendingPathComponent:key];
        if (![fileManager fileExistsAtPath:projectDir]) {
            [fileManager createDirectoryAtPath:projectDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        for (int i = 0; i < obj.count; i++) {
            NSDictionary *bug = obj[i];
            NSString *filename = [NSString stringWithFormat:@"BUG_%d.json", i];
            NSString *bugFile = [projectDir stringByAppendingPathComponent:filename];
            NSData *data = [NSJSONSerialization dataWithJSONObject:bug options:NSJSONWritingPrettyPrinted error:nil];
            [data writeToFile:bugFile atomically:YES];
        }
    }];
}

@end
