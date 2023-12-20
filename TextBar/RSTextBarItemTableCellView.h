//
//  RSTextBarItemTableCellView.h
//  TextBar
//
//  Created by RichS on 29/08/2017.
//  Copyright © 2017 RichS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RSTextBarItemTableCellView : NSTableCellView

@property (strong) IBOutlet NSButton *cellEnabledButton;
@property (strong) IBOutlet NSImageView *cellImageView;
@property (strong) IBOutlet NSTextField *cellTitleField;
@property (strong) IBOutlet NSTextField *cellDetailField;

@end
