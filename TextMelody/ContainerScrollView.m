//
//  ContainerScrollView.m
//  SendMelody
//
//  Created by Bennett Lin on 8/29/14.
//  Copyright (c) 2014 Bennett Lin. All rights reserved.
//

#import "ContainerScrollView.h"

@implementation ContainerScrollView

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//  [super touchesBegan:touches withEvent:event];
  [self.customDelegate touchesBegan:touches withEvent:event];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//  [super touchesMoved:touches withEvent:event];
  [self.customDelegate touchesMoved:touches withEvent:event];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
//  [super touchesCancelled:touches withEvent:event];
  [self.customDelegate touchesCancelled:touches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//  [super touchesEnded:touches withEvent:event];
  [self.customDelegate touchesEnded:touches withEvent:event];
}

@end
