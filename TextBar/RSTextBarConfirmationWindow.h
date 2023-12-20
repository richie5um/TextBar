//
//  RSTextBarConfirmationWindow.h
//  TextBar
//
//  Created by RichS on 21/12/2017.
//  Copyright © 2017 RichS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RSTextBarConfirmationWindow : NSWindow

@property (weak) IBOutlet NSTextField *titleTextField;
@property (weak) IBOutlet NSTextField *messageTextField;

-(IBAction)actionNO:(id)sender;
-(IBAction)actionYES:(id)sender;

@end
