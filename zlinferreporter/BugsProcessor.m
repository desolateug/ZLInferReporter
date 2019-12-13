//
//  BugsProcessor.m
//  InferReporter
//
//  Created by zlj on 2019/11/7.
//  Copyright © 2019 zlj. All rights reserved.
//

#import "BugsProcessor.h"
#import "Configuration.h"

@implementation BugsProcessor

+ (instancetype)processor {
    return [self new];
}

- (void)processWithParams:(NSArray *)params {
    NSString *file = params.lastObject;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if (![fileManager fileExistsAtPath:file isDirectory:&isDir] || isDir) {
        printf("file path error\n");
        exit(1);
    }
    
    NSString *directory = [[file stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"filtered-infer-out"];
    [fileManager removeItemAtPath:directory error:nil];
    [fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSString *fileContents = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    NSArray *allLinedStrings = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSMutableArray *sections = [NSMutableArray array];
    NSMutableArray *codeSection = [NSMutableArray array];
    for (NSString *line in allLinedStrings) {
        if (!line.length) {
            NSString *firstLine = codeSection.firstObject;
            NSRange range = [firstLine rangeOfString:@"error: " options:NSBackwardsSearch];
            if (range.location == NSNotFound) {
                range = [firstLine rangeOfString:@"warning: " options:NSBackwardsSearch];
            }
            if (range.location != NSNotFound) {
                NSString *type = [firstLine substringFromIndex:range.location+range.length];
                if ([[Configuration sharedInstance] supportType:type]) {
                    [sections addObject:codeSection];
                }
            }
            codeSection = [NSMutableArray array];
        } else {
            [codeSection addObject:line];
        }
    }
    
    // 按项目分
    NSMutableDictionary *projectDict = [NSMutableDictionary dictionary];
    NSArray *enumSections = sections.copy;
    for (NSArray<NSString *> *codeSection in enumSections) {
        NSString *firstLine = codeSection.firstObject;
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
                [projectArray addObject:codeSection];
                projectDict[project] = projectArray;
        } else {
            [sections removeObject:codeSection];
        }
    }
    
    // 按项目分的报告
    [projectDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray *obj, BOOL * _Nonnull stop) {
        NSString *projectDir = [directory stringByAppendingPathComponent:key];
        if (![fileManager fileExistsAtPath:projectDir]) {
            [fileManager createDirectoryAtPath:projectDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        NSMutableDictionary *typeDict = [NSMutableDictionary dictionary];
        for (NSArray<NSString *> *codeSection in obj) {
            NSString *firstLine = codeSection.firstObject;
            NSRange range = [firstLine rangeOfString:@"error: " options:NSBackwardsSearch];
            if (range.location == NSNotFound) {
                range = [firstLine rangeOfString:@"warning: " options:NSBackwardsSearch];
            }
            NSString *type = [firstLine substringFromIndex:range.location+range.length];
            NSInteger count = [typeDict[type] integerValue];
            typeDict[type] = @(count + 1);
            
            NSMutableString *code = [NSMutableString string];
            for (NSString *string in codeSection) {
                [code appendFormat:@"%@\n", string];
            }
            [code appendString:@"\n"];
            
            NSString *typeFile = [projectDir stringByAppendingFormat:@"/%@.txt", type];
            if (count == 0) {
                [code writeToFile:typeFile atomically:yearMask encoding:NSUTF8StringEncoding error:nil];
            } else {
                NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:typeFile];
                [fileHandle seekToEndOfFile];
                [fileHandle writeData:[code dataUsingEncoding:NSUTF8StringEncoding]];
                [fileHandle closeFile];
            }
        }
        [typeDict enumerateKeysAndObjectsUsingBlock:^(NSString *type, NSNumber *obj, BOOL * _Nonnull stop) {
            NSString *totalString = [NSString stringWithFormat:@"Found %ld issues\n", [obj integerValue]];
            NSString *typeFile = [projectDir stringByAppendingFormat:@"/%@.txt", type];
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:typeFile];
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[totalString dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        }];
    }];
    
    // 汇总的报告
    NSString *reportFile = [directory stringByAppendingPathComponent:@"filtered-bugs.txt"];
    [fileManager createFileAtPath:reportFile contents:nil attributes:nil];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:reportFile];
    NSMutableDictionary *typeDict = [NSMutableDictionary dictionary];
    for (NSArray<NSString *> *codeSection in sections) {
        NSString *firstLine = codeSection.firstObject;
        NSRange range = [firstLine rangeOfString:@"error: " options:NSBackwardsSearch];
        if (range.location == NSNotFound) {
            range = [firstLine rangeOfString:@"warning: " options:NSBackwardsSearch];
        }
        NSString *type = [firstLine substringFromIndex:range.location+range.length];
        NSInteger count = [typeDict[type] integerValue];
        typeDict[type] = @(count + 1);
        
        NSMutableString *code = [NSMutableString string];
        for (NSString *string in codeSection) {
            [code appendFormat:@"%@\n", string];
        }
        [code appendString:@"\n"];
        
        [fileHandle writeData:[code dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [fileHandle writeData:[@"Summary of the reports\n\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [typeDict enumerateKeysAndObjectsUsingBlock:^(NSString *type, NSNumber *obj, BOOL * _Nonnull stop) {
        NSString *totalString = [NSString stringWithFormat:@"%35s: %ld\n", [type UTF8String], [obj integerValue]];
        [fileHandle writeData:[totalString dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    [fileHandle writeData:[@"\n\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    [projectDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray *obj, BOOL * _Nonnull stop) {
        NSString *projectString = [NSString stringWithFormat:@"%35s: %ld\n", [key UTF8String], obj.count];
        [fileHandle writeData:[projectString dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    [fileHandle closeFile];
}

@end
