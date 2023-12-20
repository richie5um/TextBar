//
//  RSTextBarItemExport.h
//  TextBar
//
//  Created by RichS on 02/09/2017.
//  Copyright © 2017 RichS. All rights reserved.
//

#import "RSTextBarItem.h"

@interface RSTextBarItemExport : RSTextBarItem

//@property (nonatomic, strong) NSImage* image;

+(RSTextBarItemExport*)cloneFrom:(RSTextBarItem*)item;
-(RSTextBarItem*)cloneTo;

@end
