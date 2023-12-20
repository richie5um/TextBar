//
//  RSTextBarItemExport.m
//  TextBar
//
//  Created by RichS on 02/09/2017.
//  Copyright © 2017 RichS. All rights reserved.
//

#import "RSTextBarItemExport.h"
#import "NSFileManager+AppSupportFolder.h"
#import "NSImage+Extended.h"
#import "NSString+Extensions.h"
#import "RSAppDelegate.h"
#import "Helpers.h"

@implementation RSTextBarItemExport

//-------------------------------------------------------------------------//
+(RSTextBarItemExport*)cloneFrom:(RSTextBarItem*)item {
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    
    [item encodeWithCoder:archiver];
    [archiver finishEncoding];
    
    NSKeyedUnarchiver *unArchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    return [[RSTextBarItemExport alloc] initWithCoder:unArchiver];
}

//-------------------------------------------------------------------------//
-(RSTextBarItem*)cloneTo {
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    
    [self encodeWithCoder:archiver];
    [archiver finishEncoding];
    
    NSKeyedUnarchiver *unArchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    return [[RSTextBarItem alloc] initWithCoder:unArchiver];
}

//-------------------------------------------------------------------------//
-(id)init {
    if ( nil != (self = [super init])) {
    }
    
    return self;
}

//-------------------------------------------------------------------------//
-(void)encodeWithCoder:(NSCoder*)encoder {
    self.itemGuid = @"";
    self.context = nil;
    self.refreshDate = @"";
    self.cloudSubmitted = @"";
    
    [super encodeWithCoder:encoder];
    
    // If this is a custom image, then capture it
    RSAppDelegate* appDelegate = (RSAppDelegate*)[NSApp delegate];
    if ([self.imageNamed hasPrefix:@":"]) {
        NSImage* image = [appDelegate imageForName:self.imageNamed withSize:256];
        [encoder encodeObject:image forKey:@"serializedImage"];
    }
    
    // Attempt to read this string as though it is a file.
    NSError *error = nil;
    NSString* scriptPath = [Helpers pathFromTextBarScriptPath:self.script];
    if (![NSString isEmpty:scriptPath] && [scriptPath hasPrefix:@"/"]) {
        NSData *data = [NSData dataWithContentsOfFile:scriptPath
                                              options:NSDataReadingUncached
                                                error:&error];
        if (nil == error) {
            [encoder encodeObject:data forKey:@"serializedScript"];
        }
    }
    
    // Attempt to read this string as though it is a file.
    NSString* actionScriptPath = [Helpers pathFromTextBarScriptPath:self.actionScript];
    if (![NSString isEmpty:actionScriptPath] && [actionScriptPath hasPrefix:@"/"]) {
        if ([actionScriptPath isEqualToString:scriptPath]) {
            // Encode empty data so that we can detect it needs to point to the script file.
            [encoder encodeObject:[NSData data] forKey:@"serializedActionScript"];
        } else {
            NSData *data = [NSData dataWithContentsOfFile:actionScriptPath
                                                  options:NSDataReadingUncached
                                                    error:&error];
            if (nil == error) {
                [encoder encodeObject:data forKey:@"serializedActionScript"];
            }
        }
    }
}

//-------------------------------------------------------------------------//
-(id)initWithCoder:(NSCoder*)decoder {
    self = [super initWithCoder:decoder];

    if (nil != self) {
        self.isEnabled = NO;
        self.cloudSubmitted = @"";
        self.isImported = YES;
        self.itemGuid = [[[NSUUID UUID] UUIDString] lowercaseString];
        
        NSImage* serializedImage = [decoder decodeObjectForKey:@"serializedImage"];
        NSData* serializedScript = [decoder decodeObjectForKey:@"serializedScript"];
        NSData* serializedActionScript = [decoder decodeObjectForKey:@"serializedActionScript"];

        if (nil != serializedImage || nil != serializedScript || nil != serializedActionScript) {
            RSAppDelegate* appDelegate = (RSAppDelegate*)[NSApp delegate];
            NSString* scriptsPath = appDelegate.options.scriptsPath;
            if (nil == scriptsPath) {
                return nil;
            }
            
            NSError* error;
            NSString* itemScriptPath = [scriptsPath stringByAppendingPathComponent:self.itemGuid];
            [[NSFileManager defaultManager] createDirectoryAtPath:itemScriptPath withIntermediateDirectories:true attributes:nil error:&error];
            if (nil != error) {
                NSLog(@"CreateItemScriptPath %@ Error: %@", itemScriptPath, error);
                return nil;
            }
            
            // Deserialize image and ensure we use this new one
            if (nil != serializedImage) {
                NSString *imageFilePath = [itemScriptPath stringByAppendingPathComponent:@"image.png"];
                [serializedImage writeToFile:imageFilePath];
                self.imageNamed = [NSString stringWithFormat:@":%@", imageFilePath];
            }
            
            // Deserialize script and ensure we use this new one
            if (nil != serializedScript) {
                NSString* scriptFileName = [self.script lastPathComponent];
                if ([NSString isEmpty:scriptFileName]) {
                    scriptFileName = @"script";
                }
                
                NSString* scriptFilePath = [itemScriptPath stringByAppendingPathComponent:scriptFileName];
                [serializedScript writeToFile:scriptFilePath atomically:YES];
                
                error = [Helpers enableExecutePermissionsForPath:scriptFilePath];
                if (nil != error) {
                    NSLog(@"EnableExecutePermissionsForPath %@ Error: %@", scriptFilePath, error);
                    return nil;
                }
                
                self.isFileScript = YES;
                self.script = [Helpers pathToTextBarScriptPath:scriptFilePath];
            } else {
                self.script = [decoder decodeObjectForKey:@"script"];
            }
            
            // Deserialize action script and ensure we use this new one
            if (nil != serializedActionScript) {
                if (0 == serializedActionScript.length) {
                    self.actionScript = self.script;
                } else {
                    NSString* actionScriptFileName = [self.actionScript lastPathComponent];
                    if ([NSString isEmpty:actionScriptFileName]) {
                        actionScriptFileName = @"actionScript";
                    }
                    
                    NSString* actionScriptFilePath = [itemScriptPath stringByAppendingPathComponent:actionScriptFileName];
                    [serializedActionScript writeToFile:actionScriptFilePath atomically:YES];
                    
                    error = [Helpers enableExecutePermissionsForPath:actionScriptFilePath];
                    if (nil != error) {
                        NSLog(@"EnableExecutePermissionsForPath %@ Error: %@", actionScriptFilePath, error);
                        return nil;
                    }
                    
                    self.isFileActionScript = YES;
                    self.actionScript = [Helpers pathToTextBarScriptPath:actionScriptFilePath];
                }
            } else {
                self.actionScript = [decoder decodeObjectForKey:@"actionScript"];
            }
        }
    }

    return self;
}

@end
