//
//  RSTextBarItemExportWindow.h
//  TextBar
//
//  Created by RichS on 28/09/2017.
//  Copyright © 2017 RichS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RSTextBarItemExportWindow : NSWindow

@property (weak) IBOutlet NSTextField *scriptLabel;
@property (weak) IBOutlet NSTextField *actionScriptLabel;
@property (weak) IBOutlet NSTextField *messageLabel;

@property (weak) IBOutlet NSTextField *nameField;
@property (weak) IBOutlet NSTextField *scriptField;
@property (weak) IBOutlet NSTextField *actionScriptField;
@property (weak) IBOutlet NSImageView *imageView;

- (IBAction)actionCancel:(id)sender;
- (IBAction)actionExport:(id)sender;

@end
