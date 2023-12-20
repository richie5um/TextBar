//
//  RSTemporaryDirectory.m
//  TextBar
//
//  Created by RichS on 09/07/2016.
//  Copyright © 2016 RichS. All rights reserved.
//

#import "RSTemporaryDirectory.h"

@implementation RSTemporaryDirectory

//-------------------------------------------------------------------------//
+(RSTemporaryDirectory*)instance {
    return [[RSTemporaryDirectory alloc] init];
}

//-------------------------------------------------------------------------//
-(id)init {
    if ( nil != (self = [super init])) {
        _directory = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]] isDirectory:YES];
    }
    return self;
}

////-------------------------------------------------------------------------//
//-(void)createTemporaryDirectory {
//    _temporaryDirectory = [self temporaryDirectory];
//    if ( nil != _temporaryDirectory ) {
//        NSError* error;
//        [[NSFileManager defaultManager] createDirectoryAtURL:_temporaryDirectory withIntermediateDirectories:YES attributes:nil error:&error];
//    }
//}
//
////-------------------------------------------------------------------------//
//-(void)removeTemporaryDirectory {
//    if ( nil != _temporaryDirectory ) {
//        NSError* error;
//        [[NSFileManager defaultManager] removeItemAtURL:_temporaryDirectory error:&error];
//    }
//}

@end
