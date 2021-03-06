/*
 * This file is part of the JTRevealSidebar package.
 * (c) James Tang <mystcolor@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIViewController+JTRevealSidebarV2.h"
#import "UINavigationItem+JTRevealSidebarV2.h"
#import "JTRevealSidebarV2Delegate.h"
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

@interface UIViewController (JTRevealSidebarV2Private)

- (void)revealLeftSidebar:(BOOL)showLeftSidebar;
- (void)revealRightSidebar:(BOOL)showRightSidebar;

- (void)closeLeftSidebar;

@end

@implementation UIViewController (JTRevealSidebarV2)

static char *revealedStateKey;

- (void)setRevealedState:(JTRevealedState)revealedState {
    
    JTRevealedState currentState = self.revealedState;

    objc_setAssociatedObject(self, &revealedStateKey, [NSNumber numberWithInt:revealedState], OBJC_ASSOCIATION_RETAIN);

    switch (currentState) {
        case JTRevealedStateNo:
            if (revealedState == JTRevealedStateLeft) {
                [self revealLeftSidebar:YES];
            } else if (revealedState == JTRevealedStateRight) {
                [self revealRightSidebar:YES];
            } else {
                // Do Nothing
            }
            break;
        case JTRevealedStateLeft:
            if (revealedState == JTRevealedStateNo) {
                [self revealLeftSidebar:NO];
            } else if (revealedState == JTRevealedStateRight) {
                [self revealLeftSidebar:NO];
                [self revealRightSidebar:YES];
            } else {
                [self revealLeftSidebar:YES];
            }
            break;
        case JTRevealedStateRight:
            if (revealedState == JTRevealedStateNo) {
                [self revealRightSidebar:NO];
            } else if (revealedState == JTRevealedStateLeft) {
                [self revealRightSidebar:NO];
                [self revealLeftSidebar:YES];
            } else {
                [self revealRightSidebar:YES];
            }
        default:
            break;
    }
}

- (JTRevealedState)revealedState {
    return (JTRevealedState)[objc_getAssociatedObject(self, &revealedStateKey) intValue];
}

- (CGAffineTransform)baseTransform {
    CGAffineTransform baseTransform;
    
    return self.view.transform;
    switch (self.interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            baseTransform = CGAffineTransformIdentity;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            baseTransform = CGAffineTransformMakeRotation(-M_PI/2);
            break;
        case UIInterfaceOrientationLandscapeRight:
            baseTransform = CGAffineTransformMakeRotation(M_PI/2);
            break;
        default:
            baseTransform = CGAffineTransformMakeRotation(M_PI);
            break;
    }
    return baseTransform;
}

@end

#define SIDEBAR_VIEW_TAG 10000

@implementation UIViewController (JTRevealSidebarV2Private)

- (UIViewController *)selectedViewController {
    return self;
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    UIView *view = [self.view.superview viewWithTag:(int)context];
    [view removeFromSuperview];
}

- (void)showShadow
{
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
    self.view.layer.shadowOffset = CGSizeMake(-10, 1);
    self.view.layer.shadowOpacity = 0.5;
    self.view.layer.shadowRadius = 5.0;
}

- (void)closeLeftSidebar {
    id <JTRevealSidebarV2Delegate> delegate = [self selectedViewController].navigationItem.revealSidebarDelegate;
    
    if ( [delegate respondsToSelector:@selector(toggleLeftSidebar:)]) {
        [delegate toggleLeftSidebar:nil];
    }
    else
        [self revealLeftSidebar:NO];
}
- (void)revealLeftSidebar:(BOOL)showLeftSidebar {

    id <JTRevealSidebarV2Delegate> delegate = [self selectedViewController].navigationItem.revealSidebarDelegate;

    if ( ! [delegate respondsToSelector:@selector(viewForLeftSidebar)]) {
        return;
    }
    if ([delegate respondsToSelector:@selector(leftSideBarWillOpen:)]) {
        [delegate performSelector:@selector(leftSideBarWillOpen:) withObject:self];;
    }

    const int REVEAL_BUTTON_TAG  = 42355;
    
    UIView * view = delegate.view;
    
    UIButton * button = (UIButton *) [view viewWithTag:REVEAL_BUTTON_TAG]; 
    if (button == nil) {
        button = [[[UIButton alloc] initWithFrame:view.frame] autorelease];
        button.tag = REVEAL_BUTTON_TAG;
        [view addSubview:button];
        [button addTarget:self action:@selector(closeLeftSidebar) forControlEvents:UIControlEventTouchDown];
    }
    [view bringSubviewToFront:button];
    button.enabled = YES;
    
    UIView *revealedView = [delegate viewForLeftSidebar];
    revealedView.tag = SIDEBAR_VIEW_TAG;
    CGFloat width = CGRectGetWidth(revealedView.frame);

    if (showLeftSidebar) {
        [self.view.superview insertSubview:revealedView belowSubview:self.view];
        
        [UIView beginAnimations:@"" context:nil];
        [UIView setAnimationDuration:0.25];
        [UIView setAnimationCurve:UIViewAnimationOptionCurveEaseInOut];
//        [UIView setAnimationCurve:UIViewAnimationOptionCurveEaseOut];
//        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        
//        self.view.transform = CGAffineTransformTranslate([self baseTransform], width, 0);
        
        self.view.frame = CGRectOffset(self.view.frame, width, 0);
        [self showShadow];
        if ([delegate respondsToSelector:@selector(leftSideBarOpened:)]) {
            [delegate performSelector:@selector(leftSideBarOpened:) withObject:self];;
        }
    } else {
        button.enabled = NO;
        [UIView beginAnimations:@"hideSidebarView" context:(void *)SIDEBAR_VIEW_TAG];
//        self.view.transform = CGAffineTransformTranslate([self baseTransform], -width, 0);
        
        self.view.frame = (CGRect){CGPointZero, self.view.frame.size};


        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        [UIView setAnimationDelegate:self];
        if ([delegate respondsToSelector:@selector(leftSideBarClosed:)]) {
            [delegate performSelector:@selector(leftSideBarClosed:) withObject:self];;
        }
    } 
    
    NSLog(@"%@", NSStringFromCGAffineTransform(self.view.transform));


    [UIView commitAnimations];
}

- (void)revealRightSidebar:(BOOL)showRightSidebar {

    id <JTRevealSidebarV2Delegate> delegate = [self selectedViewController].navigationItem.revealSidebarDelegate;
    
    if ( ! [delegate respondsToSelector:@selector(viewForRightSidebar)]) {
        return;
    }

    UIView *revealedView = [delegate viewForRightSidebar];
    revealedView.tag = SIDEBAR_VIEW_TAG;
    CGFloat width = CGRectGetWidth(revealedView.frame);
    revealedView.frame = (CGRect){self.view.frame.size.width - width, revealedView.frame.origin.y, revealedView.frame.size};

    if (showRightSidebar) {
        [self.view.superview insertSubview:revealedView belowSubview:self.view];

        [UIView beginAnimations:@"" context:nil];
//        self.view.transform = CGAffineTransformTranslate([self baseTransform], -width, 0);
        
        self.view.frame = CGRectOffset(self.view.frame, -width, 0);
    } else {
        [UIView beginAnimations:@"hideSidebarView" context:(void *)SIDEBAR_VIEW_TAG];
//        self.view.transform = CGAffineTransformTranslate([self baseTransform], width, 0);
        self.view.frame = (CGRect){CGPointZero, self.view.frame.size};
        
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        [UIView setAnimationDelegate:self];
    }

    NSLog(@"%@", NSStringFromCGAffineTransform(self.view.transform));
    
    [UIView commitAnimations];
}

@end


@implementation UINavigationController (JTRevealSidebarV2)

- (UIViewController *)selectedViewController {
    return self.topViewController;
}

@end