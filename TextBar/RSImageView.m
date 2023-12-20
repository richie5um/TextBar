//
//  RSImageView.m
//  TextBar
//
//  Created by RichS on 18/09/2017.
//  Copyright © 2017 RichS. All rights reserved.
//

#import "RSImageView.h"

@implementation RSImageView

//-------------------------------------------------------------------------//
- (void)drawRect:(NSRect)dirtyRect {
    // RichS: Disable drawing so the view is invisible to the user - but still functions in the UI (and is in the correct z-order)
    //[super drawRect:dirtyRect];
}

//-------------------------------------------------------------------------//
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    BOOL acceptsDrag = [super performDragOperation:sender];
    
    if (acceptsDrag) {
        NSPasteboard *pboard = [sender draggingPasteboard];
        NSString *plist = [pboard stringForType:NSFilenamesPboardType];
        
        if (plist) {
            
            //NSArray *files = [NSPropertyListSerialization dataWithPropertyList:plist format:nil options:NSPropertyListImmutable error:nil];
            
            NSArray *files = [NSPropertyListSerialization propertyListWithData:[plist dataUsingEncoding:NSUTF8StringEncoding]
                                                              options:NSPropertyListImmutable
                                                                        format:nil
                                                              error:nil];
            
            if ([files count] == 1) {
                NSDictionary *userInfo = @{@"File" : [files objectAtIndex: 0]};
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"RSImageDroppedNotification"
                                                                    object:nil
                                                                  userInfo:userInfo];
            }
        }
    }
    
    return acceptsDrag;
}

@end
