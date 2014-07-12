//
//  MTENavigationControllerDelegate.m
//  mytee
//
//  Created by Vincent Tourraine on 06/03/14.
//  Copyright (c) 2014 Studio AMANgA. All rights reserved.
//

#import "MTENavigationControllerDelegate.h"

#import "MTEAnimator.h"
#import "MTETShirtsViewController.h"
#import "MTETShirtViewController.h"

@interface MTENavigationControllerDelegate () <UIGestureRecognizerDelegate>

@property (nonatomic, weak)   UINavigationController *navigationController;
@property (nonatomic, strong) MTEAnimator *animator;
@property (nonatomic, strong) UIPercentDrivenInteractiveTransition* interactionController;

@end

@implementation MTENavigationControllerDelegate

- (void)configureWithNavigationController:(UINavigationController *)navigationController
{
    self.navigationController = navigationController;

    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self.navigationController.view addGestureRecognizer:panRecognizer];
    panRecognizer.delegate = self;

    self.animator = [MTEAnimator new];
}


- (void)pan:(UIPanGestureRecognizer*)recognizer
{
    UIView *view = self.navigationController.view;

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint    location                = [recognizer locationInView:view];
        NSUInteger numberOfViewControllers = self.navigationController.viewControllers.count;
        if (location.x <  CGRectGetMidX(view.bounds) && numberOfViewControllers > 1) {
            // left half
            self.interactionController = [UIPercentDrivenInteractiveTransition new];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:view];
        CGFloat d           = fabs(translation.x / CGRectGetWidth(view.bounds));
        [self.interactionController updateInteractiveTransition:d];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if ([recognizer velocityInView:view].x > 0) {
            [self.interactionController finishInteractiveTransition];
        }
        else {
            [self.interactionController cancelInteractiveTransition];
        }
        self.interactionController = nil;
    }
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC
{
    if (operation == UINavigationControllerOperationPush) {
        if ([fromVC isKindOfClass:MTETShirtsViewController.class]
            && [toVC isKindOfClass:MTETShirtViewController.class]) {
            return self.animator;
        }
    }
    else if (operation == UINavigationControllerOperationPop) {
        if ([fromVC isKindOfClass:MTETShirtViewController.class]
            && [toVC isKindOfClass:MTETShirtsViewController.class]) {
            return self.animator;
        }
    }
    
    return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                         interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController
{
    return self.interactionController;
}

#pragma mark - Gesture regognizer

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.animator.isAnimating) {
        return NO;
    }
    else {
        return YES;
    }
}

@end
