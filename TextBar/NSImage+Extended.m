//
//  NSImage+Extended.m
//  TextBar
//
//  Created by RichS on 13/04/2015.
//  Copyright (c) 2015 RichS. All rights reserved.
//

#import "NSImage+Extended.h"

@implementation NSImage (Extended)

//-------------------------------------------------------------------------//
+(NSImage*)imageFromFile:(NSString*)path {
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:path
                                        options:NSDataReadingUncached
                                          error:&error];
    return [[NSImage alloc] initWithData:data];
}

//-------------------------------------------------------------------------//
-(void)drawEtchedInRect:(NSRect)rect {
    NSSize size = rect.size;
    CGFloat dropShadowOffsetY = size.width <= 64.0 ? -1.0 : -2.0;
    CGFloat innerShadowBlurRadius = size.width <= 32.0 ? 1.0 : 4.0;
    
    CGContextRef c = [[NSGraphicsContext currentContext] graphicsPort];
    
    //save the current graphics state
    CGContextSaveGState(c);
    
    //Create mask image:
    NSRect maskRect = rect;
    CGImageRef maskImage = [self CGImageForProposedRect:&maskRect context:[NSGraphicsContext currentContext] hints:nil];
    
    //Draw image and white drop shadow:
    CGContextSetShadowWithColor(c, CGSizeMake(0, dropShadowOffsetY), 0, CGColorGetConstantColor(kCGColorWhite));
    [self drawInRect:maskRect fromRect:NSMakeRect(0, 0, self.size.width, self.size.height) operation:NSCompositeSourceOver fraction:1.0];
    
    //Clip drawing to mask:
    CGContextClipToMask(c, NSRectToCGRect(maskRect), maskImage);
    
    //Draw gradient:
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.5 alpha:1.0]
                                                          endingColor:[NSColor colorWithDeviceWhite:0.25 alpha:1.0]];
    [gradient drawInRect:maskRect angle:90.0];
    CGContextSetShadowWithColor(c, CGSizeMake(0, -1), innerShadowBlurRadius, CGColorGetConstantColor(kCGColorBlack));
    
    //Draw inner shadow with inverted mask:
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef maskContext = CGBitmapContextCreate(NULL, CGImageGetWidth(maskImage), CGImageGetHeight(maskImage), 8, CGImageGetWidth(maskImage) * 4, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    CGContextSetBlendMode(maskContext, kCGBlendModeXOR);
    CGContextDrawImage(maskContext, maskRect, maskImage);
    CGContextSetRGBFillColor(maskContext, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(maskContext, maskRect);
    CGImageRef invertedMaskImage = CGBitmapContextCreateImage(maskContext);
    CGContextDrawImage(c, maskRect, invertedMaskImage);
    CGImageRelease(invertedMaskImage);
    CGContextRelease(maskContext);
    
    //restore the graphics state
    CGContextRestoreGState(c);
}

//-------------------------------------------------------------------------//
-(NSImage*)resizeTo:(NSSize)newSize {
    NSImage *sourceImage = self;
    
    if (![sourceImage isValid]){
        NSLog(@"Invalid Image");
    } else {
        NSImage *smallImage = [[NSImage alloc] initWithSize:newSize];
        [smallImage lockFocus];
        [sourceImage setSize:newSize];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [sourceImage drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, newSize.width, newSize.height) operation:NSCompositeCopy fraction:1.0];
        [smallImage unlockFocus];
        return smallImage;
    }
    
    return nil;
}

//-------------------------------------------------------------------------//
-(void)writeToFile:(NSString *)path {
    CGImageRef cgRef = [self CGImageForProposedRect:NULL
                                             context:nil
                                               hints:nil];
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
    [newRep setSize:[self size]];   // if you want the same resolution
    NSData *pngData = [newRep representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
    [pngData writeToFile:path atomically:YES];
}

//-------------------------------------------------------------------------//
-(NSString*)base64 {
    NSArray *keys = [NSArray arrayWithObject:@"NSImageCompressionFactor"];
    NSArray *objects = [NSArray arrayWithObject:@"1.0"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];

    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithData:[self TIFFRepresentation]];
    NSData *tiffData = [imageRep representationUsingType:NSPNGFileType properties:dictionary];

    NSString *base64 = [tiffData base64EncodedStringWithOptions:0];
    
    return base64;
}

@end
