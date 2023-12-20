//
//  RSAppDelegate.m
//  TextBar
//
//  Created by RichS on 11/25/13.
//  Copyright (c) 2013 RichS. All rights reserved.
//

#import "RSAppDelegate.h"

#import "Helpers.h"
#import "NSAttributedString+Extended.h"
#import "NSImage+Extended.h"
#import "NSString+Extensions.h"

#import "RSNamedImageTransformer.h"
#import "RSNumberTransformer.h"
#import "RSTextBarItem.h"
#import "RSTextBarItemExport.h"
#import "RSTextBarScript.h"
#import "RSTextBarImages.h"
#import "WebViewNewWindow.h"
#import "RSTextBarItemTableCellView.h"

#include <math.h>

#define MyPrivateTableViewDataType @"NSMutableDictionary"

static const NSTouchBarItemIdentifier kTextBarIdentifier = @"com.RichSomerfield.TextBar";

@interface NSUserNotification (CFIPrivate)
- (void)set_identityImage:(NSImage *)image;
@end

@implementation RSAppDelegate {
    WebViewNewWindow* _webViewNewWindow;
    NSTouchBar *_touchBar;
}

//-------------------------------------------------------------------------//
- (id)init {
    if (self = [super init]) {
        _options = [RSTextBarOptions instance];
        
        _defaultAdditionalImagesFolder = @"";
        
        _textBarScriptQueue = [[NSOperationQueue alloc] init];
        _textBarScriptQueue.maxConcurrentOperationCount = 10;
        
        _textBarItems = [NSMutableArray array];
        _textBarItemsAlt = [NSMutableArray array];
        
        _imageCache = [[NSCache alloc] init];
        
        _defaultANSIEscaper = [[AMR_ANSIEscapeHelper alloc] init];
        _itemANSIEscaper = [[AMR_ANSIEscapeHelper alloc] init];
        _highlightedItemANSIEscaper = [[AMR_ANSIEscapeHelper alloc] init];
        
        _filesToOpen = [NSMutableSet set];
        
        // We have to do this before the xib loads - as there is data binding!
        NSNumber* defaultAllImages = [[NSUserDefaults standardUserDefaults] objectForKey:@"DefaultAllImages"];
        if ( defaultAllImages && [defaultAllImages boolValue] ) {
            _textBarImages = [RSTextBarImages defaultAllImages];
        } else {
            _textBarImages = [RSTextBarImages defaultImages];
        }
        
        NSString* defaultAdditionalImagesFolder = [[NSUserDefaults standardUserDefaults] objectForKey:@"DefaultAdditionalImagesFolder"];
        if ( 0 < [defaultAdditionalImagesFolder length] ) {
            [self additionalImages:defaultAdditionalImagesFolder];
        }
        
        _textBarActions = @[kActionClipboard, kActionScript];
        
        _proxySettings = [Helpers getProxySettings];
    }
    return self;
}

//-------------------------------------------------------------------------//
- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
    NSLog(@"OpenFiles: %@", filenames);
    
    // RichS: 2017.10.29 - For some (stupid) reason, sometimes Apple sends up the same file multiple files.
    // We mitigate this by using a set and opening after a slight delay (which is long enough to eliminate the duplicates)
    [self.filesToOpen addObjectsFromArray:filenames];
    [self performSelector:@selector(openQueuedFiles) withObject:nil afterDelay:0.5];
}

//-------------------------------------------------------------------------//
-(void)openQueuedFiles {
    NSString* filename = [self.filesToOpen anyObject];
    if (nil != filename) {
        [self.filesToOpen removeObject:filename];
        
        if (![NSString isEmpty:filename]) {
            RSTextBarItem* importItem = [NSKeyedUnarchiver unarchiveObjectWithFile:filename];
            if ( nil == importItem ) {
                [self showMessageSheetWithTitle:@"Import into TextBar failed" andMessage:@"This is not a valid TextBar file."];
                return;
            }
            
            NSString* importDescription = @"Import TextBar item?";
            if (![NSString isEmpty:importItem.name]) {
                importDescription = [NSString stringWithFormat:@"Import '%@' into TextBar?", importItem.name];
            }
            
            self.textBarItemImport.messageTitle.stringValue = importDescription;
            
            // Force show the Preferences UI - so we can anchor to it.
            [self actionPreferences:nil];
            
            [self.window beginSheet:self.textBarItemImport  completionHandler:^(NSModalResponse returnCode) {
                if (NSModalResponseOK == returnCode) {
                    if ([importItem processFromImport]) {
                        [self addTextBarItemToUI:importItem];
                    } else {
                        // TODO: Error importing item
                    }
                }
                
                // Run again for multiple items
                [self performSelector:@selector(openQueuedFiles) withObject:nil afterDelay:0.5];
            }];
        }
        
        [self updateTextBarItemController];
        [self writePreferences];
    }
}

//-------------------------------------------------------------------------//
- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    NSLog(@"OpenFile: %@", filename);
    return YES;
}

//-------------------------------------------------------------------------//
- (void)openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument * _Nullable, BOOL, NSError * _Nullable))completionHandler {
    
    //if (doOpenDocument) {
    //    [super openDocumentWithContentsOfURL:url display:displayDocument completionHandler:completionHandler];
    //} else {
    completionHandler(NULL, NO, NULL);
    //}
}

//-------------------------------------------------------------------------//
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self initialiseTextBar];
}

//-------------------------------------------------------------------------//
-(void)applicationWillResignActive:(NSNotification *)notification {
    [self.textBarItemPopover close];
}

//-------------------------------------------------------------------------//
- (void)initialiseTextBar {
    if ( !_initialisedTextBar ) {
        _initialisedTextBar = YES;
#ifndef DEBUG
        [Helpers showIconInDock:NO];
#endif // DEBUG
        [self logUserDefaults];
        [self initialiseApp];
    }
}

//-------------------------------------------------------------------------//
-(void)logUserDefaults {
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *folder = [path objectAtIndex:0];
    NSLog(@"NSUserDefaults Path: %@/Preferences", folder);
    NSLog(@"NSUserDefaults Dictionary: %@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
}

//-------------------------------------------------------------------------//
-(void)initialiseApp {
    _showMenuOnAll = YES;
    
    [self initialiseTransformers];
    [self initialiseMainMenuBar];
    [self initialiseSubscriptions];
    [self registerWorkspaceNotifications];
    [self registerWebViewHandlers];
    [self registerFontHandler];
    [self readPreferences];
    [self defaultPreferences];
    
    [self.textBarItemsTable registerForDraggedTypes:@[MyPrivateTableViewDataType]];
    [self.textBarItems2Table registerForDraggedTypes:@[MyPrivateTableViewDataType]];
    
    // Fix to prevent white text when selected (hence white on white)
    [self.textBarItemsTable setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    
    // This should work better, but, created a judder when trying to find a drop position.
    //[self.textBarItemsTable setDraggingDestinationFeedbackStyle:NSTableViewDraggingDestinationFeedbackStyleGap];
    
    [[self.textBarPreferencesNews mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.options.newsURL]]];
    NSString* appVersion = [NSString stringWithFormat:@"Version %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    self.textBarPreferencesVersion.stringValue = [NSString stringWithFormat:@"You are using TextBar %@", appVersion];
    
    [self addObservers];
    
    // As we can't create a binding in IB (for a custom view), we have to do it here. This controllers the shortcut value to the selected item.
    [self.textBarItemShortcutView bind:@"shortcutValue" toObject:self.textBarItemsController withKeyPath:@"selection.shortcut" options:nil];
    
    [self.textBarPreferencesItemHiddenImage addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:nil];
    [self.textBarPreferencesItemImage addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:nil];
    [self.textBarPreferencesItemImage registerForDraggedTypes:[NSImage imageTypes]];
    
    [self initialiseCachedImages];
    
    /* RichS: Changed to look more like a button, so, removing this hack...
     // Set up the linked text to look like a HTML hyperlink
     NSColor *color = [NSColor blueColor];
     NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[self.textBarRecipesLink attributedTitle]];
     NSRange titleRange = NSMakeRange(0, [colorTitle length]);
     [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
     [colorTitle addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:titleRange];
     [self.textBarRecipesLink setAttributedTitle:colorTitle];
     */
}

//-------------------------------------------------------------------------//
-(void)initialiseCachedImages {
    //    CGFloat fontSize = [[NSFont menuFontOfSize:[NSFont systemFontSize]] pointSize];
    //    NSImage *menuItemImage = [[NSImage imageNamed:@"TextBarMenuItem"] resizeTo:CGSizeMake(fontSize, fontSize)];
    //
    //    CGFloat menuSize = [[NSStatusBar systemStatusBar] thickness] * 0.7;
    //    NSImage *menuBarImage = [[NSImage imageNamed:@"TextBarMenuBar"] resizeTo:CGSizeMake(menuSize, menuSize)];
}

//-------------------------------------------------------------------------//
-(void)initialiseTransformers {
    RSNamedImageTransformer *namedImageTransformer = [[RSNamedImageTransformer alloc] init];
    [NSValueTransformer setValueTransformer:namedImageTransformer forName:@"RSNamedImageTransformer"];
    
    RSNumberTransformer *numberTransformer = [[RSNumberTransformer alloc] init];
    [NSValueTransformer setValueTransformer:numberTransformer forName:@"RSNumberTransformer"];
}

//-------------------------------------------------------------------------//
-(void)initialiseMainMenuBar {
    [self addMainMenuBar];
}

//-------------------------------------------------------------------------//
-(void)addMainMenuBar {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    if ( nil == _statusItem ) {
        NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
        _statusItem = [statusBar statusItemWithLength:NSSquareStatusItemLength];
        
        [_statusItem setMenu:_statusMenu];
        [_statusMenu setDelegate:self];
        
        //CGFloat menuSize = [[NSStatusBar systemStatusBar] thickness] * 0.7;
        NSImage *menuImage = [NSImage imageNamed:@"TextBar32"];
        
        if ( self.options.darkMode ) {
            //menuImage.template = YES;
        }
        
        _statusItem.image = menuImage;
        _statusItem.highlightMode = YES;
    }
}

//-------------------------------------------------------------------------//
-(void)removeMainMenuBar {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    if ( _statusItem ) {
        NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
        [statusBar removeStatusItem:_statusItem];
        _statusItem = nil;
    }
}

//-------------------------------------------------------------------------//
- (void)cacheImage:(NSImage*)image forName:(NSString*)imageName {
    @synchronized(_imageCache) {
        [_imageCache setObject:image forKey:imageName];
    }
}

//-------------------------------------------------------------------------//
- (NSImage*)cachedImageForName:(NSString*)imageName {
    NSImage* image = nil;
    @synchronized(_imageCache) {
        image = [_imageCache objectForKey:imageName];
    }
    
    return image;
}

//-------------------------------------------------------------------------//
-(void)initialiseSubscriptions {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    // Subscribe for DarkMode notifications
    if ([Helpers supportsDarkMode] ) {
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                            selector:@selector(darkModeChanged:)
                                                                name:@"AppleInterfaceThemeChangedNotification"
                                                              object:nil];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(imageDropped:)
                                                 name:@"RSImageDroppedNotification"
                                               object:nil];
}

//-------------------------------------------------------------------------//
-(void)addObservers {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    // Set up watchers for Preferences (so we can update the menubar items)
    NSKeyValueObservingOptions options = NSKeyValueObservingOptionPrior|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld;
    
    [self.textBarItemsController addObserver:self forKeyPath:@"arrangedObjects" options:options context:nil];
    [self.textBarItemsController addObserver:self forKeyPath:@"arrangedObjects.name" options:options context:nil];
    [self.textBarItemsController addObserver:self forKeyPath:@"arrangedObjects.isEnabled" options:options context:nil];
    [self.textBarItemsController addObserver:self forKeyPath:@"arrangedObjects.isNotify" options:options context:nil];
    [self.textBarItemsController addObserver:self forKeyPath:@"arrangedObjects.imageNamed" options:options context:nil];
    [self.textBarItemsController addObserver:self forKeyPath:@"arrangedObjects.script" options:options context:nil];
    [self.textBarItemsController addObserver:self forKeyPath:@"arrangedObjects.refreshSeconds" options:options context:nil];
    [self.textBarItemsController addObserver:self forKeyPath:@"arrangedObjects.actionType" options:options context:nil];
    [self.textBarItemsController addObserver:self forKeyPath:@"arrangedObjects.actionScript" options:options context:nil];
    [self.textBarItemsController addObserver:self forKeyPath:@"arrangedObjects.isCloudEnabled" options:options context:nil];
    [self.textBarItemsController addObserver:self forKeyPath:@"arrangedObjects.shortcut" options:options context:nil];
}

//-------------------------------------------------------------------------//
-(void)removeObservers {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    //@try{
    [self.textBarItemsController removeObserver:self forKeyPath:@"arrangedObjects"];
    [self.textBarItemsController removeObserver:self forKeyPath:@"arrangedObjects.name"];
    [self.textBarItemsController removeObserver:self forKeyPath:@"arrangedObjects.isEnabled"];
    [self.textBarItemsController removeObserver:self forKeyPath:@"arrangedObjects.isNotify"];
    [self.textBarItemsController removeObserver:self forKeyPath:@"arrangedObjects.imageNamed"];
    [self.textBarItemsController removeObserver:self forKeyPath:@"arrangedObjects.script"];
    [self.textBarItemsController removeObserver:self forKeyPath:@"arrangedObjects.refreshSeconds"];
    [self.textBarItemsController removeObserver:self forKeyPath:@"arrangedObjects.actionType"];
    [self.textBarItemsController removeObserver:self forKeyPath:@"arrangedObjects.actionScript"];
    [self.textBarItemsController removeObserver:self forKeyPath:@"arrangedObjects.isCloudEnabled"];
    [self.textBarItemsController removeObserver:self forKeyPath:@"arrangedObjects.shortcut"];
    //}
    //@catch (NSException * __unused exception) {}
    
    // RichS: Theoretically this should be better, but, if you quickly add/remove TextBar items in Preferences UI, the menubar goes nuts and adds loads of entry.
    //    [Helpers removeObserver:self fromObject:self.textBarItemsController forKeyPath:@"arrangedObjects"];
    //    [Helpers removeObserver:self fromObject:self.textBarItemsController forKeyPath:@"arrangedObjects.isEnabled"];
    //    [Helpers removeObserver:self fromObject:self.textBarItemsController forKeyPath:@"arrangedObjects.isNotify"];
    //    [Helpers removeObserver:self fromObject:self.textBarItemsController forKeyPath:@"arrangedObjects.imageNamed"];
    //    [Helpers removeObserver:self fromObject:self.textBarItemsController forKeyPath:@"arrangedObjects.script"];
    //    [Helpers removeObserver:self fromObject:self.textBarItemsController forKeyPath:@"arrangedObjects.refreshSeconds"];
    //    [Helpers removeObserver:self fromObject:self.textBarItemsController forKeyPath:@"arrangedObjects.actionType"];
    //    [Helpers removeObserver:self fromObject:self.textBarItemsController forKeyPath:@"arrangedObjects.actionScript"];
}

//-------------------------------------------------------------------------//
-(void)defaultPreferences {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    if ( 0 == [self.textBarItems count]) {
        RSTextBarItem* item;// = [RSTextBarItem instance];
        
        /* Debugging
         for( int i = 0; i < 4; ++i ) {
         item = [RSTextBarItem instance];
         item.isEnabled = YES;
         item.isNotify = YES;
         item.imageNamed = @"computer-32";
         item.script = [NSString stringWithFormat:@"echo \"%dHello%d\"", i, i];
         item.refreshSeconds = [NSNumber numberWithUnsignedInt:10];
         [self addTextBarItemInternal:item];
         }
         */
        
        ///*
        // Own IP Address
        item = [RSTextBarItem instance];
        item.name = @"Local IP Address";
        item.isEnabled = YES;
        item.isNotify = YES;
        item.imageNamed = @"computer-32";
        item.script = @"ipconfig getifaddr en0";
        item.refreshSeconds = [NSNumber numberWithUnsignedInt:60];
        [self addTextBarItemInternal:item];
        
        // External IP Address
        item = [RSTextBarItem instance];
        item.name = @"External IP Address";
        item.isEnabled = YES;
        item.imageNamed = @"globe-32";
        item.script = @"curl -s http://ipinfo.io/ip";
        item.refreshSeconds = [NSNumber numberWithUnsignedInt:60];
        [self addTextBarItemInternal:item];
        
        // Username
        item = [RSTextBarItem instance];
        item.name = @"Who Am I";
        item.isEnabled = YES;
        item.imageNamed = @"user_male3-32";
        item.script = @"whoami";
        item.refreshSeconds = [NSNumber numberWithUnsignedInt:360];
        [self addTextBarItemInternal:item];
        
        //        // Time in UK timezone
        //        item = [RSTextBarItem instance];
        //        item.isEnabled = YES;
        //        item.imageNamed = @"clock-32";
        //        item.script = @"UKDATE=`TZ=UK/Manchester date +\"%H:%M %p\"` ; echo \"UK: $UKDATE\"";
        //        item.refreshSeconds = [NSNumber numberWithUnsignedInt:60];
        //        [self addTextBarItemInternal:item];
        
        // SSID
        item = [RSTextBarItem instance];
        item.name = @"WiFi SSID";
        item.isEnabled = YES;
        item.isNotify = YES;
        item.imageNamed = @"rfid_signal-32";
        item.script = @"networksetup -getairportnetwork en0 | sed 's/.*[:] //'";
        item.refreshSeconds = [NSNumber numberWithUnsignedInt:60];
        [self addTextBarItemInternal:item];
        
        // DF
        item = [RSTextBarItem instance];
        item.name = @"Free Disk Space";
        item.isEnabled = YES;
        item.isNotify = YES;
        item.imageNamed = @"database-32";
        item.script = @"df -H / | egrep '/$' | awk '{print $4}'";
        item.refreshSeconds = [NSNumber numberWithUnsignedInt:60];
        [self addTextBarItemInternal:item];
        //*/
        
        // RelayFM - Next Show
        //        item = [RSTextBarItem instance];
        //        item.isEnabled = YES;
        //        item.imageNamed = @"relayfm-32";
        //        item.script = @"Relay FM";
        //        item.refreshSeconds = [NSNumber numberWithUnsignedInt:360];
        //        item.isNotify = YES;
        //        item.actionType = @"Script";
        //        item.actionScript = @"Relay FM";
        //        [self addTextBarItemInternal:item];
        
        [self writePreferences];
        
        [self updateTextBarItemController];
        [self addBarItems];
    }
}

//-------------------------------------------------------------------------//
-(void)additionalImages:(NSString*)imagesFolder {
    NSMutableArray* textBarImages = [_textBarImages mutableCopy];
    
    NSString *filename;
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:imagesFolder];
    while (filename = [enumerator nextObject]) {
        if ([[filename pathExtension] isEqualToString:@"png"]) {
            // Prefix for ":" to indicate the name is a full path
            [textBarImages addObject:[NSString stringWithFormat:@":%@", [imagesFolder stringByAppendingPathComponent:filename]]];
        }
    }
    
    _textBarImages = textBarImages;
}

//-------------------------------------------------------------------------//
+(NSFont*)fontWithName:(NSString*)name size:(NSUInteger)size {
    NSFont* font;
    
    if (name && 0 < [name length]) {
        if (NSOrderedSame == [@"System" compare:name]) {
            font = [NSFont systemFontOfSize:size];
        } else if (NSOrderedSame == [@"System" compare:name]) {
            font = [NSFont boldSystemFontOfSize:size];
        } else if (NSOrderedSame == [@"Label" compare:name]) {
            font = [NSFont labelFontOfSize:size];
        } else if (NSOrderedSame == [@"TitleBar" compare:name]) {
            font = [NSFont titleBarFontOfSize:size];
        } else if (NSOrderedSame == [@"MenuBar" compare:name]) {
            font = [NSFont menuBarFontOfSize:size];
        } else if (NSOrderedSame == [@"Menu" compare:name]) {
            font = [NSFont menuFontOfSize:size];
        } else {
            font = [NSFont fontWithName:name size:size];
        }
    }
    
    return font;
}

//-------------------------------------------------------------------------//
-(void)darkModeChanged:(NSNotification *)notif {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    BOOL originalDarkMode = self.options.darkMode;
    self.options.darkMode = [Helpers isDarkMode];
    
    if ( originalDarkMode != self.options.darkMode ) {
        [self updateANSIEscaper];
        [self refreshTextBarItems];
    }
}

//-------------------------------------------------------------------------//
-(void)imageDropped:(NSNotification*)notif {
    NSString* imageFile = [notif.userInfo objectForKey:@"File"];
    RSTextBarItem* item = [self.textBarItemsController.selectedObjects firstObject];
    if (nil != item && imageFile && 0 < imageFile.length) {
        item.imageNamed = [NSString stringWithFormat:@":%@", imageFile];
    }
}

//-------------------------------------------------------------------------//
-(void)receiveSleepNote:(NSNotification*)notif {
    if (self.options.scriptLogging) {
        NSLog(@"receiveSleepNote: %@", [notif name]);
    }
}

//-------------------------------------------------------------------------//
-(void)receiveWakeNote:(NSNotification*)notif {
    if (self.options.scriptLogging) {
        NSLog(@"receiveWakeNote: %@", [notif name]);
    }
    
    if (self.options.refreshOnWake) {
        
        // Delay execution for a few seconds - to try to let wifi re-connect.
        double delayTime = 6.0; // Seconds
        NSLog(@"TextBar: Refresh on wake detected");
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            NSLog(@"TextBar: Refresh on wake actioned");
            [self refreshTextBarItems];
        });
    }
}

//-------------------------------------------------------------------------//
-(void)registerWorkspaceNotifications {
    //These notifications are filed on NSWorkspace's notification center, not the default
    // notification center. You will not receive sleep/wake notifications if you file
    //with the default notification center.
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(receiveSleepNote:)
                                                               name:NSWorkspaceWillSleepNotification object:NULL];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(receiveWakeNote:)
                                                               name:NSWorkspaceDidWakeNotification object:NULL];
}

//-------------------------------------------------------------------------//
// RichS: A fairly hacky approach to launch a browers window externally.
// We register for new 'windows' with createWebViewWithRequest. But, the request is always nil! Argh.
// So, we create a new fake webview, return it (to say this'll handle the request). We make the fake
// webview then call us when a naviation occurs, and then use that to launch the external browser.
// Sigh.
-(void)registerWebViewHandlers {
    _webViewNewWindow = [WebViewNewWindow instance];
    [self.textBarItemWebView setUIDelegate:self];
    [self.textBarItemWebView setPolicyDelegate:self];
    [self.textBarItemWebView setFrameLoadDelegate:self];
}

//-------------------------------------------------------------------------//
- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request {
    return [_webViewNewWindow newWebView];
}

//-------------------------------------------------------------------------//
-(void)webView:(WebView *)webView decidePolicyForNewWindowAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request newFrameName:(NSString *)frameName decisionListener:(id<WebPolicyDecisionListener>)listener {
    
    if ([actionInformation objectForKey:WebActionElementKey]) {
        [[NSWorkspace sharedWorkspace] openURL:[request URL]];
    }
}

//-------------------------------------------------------------------------//
-(void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame {
    if (frame == [self.textBarItemWebView mainFrame]) {
        self.textBarItemPopoverTitle.stringValue = title;
    }
}

//-------------------------------------------------------------------------//
-(void)registerFontHandler {
    [[NSFontManager sharedFontManager] setAction:@selector(changeDefaultFont:)];
}

//-------------------------------------------------------------------------//
-(void)changeDefaultFont:(id)sender {
    
    NSLog(@"Changed Font");
    
    NSFont *oldFont = [RSAppDelegate fontWithName:self.options.defaultFontName size:self.options.defaultFontSize];
    NSFont *newFont = [sender convertFont:oldFont];
    
    self.options.defaultFontName = newFont.fontName;
    self.options.defaultFontSize = newFont.pointSize;
    
    return;
}

//-------------------------------------------------------------------------//
-(void)refreshOptionsAndTextBarItems {
    [self updateANSIEscaper];
    [self refreshTextBarItems];
}

//-------------------------------------------------------------------------//
-(void)addTextBarItemInternal:(RSTextBarItem*)item {
    [self.textBarItems addObject:item];
    [self.textBarItemsAlt addObject:item];
}

//-------------------------------------------------------------------------//
-(void)displayTextBarItems {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    for( RSTextBarItem* item in self.textBarItems ) {
        [item enable];
    }
}

//-------------------------------------------------------------------------//
-(void)removeTextBarItems:(BOOL)controllerRefresh {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    [self removeBarItems];
    [self.textBarItems removeAllObjects];
    [self.textBarItemsAlt removeAllObjects];
    
    // Can cause issues as it is handled in separate events (via dispatch)
    if (controllerRefresh) {
        [self.textBarItemsController rearrangeObjects];
    }
}

//-------------------------------------------------------------------------//
-(void)refreshTextBarItems {
    [self refreshTextBarItems:NO];
}

//-------------------------------------------------------------------------//
-(void)refreshTextBarItems:(BOOL)refreshAll {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    for( RSTextBarItem* item in self.textBarItems ) {
        // Only refresh items if positive refresh time, not already refreshed, or, all if requested.
        if (item.isEnabled && (refreshAll || 0 < [item.refreshSeconds integerValue] || 0 == item.refreshDate.length)) {
            [item refresh];
        }
    }
}

//-------------------------------------------------------------------------//
-(void)refreshTextBarItemForIndex:(NSUInteger)index {
    if (index < self.textBarItems.count) {
        RSTextBarItem* item = [self.textBarItems objectAtIndex:index];
        [item refresh];
    }
}

//-------------------------------------------------------------------------//
-(void)removeBarItems {
    [self removeStatusBarItems];
    [self removeTouchBarItems];
}

//-------------------------------------------------------------------------//
-(void)removeStatusBarItems {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    // This works around the limitations of KVO not telling us which item has been removed
    NSSet *statusBarItems = [NSSet setWithArray:self.textBarItems];
    NSMutableSet *statusBarItemsAlt = [NSMutableSet setWithArray:self.textBarItemsAlt];
    
    [statusBarItemsAlt unionSet:statusBarItems];
    for( RSTextBarItem* item in statusBarItemsAlt ) {
        [item removeStatusBar];
    }
}

//-------------------------------------------------------------------------//
-(void)removeTouchBarItems {
    [_touchBar setDefaultItemIdentifiers:[NSArray array]];
}

//-------------------------------------------------------------------------//
-(void)addBarItems {
    [self addStatusBarItems];
    [self addTouchBarItems];
}

//-------------------------------------------------------------------------//
-(void)addStatusBarItems {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    BOOL requireMainMenuBar = YES;
    
    for( RSTextBarItem* item in [self.textBarItems reverseObjectEnumerator] ) {
        [item enable];
        
        if ( item.isEnabled ) {
            requireMainMenuBar = NO;
        }
    }
    
    if ( requireMainMenuBar ) {
        [self addMainMenuBar];
    } else {
        [self removeMainMenuBar];
    }
}

//-------------------------------------------------------------------------//
-(void)addTouchBarItems {
    if (self.options.touchBar) {
        if ( ![NSThread isMainThread] ) {
            NSLog(@"Not on MainThead: %s", __FUNCTION__);
        }
        
        NSMutableArray* touchBarIdentifiers = [NSMutableArray array];
        for( RSTextBarItem* item in self.textBarItems ) {
            if ( item.isEnabled ) {
                [touchBarIdentifiers addObject:item.itemGuid];
            }
        }
        
        [_touchBar setDefaultItemIdentifiers:touchBarIdentifiers];
        [_touchBar setCustomizationAllowedItemIdentifiers:touchBarIdentifiers];
    }
}

//-------------------------------------------------------------------------//
-(RSTextBarItem*)itemForGuid:(NSString*)guid {
    for( RSTextBarItem* item in self.textBarItems ) {
        if (NSOrderedSame == [item.itemGuid compare:guid]) {
            return item;
        }
    }
    
    return nil;
}

//-------------------------------------------------------------------------//
-(void)addOrRemoveMainMenuBar {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    BOOL requireMainMenuBar = YES;
    
    for( RSTextBarItem* item in self.textBarItems ) {
        if ( item.isEnabled ) {
            requireMainMenuBar = NO;
        }
    }
    
    if ( requireMainMenuBar ) {
        [self addMainMenuBar];
    } else {
        [self removeMainMenuBar];
    }
}

//-------------------------------------------------------------------------//
-(NSImage*)menuImageForName:(NSString*)imageName {
    return [self imageForName:imageName withSize:self.options.defaultMenuImageSize];
}

//-------------------------------------------------------------------------//
-(NSImage*)itemImageForName:(NSString*)imageName {
    return [self imageForName:imageName withSize:self.options.defaultImageSize];
}

//-------------------------------------------------------------------------//
-(NSImage*)imageForName:(NSString*)imageName withSize:(long)size {
    NSImage* image;
    
    //NSLog(@"ImageForName: %@ withSize: %ld", imageName, size);
    
    NSString* imageCacheName = [NSString stringWithFormat:@"%ld:%@", (long)size, imageName];
    image = [self cachedImageForName:imageCacheName];
    if ( nil == image ) {
        if ( [imageName hasPrefix:@":"] ) {
            // Avoid caching user provided files
            //imageCacheName = @"";
            
            NSString* imageFileName = [imageName substringFromIndex:1];
            image = [[[NSImage alloc] initWithContentsOfFile:imageFileName] copy];
            
            if ( 0 < size ) {
                image = [self resizeImageAspectRatio:image withSize:size];
            }
        } else {
            image = [[NSImage imageNamed:imageName] copy];
            if ( 0 < size ) {
                image = [self resizeImageAspectRatio:image withSize:size];
            }
        }
        
        if ( nil != image && 0 < [imageCacheName length] ) {
            [self cacheImage:image forName:imageCacheName];
        }
    }
    
    return image;
}

//-------------------------------------------------------------------------//
-(NSSize)aspectRatioForSize:(NSSize)size withMax:(long)maxSize {
    double ratio = fmin(maxSize / size.width, maxSize / size.height);
    
    return CGSizeMake(size.width * ratio, size.height * ratio);
}

//-------------------------------------------------------------------------//
-(NSImage*)resizeImageAspectRatio:(NSImage*)image withSize:(long)size {
    NSSize imageSize = [image size];
    
    return [image resizeTo:[self aspectRatioForSize:imageSize withMax:size]];
}

//-------------------------------------------------------------------------//
-(SEL)itemCopyToClipboardSelector {
    return @selector(itemCopyToClipboard:);
}

//-------------------------------------------------------------------------//
-(void)itemCopyToClipboard:(id)sender {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    NSMenuItem* menuItem = (NSMenuItem*)sender;
    RSTextBarItem* item = (RSTextBarItem*)menuItem.representedObject;
    
    NSAttributedString* attributedString = [item getAttributedTextForText:[item.textBarScript resultStringToFirstItem:item.scriptResult]];
    [self setPasteboardAttributedString:attributedString];
}

//-------------------------------------------------------------------------//
-(SEL)itemCopyToClipboardAttributedTextSelector {
    return @selector(itemCopyToClipboardAttributedText:);
}

//-------------------------------------------------------------------------//
-(void)itemCopyToClipboardAttributedText:(id)sender {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    NSMenuItem* menuItem = (NSMenuItem*)sender;
    NSAttributedString* attributedString = (NSAttributedString*)menuItem.representedObject;
    
    [self setPasteboardAttributedString:attributedString];
}

//-------------------------------------------------------------------------//
-(SEL)itemActionSelector {
    return @selector(itemAction:);
}

//-------------------------------------------------------------------------//
-(void)itemAction:(id)sender {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    NSMenuItem* menuItem = (NSMenuItem*)sender;
    RSTextBarItem* item = (RSTextBarItem*)menuItem.representedObject;
    NSAttributedString* attributedString = (NSAttributedString*)menuItem.attributedTitle;
    
    [self executeItemAction:item withText:attributedString andIndex:menuItem.tag];
}

//-------------------------------------------------------------------------//
-(void)executeItemAction:(RSTextBarItem*)item withText:(NSAttributedString*)attributedString andIndex:(NSInteger)index {
    
    NSString* actionScript = item.actionScript;
    if (nil != item.actionScriptOverride) {
        actionScript = item.actionScriptOverride;
    }
    
    if ( 0 < [item.actionScriptOverride length] || (item.isActionScript && 0 < [item.actionScript length]) ) {
        if (NSOrderedSame == [actionScript compare:@"Relay FM"] || NSOrderedSame == [actionScript compare:@"Relay.FM"]) {
            NSBundle *myBundle = [NSBundle mainBundle];
            NSString *scriptPath= [myBundle pathForResource:@"textbar-relayfm-action" ofType:@"sh"];
            actionScript = [NSString stringWithFormat:@"cd '%@' && './%@'", [scriptPath stringByDeletingLastPathComponent], [scriptPath lastPathComponent]];
        }
        
        NSMutableDictionary* environment = [NSMutableDictionary dictionary];
        [environment setObject:[NSString stringWithFormat:@"%lu", index] forKey:@"TEXTBAR_INDEX"];
        [environment setObject:[attributedString string] forKey:@"TEXTBAR_TEXT"];
        
        [self.textBarScriptQueue addOperationWithBlock:^{
            RSTextBarScript* textBarScript = [RSTextBarScript instanceWithScript:actionScript andOptions:self.options];
            item.textBarScript = textBarScript;
            [textBarScript executeWithEnvironment:environment andCompletionBlock:^(NSString *output) {
                [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                    [item refresh];
                }];
            }];
        }];
    } else {
        [self setPasteboardAttributedString:attributedString];
    }
}

//-------------------------------------------------------------------------//
-(SEL)itemRefreshSelector {
    return @selector(itemRefresh:);
}

//-------------------------------------------------------------------------//
-(void)itemRefresh:(id)sender {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    NSMenuItem* menuItem = (NSMenuItem*)sender;
    RSTextBarItem* item = (RSTextBarItem*)menuItem.representedObject;
    
    [item refresh];
}

//-------------------------------------------------------------------------//
-(SEL)refreshAllSelector {
    return @selector(refreshAll:);
}

//-------------------------------------------------------------------------//
-(void)refreshAll:(id)sender {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    [self refreshTextBarItems];
}

//-------------------------------------------------------------------------//
-(void)setPasteboardAttributedString:(NSAttributedString*)text {
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] writeObjects:@[text]];
}

//-------------------------------------------------------------------------//
-(BOOL)setPasteboardString:(NSString*)text {
    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:nil];
    return [[NSPasteboard generalPasteboard] setString:text forType:NSPasteboardTypeString];
}

//-------------------------------------------------------------------------//
-(void)menuWillOpen:(NSMenu *)menu {
    if ( 0 < menu.itemArray.count ) {
        NSMenuItem* menuItem = [menu itemAtIndex:menu.itemArray.count-1];
        if ( nil != menuItem ) {
            RSTextBarItem* item = (RSTextBarItem*)menuItem.representedObject;
            if ( nil != item ) {
                [item.context setObject:@"Open" forKey:@"MenuOpen"];
                [item updateMenuBar];
            }
        }
    }
}

//-------------------------------------------------------------------------//
-(void)menuDidClose:(NSMenu *)menu {
    if ( 0 < menu.itemArray.count ) {
        NSMenuItem* menuItem = [menu itemAtIndex:menu.itemArray.count-1];
        if ( nil != menuItem ) {
            RSTextBarItem* item = (RSTextBarItem*)menuItem.representedObject;
            if ( nil != item ) {
                [item.context removeObjectForKey:@"MenuOpen"];
                [item updateMenuBar];
            }
        }
    }
}

//-------------------------------------------------------------------------//
- (void)readPreferences {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    [self.options readPreferences:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
    [self updateANSIEscaper];
    
    // Feature requested by customer.
    if(self.options.hideTextBarMenuIcon) {
        NSMenuItem* item = [_statusMenu itemAtIndex:0];
        item.image = nil;
    }
    
    NSDictionary* textBarPreferences = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"textBarPreferences"]];
    [self loadTextBarItems:textBarPreferences];
}

//-------------------------------------------------------------------------//
- (void)loadTextBarItems:(NSDictionary*)textBarPreferences {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    [self removeTextBarItems:NO];
    
    if ( 2 == [[textBarPreferences objectForKey:@"Version"] unsignedIntegerValue] ) {
        NSArray* items = [textBarPreferences objectForKey:@"Items"];
        
        for( RSTextBarItem* item in items ) {
            [self addTextBarItemInternal:item];
        }
        
        [self updateTextBarItemController];
        [self addBarItems];
    }
}

//-------------------------------------------------------------------------//
- (NSDictionary*)preferencesAsDict {
    NSDictionary* textBarPreferences = @{@"Version" : [NSNumber numberWithUnsignedInt:2],
                                         @"Items" : self.textBarItems};
    
    return textBarPreferences;
}

//-------------------------------------------------------------------------//
- (void)writePreferences {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:[self preferencesAsDict]] forKey:@"textBarPreferences"];
    
    // Flush to disk - to try to avoid any corruption (if app crashes).
    [[NSUserDefaults standardUserDefaults] synchronize];
}

//-------------------------------------------------------------------------//
- (void)cleanPreferences {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"textBarPreferences"];
}

//-------------------------------------------------------------------------//
-(void)updateANSIEscaper {
    _defaultANSIEscaper.defaultStringColor = [NSColor labelColor];
    
    _itemANSIEscaper.defaultStringColor = [NSColor labelColor];
    _itemANSIEscaper.font = [RSAppDelegate fontWithName:self.options.defaultFontName size:self.options.defaultFontSize];
    
    // Highlighted color is always light - which, confusingly, is handled by macOS so we have to swap the colors :-/.
    _highlightedItemANSIEscaper.defaultStringColor = self.options.darkMode ? [NSColor labelColor] : [NSColor textBackgroundColor];
    _highlightedItemANSIEscaper.font = [RSAppDelegate fontWithName:self.options.defaultFontName size:self.options.defaultFontSize];
}

//-------------------------------------------------------------------------//
- (void)observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object change:(NSDictionary *) change context:(void *) context {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    //    NSLog(@"ArrangedObjects keyPath: %@, change: %@, object: %@", keyPath, change, object);
    
    if(object == self.textBarPreferencesItemHiddenImage && [keyPath isEqualToString:@"image"])
    {
        NSLog(@"Image Name: %@", keyPath);
    } else {
        [self removeObservers];
        
        if ([object isKindOfClass:[NSArrayController class]]) {
            NSArrayController* controller = object;
            if (1 == controller.selectedObjects.count) {
                id item = [controller.selectedObjects objectAtIndex:0];
                if ([item isKindOfClass:[RSTextBarItem class]]) {
                    RSTextBarItem* textBarItem = item;
                    if (0 < textBarItem.script.length) {
                        if (NSOrderedSame == [textBarItem.script compare:@"Relay FM"] || NSOrderedSame == [textBarItem.script compare:@"Relay.FM"]) {
                            if (0 == textBarItem.actionScript.length) {
                                textBarItem.imageNamed = @"relayfm-32";
                                textBarItem.refreshSeconds = [NSNumber numberWithUnsignedInt:360];
                                textBarItem.isNotify = YES;
                                textBarItem.actionType = @"Script";
                                textBarItem.actionScript = @"Relay FM";
                            }
                        } else if (NSOrderedSame == [textBarItem.script compare:@"Pictures"]) {
                            if (0 == textBarItem.actionScript.length) {
                                textBarItem.imageNamed = @"picture-32";
                                textBarItem.refreshSeconds = [NSNumber numberWithUnsignedInt:360];
                            }
                        }
                    }
                }
            }
        }
        
        __weak RSAppDelegate* weakSelf = self;
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
            BOOL fullRefresh = NO;
            
            [weakSelf writePreferences];
            if ( [weakSelf.textBarItems count] != [weakSelf.textBarItemsAlt count ]) {
                fullRefresh = YES;
            } else if([keyPath hasPrefix:@"arrangedObjects.isEnabled"]) {
                fullRefresh = YES;
            } else if([keyPath hasPrefix:@"arrangedObjects.script"]) {
                [weakSelf refreshTextBarItems];
            } else if([keyPath hasPrefix:@"arrangedObjects."]) {
                [weakSelf displayTextBarItems];
            } else if([keyPath hasPrefix:@"arrangedObjects"]) {
                fullRefresh = YES;
            }
            
            if ( fullRefresh ) {
                [weakSelf removeBarItems];
                [weakSelf addBarItems];
                [weakSelf textBarItemsAltCopy];
            }
            
            [weakSelf addObservers];
        }];
    }
}

//-------------------------------------------------------------------------//
-(void)textBarItemsAltCopy {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    [self.textBarItemsAlt removeAllObjects];
    for( RSTextBarItem* item in self.textBarItems ) {
        [self.textBarItemsAlt addObject:item];
    }
}

//-------------------------------------------------------------------------//
-(void)updateTextBarItemController {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    [self.textBarItemsController rearrangeObjects];
}

//-------------------------------------------------------------------------//
-(void)updateTextBarItemControllerAsync {
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
        // We need to disable/enable the observers otherwise there is often a crash on the mian thread.
        [self removeObservers];
        [self.textBarItemsController rearrangeObjects];
        [self addObservers];
    }];
}

//-------------------------------------------------------------------------//
- (IBAction)progressSheetButton:(id)sender {
    [self dismissProgressSheet];
}

//-------------------------------------------------------------------------//
- (IBAction)actionSelectFont:(id)sender {
    [[NSFontPanel sharedFontPanel] makeKeyAndOrderFront:self];
    NSFont *theFont = [NSFont fontWithName:self.options.defaultFontName size:self.options.defaultFontSize];
    [[NSFontPanel sharedFontPanel] setPanelFont:theFont isMultiple:NO];
    
    [[NSFontManager sharedFontManager] setDelegate:self];
}

//-------------------------------------------------------------------------//
- (IBAction)actionResetFont:(id)sender {
    
    [self.options resetDefaultFont];
}

//-------------------------------------------------------------------------//
- (IBAction)actionResetImageSize:(id)sender {
    [self.options resetDefaultImageSize];
}

//-------------------------------------------------------------------------//

- (IBAction)actionResetVerticalAdjustor:(id)sender {
    [self.options resetDefaultVerticalAdjustor];
}

//-------------------------------------------------------------------------//
-(IBAction)actionResetDefaultShell:(id)sender {
    [self.options resetDefaultShell];
}

//-------------------------------------------------------------------------//
-(IBAction)actionResetDefaultHome:(id)sender {
    [self.options resetDefaultHome];
}

//-------------------------------------------------------------------------//
-(IBAction)actionResetShellArguments:(id)sender {
    [self.options resetTaskArguments];
}

//-------------------------------------------------------------------------//
-(NSUInteger)validModesForFontPanel:(NSFontPanel *)fontPanel {
    return NSFontPanelFaceModeMask |  NSFontPanelSizeModeMask | NSFontPanelCollectionModeMask;
}

//-------------------------------------------------------------------------//
-(void)showProgressSheet {
    self.progressSheetText.stringValue = @"Please wait... Enabling";
    self.progressSheetButton.enabled = NO;
    self.progressSheetButton.stringValue = @"...";
    
    [NSApp beginSheet:self.progressSheet
       modalForWindow:self.window
        modalDelegate:self
       didEndSelector:@selector(progressSheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

//-------------------------------------------------------------------------//
- (void)dismissProgressSheet {
    [NSApp endSheet:self.progressSheet returnCode:NSModalResponseOK];
}

//-------------------------------------------------------------------------//
- (void)progressSheetDidEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo {
    if (returnCode == NSModalResponseOK) {
        // ...
    } else if (returnCode == NSModalResponseCancel) {
        // ...
    } else {
        // ...
    }
    
    [sheet close];
}

//-------------------------------------------------------------------------//
-(void)shareEmailToAddresses:(NSArray*)recipients withSubject:(NSString*)subject andItems:(NSArray*)items {
    NSSharingService *mailShare = [NSSharingService sharingServiceNamed:NSSharingServiceNameComposeEmail];
    mailShare.delegate = self;
    mailShare.subject = subject;
    mailShare.recipients = recipients;
    [mailShare performWithItems:items];
}

//-------------------------------------------------------------------------//
-(void)donate {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.paypal.me/richie5um"]];
}

//-------------------------------------------------------------------------//
- (IBAction)actionToolbarGeneral:(id)sender {
    [self.preferencesTab selectTabViewItemWithIdentifier:@"Advanced"];
}

//-------------------------------------------------------------------------//
- (IBAction)actionToolbarLive:(id)sender {
    [self.preferencesTab selectTabViewItemWithIdentifier:@"Live"];
}

//-------------------------------------------------------------------------//
- (IBAction)actionToolbarItems:(id)sender {
    [self.preferencesTab selectTabViewItemWithIdentifier:@"Items"];
}

//-------------------------------------------------------------------------//
- (IBAction)actionToolbarItems2:(id)sender {
    [self.preferencesTab selectTabViewItemWithIdentifier:@"Items2"];
}

//-------------------------------------------------------------------------//
- (IBAction)actionToolbarImportExport:(id)sender {
    [self.preferencesTab selectTabViewItemWithIdentifier:@"ImportExport"];
}

//-------------------------------------------------------------------------//
- (IBAction)actionToolbarNews:(id)sender {
    [self.preferencesTab selectTabViewItemWithIdentifier:@"News"];
}

//-------------------------------------------------------------------------//
- (IBAction)actionToolbarNetwork:(id)sender {
    [self.preferencesTab selectTabViewItemWithIdentifier:@"Network"];
}

//-------------------------------------------------------------------------//
- (IBAction)actionPreferences:(id)sender {
    NSMenu* menu = (NSMenu*)[[((NSMenuItem*)sender) parentItem] menu];
    if (nil != menu && 0 < menu.itemArray.count ) {
        NSMenuItem* menuItem = [menu itemAtIndex:menu.itemArray.count-1];
        if ( nil != menuItem ) {
            RSTextBarItem* item = (RSTextBarItem*)menuItem.representedObject;
            
            // Try to scroll to this item in the table.
            if (nil != item) {
                [self.textBarItemsController setSelectedObjects:@[item]];
                [self.textBarItems2Table scrollRowToVisible:self.textBarItemsController.selectionIndex];
            }
        }
    }
    
    [self.textBarPreferences makeKeyAndOrderFront:self];
    
    // Force the Window to the front.
    [NSApp activateIgnoringOtherApps:YES];
}

//-------------------------------------------------------------------------//
- (IBAction)actionCancelProxySettings:(id)sender {
    [self.options readProxyOptions];
}

//-------------------------------------------------------------------------//
- (IBAction)actionUpdateProxySettings:(id)sender {
    [self.options writeProxyOptions];
}

//-------------------------------------------------------------------------//
- (IBAction)actionAbout:(id)sender {
    [NSApp orderFrontStandardAboutPanel:self];
    
    // Force the Window to the front.
    [NSApp activateIgnoringOtherApps:YES];
}

//-------------------------------------------------------------------------//
- (IBAction)actionExit:(id)sender {
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
}

//-------------------------------------------------------------------------//
- (IBAction)actionDonate:(id)sender {
    [self donate];
}

//-------------------------------------------------------------------------//
- (IBAction)actionDonate2:(id)sender {
    [self donate];
}

//-------------------------------------------------------------------------//
- (IBAction)actionFeedback:(id)sender {
}

//-------------------------------------------------------------------------//
- (IBAction)actionResetPreferences:(id)sender {
    [self showConfirmationSheetWithTitle:@"Are you sure?" andMessage:@"Resetting to defaults will remove all of your TextBar scripts." completionHandler:^(NSModalResponse returnCode) {
        if (NSModalResponseOK == returnCode) {
            
            // RichS: No idea why we have to use a performSelector, but if we don't the we either get:
            // * If we don't dispatch an operation to the main queue we don't get a dismissal of the sheet
            // * If we do dispatch an operaiton to the main queue we get a crash
            [self performSelector:@selector(resetToDefaults) withObject:nil afterDelay:0.5];
            
            //            __weak RSAppDelegate* weakSelf = self;
            //            [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
            //                [weakSelf removeTextBarItems:NO];
            //                [weakSelf defaultPreferences];
            //            };
        }
    }];
}

//-------------------------------------------------------------------------//
-(void)resetToDefaults {
    [self removeTextBarItems:NO];
    [self defaultPreferences];
}

//-------------------------------------------------------------------------//
- (IBAction)actionRecipes:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.github.com/richie5um/TextBar-Recipes"]];
}

//-------------------------------------------------------------------------//
- (IBAction)actionBrowserForwards:(id)sender {
    [self.textBarItemWebView goForward];
}

//-------------------------------------------------------------------------//
- (IBAction)actionBrowserBackwards:(id)sender {
    [self.textBarItemWebView goBack];
}

//-------------------------------------------------------------------------//
- (IBAction)actionBrowserOpen:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:self.textBarItemWebView.mainFrameURL]];
}

//-------------------------------------------------------------------------//
- (IBAction)actionShowWebMenu:(id)sender {
    NSRect frame = [(NSButton *)sender frame];
    NSPoint menuOrigin = [[(NSButton *)sender superview] convertPoint:NSMakePoint(frame.origin.x, frame.origin.y+frame.size.height+40) toView:[(NSButton *)sender superview]];
    
    NSEvent *event =  [NSEvent mouseEventWithType:NSLeftMouseDown
                                         location:menuOrigin
                                    modifierFlags:NSLeftMouseDownMask // 0x100
                                        timestamp:0
                                     windowNumber:[[(NSButton *)sender window] windowNumber]
                                          context:[[(NSButton *)sender window] graphicsContext]
                                      eventNumber:0
                                       clickCount:1
                                         pressure:1];
    
    [NSMenu popUpContextMenu:self.statusMenu withEvent:event forView:[(NSButton *)sender superview]];
}

//-------------------------------------------------------------------------//
- (IBAction)actionWebMenuRefreshAll:(id)sender {
    [self refreshTextBarItems];
}

//-------------------------------------------------------------------------//
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
    // TableDragDrop: Copy the row numbers to the pasteboard.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:MyPrivateTableViewDataType] owner:self.textBarItemsController];
    [pboard setData:data forType:MyPrivateTableViewDataType];
    return YES;
}

//-------------------------------------------------------------------------//
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
    // TableDragDrop: Add code here to validate the drop
    return NSDragOperationEvery;
}

//-------------------------------------------------------------------------//
- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)to dropOperation:(NSTableViewDropOperation)operation{
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    // TableDragDrop: This is the code that handles drag-n-drop ordering - table currently doesn't need to accept drops from outside!
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:MyPrivateTableViewDataType];
    
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    NSUInteger from = [rowIndexes firstIndex];
    
    NSMutableDictionary *traveller = [[self.textBarItemsController arrangedObjects] objectAtIndex:from];
    NSUInteger length = [[self.textBarItemsController arrangedObjects] count];
    
    // Ensure the item has moved
    if ( from != to && from != ( to - 1 ) ) {
        [self removeObservers];
        int i = 0;
        for (; i <= length; i++){
            if(i == to){
                if(from > to){
                    [self.textBarItemsController insertObject:traveller atArrangedObjectIndex:to];
                    [self.textBarItemsController removeObjectAtArrangedObjectIndex:from+1];
                } else{
                    [self.textBarItemsController insertObject:traveller atArrangedObjectIndex:to];
                    [self.textBarItemsController removeObjectAtArrangedObjectIndex:from];
                }
            }
        }
        [self textBarItemsAltCopy];
        [self addObservers];
        
        [self writePreferences];
        
        // Re-loads the status bar items (in the new order!)
        [self removeBarItems];
        [self addBarItems];
    }
    
    return YES;
}

//-------------------------------------------------------------------------//
-(IBAction)actionImportTextBarItems:(id)sender {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    
    // This method displays the panel and returns immediately. The completion handler is called when the user selects an
    // item or cancels the panel.
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL* filePath = [[panel URLs] objectAtIndex:0];
            
            NSDictionary* textBarPreferences = [NSKeyedUnarchiver unarchiveObjectWithFile:[filePath path]];
            if (textBarPreferences) {
                [self loadTextBarItems:textBarPreferences];
            }
        }
    }];
}

//-------------------------------------------------------------------------//
- (IBAction)actionExportTextBarItems:(id)sender {
    // Set the default name for the file and show the panel.
    NSSavePanel* panel = [NSSavePanel savePanel];
    [panel setNameFieldStringValue:@"TextBarItems.tb-export"];
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL* filePath = [panel URL];
            
            // Write the contents in the new format.
            BOOL success = [NSKeyedArchiver archiveRootObject:[self preferencesAsDict] toFile:[filePath path]];
            NSLog(@"Exported: %@", success ? @"Yes" : @"No");
        }
    }];
}

//-------------------------------------------------------------------------//
- (IBAction)actionExportTextBarItem:(id)sender {
    RSTextBarItem* item = [self.textBarItemsController.selectedObjects firstObject];
    
    if (nil != item) {
        RSTextBarItem* exportItem = [item clone];
        [exportItem prepareForExport];
        
        // Try to make file exports explainable by changing the field name.
        self.textBarItemExport.scriptLabel.stringValue = exportItem.isFileScript ? @"Script File:" : @"Script:";
        self.textBarItemExport.actionScriptLabel.stringValue = exportItem.isFileActionScript ? @"Action File:" : @"Action Script:";
        
        // Hide the action script if they are empty or a clipboard action.
        //self.textBarItemExport.actionScriptLabel.enabled = !([NSString isEmpty:exportItem.actionScript] || exportItem.actionType == kActionClipboard);
        self.textBarItemExport.actionScriptField.editable = !([NSString isEmpty:exportItem.actionScript] || exportItem.actionType == kActionClipboard);
        
        // Set the date in the fields
        self.textBarItemExport.imageView.image = [self imageForName:exportItem.imageNamed withSize:52];
        self.textBarItemExport.nameField.stringValue = exportItem.name;
        self.textBarItemExport.scriptField.stringValue = exportItem.script;
        if (!([NSString isEmpty:exportItem.actionScript] || exportItem.actionType == kActionClipboard)) {
            self.textBarItemExport.actionScriptField.stringValue = exportItem.actionScript;
        } else {
            self.textBarItemExport.actionScriptField.stringValue = @"";
        }
        
        NSMutableString* message = [[NSMutableString alloc] init];
        if (exportItem.isFileScript) {
            [message appendString:@"Script was detected as a file - automatically exporting file contents.\n"];
        } else {
            [message appendString:@"If the script uses any dependent files they are not exported.\n"];
        }
        if (exportItem.isFileActionScript) {
            [message appendString:@"Action Script was detected as a file - automatically exporting file contents.\n"];
        } else if (![NSString isEmpty:exportItem.actionScript]) {
            [message appendString:@"If the action script uses any dependent files they are not exported.\n"];
        }
        self.textBarItemExport.messageLabel.stringValue = 0 < message.length ? message : @"";
        
        [self.window beginSheet:self.textBarItemExport  completionHandler:^(NSModalResponse returnCode) {
            if (NSModalResponseOK == returnCode) {
                // Set the default name for the file and show the panel.
                NSSavePanel* panel = [NSSavePanel savePanel];
                [panel setNameFieldStringValue:[NSString stringWithFormat:@"%@.textbar", item.name]];
                [panel beginWithCompletionHandler:^(NSInteger result){
                    if (result == NSFileHandlingPanelOKButton) {
                        NSURL* filePath = [panel URL];
                        BOOL success = [NSKeyedArchiver archiveRootObject:exportItem toFile:[filePath path]];
                        NSLog(@"Exported: %@", success ? @"Yes" : @"No");
                    }
                }];
            }
        }];
    }
}

//-------------------------------------------------------------------------//
-(void)showMessageSheetWithTitle:(NSString*)title andMessage:(NSString*)message {
    self.textBarMessage.titleTextField.stringValue = title;
    self.textBarMessage.messageTextField.stringValue = message;
    
    // Force show the Preferences UI - so we can anchor to it.
    [self actionPreferences:nil];
    
    [self.window beginSheet:self.textBarMessage  completionHandler:^(NSModalResponse returnCode) {
        if (NSModalResponseOK == returnCode) {
        }
    }];
}

//-------------------------------------------------------------------------//
-(void)showConfirmationSheetWithTitle:(NSString*)title andMessage:(NSString*)message completionHandler:(void (^)(NSModalResponse returnCode))completionHandler {
    self.textBarConfirmation.titleTextField.stringValue = title;
    self.textBarConfirmation.messageTextField.stringValue = message;
    
    // Force show the Preferences UI - so we can anchor to it.
    [self actionPreferences:nil];
    
    [self.window beginSheet:self.textBarConfirmation completionHandler:^(NSModalResponse returnCode) {
        completionHandler(returnCode);
    }];
}

//-------------------------------------------------------------------------//
- (IBAction)actionSelectScriptFile:(id)sender {
    RSTextBarItem* item = [self.textBarItemsController.selectedObjects firstObject];
    
    if (nil != item) {
        NSOpenPanel* panel = [NSOpenPanel openPanel];
        
        // This method displays the panel and returns immediately. The completion handler is called when the user selects an
        // item or cancels the panel.
        [panel beginWithCompletionHandler:^(NSInteger result){
            if (result == NSFileHandlingPanelOKButton) {
                NSURL* filePath = [[panel URLs] objectAtIndex:0];
                
                if (nil == [Helpers enableExecutePermissionsForPath:[filePath path]]) {
                    item.script = [Helpers pathToTextBarScriptPath:[filePath path]];
                    item.isFileScript = YES;
                }
            }
        }];
    }
}

//-------------------------------------------------------------------------//
- (IBAction)actionSelectActionScriptFile:(id)sender {
    RSTextBarItem* item = [self.textBarItemsController.selectedObjects firstObject];
    
    if (nil != item) {
        NSOpenPanel* panel = [NSOpenPanel openPanel];
        
        // This method displays the panel and returns immediately. The completion handler is called when the user selects an
        // item or cancels the panel.
        [panel beginWithCompletionHandler:^(NSInteger result){
            if (result == NSFileHandlingPanelOKButton) {
                NSURL* filePath = [[panel URLs] objectAtIndex:0];
                
                if (nil == [Helpers enableExecutePermissionsForPath:[filePath path]]) {
                    item.actionScript = [Helpers pathToTextBarScriptPath:[filePath path]];
                    item.isFileActionScript = YES;
                }
            }
        }];
    }
}

//-------------------------------------------------------------------------//
- (IBAction)actionAddTextBarItem:(id)sender {
    RSTextBarItem* item = [RSTextBarItem instance];
    [self addTextBarItemToUI:item];
}

//-------------------------------------------------------------------------//
- (IBAction)actionRemoveTextBarItem:(id)sender {
    
    NSInteger index = self.textBarItemsController.selectionIndex;
    
    if (0 <= index) {
        [self removeObservers];
        
        // Remove any associations.
        RSTextBarItem* item = [[self.textBarItemsController arrangedObjects] objectAtIndex:index];
        [item enable];
        [item removeStatusBar];
        item.shortcut = nil;
        
        [self.textBarItemsController removeObjectAtArrangedObjectIndex:index];
        [self textBarItemsAltCopy];
        [self.textBarItemsController rearrangeObjects];
        
        NSInteger newIndex = MAX(index-1, 0);
        [self.textBarItemsController setSelectionIndex:newIndex];
        
        [self addObservers];
        [self writePreferences];
        
        [self addOrRemoveMainMenuBar];
        
        // If this was an import, then remove from disk.
        if (item.isFileScript) {
            NSString* scriptPath = [Helpers pathFromTextBarScriptPath:item.script];
            if ([[scriptPath lowercaseString] hasPrefix:[self.options.scriptsPath lowercaseString]]) {
                NSString *pathToRemove = [scriptPath stringByDeletingLastPathComponent];
                NSError* error;
                [[NSFileManager defaultManager] removeItemAtPath:pathToRemove error:&error];
                if (nil != error) {
                    NSLog(@"Error Removing Item: %@", error);
                }
            }
        }
        
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
            context.allowsImplicitAnimation = YES;
            [self.textBarItems2Table scrollRowToVisible:newIndex];
        } completionHandler:NULL];
    }
}

//-------------------------------------------------------------------------//
-(void)addTextBarItemToUI:(RSTextBarItem*)item {
    
    [self removeObservers];
    
    NSInteger index = ((NSArray*)self.textBarItemsController.arrangedObjects).count;
    [self addTextBarItemInternal:item];
    [self.textBarItemsController rearrangeObjects];
    [self.textBarItemsController setSelectionIndex:index];
    
    [self addObservers];
    //[self textBarItemsAltCopy];
    [self writePreferences];
    
    [self addOrRemoveMainMenuBar];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
        context.allowsImplicitAnimation = YES;
        [self.textBarItems2Table scrollRowToVisible:index];
    } completionHandler:NULL];
    
    // RichS: Because addObject doesnt happen until the next run loop, I believe, we need to do the selection after a little delay.
    //    double delayInSeconds = 0.5f;
    //    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    //    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    //
    //        [self.textBarItems2Table scrollRowToVisible:index];
    //
    //        // Re-loads the status bar items (in the new order!)
    //        //[self removeStatusBarItems];
    //        //[self addStatusBarItems];
    //    });
}

//-------------------------------------------------------------------------//
- (IBAction)actionOpenScriptsFolder:(id)sender {
    NSURL *scriptsFolderURL = [NSURL fileURLWithPath:self.options.scriptsPath];
    [[NSWorkspace sharedWorkspace] openURL:scriptsFolderURL];
}

//-------------------------------------------------------------------------//
- (IBAction)actionOpenScriptFileFolder:(id)sender {
    RSTextBarItem* item = [self.textBarItemsController.selectedObjects firstObject];
    
    if (nil != item && item.isFileScript) {
        NSString* scriptPath = [[Helpers pathFromTextBarScriptPath:item.script] stringByDeletingLastPathComponent];
        if (![NSString isEmpty:scriptPath]) {
            NSURL *scriptFolderURL = [NSURL fileURLWithPath:scriptPath];
            [[NSWorkspace sharedWorkspace] openURL:scriptFolderURL];
        }
    }
}

//-------------------------------------------------------------------------//
- (IBAction)actionOpenActionScriptFileFolder:(id)sender {
    RSTextBarItem* item = [self.textBarItemsController.selectedObjects firstObject];
    
    if (nil != item && item.isFileActionScript) {
        NSString* actionScriptPath = [[Helpers pathFromTextBarScriptPath:item.actionScript] stringByDeletingLastPathComponent];
        if (![NSString isEmpty:actionScriptPath]) {
            NSURL *actionScriptFolderURL = [NSURL fileURLWithPath:actionScriptPath];
            [[NSWorkspace sharedWorkspace] openURL:actionScriptFolderURL];
        }
    }
}

////-------------------------------------------------------------------------//
//-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
//    return self.textBarItems.count;
//}
//
//-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//    NSString* cellIdentifier = tableColumn.identifier;
//    if ([cellIdentifier isEqualToString:@"ItemsCell"]) {
//        RSTextBarItem* item = [self.textBarItems objectAtIndex:row];
//        
//        RSTextBarItemTableCellView* cell = [tableView makeViewWithIdentifier:@"ItemsCell" owner:self];
//        cell.cellEnabledButton.state = item.isEnabled;
//        cell.cellTitleField.stringValue = item.script;
//        cell.cellDetailField.stringValue = item.description;
//        cell.cellImageView.image = [self imageForName:item.imageNamed withSize:64];
//        return cell;
//    }
//    return nil;
//}

@end
