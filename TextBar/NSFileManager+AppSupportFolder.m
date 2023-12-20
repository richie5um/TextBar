//
//  NSFileManager+AppSupportFolder.m
//  TextBar
//
//  Created by RichS on 03/09/2017.
//  Copyright © 2017 RichS. All rights reserved.
//

#import "NSFileManager+AppSupportFolder.h"

@implementation NSFileManager (AppSupportFolder)

//-------------------------------------------------------------------------//
-(NSURL*)applicationSupportFolder {
    NSError *error;
    NSFileManager *manager = [NSFileManager defaultManager];
    NSURL *applicationSupport = [manager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:false error:&error];
    if (nil != error) {
        NSLog(@"AppSupportFolder Error: %@", error);
        return nil;
    }
    
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    NSURL *folder = [applicationSupport URLByAppendingPathComponent:identifier];
    [manager createDirectoryAtURL:folder withIntermediateDirectories:true attributes:nil error:&error];
    if (nil != error) {
        NSLog(@"AppSupportFolder Error: %@", error);
        return nil;
    }

    return folder;
}

@end
