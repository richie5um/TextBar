//
//  NSAttributedString+Extended.h
//  TextBar
//
//  Created by RichS on 22/04/2015.
//  Copyright (c) 2015 RichS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (Extended)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL;
@end
