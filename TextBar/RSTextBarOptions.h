//
//  RSTextBarOptions.h
//  TextBar
//
//  Created by RichS on 09/07/2016.
//  Copyright © 2016 RichS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSTextBarProxyOptions.h"

@interface RSTextBarOptions : NSObject

+(RSTextBarOptions*)instance;

@property (nonatomic, assign) BOOL isDisableItemsOnStart;
@property (nonatomic, assign) BOOL darkMode;
@property (nonatomic, assign) BOOL scriptLogging;
@property (nonatomic, assign) BOOL isDynamicControlEnabled;
@property (nonatomic, strong) NSString* defaultShell;
@property (nonatomic, assign) BOOL forceDefaultFont;
@property (nonatomic, assign) NSUInteger defaultFontSize;
@property (nonatomic, strong) NSString* defaultFontName;
@property (nonatomic, strong) NSString* defaultFontDescription;
@property (nonatomic, assign) NSUInteger defaultMaxWidth;
@property (nonatomic, assign) NSUInteger defaultImageSize;
@property (nonatomic, assign) NSUInteger defaultMenuImageSize;
@property (nonatomic, assign) NSUInteger defaultNotificationImageSize;
@property (nonatomic, assign) BOOL defaultVerticalAdjustor;
@property (nonatomic, assign) BOOL refreshOnWake;
@property (nonatomic, assign) BOOL cloneEnvironmentVars;
@property (nonatomic, assign) BOOL showErrorsInMenu;
@property (nonatomic, strong) NSString* taskArguments;
@property (nonatomic, strong) NSString* defaultHome;
@property (nonatomic, assign) BOOL hideTextBarMenuIcon;
@property (nonatomic, assign) BOOL touchBar;
@property (nonatomic, assign) BOOL hideTextBarMenuItems;

@property (nonatomic, strong) RSTextBarProxyOptions* proxyOptions;

@property (nonatomic, assign) float defaultVerticalAdjustorWithImage;
@property (nonatomic, assign) float defaultVerticalAdjustorWithoutImage;

@property (nonatomic, strong) NSString* newsURL;
@property (nonatomic, strong) NSString* scriptsPath;

-(void)readPreferences:(NSDictionary*)preferences;
-(void)writeProxyOptions;
-(void)readProxyOptions;

-(void)resetDefaultFont;
-(void)resetDefaultImageSize;
-(void)resetDefaultVerticalAdjustor;
-(void)resetDefaultShell;
-(void)resetDefaultHome;
-(void)resetTaskArguments;

-(NSDictionary*)defaultEnvironmentVars;

@end
