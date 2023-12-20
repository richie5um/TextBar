//
//  RSTextBarItem.m
//  TextBar
//
//  Created by RichS on 11/26/13.
//  Copyright (c) 2013 RichS. All rights reserved.
//

#import "RSTextBarItem.h"
#import "Helpers/Helpers.h"
#import "RSAppDelegate.h"
#import "RSWebView.h"
#import "NSString+Extensions.h"
#import "NSFileManager+AppSupportFolder.h"
#import "NSImage+Extended.h"
#import <GCDWebServer/GCDWebServer.h>
#import <GCDWebServer/GCDWebServerDataRequest.h>
#import <GCDWebServer/GCDWebServerDataResponse.h>

NSString *const kActionClipboard = @"Clipboard";
NSString *const kActionScript = @"Script";

@implementation RSTextBarItem {
    RSAppDelegate* _appDelegate;
}

@synthesize shortcut = _shortcut;

//-------------------------------------------------------------------------//
+(RSTextBarItem*)instance {
    return [[RSTextBarItem alloc] init];
}

//-------------------------------------------------------------------------//
-(RSTextBarItem*)clone {
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
        _appDelegate = (RSAppDelegate*)[NSApp delegate];
        
        _isEnabled = NO;
        _name = @"Item";
        _isNotify = NO;
        _isImported = NO;
        _isFileScript = NO;
        _imageNamed = @"info-32";
        _text = @"Wait...";
        _script = @"echo 'Hello'";
        _refreshSeconds = [NSNumber numberWithUnsignedInteger:60];
        _actionType = kActionClipboard;
        _actionScript = @"";
        _itemGuid = [[[NSUUID UUID] UUIDString] lowercaseString];
        _isCloudEnabled = YES; //_appDelegate.options.isCloudEnabled;
        _shortcut = nil;
        
        _context = [NSMutableDictionary dictionary];
    }
    return self;
}

//-------------------------------------------------------------------------//
-(void)encodeWithCoder:(NSCoder*)encoder {
    [encoder encodeObject:[NSNumber numberWithUnsignedInt:1] forKey:@"version"];
    [encoder encodeObject:[NSNumber numberWithBool:self.isEnabled] forKey:@"isEnabled"];
    [encoder encodeObject:[NSNumber numberWithBool:self.isNotify] forKey:@"isNotify"];
    [encoder encodeObject:[NSNumber numberWithBool:self.isImported] forKey:@"isImported"];
    [encoder encodeObject:[NSNumber numberWithBool:self.isFileScript] forKey:@"isFileScript"];
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.imageNamed forKey:@"imageNamed"];
    [encoder encodeObject:self.script forKey:@"script"];
    [encoder encodeObject:self.refreshSeconds forKey:@"refreshSeconds"];
    [encoder encodeObject:self.actionType forKey:@"actionType"];
    [encoder encodeObject:self.actionScript forKey:@"actionScript"];
    [encoder encodeObject:self.itemGuid forKey:@"itemGuid"];
    [encoder encodeObject:self.cloudSubmitted forKey:@"cloudSubmitted"];
    [encoder encodeObject:self.shortcut forKey:@"shortcut"];
    [encoder encodeObject:[NSNumber numberWithBool:self.isCloudEnabled] forKey:@"IsCloudEnabled"];
    [encoder encodeObject:self.serializeContext forKey:@"serializeContext"];
}

//-------------------------------------------------------------------------//
-(id)initWithCoder:(NSCoder*)decoder {
    if(self = [self init]) {
        NSNumber* version = [decoder decodeObjectForKey:@"version"];
        if ( nil != version && 1 == [version unsignedIntegerValue]) {
            if (!_appDelegate.options.isDisableItemsOnStart) {
                self.isEnabled = [[decoder decodeObjectForKey:@"isEnabled"] boolValue];
            }
            self.isNotify = [[decoder decodeObjectForKey:@"isNotify"] boolValue];
            self.isImported = [[decoder decodeObjectForKey:@"isImported"] boolValue];
            self.isFileScript = [[decoder decodeObjectForKey:@"isFileScript"] boolValue];
            self.name = [decoder decodeObjectForKey:@"name"];
            self.imageNamed = [decoder decodeObjectForKey:@"imageNamed"];
            self.script = [decoder decodeObjectForKey:@"script"];
            self.refreshSeconds = [decoder decodeObjectForKey:@"refreshSeconds"];
            self.context = [NSMutableDictionary dictionary];
            self.actionType = [decoder decodeObjectForKey:@"actionType"];
            self.actionScript = [decoder decodeObjectForKey:@"actionScript"];
            self.isCloudEnabled = [[decoder decodeObjectForKey:@"IsCloudEnabled"] boolValue];
            self.cloudSubmitted = @""; //[decoder decodeObjectForKey:@"cloudSubmitted"];
            self.shortcut = [decoder decodeObjectForKey:@"shortcut"];
            self.serializeContext = [decoder decodeObjectForKey:@"serializeContext"];
            
            // Fixup to ensure spaces are escaped
            if (self.isFileScript && ![self.script hasPrefix:@"'"]) {
                self.script = [Helpers escapeUnescapedSpaces:self.script];
            }
            if (self.isFileActionScript && ![self.actionScript hasPrefix:@"'"]) {
                self.actionScript = [Helpers escapeUnescapedSpaces:self.actionScript];
            }
            
            NSString* itemGuid = [decoder decodeObjectForKey:@"itemGuid"];
            if ( 0 < itemGuid.length ) {
                self.itemGuid = itemGuid;
            }
            
            if ( 0 == [self.actionType length] ) {
                 self.actionType = kActionClipboard;
            }
                     
            // Defaults
            self.text = @"...";
            self.name = self.name ? self.name : @"Item";
        } else {
            NSLog( @"Decode Failed for RSTextBarItem [%@]", [decoder description] );
        }
    }
    return self;
}

//-------------------------------------------------------------------------//
// We use this to allow IB to enable/disable the actionscript text field (on the 'actionType' value)
+ (NSSet *)keyPathsForValuesAffectingIsActionScript {
    
    return [NSSet setWithObject:@"actionType"];
}

//-------------------------------------------------------------------------//
-(void)setShortcut:(MASShortcut*)shortcut {
    MASShortcutMonitor* shortcutMonitor = [MASShortcutMonitor sharedMonitor];
    
    if ([shortcutMonitor isShortcutRegistered:_shortcut]) {
        [shortcutMonitor unregisterShortcut:_shortcut];
    }
    
    _shortcut = shortcut;
    
    if (nil != _shortcut) {
        __weak RSTextBarItem* weakSelf = self;
        [shortcutMonitor registerShortcut:_shortcut withAction:^{
            [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                [weakSelf refresh];
            }];
        }];
    }
}

//-------------------------------------------------------------------------//
-(MASShortcut*)shortcut {
    return _shortcut;
}

//-------------------------------------------------------------------------//
-(NSAttributedString*)imageNamedAttributed {
    NSImage *image = [[NSImage imageNamed:self.imageNamed] copy];
    NSTextAttachmentCell *attachmentCell = [[NSTextAttachmentCell alloc] initImageCell:image];
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    [attachment setAttachmentCell: attachmentCell ];
    NSAttributedString *attributedString = [NSAttributedString  attributedStringWithAttachment:attachment];
    return attributedString;
}

//-------------------------------------------------------------------------//
-(BOOL)isActionScript {
    return [kActionScript isEqualToString:self.actionType];
}

//-------------------------------------------------------------------------//
-(NSString*)description {
    return [NSString stringWithFormat:@"<%@ [%p]: IsEnabled \"%@\", IsNotify \"%@\", IsCloudEnabled \"%@\", ImageNamed \"%@\", Script \"%@\", RefreshSeconds \"%@\", RefreshSecondsOverride \"%@\", Context %@, ActionType %@, ActionScript\"%@\">",
            NSStringFromClass([self class]),
            self,
            self.isEnabled ? @"YES" : @"NO",
            self.isNotify ? @"YES" : @"NO",
            self.isCloudEnabled ? @"YES" : @"NO",
            self.imageNamed,
            self.script,
            self.refreshSeconds,
            self.refreshSecondsOverride,
            self.context,
            self.actionType,
            self.actionScript];
}

//-------------------------------------------------------------------------//
-(NSString*)details {
    NSMutableArray* detailsArray = [NSMutableArray array];

    [detailsArray addObject:[NSString stringWithFormat:@"%@s", self.refreshSeconds]];
    
    if (self.isNotify) {
        [detailsArray addObject:@"Notify"];
    }

    if (self.isCloudEnabled) {
        [detailsArray addObject:@"Live"];
    }
    
    [detailsArray addObject:[NSString stringWithFormat:@"%@", self.actionType]];

    
    return [detailsArray componentsJoinedByString:@", "];
}

//-------------------------------------------------------------------------//
-(NSImage*)image {
    return [_appDelegate imageForName:self.imageNamed withSize:32];
}

//-------------------------------------------------------------------------//
-(void)enable {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    if ( self.isEnabled ) {
        NSStatusItem* statusItem = [self.context objectForKey:@"StatusItem"];
        if ( nil == statusItem ) {
            [self createStatusBar];
            [self updateMenuBar];
        } else {
            [self setStatusBarItem:statusItem forItem:self withImage:self.imageNamed];
        }
        
        if ([self.script hasPrefix:@":"]) {
            NSInteger port = [[self.script substringFromIndex:1] integerValue];
            [self createWebServerForPort:port];
            
        } else {
            NSTimer* timerItem = [self.context objectForKey:@"ScriptTimer"];
            if (nil == timerItem ||
                (nil != self.refreshSecondsOverride && timerItem.timeInterval != [self.refreshSecondsOverride unsignedIntValue]) ||
                (nil == self.refreshSecondsOverride && timerItem.timeInterval != [self.refreshSeconds unsignedIntValue])) {
                [timerItem invalidate];
                [self createScriptTimerAndFire:YES];
            }
        }
    } else {
        self.cloudSubmitted = @"";
        [self removeStatusBar];
        [self removeWebServer];
    }
}

//-------------------------------------------------------------------------//
-(void)createWebServerForPort:(NSInteger)port {
    if (nil == [self.context objectForKey:@"WebServer"]) {
    
        GCDWebServer* webServer = [[GCDWebServer alloc] init];
        [self.context setObject:webServer forKey:@"WebServer"];
        
        [webServer addDefaultHandlerForMethod:@"GET"
                                 requestClass:[GCDWebServerRequest class]
                                 processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                                     
                                     return [GCDWebServerDataResponse responseWithText:self.text];
                                 }];
        
        [webServer addDefaultHandlerForMethod:@"POST"
                          requestClass:[GCDWebServerDataRequest class]
                          processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                              
                              NSData* data = [(GCDWebServerDataRequest*)request data];
                              NSString* text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                              NSString* outputError = @"";
                              
                              RSTextBarScript* textBarScript = [RSTextBarScript instanceWithScript:@"" andOptions:_appDelegate.options];
                              self.textBarScript = textBarScript;
                              
                              [textBarScript initScriptContext];
                              NSDictionary* scriptContext = [textBarScript convertOutputToScriptContext:text withError:outputError];
                              [self processScriptContext:scriptContext forItem:self];
                              
                              return [GCDWebServerResponse responseWithStatusCode:200];
                          }];
        
        [webServer startWithPort:port bonjourName:nil];
        NSLog(@"Visit %@ in your web browser", webServer.serverURL);
    }
}

//-------------------------------------------------------------------------//
-(void)removeWebServer {
    GCDWebServer* webServer = [self.context objectForKey:@"WebServer"];
    if (nil != webServer) {
        [self.context removeObjectForKey:@"WebServer"];
        
        [webServer stop];
    }
}

//-------------------------------------------------------------------------//
-(void)refresh {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    if (![self.script hasPrefix:@":"]) {
        NSTimer* timer = [self.context objectForKey:@"ScriptTimer"];
        if (nil != timer && timer.isValid) {
            [timer fire];
        } else if (self.isEnabled) {
            [self createScriptTimerAndFire:YES];
        }
    }
}

//-------------------------------------------------------------------------//
-(void)createStatusBar {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    NSStatusItem* statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.context setObject:statusItem forKey:@"StatusItem"];
    [self.context removeObjectForKey:@"StatusItemImage"];
    [self.context removeObjectForKey:@"StatusItemImageView"];
    [self.context removeObjectForKey:@"StatusItemWebView"];
    
    [statusItem setHighlightMode:YES];
    
    // Duplicates the Main Menu so that we can support additional per-item actions.
    if ( _appDelegate.showMenuOnAll ) {
        NSMenuItem* menuItem;
        NSMenu* statusMenu = [[NSMenu alloc] init];
        statusMenu.delegate = self;
        
        if (!_appDelegate.options.hideTextBarMenuItems) {
            menuItem = [[NSMenuItem alloc] initWithTitle:@"Copy" action:[_appDelegate itemCopyToClipboardSelector] keyEquivalent:@""];
            menuItem.representedObject = self;
            [statusMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:@"Refresh" action:[_appDelegate itemRefreshSelector] keyEquivalent:@""];
            menuItem.representedObject = self;
            [statusMenu addItem:menuItem];
            
            menuItem = [NSMenuItem separatorItem];
            [statusMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:@"Refresh All" action:[_appDelegate refreshAllSelector] keyEquivalent:@""];
            menuItem.representedObject = self;
            [statusMenu addItem:menuItem];
            
            menuItem = [NSMenuItem separatorItem];
            [statusMenu addItem:menuItem];
        }
        
        for ( menuItem in [_appDelegate.statusMenu itemArray] ) {
            [statusMenu addItem:[menuItem copy]];
        }
        
        // RichS: A hidden menu that we use for a reference to the 'item'. There *must* be a better way than this. ?!
        menuItem = [NSMenuItem separatorItem];
        menuItem.hidden = YES;
        menuItem.representedObject = self;
        [statusMenu addItem:menuItem];
        
        [statusItem setMenu:statusMenu];
        
        [self.context setObject:statusMenu forKey:@"StatusMenu"];
    }
    
    if ( [Helpers isOSGreaterThanOrEqualTo:NSAppKitVersionNumber10_10] && 0 < _appDelegate.options.defaultMaxWidth ) {
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
            NSButton* button = [statusItem button];
            
            NSString* visualFormat = [NSString stringWithFormat:@"[button(<=%lu)]", (unsigned long)_appDelegate.options.defaultMaxWidth];
            NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(button);
            NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:visualFormat
                                                                           options:0
                                                                           metrics:nil
                                                                             views:viewsDictionary];
            [button addConstraints:constraints];
        }];
    }
    
    [self.context setObject:statusItem forKey:@"StatusItem"];
    
    [self setStatusBarItem:statusItem forItem:self withImage:self.imageNamed];
    [self setStatusBarItem:statusItem forItem:self withAttributedText:[self getAttributedTextFromTextBarItem:self]];
}

//-------------------------------------------------------------------------//
-(NSButton*)createTouchBarButton {
    NSButton *button = [NSButton buttonWithTitle:@"" target:self action:@selector(actionTouchBarItem:)];
    [self.context setObject:button forKey:@"TouchButton"];
    
    // For debugging
    //button.wantsLayer = YES;
    //button.layer.backgroundColor = [NSColor greenColor].CGColor;
    
    [self updateTouchBar];
    
    return button;
}

//-------------------------------------------------------------------------//
-(void)removeStatusBar {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    NSStatusItem* statusItem = [self.context objectForKey:@"StatusItem"];
    if ( nil != statusItem ) {
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
            [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
        }];
        [self.context removeObjectForKey:@"StatusItem"];
        [self.context removeObjectForKey:@"StatusItemImage"];
    }
    
    NSTimer* timerItem = [self.context objectForKey:@"ScriptTimer"];
    if ( nil != timerItem ) {
        [timerItem invalidate];
        [self.context removeObjectForKey:@"ScriptTimer"];
    }
    
    if (nil != self.refreshSecondsOverride) {
        self.refreshSecondsOverride = nil;
    }
    
    if (nil != self.actionScriptOverride) {
        self.actionScriptOverride = nil;
    }
}

//-------------------------------------------------------------------------//
-(void)menuWillOpen:(NSMenu *)menu {
    [_appDelegate menuWillOpen:menu];
}

//-------------------------------------------------------------------------//
-(void)menuDidClose:(NSMenu *)menu {
    [_appDelegate menuDidClose:menu];
}

//-------------------------------------------------------------------------//
-(void)createScriptTimerAndFire:(BOOL)fire {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    unsigned int interval = [self.refreshSeconds unsignedIntValue];
    if (nil != self.refreshSecondsOverride) {
        interval = [self.refreshSecondsOverride unsignedIntValue];
        self.refreshSecondsOverride = nil;
    }
    BOOL repeating = 0 == interval ? NO : YES;
    
    __weak RSTextBarItem* weakSelf = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
        NSTimer* scriptTimer;
        scriptTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                       target:weakSelf
                                                     selector:@selector(timerScriptExecuteAction:)
                                                     userInfo:weakSelf
                                                      repeats:repeating];
        
        [[NSRunLoop mainRunLoop] addTimer:scriptTimer forMode:NSDefaultRunLoopMode];
        
        // Double check that we don't have an existing timer
        NSTimer* oldTimer = [weakSelf.context objectForKey:@"ScriptTimer"];
        [oldTimer invalidate];
        
        // Set the new timer
        [weakSelf.context setObject:scriptTimer forKey:@"ScriptTimer"];
        
        // Move to the background
        if ( fire ) {
            [scriptTimer fire];
        }
    }];
}

//-------------------------------------------------------------------------//
-(void)timerScriptExecuteAction:(NSTimer*)timer {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    if ( timer.isValid ) {
        RSTextBarItem* item = timer.userInfo;
        
        // Ensure our item is enabled, and, the timer matches the saved time (a poor-mans check for invalid multiple timers)
        if ( item && item.isEnabled && timer == [item.context objectForKey:@"ScriptTimer"] ) {
            // Important for an anti-retain cycle.
            __weak RSTextBarItem* weakSelf = self;
            
            [_appDelegate.textBarScriptQueue addOperationWithBlock:^{
                NSString* script = item.script;
                if ( nil != script ) {
                    RSTextBarScript* textBarScript = [RSTextBarScript instanceWithScript:script andOptions:_appDelegate.options];
                    NSDictionary* scriptContext = [textBarScript execute];
                    item.textBarScript = textBarScript;
                    
                    [weakSelf processScriptContext:scriptContext forItem:item];
                    
                    if (nil != item.refreshSecondsOverride) {
                        [weakSelf refreshTimerScript];
                    }
                }
            }];
        }
    }
}

//-------------------------------------------------------------------------//
-(void)processScriptContext:(NSDictionary*)scriptContext forItem:(RSTextBarItem*)item {
    
    item.scriptResult = scriptContext[@"output"];
    item.scriptResultError = scriptContext[@"outputError"];
    item.refreshDate = scriptContext[@"refreshDate"];
    item.refreshSecondsOverride = scriptContext[@"refresh"];
    item.actionScriptOverride = scriptContext[@"actionScript"];
    item.barType = scriptContext[@"barType"];
    item.barWidth = scriptContext[@"barWidth"];
    item.viewType = scriptContext[@"viewType"];
    item.viewSize = scriptContext[@"viewSize"];
    item.imageNamedOverride = scriptContext[@"imageName"];
    item.scriptContext = scriptContext;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
        
        NSString* originalText = [[self getAttributedTextFromTextBarItem:item] string];
        //NSString* originalFullText = [weakSelf getTextBarItemString];
        
        [self processScriptResultForItem:item];
        [self updateMenuBar];
        [self updatePopover];
        
        NSString* newText = [[self getAttributedTextFromTextBarItem:item] string];
        NSString* newFullText = [self getTextBarItemString];
        
        if ( self.isNotify &&
            0 < [newText length] &&
            0 < [originalText length] &&
            NSOrderedSame != [originalText compare:newText] &&
            NSOrderedSame != [@"." compare:newText] &&
            NSOrderedSame != [@"Wait..." compare:originalText] ) {
            
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = @"TextBar";
            if ( NSOrderedSame != [self.imageNamed compare:@"_no_image-32"] ) {
                NSImage* image = [_appDelegate imageForName:self.imageNamed
                                                   withSize:_appDelegate.options.defaultNotificationImageSize];
                
                // RichS: Hack to show the image on the left (with the app icon by the title)
                //[notification set_identityImage:image];
                
                notification.contentImage = image;
            }
            
            notification.informativeText = newText;
            notification.soundName = NSUserNotificationDefaultSoundName;
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        }
    }];
}

//-------------------------------------------------------------------------//
-(void)refreshTimerScript {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    NSTimer* timerItem = [self.context objectForKey:@"ScriptTimer"];
    if (nil != timerItem && self.isEnabled) {
        [timerItem invalidate];
        [self createScriptTimerAndFire:NO];
    }
}

//-------------------------------------------------------------------------//
-(void)processScriptResultForItem:(RSTextBarItem*)item {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    item.text = [item.textBarScript resultStringToFirstItem:item.scriptResult];
}

//-------------------------------------------------------------------------//
-(void)updateMenuBar {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    NSStatusItem* statusItem = [self.context objectForKey:@"StatusItem"];
    
    if ([self.barType isEqualToString:@"WEB"] || [self.barType isEqualToString:@"CHART"]) {
        NSString* imageNamed = 0 < self.imageNamedOverride ? self.imageNamedOverride : self.imageNamed;
        NSImage* image = [self getStatusBarImageForItem:(RSTextBarItem*)self withImage:(NSString*)imageNamed];
        
        // Do we need to redisplay?!
        NSImageView* imageView = [self.context objectForKey:@"StatusItemImageView"];
        imageView.image = image;
        
        BOOL newWebView = NO;
        float width = self.barWidth ? [self.barWidth floatValue] : 80.0;
        float height = [[NSStatusBar systemStatusBar] thickness];
        float webWidth = 0.0;
        
        RSWebView* webView = [self.context objectForKey:@"StatusItemWebView"];
        if (!(imageView && image) || nil == webView) {
            newWebView = YES;
            
            // Remove existing statusbar item
            [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
            }];
            [self.context removeObjectForKey:@"StatusItem"];
            
            // Create a Web NSStatusItem.
            NSStatusItem* newStatusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:width];
            
            webWidth = width;
            float imageWidth = 0;
            if (image) {
                imageWidth = 22;
                webWidth -= imageWidth;
                
                imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, imageWidth, height)];
                imageView.image = image;
                [newStatusItem.button addSubview:imageView];
                
                [self.context setObject:imageView forKey:@"StatusItemImageView"];
            } else {
                [self.context removeObjectForKey:@"StatusItemImageView"];
            }
            
            webView = [[RSWebView alloc] initWithFrame:NSMakeRect(imageWidth, 0, webWidth, height)];
            webView.statusItem = newStatusItem;
            webView.textBarItem = self;
            webView.ignoreMouseInteraction = YES;
            webView.drawsBackground = NO;
            webView.mainFrame.frameView.allowsScrolling = NO;
            
            [newStatusItem.button addSubview:webView];
            
            [self.context setObject:webView forKey:@"StatusItemWebView"];
            
//            newStatusItem.button.wantsLayer = YES;
//            newStatusItem.button.layer.backgroundColor = [NSColor greenColor].CGColor;
            
            [newStatusItem setMenu:statusItem.menu];
            [newStatusItem setHighlightMode:YES];
            statusItem.menu = nil;
            
            [self.context setObject:newStatusItem forKey:@"StatusItem"];
            statusItem = newStatusItem;
        }
        
        if ([self.barType isEqualToString:@"WEB"]) {
            [webView.mainFrame loadHTMLString:self.text baseURL:nil];
        } else if ([self.barType isEqualToString:@"CHART"]) {
            NSString* setChartDataFunc = [NSString stringWithFormat:@"setChartData(%@, -15*60*24*30);", self.text];

            if (newWebView) {
               
                NSString *textBarChartFile = [[NSBundle mainBundle] pathForResource:@"textbar-chart" ofType:@"html"];
                NSError* error = nil;
                NSString* content = [NSString stringWithContentsOfFile:textBarChartFile
                                                              encoding:NSUTF8StringEncoding
                                                                 error:&error];
                
                // Perform initial load of data this way as otherwise there is a timing issue with loading the scripts.
                content = [content stringByReplacingOccurrencesOfString:@"{{ setChartDataFunc }}" withString:setChartDataFunc];
                content = [content stringByReplacingOccurrencesOfString:@"{{ canvasWidth }}" withString:[NSString stringWithFormat:@"%f", webWidth-4]];
                content = [content stringByReplacingOccurrencesOfString:@"{{ canvasHeight }}" withString:[NSString stringWithFormat:@"%f", height-6]];
                [webView.mainFrame loadHTMLString:content baseURL:nil];
            } else {
                [webView stringByEvaluatingJavaScriptFromString:setChartDataFunc];
            }
        }
    } else {
        RSWebView* webView = [self.context objectForKey:@"StatusItemWebView"];
        if (nil != webView) {
            // TODO: Revert back to normal
            if ( nil != statusItem ) {
                [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                    [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
                }];
                [self.context removeObjectForKey:@"StatusItem"];
                [self.context removeObjectForKey:@"StatusItemImage"];
                [self.context removeObjectForKey:@"StatusItemImageView"];
                [self.context removeObjectForKey:@"StatusItemWebView"];
            }
            
            [self createStatusBar];
        }
        
        NSString* imageNamed = 0 < self.imageNamedOverride ? self.imageNamedOverride : self.imageNamed;
        [self setStatusBarItem:statusItem forItem:self withImage:imageNamed];
        [self setStatusBarItem:statusItem forItem:self withAttributedText:[self getAttributedTextFromTextBarItem:self]];
    }
    
    if ([self.viewType isEqualToString:@"HTML"] || [self.viewType isEqualToString:@"URL"]) {
        [statusItem setTarget:self];
        [statusItem setAction:@selector(showPopover:)];
        [statusItem setMenu:nil];
    } else {
        NSMenu* menu = [self.context objectForKey:@"StatusMenu"];
        [statusItem setMenu:menu];
        
        if ( [self.context objectForKey:@"MenuOpen"] ) {
            [self setTextBarMultiAttributedItem:self];
        }
    }
    
    [self updateTouchBar];
}

//-------------------------------------------------------------------------//
-(void)updateTouchBar {
    NSButton* button = [self.context objectForKey:@"TouchButton"];
    if (nil != button) {
        RSWebView* webView = [self.context objectForKey:@"StatusItemWebView"];
        if (nil != webView) {
            bool bViewAdded = false;
            for(NSView* view in [button subviews]) {
                if (view == webView) {
                    bViewAdded = true;
                    break;
                }
            }
            
            if (!bViewAdded) {
                [button addSubview:webView];
            }
            
            button.attributedTitle = @"";
        } else {
            NSAttributedString* text = [self getAttributedTextFromTextBarItem:self];
            button.attributedTitle = text;
        }
        
        [button sizeToFit];
        
        NSStatusItem* statusItem = [self.context objectForKey:@"StatusItem"];
        CGFloat width = statusItem.button.frame.size.width * 1.2;
    
        //NSString* visualFormat = [NSString stringWithFormat:@"[button(<=%lu)]", (unsigned long)_appDelegate.options.defaultMaxWidth];
        NSString* visualFormat = [NSString stringWithFormat:@"[button(<=%lu)]", (unsigned long)width];
        NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(button);
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:visualFormat
                                                                       options:0
                                                                       metrics:nil
                                                                         views:viewsDictionary];
        //button.constraints = contraints;
        [button addConstraints:constraints];
    }
}

//-------------------------------------------------------------------------//
-(BOOL)isWebViewType {
    return ([self.viewType isEqualToString:@"URL"] || [self.viewType isEqualToString:@"HTML"]);
}

//-------------------------------------------------------------------------//
-(void)updatePopover {
    // Update the popover if we are the item being shown
    if (_appDelegate.textBarItemPopoverRefreshButton.target == self && [self isWebViewType]) {
        _appDelegate.textBarItemPopoverRefreshDate.stringValue = self.refreshDate;
        _appDelegate.textBarItemPopoverRefreshDate.toolTip = self.refreshDate;
        
        NSString* viewSizeString = self.viewSize;
        if (nil == viewSizeString || 0 == viewSizeString.length) {
            viewSizeString = @"600,400";
        }
        
        NSArray *viewSizeParts = [viewSizeString componentsSeparatedByString:@","];
        double viewSizeWidth = 0;
        double viewSizeHeight = 0;
        if (1 <= viewSizeParts.count ) {
            viewSizeWidth = [viewSizeParts.firstObject floatValue];
            viewSizeHeight = [viewSizeParts.firstObject floatValue];
            if (2 == viewSizeParts.count ) {
                viewSizeHeight = [viewSizeParts.lastObject floatValue];
            }
        }
        CGSize viewSize = CGSizeMake(viewSizeWidth > 0 ? viewSizeWidth : 600, viewSizeHeight > 0 ? viewSizeHeight : 400);

        [_appDelegate.textBarItemPopover setContentSize:viewSize];
    
        if ([self.viewType isEqualToString:@"HTML"]) {            
            NSString* textBarItemString = self.scriptResult;
            
            // Remove the first line, which is used for the Menubar text.
            NSMutableArray* lines = [[textBarItemString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy];
            if ( nil != lines && 0 < lines.count ) {
                [lines removeObjectAtIndex:0];
            }
            textBarItemString = [lines componentsJoinedByString:@"\n"];
            
            NSString* customUserAgent = [self.scriptContext objectForKey:@"userAgent"];
            if (customUserAgent) {
                [[[_appDelegate.textBarItemWebView mainFrame] webView] setCustomUserAgent:customUserAgent];
            } else {
                [[[_appDelegate.textBarItemWebView mainFrame] webView] setCustomUserAgent:@""];
            }
            [[_appDelegate.textBarItemWebView mainFrame] loadHTMLString:textBarItemString baseURL:nil];
            _appDelegate.textBarItemPopoverOpenButton.hidden = YES;
            _appDelegate.textBarItemPopoverBackButton.hidden = YES;
            _appDelegate.textBarItemPopoverForwardButton.hidden = YES;
        } else if ([self.viewType isEqualToString:@"URL"]) {
            NSString* textBarItemString = self.scriptResult;
            
            NSMutableArray* lines = [[textBarItemString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy];
            [lines removeObjectAtIndex:0];
            NSString* urlString = lines.lastObject;
            
            NSString* customUserAgent = [self.scriptContext objectForKey:@"userAgent"];
            if (customUserAgent) {
                [[[_appDelegate.textBarItemWebView mainFrame] webView] setCustomUserAgent:customUserAgent];
            } else {
                [[[_appDelegate.textBarItemWebView mainFrame] webView] setCustomUserAgent:@""];
            }
            [[_appDelegate.textBarItemWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
            _appDelegate.textBarItemPopoverOpenButton.hidden = NO;
            _appDelegate.textBarItemPopoverBackButton.hidden = NO;
            _appDelegate.textBarItemPopoverForwardButton.hidden = NO;
        }
    }
}

//-------------------------------------------------------------------------//
-(void)showMenu:(id)sender {
    NSStatusItem* statusItem = [self.context objectForKey:@"StatusItem"];
    [statusItem popUpStatusItemMenu:statusItem.menu];
}

//-------------------------------------------------------------------------//
-(void)showPopover:(id)sender {
    if (!_appDelegate.textBarItemPopover.isShown) {
        
        // Prevent page reload if this is the most recent item - to avoid clearing the page.
        BOOL isCurrentPopover = _appDelegate.textBarItemPopoverRefreshButton.target == self;
        
        _appDelegate.textBarItemPopoverRefreshButton.action = @selector(actionWebMenuRefresh:);
        _appDelegate.textBarItemPopoverRefreshButton.target = self;

        if (!isCurrentPopover) {
            // Blank the view asap - then load the correct content.
            [[_appDelegate.textBarItemWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
            [self updatePopover];
        }
        
        [_appDelegate.textBarItemPopover showRelativeToRect:[[[sender valueForKey:@"window"] contentView] frame]
                                                     ofView:[[sender valueForKey:@"window"] contentView]
                                              preferredEdge:NSMaxYEdge];
        
    } else {
        [_appDelegate.textBarItemPopover close];
    }
}

//-------------------------------------------------------------------------//
- (IBAction)actionWebMenuRefresh:(id)sender {
    [self refresh];
}

//-------------------------------------------------------------------------//
- (void)actionTouchBarItem:(NSButton*)button {
    NSLog(@"TouchBar Button Pressed");
    
    RSAppDelegate* appDelegate = (RSAppDelegate*)[NSApp delegate];
    
    NSAttributedString* attributedString = [self getAttributedTextFromTextBarItem:self];
    [appDelegate executeItemAction:self withText:attributedString andIndex:0];
}

//-------------------------------------------------------------------------//
-(NSString*)attributedStringToHTML:(NSAttributedString*)attributedString {
    NSDictionary *documentAttributes = @{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType};
    NSData *htmlData = [attributedString dataFromRange:NSMakeRange(0, attributedString.length) documentAttributes:documentAttributes error:NULL];
    NSString *htmlString = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
    
    return htmlString;
}

//-------------------------------------------------------------------------//
-(NSString*)getTextBarItemString {
    NSAttributedString* attributedString = [self getAttributedTextFromTextBarItem:self];
    NSMutableArray* attributedItems = [self getTextBarMultiAttributedItem: self];

    NSMutableString* itemBuilder = [[NSMutableString alloc] init];
    [itemBuilder appendString:[attributedString string]];
    
    if ( 1 < attributedItems.count) {
        for (int i = 0; i < attributedItems.count; ++i) {
            [itemBuilder appendString:@"\\n"];
            [itemBuilder appendString:[[attributedItems objectAtIndex:i] string]];
        }
    }
    return itemBuilder;
}

//-------------------------------------------------------------------------//
-(NSString*)getTextBarItemHTMLString {
    NSAttributedString* attributedString = [self getAttributedTextFromTextBarItem:self];
    NSMutableArray* attributedItems = [self getTextBarMultiAttributedItem: self];
    
    NSMutableString* itemBuilder = [[NSMutableString alloc] init];
    [itemBuilder appendString:[self attributedStringToHTML:attributedString]];
    
    if ( 1 < attributedItems.count) {
        for (int i = 0; i < attributedItems.count; ++i) {
            [itemBuilder appendString:@"\\n"];
            [itemBuilder appendString:[self attributedStringToHTML:[attributedItems objectAtIndex:i]]];
        }
    }
    return itemBuilder;
}

//-------------------------------------------------------------------------//
-(NSMutableArray*)getTextBarMultiAttributedItem:(RSTextBarItem*)item {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    NSArray *textItems = [item.textBarScript resultStringToItems:item.scriptResult];
    
    NSMutableArray* attributedTextItems = [NSMutableArray array];
    if ( 1 < textItems.count ) {
        for ( int i = 1; i < textItems.count; ++i ) {
            NSMutableAttributedString* attributedText = [self getAttributedTextForText:[textItems objectAtIndex:i]];
            if (nil != attributedText) {
                [attributedTextItems addObject:attributedText];
            }
        }
        
        // Remove empty strings
        [attributedTextItems enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if(0 == ((NSAttributedString*)obj).length) {
                [attributedTextItems removeObjectAtIndex:idx];
            }
        }];
    }
        
    return attributedTextItems;
}

//-------------------------------------------------------------------------//
-(void)setTextBarMultiAttributedItem:(RSTextBarItem*)item {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    NSStatusItem* statusItem = [item.context objectForKey:@"StatusItem"];
    NSMutableArray *textItems = [[item.textBarScript resultStringToItems:item.scriptResult] mutableCopy];
    
    if ( 0 < textItems.count) {
        [textItems addObject:@"----"];
    }
    
    if (!_appDelegate.options.hideTextBarMenuItems) {
        [textItems addObject:item.refreshDate];
    }
    
    if (_appDelegate.options.showErrorsInMenu && ![NSString isEmpty:item.scriptResultError]) {
        if ( 0 < textItems.count) {
            [textItems addObject:@"----"];
        }
        NSString* errorPrefix = @"\e[1;31mError:";
        NSString* errorMessage = [NSString stringWithFormat:@"%@ %@", errorPrefix, item.scriptResultError];
        [textItems addObject:errorMessage];
    }
    
    if ( 1 < textItems.count ) {
        NSMutableArray* attributedTextItems = [NSMutableArray array];
        for ( int i = 1; i < textItems.count; ++i ) {
            NSMutableAttributedString* attributedText = [self getAttributedTextForText:[textItems objectAtIndex:i]];
            if (nil != attributedText) {
                [attributedTextItems addObject:attributedText];
            }
        }
        
        // Remove empty strings
        [attributedTextItems enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if(0 == ((NSAttributedString*)obj).length) {
                [attributedTextItems removeObjectAtIndex:idx];
            }
        }];
        
        // Only show entries that have more than 1 line
        if ( 0 < attributedTextItems.count ) {
            [self setStatusBarItem:statusItem forItem:item withMultiAttributedText:attributedTextItems];
        } else {
            [self setStatusBarItem:statusItem forItem:item withMultiAttributedText:nil];
        }
    } else {
        [self setStatusBarItem:statusItem forItem:item withMultiAttributedText:nil];
    }
}

//-------------------------------------------------------------------------//
-(NSImage*)getStatusBarImageForItem:(RSTextBarItem*)item withImage:(NSString*)statusImage {
    NSImage* image;
    NSString* statusImageWithSize = [NSString stringWithFormat:@"%@:%lu", statusImage, _appDelegate.options.defaultImageSize];
    
    if ( nil != statusImage && 0 < [statusImage length] && NSOrderedSame != [statusImage compare:@"_no_image-32"] ) {
        RSAppDelegate* appDelegate = (RSAppDelegate*)[NSApp delegate];
        
        image = [appDelegate itemImageForName:statusImage];
        if ( ![statusImage hasPrefix:@":"] && [Helpers supportsDarkMode] ) {
            image.template = YES;
        }
    }
    
    return image;
}

//-------------------------------------------------------------------------//
-(void)setStatusBarItem:(NSStatusItem*)statusItem forItem:(RSTextBarItem*)item withImage:(NSString*)statusImage {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    NSImage* image;
    BOOL setImage = YES;
    
    NSString* statusImageWithSize = [NSString stringWithFormat:@"%@:%lu", statusImage, _appDelegate.options.defaultImageSize];
    
    if ( nil != statusImage && 0 < [statusImage length] && NSOrderedSame != [statusImage compare:@"_no_image-32"] ) {
        // Determine if we need to re-calculate the image
        NSString* origImage = [item.context objectForKey:@"StatusItemImage"];
        if ( nil != origImage && NSOrderedSame == [statusImageWithSize compare:origImage] ) {
            setImage = NO;
        } else {
            RSAppDelegate* appDelegate = (RSAppDelegate*)[NSApp delegate];
            
            image = [appDelegate itemImageForName:statusImage];
            if ( ![statusImage hasPrefix:@":"] && [Helpers supportsDarkMode] ) {
                image.template = YES;
            }
        }
    }
    
    // Store the image name so that we can re-use it if it doesn't change
    if ( nil != statusImage ) {
        [item.context setObject:statusImageWithSize forKey:@"StatusItemImage"];
    } else {
        [item.context removeObjectForKey:@"StatusItemImage"];
    }
    
    // Set the image on the main thread
    if ( setImage ) {
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
            RSWebView* webView = [self.context objectForKey:@"StatusItemWebView"];
            if (nil != webView) {
//                NSImageView* imageView = [item.context objectForKey:@"StatusItemImageView"];
//                imageView.image = image;
                [self updateMenuBar];
            } else {
                [statusItem setImage:image];
            }
            
            // Force redraw the text - otherwise the text sometimes gets truncated.
            [statusItem setAttributedTitle:statusItem.attributedTitle];
        }];
    }
}

//-------------------------------------------------------------------------//
-(void)setStatusBarItem:(NSStatusItem*)statusItem forItem:(RSTextBarItem*)item withAttributedText:(NSAttributedString*)attributedText {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    if ( nil != attributedText ) {
        [statusItem setAttributedTitle:attributedText];
    }
}

//-------------------------------------------------------------------------//
-(void)setStatusBarItem:(NSStatusItem*)statusItem forItem:(RSTextBarItem*)item withMultiAttributedText:(NSArray*)attributedTextItems {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    [self _setStatusBarItem:statusItem forItem:item withMultiAttributedText:attributedTextItems];
}

//-------------------------------------------------------------------------//
-(void)_setStatusBarItem:(NSStatusItem*)statusItem forItem:(RSTextBarItem*)item withMultiAttributedText:(NSArray*)attributedTextItems {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    NSMenu* menu = [statusItem menu];
    NSMenuItem* menuItem;
    
    unsigned long menuIndexSeparatorTag = 9999;
    unsigned long menuIndex = 0;
    
    RSAppDelegate* appDelegate = (RSAppDelegate*)[NSApp delegate];
    
    if ( nil == attributedTextItems || 0 == attributedTextItems.count ) {
        
        if ( 0 < menu.itemArray.count ) {
            
            menuItem = [menu itemAtIndex:0];
            while ( 0 < menu.itemArray.count && menuItem && 0 < menuItem.tag ) {
                [menu removeItem:menuItem];
                menuItem = [menu itemAtIndex:0];
            }
        }
    } else {
        
        menuItem = [menu itemWithTag:menuIndexSeparatorTag];
        if ( nil == menuItem ) {
            
            unsigned long menuIndexTag = 1;
            for ( menuIndex = 0; menuIndex < attributedTextItems.count; ++menuIndex ) {
                NSAttributedString* menuText = [attributedTextItems objectAtIndex:menuIndex];

                if ([[menuText string] isEqualToString:@"----"]) {
                    menuItem = [NSMenuItem separatorItem];
                } else {
                    menuItem = [[NSMenuItem alloc] init];
                    menuItem.action = [appDelegate itemActionSelector];
                    
                    menuItem.attributedTitle = menuText;
                    menuItem.representedObject = item;
                    menuItem.tag = menuIndexTag;
                    ++menuIndexTag;
                }
                
                [menu insertItem:menuItem atIndex:menuIndex];
            }
            
            menuItem = [NSMenuItem separatorItem];
            menuItem.tag = menuIndexSeparatorTag;
            [menu insertItem:menuItem atIndex:attributedTextItems.count];
        } else {
            menuIndex = 0;
            NSUInteger menuIndexTag = 1;
            
            while(true) {
                
                // Do we have remaning textbar items to show
                if ( menuIndex < attributedTextItems.count ) {
                    NSAttributedString* menuText = [attributedTextItems objectAtIndex:menuIndex];
                    
                    // Defensive check!
                    if ( menuIndex < menu.itemArray.count ) {
                        menuItem = [menu itemAtIndex:menuIndex];
                        
                        // Have we reached the end of the available menu items?
                        if ( menuIndexSeparatorTag == menuItem.tag ) {
                            // Everything now is new additions
                            NSMenuItem* menuItem;
                            if ([[menuText string] isEqualToString:@"----"]) {
                                menuItem = [NSMenuItem separatorItem];
                            } else {
                                menuItem = [self createMenuItemWithText:menuText andItem:item andTag:menuIndexTag];
                                menuIndexTag++;
                            }
                            [menu insertItem:menuItem atIndex:menuIndex];
                            menuIndex++;
                        } else {
                            // We need to modify existing menu items
                            if ([[menuText string] isEqualToString:@"----"] && menuItem.separatorItem) {
                                // Do nothing
                            } else if ([[menuText string] isEqualToString:@"----"] && !menuItem.separatorItem) {
                                // Change from a text item to a separator
                                [menu removeItemAtIndex:menuIndex];
                                [menu insertItem:[NSMenuItem separatorItem] atIndex:menuIndex];
                            } else if (![[menuText string] isEqualToString:@"----"] && menuItem.separatorItem) {
                                // Change from a separator to a text item
                                [menu removeItemAtIndex:menuIndex];
                                menuItem = [self createMenuItemWithText:menuText andItem:item andTag:menuIndexTag];
                                [menu insertItem:menuItem atIndex:menuIndex];
                                menuIndexTag++;
                            } else {
                                // Update a text item
//                                [menu removeItemAtIndex:menuIndex];
//                                menuItem = [self createMenuItemWithText:menuText andItem:item andTag:menuIndexTag];
//                                menu insertItem:[NSMenuItem separatorItem] atIndex:menuIndex];
                                
                                menuItem.attributedTitle = menuText;
                                menuItem.representedObject = item;
                                menuItem.tag = menuIndexTag;
                                ++menuIndexTag;
                            }
                            menuIndex++;
                        }
                    } else {
                        // We should never get here!
                        break;
                    }
                    
                } else {
                    // If we have no more textbar items, then remove the remaining menu items
                    menuItem = [menu itemAtIndex:menuIndex];
                    if ( menuIndexSeparatorTag != menuItem.tag && menuIndex < menu.itemArray.count ) {
                        [menu removeItemAtIndex:menuIndex];
                    } else {
                        break;
                    }
                }

            }
        }
    }
}

//-------------------------------------------------------------------------//
-(void)setTouchBarItem:(NSTouchBarItem*)touchBarItem forItem:(RSTextBarItem*)item {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
}

//-------------------------------------------------------------------------//
-(NSMenuItem*)createMenuItemWithText:(NSAttributedString*)title andItem:(RSTextBarItem*)item andTag:(NSUInteger)tag {
    RSAppDelegate* appDelegate = (RSAppDelegate*)[NSApp delegate];
    
    NSMenuItem* menuItem = [[NSMenuItem alloc] init];
    menuItem.action = [appDelegate itemActionSelector];
    menuItem.attributedTitle = title;
    menuItem.representedObject = item;
    menuItem.tag = tag;
    
    return menuItem;
}

//-------------------------------------------------------------------------//
-(NSMutableAttributedString*)getAttributedTextFromTextBarItem:(RSTextBarItem*)item {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    NSMutableAttributedString* attributedText;
    
    if ( [RSTextBarScript isHTMLString:item.text] ) {
        NSDictionary* attributes = nil;
        attributedText = [[NSMutableAttributedString alloc] initWithHTML:[item.text dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:&attributes];
    } else {
        RSAppDelegate* appDelegate = (RSAppDelegate*)[NSApp delegate];
        
        AMR_ANSIEscapeHelper* ansiEscaper = appDelegate.itemANSIEscaper;
        if ( [item.context objectForKey:@"MenuOpen"] ) {
            ansiEscaper = appDelegate.highlightedItemANSIEscaper;
        }
        
        attributedText = [[ansiEscaper attributedStringWithANSIEscapedString:item.text] mutableCopy];
        
        NSMutableParagraphStyle* paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        
        // Layout offset for vertical text position
        [attributedText addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [attributedText length])];
        
        if ( YES == appDelegate.options.defaultVerticalAdjustor ) {
            if ( nil == item.imageNamed || 0 == [item.imageNamed length] || NSOrderedSame == [item.imageNamed compare:@"_no_image-32"] ) {
                [attributedText addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:appDelegate.options.defaultVerticalAdjustorWithoutImage] range:NSMakeRange (0, [attributedText length])];
            } else {
                [attributedText addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:appDelegate.options.defaultVerticalAdjustorWithImage] range:NSMakeRange (0, [attributedText length])];
            }
        }
    }
    
    // Defensive coding (Claudia's Crash - 2017.08.21)
    if (nil == attributedText) {
        attributedText = [[NSMutableAttributedString alloc] initWithString:item.text];
    }
    
    // Super defensive coding (Claudia's Crash - 2017.08.21)
    if (nil == attributedText) {
        attributedText = [[NSMutableAttributedString alloc] initWithString:@"..."];
    }
    
    return attributedText;
}

//-------------------------------------------------------------------------//
-(NSMutableAttributedString*)getAttributedTextForText:(NSString*)text {
    if ( ![NSThread isMainThread] ) {
        NSLog(@"Not on MainThead: %s", __FUNCTION__);
    }
    
    NSMutableAttributedString* attributedText;
    
    if ( [RSTextBarScript isHTMLString:text] ) {
        NSDictionary* attributes = nil;
        attributedText = [[NSMutableAttributedString alloc] initWithHTML:[text dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:&attributes];
    } else {
        attributedText = [[_appDelegate.defaultANSIEscaper attributedStringWithANSIEscapedString:text] mutableCopy];
        
        NSMutableParagraphStyle* paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        [attributedText addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [attributedText length])];
    }
    
    // Defensive coding (Claudia's Crash - 2017.08.21)
    if (nil == attributedText) {
        attributedText = [[NSMutableAttributedString alloc] initWithString:text];
    }
    
    return attributedText;
}

//-------------------------------------------------------------------------//
-(void)prepareForExport {
    self.itemGuid = @"";
    self.refreshDate = @"";
    self.cloudSubmitted = @"";
    
    self.context = nil;
    self.serializeContext = [NSMutableDictionary dictionary];
    
    // If this is a custom image, then capture it
    RSAppDelegate* appDelegate = (RSAppDelegate*)[NSApp delegate];
    if ([self.imageNamed hasPrefix:@":"]) {
        NSImage* image = [appDelegate imageForName:self.imageNamed withSize:256];
        [self.serializeContext setObject:image forKey:@"serializedImage"];
    }
    
    // Attempt to read this string as though it is a file.
    NSError *error = nil;
    NSString* scriptPath = [Helpers pathFromTextBarScriptPath:self.script];
    if (![NSString isEmpty:scriptPath] && [scriptPath hasPrefix:@"/"]) {
        NSData *data = [NSData dataWithContentsOfFile:scriptPath
                                              options:NSDataReadingUncached
                                                error:&error];
        if (nil == error) {
            self.script = scriptPath;
            [self.serializeContext setObject:data forKey:@"serializedScript"];
            self.isFileScript = YES;
        }
    }
    
    // Attempt to read this string as though it is a file.
    NSString* actionScriptPath = [Helpers pathFromTextBarScriptPath:self.actionScript];
    if (![NSString isEmpty:actionScriptPath] && [actionScriptPath hasPrefix:@"/"]) {
        if ([actionScriptPath isEqualToString:scriptPath]) {
            // Encode empty data so that we can detect it needs to point to the script file.
            self.actionScript = scriptPath;
            [self.serializeContext setObject:[NSData data] forKey:@"serializedActionScript"];
            self.isFileActionScript = YES;
        } else {
            NSData *data = [NSData dataWithContentsOfFile:actionScriptPath
                                                  options:NSDataReadingUncached
                                                    error:&error];
            if (nil == error) {
                self.actionScript = actionScriptPath;
                [self.serializeContext setObject:data forKey:@"serializedActionScript"];
                self.isFileActionScript = YES;
            }
        }
    }
}

//-------------------------------------------------------------------------//
-(BOOL)processFromImport {
    self.isEnabled = NO;
    self.cloudSubmitted = @"";
    self.isImported = YES;
    
    // Create a new Guid on import
    self.itemGuid = [[[NSUUID UUID] UUIDString] lowercaseString];
    
    NSImage* serializedImage = [self.serializeContext objectForKey:@"serializedImage"];
    NSData* serializedScript = [self.serializeContext objectForKey:@"serializedScript"];
    NSData* serializedActionScript = [self.serializeContext objectForKey:@"serializedActionScript"];
    
    if (nil != serializedImage || nil != serializedScript || nil != serializedActionScript) {
        RSAppDelegate* appDelegate = (RSAppDelegate*)[NSApp delegate];
        NSString* scriptsPath = appDelegate.options.scriptsPath;
        if (nil == scriptsPath) {
            return false;
        }
        
        NSError* error;
        NSString* itemScriptPath = [scriptsPath stringByAppendingPathComponent:self.itemGuid];
        [[NSFileManager defaultManager] createDirectoryAtPath:itemScriptPath withIntermediateDirectories:true attributes:nil error:&error];
        if (nil != error) {
            NSLog(@"CreateItemScriptPath %@ Error: %@", itemScriptPath, error);
            return false;
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
                return false;
            }
            
            self.isFileScript = YES;
            self.script = [Helpers pathToTextBarScriptPath:scriptFilePath];
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
                    return false;
                }
                
                self.isFileActionScript = YES;
                self.actionScript = [Helpers pathToTextBarScriptPath:actionScriptFilePath];
            }
        }
    }
    
    // Wipe serializeContext so that it doens't hang around.
    self.serializeContext = nil;
    
    return true;
}

@end
