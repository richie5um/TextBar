//
//  RSTextBarItemExportWindow.m
//  TextBar
//
//  Created by RichS on 28/09/2017.
//  Copyright © 2017 RichS. All rights reserved.
//

#import "RSTextBarItemExportWindow.h"

@implementation RSTextBarItemExportWindow

//-------------------------------------------------------------------------//
- (IBAction)actionExport:(id)sender {
    [self.sheetParent endSheet:self returnCode:NSModalResponseOK];
}

//-------------------------------------------------------------------------//
- (IBAction)actionCancel:(id)sender {
    [self.sheetParent endSheet:self returnCode:NSModalResponseCancel];
}

@end
