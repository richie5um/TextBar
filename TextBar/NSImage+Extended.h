//
//  NSImage+Extended.h
//  TextBar
//
//  Created by RichS on 13/04/2015.
//  Copyright (c) 2015 RichS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (EtchedImageDrawing)

+(NSImage*)imageFromFile:(NSString*)path;
    
-(void)drawEtchedInRect:(NSRect)rect;
-(NSImage*)resizeTo:(NSSize)newSize;
-(void)writeToFile:(NSString*)path;
-(NSString*)base64;

@end
