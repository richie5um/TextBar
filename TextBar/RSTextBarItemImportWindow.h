//
//  RSTextBarItemImportWindow.h
//  TextBar
//
//  Created by RichS on 27/09/2017.
//  Copyright © 2017 RichS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RSTextBarItemImportWindow : NSWindow

@property (weak) IBOutlet NSTextField *messageTitle;

- (IBAction)actionCancel:(id)sender;
- (IBAction)actionInstall:(id)sender;

@end
