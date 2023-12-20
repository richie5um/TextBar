//
//  RSTextBarMessageWindow.h
//  TextBar
//
//  Created by RichS on 13/10/2017.
//  Copyright © 2017 RichS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RSTextBarMessageWindow : NSWindow

@property (weak) IBOutlet NSTextField *titleTextField;
@property (weak) IBOutlet NSTextField *messageTextField;

-(IBAction)actionDismiss:(id)sender;

@end
