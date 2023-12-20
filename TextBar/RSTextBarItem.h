//
//  RSTextBarItem.h
//  TextBar
//
//  Created by RichS on 11/26/13.
//  Copyright (c) 2013 RichS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSTextBarScript.h"
#import <MASShortcut/Shortcut.h>

extern NSString *const kActionClipboard;
extern NSString *const kActionScript;

@interface RSTextBarItem : NSObject <NSCoding, NSMenuDelegate>

@property (atomic, assign) BOOL isEnabled;
@property (atomic, assign) BOOL isNotify;
@property (atomic, assign) BOOL isImported;
@property (atomic, assign) BOOL isFileScript;
@property (atomic, assign) BOOL isFileActionScript;
@property (atomic, readonly) BOOL isActionScript;
@property (atomic, strong) NSString* name;
@property (atomic, strong) NSString* imageNamed;
@property (atomic, strong) NSString* imageNamedOverride;
@property (atomic, strong) NSString* text;
@property (atomic, strong) NSString* script;
@property (atomic, strong) NSString* scriptResult;
@property (atomic, strong) NSString* scriptResultError;
@property (atomic, strong) NSNumber* refreshSeconds;
@property (atomic, strong) NSNumber* refreshSecondsOverride;
@property (atomic, assign) NSString* actionType;
@property (atomic, strong) NSString* actionScript;
@property (atomic, strong) NSString* actionScriptOverride;
@property (atomic, strong) NSString* itemGuid;
@property (atomic, assign) BOOL isCloudEnabled;
@property (atomic, strong) NSString* cloudSubmitted;
@property (atomic, strong) NSString* refreshDate;
@property (atomic, strong) NSString* viewType;
@property (atomic, strong) NSString* barType;
@property (atomic, strong) NSNumber* barWidth;
@property (atomic, strong) NSString* viewSize;
@property (nonatomic) MASShortcut* shortcut;
@property (atomic, strong) RSTextBarScript* textBarScript;
@property (atomic, strong) id context;
@property (atomic, strong) NSMutableDictionary* serializeContext;
@property (atomic, strong) NSDictionary* scriptContext;

+(RSTextBarItem*)instance;
-(RSTextBarItem*)clone;

-(void)enable;
-(void)refresh;
-(void)updateMenuBar;
-(void)createScriptTimerAndFire:(BOOL)fire;
-(NSMutableAttributedString*)getAttributedTextForText:(NSString*)text;
-(NSButton*)createTouchBarButton;
-(void)prepareForExport;
-(BOOL)processFromImport;

-(void)removeStatusBar;

@end
