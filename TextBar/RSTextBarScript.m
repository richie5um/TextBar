//
//  RSTextBarScript.m
//  TextBar
//
//  Created by RichS on 09/07/2016.
//  Copyright © 2016 RichS. All rights reserved.
//

#import "RSTextBarScript.h"
#import "RSTemporaryDirectory.h"
#import "NSString+Extensions.h"

@implementation RSTextBarScript

//-------------------------------------------------------------------------//
+(RSTextBarScript*)instanceWithScript:(NSString*)script andOptions:(RSTextBarOptions*)options {
    return [[RSTextBarScript alloc] initWithScript:script andOptions:options];
}

//-------------------------------------------------------------------------//
-(id)initWithScript:(NSString*)script andOptions:(RSTextBarOptions*)options {
    if ( nil != (self = [super init])) {
        _script = script;
        _options = options;
    }
    return self;
}

//-------------------------------------------------------------------------//
-(void)initScriptContext {
    self.scriptContext = [NSMutableDictionary dictionary];
}

//-------------------------------------------------------------------------//
-(NSDictionary*)execute {
    [self initScriptContext];
    NSString* scriptClone = [NSString stringWithString:self.script];
    
    NSString* output;
    NSString* outputError;
    if ( 0 < [scriptClone length] ) {
        NSBundle *myBundle = [NSBundle mainBundle];
        
        if (NSOrderedSame == [scriptClone caseInsensitiveCompare:@"Relay FM"] || NSOrderedSame == [scriptClone caseInsensitiveCompare:@"Relay.FM"]) {
            NSString *scriptPath = [myBundle pathForResource:@"textbar-relayfm" ofType:@"sh"];
            scriptClone = [NSString stringWithFormat:@"cd '%@' && './%@'", [scriptPath stringByDeletingLastPathComponent], [scriptPath lastPathComponent]];
        } else if (NSOrderedSame == [scriptClone caseInsensitiveCompare:@"Pictures"]) {
            NSString *scriptPath = [myBundle pathForResource:@"textbar-pictures" ofType:@"py"];
            scriptClone = [NSString stringWithFormat:@"cd '%@' && './%@'", [scriptPath stringByDeletingLastPathComponent], [scriptPath lastPathComponent]];
        }
        
        @autoreleasepool {
            @try {
                NSTask* task = [self createTaskWithScript:scriptClone andEnvironment:nil];
                
                NSPipe *pipeStdOut = [NSPipe pipe];
                NSPipe *pipeStdErr = [NSPipe pipe];
                
                [task setStandardOutput:pipeStdOut];
                [task setStandardError:pipeStdErr];
                
                NSFileHandle *fileStdOut = [pipeStdOut fileHandleForReading];
                NSFileHandle *fileStdErr = [pipeStdErr fileHandleForReading];
                
                [task launch];
                
                NSData *dataStdOut = [fileStdOut readDataToEndOfFile];
                output = [[NSString alloc] initWithData:dataStdOut encoding:NSUTF8StringEncoding];
                
                if ( self.options.scriptLogging ) {
                    //NSLog(@"Script output: %@", output);
                }
                
                NSData *dataStdErr = [fileStdErr readDataToEndOfFile];
                outputError = [[NSString alloc] initWithData:dataStdErr encoding:NSUTF8StringEncoding];
                if ( self.options.scriptLogging && 0 < [outputError length] ) {
                    NSLog(@"Script output error: %@", outputError);
                }
                
                [fileStdOut closeFile];
                [fileStdErr closeFile];
                [task terminate];
            }
            @catch (NSException *exception) {
                outputError = [NSString stringWithFormat:@"Script command exception: %@ %@ %@", exception.name, exception.reason, exception.callStackSymbols];
                NSLog(@"%@", outputError);
            }
        }
    }
    
    return [self convertOutputToScriptContext:output withError:outputError];
}

//-------------------------------------------------------------------------//
-(NSDictionary*)convertOutputToScriptContext:(NSString*)output withError:(NSString*)outputError {
    
    NSString *dateString = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                          dateStyle:NSDateFormatterShortStyle
                                                          timeStyle:NSDateFormatterLongStyle];
    [self.scriptContext setObject:[NSString stringWithFormat:@"Updated: %@", dateString] forKey:@"refreshDate"];
    
    if (self.options.isDynamicControlEnabled) {
        NSMutableArray* lines = [[output componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy];
        if ( nil != lines && 0 < lines.count ) {
            NSUInteger index = [lines indexOfObject:@"----TEXTBAR----"];
            
            if (NSNotFound != index) {
                NSRange theRange;
                
                // Separate the dynamic items
                theRange.location = index+1;
                theRange.length = [lines count] - index - 1;
                NSArray* dynamicLines = [lines subarrayWithRange:theRange];
                
                theRange.location = index;
                theRange.length = [lines count] - index;
                
                // Remove the dynamic items from the actual items
                [lines removeObjectsInRange:theRange];
                output = [lines componentsJoinedByString:@"\n"];
                
                NSString* refreshPrefix = @"REFRESH=";
                NSString* actionScriptPrefix = @"ACTIONSCRIPT=";
                NSString* barTypePrefix = @"BARTYPE=";
                NSString* viewTypePrefix = @"VIEWTYPE=";
                NSString* viewSizePrefix = @"VIEWSIZE=";
                NSString* imageNamePrefix = @"IMAGE=";
                NSString* userAgentPrefix = @"USERAGENT=";
                NSString* barWidthPrefix = @"BARWIDTH=";
                //                        NSString* notificationPrefix = @"NOTIFICATION=";
                //                        NSString* livePrefix = @"LIVE=";
                
                NSString* viewType;
                NSString* barType;
                for(NSString* dynamicLine in dynamicLines) {
                    if ([dynamicLine hasPrefix:refreshPrefix]) {
                        NSNumber* refresh = [NSNumber numberWithInteger:[[dynamicLine substringFromIndex:[refreshPrefix length]] integerValue]];
                        NSLog(@"Refresh: %@", refresh);
                        [self.scriptContext setObject:refresh forKey:@"refresh"];
                    } else if ([dynamicLine hasPrefix:actionScriptPrefix]) {
                        NSString* actionScript = [dynamicLine substringFromIndex:[actionScriptPrefix length]];
                        NSLog(@"ActionScript: %@", actionScript);
                        [self.scriptContext setObject:actionScript forKey:@"actionScript"];
                    } else if ([dynamicLine hasPrefix:barTypePrefix]) {
                        barType = [dynamicLine substringFromIndex:[barTypePrefix length]];
                        NSLog(@"BarType: %@", barType);
                    } else if ([dynamicLine hasPrefix:viewTypePrefix]) {
                        viewType = [dynamicLine substringFromIndex:[viewTypePrefix length]];
                        NSLog(@"ViewType: %@", viewType);
                    } else if ([dynamicLine hasPrefix:viewSizePrefix]) {
                        NSString* viewSize = [dynamicLine substringFromIndex:[viewSizePrefix length]];
                        NSLog(@"ViewSize: %@", viewSize);
                        [self.scriptContext setObject:viewSize forKey:@"viewSize"];
                    } else if ([dynamicLine hasPrefix:imageNamePrefix]) {
                        NSString* imageName = [dynamicLine substringFromIndex:[imageNamePrefix length]];
                        NSLog(@"ImageName: %@", imageName);
                        [self.scriptContext setObject:imageName forKey:@"imageName"];
                    } else if ([dynamicLine hasPrefix:userAgentPrefix]) {
                        NSString* userAgent = [dynamicLine substringFromIndex:[userAgentPrefix length]];
                        NSLog(@"UserAgent: %@", userAgent);
                        [self.scriptContext setObject:userAgent forKey:@"userAgent"];
                    } else if ([dynamicLine hasPrefix:barWidthPrefix]) {
                        NSString* barWidth = [dynamicLine substringFromIndex:[barWidthPrefix length]];
                        NSLog(@"BarWidth: %@", barWidth);
                        NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
                        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
                        [self.scriptContext setObject:[formatter numberFromString:barWidth] forKey:@"barWidth"];
                    }
                }
                
                // Ensure we clean up the viewType if it is no longer configured.
                if (viewType) {
                    [self.scriptContext setObject:viewType forKey:@"viewType"];
                } else {
                    [self.scriptContext removeObjectForKey:@"viewType"];
                }
                
                if (barType) {
                    [self.scriptContext setObject:barType forKey:@"barType"];
                } else {
                    [self.scriptContext removeObjectForKey:@"barType"];
                }
            }
        }
    }
    
    if ( 0 == [output length] ) {
        output = @".";
    } else {
        // To handle invalid escaping on the ANSI escaped data
        output = [output stringByReplacingOccurrencesOfString:@"\\e[" withString:@"\e["];
    }
    
    //output = @"OK";
    [self.scriptContext setObject:output forKey:@"output"];
    [self.scriptContext setObject:outputError forKey:@"outputError"];
    
    return self.scriptContext;
}

//-------------------------------------------------------------------------//
-(NSTask*)createTaskWithScript:(NSString*)script andEnvironment:(NSMutableDictionary*)environment {
    
    environment = environment ? environment : [NSMutableDictionary dictionary];
    
    NSTask *task;
    task = [[NSTask alloc] init];
    
    [environment setObject:@"en_US.UTF-8" forKey:@"LC_ALL"];
    [environment setObject:@"en_US.UTF-8" forKey:@"LANG"];
    
    [environment addEntriesFromDictionary:[self.options defaultEnvironmentVars]];
    
    if (![NSString isEmpty:self.options.defaultHome]) {
        [environment setObject:self.options.defaultHome forKey:@"HOME"];
    }
    
    if (self.options.proxyOptions.isEnabled) {
        [self.options.proxyOptions updateEnvironment:environment];
    }
    
    // To handle invalid escaping on the ANSI escaped data
    script = [script stringByReplacingOccurrencesOfString:@"\\e[" withString:@"\e["];
    
    NSMutableArray* taskArguments = [NSMutableArray array];
    if (![NSString isEmpty:self.options.taskArguments]) {
        [taskArguments addObjectsFromArray:[self.options.taskArguments componentsSeparatedByString:@","]];
    }
    
    [taskArguments addObjectsFromArray:@[@"-c", [NSString stringWithFormat:@"%@", script]]];
    
    if ( self.options.scriptLogging ) {
        NSLog(@"Script command: %@ %@", self.options.defaultShell, taskArguments);
        NSLog(@"Script command: %@", environment);
    }
    
    [task setArguments:taskArguments];
    [task setLaunchPath:self.options.defaultShell];
    task.environment = environment;
    
    return task;
}

//-------------------------------------------------------------------------//
-(void)executeWithEnvironment:(NSMutableDictionary*)environment andCompletionBlock:(void(^)(NSString* output))completionBlock {
    __block NSString* scriptClone = [NSString stringWithString:self.script];
    
    if ( 0 < [scriptClone length] ) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            @autoreleasepool {
                @try {
                    NSTask* task = [self createTaskWithScript:scriptClone andEnvironment:environment];
                    
                    NSPipe *outputPipe = [NSPipe pipe];
                    task.standardOutput = outputPipe;
                    [[outputPipe fileHandleForReading] readToEndOfFileInBackgroundAndNotify];
                    
                    [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleReadToEndOfFileCompletionNotification
                                                                      object:[outputPipe fileHandleForReading]
                                                                       queue:nil
                                                                  usingBlock:^(NSNotification *notification){
                                                                      
                                                                      NSData* data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
                                                                      NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                                      if ( self.options.scriptLogging ) {
                                                                          //NSLog(@"Script output: %@", output);
                                                                      }
                                                                      
                                                                      if ( 0 == [output length] ) {
                                                                          output = @".";
                                                                      } else {
                                                                          // To handle invalid escaping on the ANSI escaped data
                                                                          output = [output stringByReplacingOccurrencesOfString:@"\\e[" withString:@"\e["];
                                                                      }
                                                                      
                                                                      [[NSNotificationCenter defaultCenter] removeObserver:self
                                                                                                                      name:NSFileHandleReadToEndOfFileCompletionNotification
                                                                                                                    object:[notification object]];
                                                                      
                                                                      if ( nil != completionBlock ) {
                                                                          completionBlock(output);
                                                                      }
                                                                  }];
                    
                    [task launch];
                }
                @catch (NSException *exception) {
                    NSLog(@"Script command exception: %@ %@", exception.name, exception.reason);
                }
            }
        }];
    }
}

//-------------------------------------------------------------------------//
+(bool)isHTMLString:(NSString*)value {
    if ([value hasPrefix:@"<html"] && [value hasSuffix:@"</html>"]) {
        return YES;
    }
    
    return NO;
}

//-------------------------------------------------------------------------//
-(NSString*)processResultString:(NSString*)value {
    if ( [RSTextBarScript isHTMLString:value]) {
        value = [NSString stringWithFormat:@"<html style=\"color:%@; font-family: -apple-system; font-size:%lupt\">%@",
                 self.options.darkMode ? @"white" : @"black",
                 (unsigned long)self.options.defaultFontSize-2,
                 [value substringWithRange:NSMakeRange(@"<html>".length, value.length - @"<html>".length)]];
    }
    return value;
}

//-------------------------------------------------------------------------//
-(NSArray*)resultStringToItems:(NSString*)resultString {
    NSMutableArray* lines = [[resultString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy];
    if ( nil != lines && 0 < lines.count ) {
        for(NSInteger i = 0; i < lines.count; ++i) {
            NSString* line = [lines objectAtIndex:i];
            
            line = [self processResultString:line];
            if (nil != line) {
                [lines replaceObjectAtIndex:i withObject:line];
            } else {
                NSLog(@"Empty");
            }
        }
    }
    
    if ( nil == lines || 0 == lines.count ) {
        NSString* result = [self processResultString:resultString];
        if (nil != result) {
            return @[result];
        } else {
            return @[];
        }
    }
    
    return lines;
}

//-------------------------------------------------------------------------//
-(NSString*)resultStringToFirstItem:(NSString*)resultString {
    return [[self resultStringToItems:resultString] objectAtIndex:0];
}

@end
