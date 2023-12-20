//
//  RSTextBarOptions.m
//  TextBar
//
//  Created by RichS on 09/07/2016.
//  Copyright © 2016 RichS. All rights reserved.
//

#import "RSTextBarOptions.h"
#import "RSAppDelegate.h"
#import "Helpers.h"
#import "NSString+Extensions.h"
#import "NSFileManager+AppSupportFolder.h"

@implementation RSTextBarOptions {
}

@synthesize scriptsPath = _scriptsPath;

//-------------------------------------------------------------------------//
+(RSTextBarOptions*)instance {
    return [[RSTextBarOptions alloc] init];
}

//-------------------------------------------------------------------------//
-(id)init {
    if ( nil != (self = [super init])) {
        
        //_forceDefaultFont = YES;
        _forceDefaultFont = NO;        
        
        _scriptLogging = NO;
        _isDynamicControlEnabled = YES;
        _defaultShell = @"/bin/sh";
        _defaultFontSize = 13.0;
        _defaultFontName = @"MenuBar";
        _defaultFontDescription = [NSString stringWithFormat:@"%@ %lu", self.defaultFontName, (unsigned long)self.defaultFontSize];
        _defaultMaxWidth = 0;
        _defaultImageSize = 14;
        _defaultMenuImageSize = 28;
        _defaultNotificationImageSize = 28;
        _refreshOnWake = YES;
        _cloneEnvironmentVars = NO;
        _hideTextBarMenuIcon = NO;
        
        _defaultVerticalAdjustor = NO;
        _defaultVerticalAdjustorWithImage = 0.4;
        _defaultVerticalAdjustorWithoutImage = 0.2;
        
        _taskArguments = @"-l";
        
        _proxyOptions = [[RSTextBarProxyOptions alloc] init];
        
        _newsURL = @"http://richsomerfield.com/apps/textbar/releasenotes_textbar.html";
        _scriptsPath = @"";
        
        _darkMode = [Helpers isDarkMode];
        
        [self initialiseShell];
        [self initialiseHome];
    }
    
    return self;
}

//-------------------------------------------------------------------------//
-(void)initialiseShell {
    NSDictionary *environmentDict = [[NSProcessInfo processInfo] environment];
    NSString *userShell = [environmentDict objectForKey:@"SHELL"];
    if (0 < [userShell length]) {
        _defaultShell = userShell;
    }
}

//-------------------------------------------------------------------------//
-(void)initialiseHome {
    NSDictionary *environmentDict = [[NSProcessInfo processInfo] environment];
    NSString *userHome = [environmentDict objectForKey:@"HOME"];
    if (0 < [userHome length]) {
        _defaultHome = userHome;
    }
}

//-------------------------------------------------------------------------//
-(NSDictionary*)defaultEnvironmentVars {
    if (self.cloneEnvironmentVars) {
        return [[NSProcessInfo processInfo] environment];
    }
    
    return @{};
}

//-------------------------------------------------------------------------//
-(void)readPreferences:(NSDictionary*)preferences {
    NSNumber* scriptLogging = [preferences objectForKey:@"ScriptLogging"];
    if ( scriptLogging ) {
        self.scriptLogging = [scriptLogging boolValue];
    }
    
    [self readProxyOptions];
    
    NSNumber* isDynamicControlEnabled = [preferences objectForKey:@"DynamicControlEnabled"];
    if ( isDynamicControlEnabled ) {
        self.isDynamicControlEnabled = [isDynamicControlEnabled boolValue];
    }
    if ( !self.forceDefaultFont ) {
        NSString* defaultFontName = [preferences objectForKey:@"DefaultFontName"];
        if ( defaultFontName && 0 < [defaultFontName length] ) {
            self.defaultFontName = defaultFontName;
        }
        NSNumber* defaultFontSize = [preferences objectForKey:@"DefaultFontSize"];
        if ( defaultFontSize && 0 < defaultFontSize ) {
            self.defaultFontSize = [defaultFontSize unsignedIntegerValue];
        }
    }
    NSString* defaultHome = [preferences objectForKey:@"DefaultHome"];
    if ( defaultHome && 0 < [defaultHome length] ) {
        self.defaultHome = defaultHome;
    }
    NSString* defaultShell = [preferences objectForKey:@"DefaultShell"];
    if ( defaultShell && 0 < [defaultShell length] ) {
        self.defaultShell = defaultShell;
    }
    NSString* taskArguments = [preferences objectForKey:@"TaskArguments"];
    if ( taskArguments ) {
        self.taskArguments = taskArguments;
    }
    NSNumber* defaultMaxWidth = [preferences objectForKey:@"DefaultMaxWidth"];
    if ( defaultMaxWidth && 0 < defaultMaxWidth ) {
        self.defaultMaxWidth = [defaultMaxWidth unsignedIntegerValue];
    }
    NSNumber* defaultImageSize = [preferences objectForKey:@"DefaultImageSize"];
    if ( defaultImageSize && 0 < defaultImageSize ) {
        self.defaultImageSize = [defaultImageSize unsignedIntegerValue];
    }
    NSNumber* defaultNotificationImageSize = [preferences objectForKey:@"DefaultNotificationImageSize"];
    if ( defaultNotificationImageSize ) {
        self.defaultNotificationImageSize = [defaultNotificationImageSize unsignedIntegerValue];
    }
    NSNumber* defaultVerticalAdjustor = [preferences objectForKey:@"DefaultVerticalAdjustor"];
    if ( defaultVerticalAdjustor ) {
        self.defaultVerticalAdjustor = [defaultVerticalAdjustor boolValue];
    }
    NSNumber* defaultVerticalAdjustorWithImage = [preferences objectForKey:@"DefaultVerticalAdjustorWithImage"];
    if ( defaultVerticalAdjustorWithImage ) {
        self.defaultVerticalAdjustorWithImage = [defaultVerticalAdjustorWithImage floatValue];
    }
    NSNumber* defaultVerticalAdjustorWithoutImage = [preferences objectForKey:@"DefaultVerticalAdjustorWithoutImage"];
    if ( defaultVerticalAdjustorWithoutImage ) {
        self.defaultVerticalAdjustorWithoutImage = [defaultVerticalAdjustorWithoutImage floatValue];
    }
    NSNumber* defaultMenuImageSize = [[NSUserDefaults standardUserDefaults] objectForKey:@"DefaultMenuImageSize"];
    if ( defaultMenuImageSize && 0 < defaultMenuImageSize ) {
        self.defaultMenuImageSize = [defaultMenuImageSize unsignedIntegerValue];
    }
    NSNumber* refreshOnWake = [preferences objectForKey:@"RefreshOnWake"];
    if ( refreshOnWake ) {
        self.refreshOnWake = [refreshOnWake boolValue];
    }
    NSNumber* cloneEnvironmentVars = [preferences objectForKey:@"CloneEnvironmentVars"];
    if ( cloneEnvironmentVars ) {
        self.cloneEnvironmentVars = [cloneEnvironmentVars boolValue];
    }
    NSNumber* hideTextBarMenuIcon = [preferences objectForKey:@"HideTextBarMenuIcon"];
    if ( hideTextBarMenuIcon ) {
        self.hideTextBarMenuIcon = [hideTextBarMenuIcon boolValue];
    }
    NSNumber* touchBar = [preferences objectForKey:@"TouchBar"];
    if ( touchBar ) {
        self.touchBar = [touchBar boolValue];
    }
    NSNumber* hideTextBarMenuItems = [preferences objectForKey:@"HideTextBarMenuItems"];
    if ( hideTextBarMenuItems ) {
        self.hideTextBarMenuItems = [hideTextBarMenuItems boolValue];
    }

    NSNumber* showErrorsInMenu = [preferences objectForKey:@"ShowErrorsInMenu"];
    if ( showErrorsInMenu ) {
        self.showErrorsInMenu = [showErrorsInMenu boolValue];
    }

    NSString* newsURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"NewsURL"];
    if (newsURL && 0 < newsURL.length) {
        self.newsURL = newsURL;
    }

    NSString* scriptsPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"ScriptsPath"];
    if (scriptsPath && 0 < scriptsPath.length) {
        self.scriptsPath = scriptsPath;
    }
    
    NSNumber* isDisableItemsOnStart = [[NSUserDefaults standardUserDefaults] objectForKey:@"DisableItemsOnStart"];
    if (isDisableItemsOnStart) {
        self.isDisableItemsOnStart = [isDisableItemsOnStart boolValue];
    }
}

//-------------------------------------------------------------------------//
//-(void)writePreferences {
//    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.isCloudEnabled] forKey:@"IsCloudEnabled"];
//    
//    // Flush to disk - to try to avoid any corruption (if app crashes).
//    [[NSUserDefaults standardUserDefaults] synchronize];
//
//}

//-------------------------------------------------------------------------//
-(void)setDefaultShell:(NSString*)defaultShell {
    _defaultShell = defaultShell ? defaultShell : @"";
    [[NSUserDefaults standardUserDefaults] setObject:_defaultShell forKey:@"DefaultShell"];
}

//-------------------------------------------------------------------------//
-(void)setDefaultHome:(NSString*)defaultHome {
    _defaultHome = defaultHome;
    [[NSUserDefaults standardUserDefaults] setObject:_defaultHome forKey:@"DefaultHome"];
}

//-------------------------------------------------------------------------//
-(void)setTaskArguments:(NSString*)taskArguments {
    _taskArguments = taskArguments ? taskArguments : @"";
    [[NSUserDefaults standardUserDefaults] setObject:_taskArguments forKey:@"TaskArguments"];
}

//-------------------------------------------------------------------------//
-(void)setDefaultFontName:(NSString *)defaultFontName {
    _defaultFontName = defaultFontName;
    self.defaultFontDescription = [NSString stringWithFormat:@"%@ %lu", self.defaultFontName, (unsigned long)self.defaultFontSize];
    [(RSAppDelegate*)[NSApp delegate] refreshOptionsAndTextBarItems];
    
    [[NSUserDefaults standardUserDefaults] setObject:_defaultFontName forKey:@"DefaultFontName"];
}

//-------------------------------------------------------------------------//
-(void)setDefaultFontSize:(NSUInteger)defaultFontSize {
    _defaultFontSize = defaultFontSize;
    self.defaultFontDescription = [NSString stringWithFormat:@"%@ %lu", self.defaultFontName, (unsigned long)self.defaultFontSize];
    [(RSAppDelegate*)[NSApp delegate] refreshOptionsAndTextBarItems];
    
    NSNumber* value = [NSNumber numberWithUnsignedInteger:_defaultFontSize];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:@"DefaultFontSize"];
}

//-------------------------------------------------------------------------//
-(void)resetDefaultFont {
    self.defaultFontSize = 13.0;
    self.defaultFontName = @"MenuBar";
}

//-------------------------------------------------------------------------//
-(void)setDefaultImageSize:(NSUInteger)defaultImageSize {
    _defaultImageSize = defaultImageSize;
    [(RSAppDelegate*)[NSApp delegate] refreshOptionsAndTextBarItems];
    
    NSNumber* value = [NSNumber numberWithUnsignedInteger:_defaultImageSize];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:@"DefaultImageSize"];
}

//-------------------------------------------------------------------------//
-(void)resetDefaultImageSize {
    [self setDefaultImageSize:14];
}

//-------------------------------------------------------------------------//
-(void)setDefaultVerticalAdjustor:(BOOL)defaultVerticalAdjustor {
    _defaultVerticalAdjustor = defaultVerticalAdjustor;
    [(RSAppDelegate*)[NSApp delegate] refreshOptionsAndTextBarItems];
    
    NSNumber* value = [NSNumber numberWithBool:_defaultVerticalAdjustor];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:@"DefaultVerticalAdjustor"];
}

//-------------------------------------------------------------------------//
-(void)setDefaultVerticalAdjustorWithImage:(float)defaultVerticalAdjustorWithImage {
    _defaultVerticalAdjustorWithImage = defaultVerticalAdjustorWithImage;
    [(RSAppDelegate*)[NSApp delegate] refreshOptionsAndTextBarItems];
    
    NSNumber* value = [NSNumber numberWithFloat:_defaultVerticalAdjustorWithImage];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:@"DefaultVerticalAdjustorWithImage"];
}

//-------------------------------------------------------------------------//
-(void)setDefaultVerticalAdjustorWithoutImage:(float)defaultVerticalAdjustorWithoutImage {
    _defaultVerticalAdjustorWithoutImage = defaultVerticalAdjustorWithoutImage;
    [(RSAppDelegate*)[NSApp delegate] refreshOptionsAndTextBarItems];
    
    NSNumber* value = [NSNumber numberWithFloat:_defaultVerticalAdjustorWithoutImage];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:@"DefaultVerticalAdjustorWithoutImage"];
}

//-------------------------------------------------------------------------//
-(void)resetDefaultVerticalAdjustor {
    self.defaultVerticalAdjustor = NO;
    self.defaultVerticalAdjustorWithImage = 0.4;
    self.defaultVerticalAdjustorWithoutImage = 0.2;
}

//-------------------------------------------------------------------------//
-(void)resetTaskArguments {
    self.taskArguments = @"-l";
}

//-------------------------------------------------------------------------//
-(void)resetDefaultShell {
    _defaultShell = @"/bin/bash";
    [self initialiseShell];
    
    // Force save (and update in UI)
    self.defaultShell = _defaultShell;
}

//-------------------------------------------------------------------------//
-(void)resetDefaultHome {
    _defaultHome = nil;
    [self initialiseHome];
    
    // Force save (and update in UI)
    self.defaultHome = _defaultHome;
}

//-------------------------------------------------------------------------//
-(void)setScriptLogging:(BOOL)scriptLogging {
    _scriptLogging = scriptLogging;
    
    NSNumber* value = [NSNumber numberWithBool:_scriptLogging];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:@"ScriptLogging"];
}

//-------------------------------------------------------------------------//
-(void)setRefreshOnWake:(BOOL)refreshOnWake {
    _refreshOnWake = refreshOnWake;
    
    NSNumber* value = [NSNumber numberWithBool:_refreshOnWake];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:@"RefreshOnWake"];
}

//-------------------------------------------------------------------------//
-(void)setShowErrorsInMenu:(BOOL)showErrorsInMenu {
    _showErrorsInMenu = showErrorsInMenu;
    
    NSNumber* value = [NSNumber numberWithBool:_showErrorsInMenu];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:@"ShowErrorsInMenu"];
}

//-------------------------------------------------------------------------//
-(void)setCloneEnvironmentVars:(BOOL)cloneEnvironmentVars {
    _cloneEnvironmentVars = cloneEnvironmentVars;
    
    NSNumber* value = [NSNumber numberWithBool:_cloneEnvironmentVars];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:@"CloneEnvironmentVars"];
}

//-------------------------------------------------------------------------//
-(void)setScriptsPath:(NSString*)scriptsPath {
    _scriptsPath = scriptsPath;
    
    // TODO: Verify it is a valid path, or, empty string (which means default)
    
    [[NSUserDefaults standardUserDefaults] setObject:_scriptsPath forKey:@"ScriptsPath"];
}

//-------------------------------------------------------------------------//
-(NSString*)scriptsPath {
    NSString* scriptsPath = _scriptsPath;
    
    if ([NSString isEmpty:scriptsPath]) {
        NSURL* appSupportFolder = [[NSFileManager defaultManager] applicationSupportFolder];
        NSURL *scriptsURL = [appSupportFolder URLByAppendingPathComponent:@"scripts"];
        scriptsPath = [scriptsURL path];
    }
    
    return scriptsPath;
}

//-------------------------------------------------------------------------//
-(void)writeProxyOptions {
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:self.proxyOptions];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"ProxyOptions"];
}

//-------------------------------------------------------------------------//
-(void)readProxyOptions {
    RSTextBarProxyOptions* proxyOptions = nil;
    NSData* data = [[NSUserDefaults standardUserDefaults] objectForKey:@"ProxyOptions"];
    if (nil != data) {
        proxyOptions = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    self.proxyOptions = proxyOptions ? proxyOptions : [[RSTextBarProxyOptions alloc] init];
}

@end
