//
//  NSAttributedString+Extended.m
//  TextBar
//
//  Created by RichS on 22/04/2015.
//  Copyright (c) 2015 RichS. All rights reserved.
//

#import "NSAttributedString+Extended.h"

@implementation NSAttributedString (Extended)

//-------------------------------------------------------------------------//
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL
{
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: inString];
    NSRange range = NSMakeRange(0, [attrString length]);
    
    [attrString beginEditing];
    [attrString addAttribute:NSLinkAttributeName value:[aURL absoluteString] range:range];
    
    // Make the text appear in blue
    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
    
    // Next make the text appear with an underline
    [attrString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:range];
    [attrString endEditing];
    
    return attrString;
}
@end
