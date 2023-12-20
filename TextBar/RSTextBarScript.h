//
//  RSTextBarScript.h
//  TextBar
//
//  Created by RichS on 09/07/2016.
//  Copyright © 2016 RichS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSTextBarOptions.h"

@interface RSTextBarScript : NSObject

+(RSTextBarScript*)instanceWithScript:(NSString*)script andOptions:(RSTextBarOptions*)options;

@property (atomic, strong) RSTextBarOptions* options;
@property (atomic, strong) NSString* script;
@property (atomic, strong) NSMutableDictionary* scriptContext;

-(void)initScriptContext;
-(NSDictionary*)execute;
//-(void)executeUsingCompletionBlock:(void(^)(NSString* output))completionBlock;
-(NSTask*)createTaskWithScript:(NSString*)script andEnvironment:(NSMutableDictionary*)environment;
-(void)executeWithEnvironment:(NSMutableDictionary*)environment andCompletionBlock:(void(^)(NSString* output))completionBlock;
-(NSString*)processResultString:(NSString*)value;
-(NSArray*)resultStringToItems:(NSString*)resultString;
-(NSString*)resultStringToFirstItem:(NSString*)resultString;
-(NSDictionary*)convertOutputToScriptContext:(NSString*)output withError:(NSString*)outputError;

+(bool)isHTMLString:(NSString*)value;

@end
