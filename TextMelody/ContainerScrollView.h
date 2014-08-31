//
//  ContainerScrollView.h
//  SendMelody
//
//  Created by Bennett Lin on 8/29/14.
//  Copyright (c) 2014 Bennett Lin. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ContainerDelegate;

@interface ContainerScrollView : UIScrollView

@property (weak, nonatomic) id<ContainerDelegate> customDelegate;
@property (nonatomic) BOOL noteTouched;

@end

@protocol ContainerDelegate <NSObject>

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;

@end


