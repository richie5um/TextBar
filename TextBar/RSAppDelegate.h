//
//  RSAppDelegate.h
//  TextBar
//
//  Created by RichS on 11/25/13.
//  Copyright (c) 2013 RichS. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

#import "AMR_ANSIEscapeHelper.h"

#import "RSStatusBarAction.h"
#import "RSTextBarOptions.h"
#import "RSTextBarItem.h"
#import "RSTextBarItemImportWindow.h"
#import "RSTextBarItemExportWindow.h"
#import "RSTextBarMessageWindow.h"
#import "RSTextBarConfirmationWindow.h"
#import <MASShortcut/Shortcut.h>

@interface RSAppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate, NSSharingServiceDelegate, WebUIDelegate, WebPolicyDelegate, NSTableViewDataSource, NSTableViewDelegate, NSTouchBarDelegate> {
    
    IBOutlet NSMenu *_statusExtendedMenu;
    IBOutlet NSMenuItem *_statusExtendedMenuItem;
    NSStatusItem *_statusItem;
    __weak NSMenu *_menuHistory;
    __weak NSMenuItem *_menuLogout;
    
    BOOL _initialisedTextBar;
    
    NSString* _defaultAdditionalImagesFolder;
    
    NSURL* _temporaryDirectory;
    
    NSCache* _imageCache;
}

@property (atomic, strong) IBOutlet NSMenu *statusMenu;
@property (assign) BOOL showMenuOnAll;

@property (atomic, strong) AMR_ANSIEscapeHelper* defaultANSIEscaper;
@property (atomic, strong) AMR_ANSIEscapeHelper* itemANSIEscaper;
@property (atomic, strong) AMR_ANSIEscapeHelper* highlightedItemANSIEscaper;

@property (atomic, strong) RSTextBarOptions* options;
@property (atomic, strong) NSDictionary* proxySettings;
@property (atomic, strong) NSOperationQueue* textBarScriptQueue;
@property (atomic, strong) NSMutableArray *textBarItems;
@property (atomic, strong) NSMutableArray *textBarItemsAlt;
@property (atomic, strong) NSArray *textBarImages;
@property (atomic, strong) NSArray *textBarActions;
@property (atomic, strong) IBOutlet NSButton *textBarRecipesLink;
@property (weak) IBOutlet NSArrayController *textBarItemsController;

@property (assign) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSWindow *progressSheet;
@property (strong) IBOutlet NSTableView *textBarItemsTable;
@property (strong) IBOutlet NSTableView *textBarItems2Table;
@property (unsafe_unretained) IBOutlet NSWindow *textBarPreferences;
@property (unsafe_unretained) IBOutlet NSWindow *textBarCrashReporter;
@property (weak) IBOutlet RSTextBarItemImportWindow *textBarItemImport;
@property (weak) IBOutlet RSTextBarItemExportWindow *textBarItemExport;
@property (weak) IBOutlet RSTextBarMessageWindow *textBarMessage;
@property (weak) IBOutlet RSTextBarConfirmationWindow *textBarConfirmation;

@property (strong) IBOutlet NSTabView *preferencesTab;
@property (strong) IBOutlet NSMenuItem *menuDeactivate;
@property (strong) IBOutlet NSButton *cloudEnabled;
@property (strong) IBOutlet NSTextField *progressSheetText;
@property (strong) IBOutlet NSProgressIndicator *progressSheetSpinner;
@property (strong) IBOutlet NSButton *progressSheetButton;
@property (strong) IBOutlet WebView *textBarItemWebView;
@property (strong) IBOutlet NSPopover *textBarItemPopover;
@property (strong) IBOutlet NSButton *textBarItemPopoverRefreshButton;
@property (strong) IBOutlet NSButton *textBarItemPopoverOpenButton;
@property (strong) IBOutlet NSTextField *textBarItemPopoverRefreshDate;
@property (weak) IBOutlet NSTextField *textBarPreferencesFont;
@property (weak) IBOutlet NSTextField *textBarItemPopoverTitle;
@property (weak) IBOutlet WebView *textBarPreferencesNews;
@property (weak) IBOutlet MASShortcutView *textBarItemShortcutView;
@property (weak) IBOutlet NSImageView *textBarPreferencesItemImage;
@property (weak) IBOutlet NSImageView *textBarPreferencesItemHiddenImage;
@property (weak) IBOutlet NSTextField *textBarPreferencesVersion;
@property (weak) IBOutlet NSButton *textBarItemPopoverBackButton;
@property (weak) IBOutlet NSButton *textBarItemPopoverForwardButton;

@property (atomic, strong) NSMutableSet *filesToOpen;

- (void)cacheImage:(NSImage*)image forName:(NSString*)imageName;
- (NSImage*)cachedImageForName:(NSString*)imageName;
- (NSImage*)itemImageForName:(NSString*)imageName;
- (NSImage*)menuImageForName:(NSString*)imageName;

-(IBAction)actionPreferences:(id)sender;
-(IBAction)actionAbout:(id)sender;
-(IBAction)actionExit:(id)sender;
-(IBAction)actionDonate:(id)sender;
-(IBAction)actionDonate2:(id)sender;
-(IBAction)actionFeedback:(id)sender;
-(IBAction)actionSendReport:(id)sender;
-(IBAction)actionIgnoreReport:(id)sender;
-(IBAction)actionCrash:(id)sender;
-(IBAction)actionCheckForUpdates:(id)sender;
-(IBAction)actionRegister:(id)sender;
-(IBAction)actionDeregister:(id)sender;
-(IBAction)actionResetPreferences:(id)sender;
-(IBAction)actionRecipes:(id)sender;
-(IBAction)actionBrowserForwards:(id)sender;
-(IBAction)actionBrowserBackwards:(id)sender;
-(IBAction)actionBrowserOpen:(id)sender;
-(IBAction)actionShowLiveWeb:(id)sender;
-(IBAction)actionShowWebMenu:(id)sender;
-(IBAction)actionWebMenuRefreshAll:(id)sender;
-(IBAction)actionWebMenuRefresh:(id)sender;
-(IBAction)progressSheetButton:(id)sender;
-(IBAction)actionSelectFont:(id)sender;
-(IBAction)actionResetFont:(id)sender;
-(IBAction)actionResetImageSize:(id)sender;
-(IBAction)actionResetVerticalAdjustor:(id)sender;
-(IBAction)actionImportTextBarItems:(id)sender;
-(IBAction)actionExportTextBarItems:(id)sender;
-(IBAction)actionExportTextBarItem:(id)sender;
-(IBAction)actionSelectScriptFile:(id)sender;
-(IBAction)actionSelectActionScriptFile:(id)sender;
-(IBAction)actionAddTextBarItem:(id)sender;
-(IBAction)actionRemoveTextBarItem:(id)sender;
-(IBAction)actionOpenScriptsFolder:(id)sender;
-(IBAction)actionOpenScriptFileFolder:(id)sender;
-(IBAction)actionOpenActionScriptFileFolder:(id)sender;
-(IBAction)actionResetDefaultShell:(id)sender;
-(IBAction)actionResetDefaultHome:(id)sender;
-(IBAction)actionResetShellArguments:(id)sender;

//-(void)statusBarAction:(id)sender withTag:(id)tag;

-(void)refreshOptionsAndTextBarItems;
-(void)refreshTextBarItems;
-(void)refreshTextBarItemForIndex:(NSUInteger)index;
-(void)executeItemAction:(RSTextBarItem*)item withText:(NSAttributedString*)attributedString andIndex:(NSInteger)index;

-(NSImage*)imageForName:(NSString*)imageName withSize:(long)size;

-(SEL)itemActionSelector;
-(SEL)itemCopyToClipboardSelector;
-(SEL)itemCopyToClipboardAttributedTextSelector;
-(SEL)itemRefreshSelector;
-(SEL)refreshAllSelector;

@end
