//
//  MTEAnimator.m
//  mytee
//
//  Created by Vincent Tourraine on 06/03/14.
//  Copyright (c) 2014 Studio AMANgA. All rights reserved.
//

#import "MTEAnimator.h"
#import "MTETShirtsViewController.h"
#import "MTETShirtViewController.h"

@interface MTEAnimator ()

@property (nonatomic, assign, readwrite, getter = isAnimating) BOOL animating;

@end


@implementation MTEAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.5;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController* toViewController   = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    if ([fromViewController isKindOfClass:MTETShirtViewController.class]
        && [toViewController isKindOfClass:MTETShirtsViewController.class]) {
        // Pop
        MTETShirtViewController  *tshirtViewController  = (MTETShirtViewController *)fromViewController;
        MTETShirtsViewController *tshirtsViewController = (MTETShirtsViewController *)toViewController;

        CGPoint tshirtScrollViewOffset = tshirtViewController.mainScrollView.contentOffset;

        NSIndexPath                      *indexPath        = tshirtsViewController.selectedCellIndexPath;
        UICollectionViewLayoutAttributes *layoutAttributes = [tshirtsViewController.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath];
        UICollectionViewCell             *cell             = [tshirtsViewController collectionView:tshirtsViewController.collectionView
                                                                            cellForItemAtIndexPath:indexPath];
        UIImageView *destinationImageView = cell.contentView.subviews.lastObject;

        CGRect destinationFrame = CGRectMake(layoutAttributes.frame.origin.x + destinationImageView.frame.origin.x,
                                             layoutAttributes.frame.origin.y + tshirtScrollViewOffset.y + destinationImageView.frame.origin.y - tshirtsViewController.collectionView.contentOffset.y - tshirtsViewController.collectionView.contentInset.top,
                                             CGRectGetWidth(destinationImageView.frame),
                                             CGRectGetHeight(destinationImageView.frame));

        UIImageView *tshirtImageView = tshirtViewController.tshirtImageView;

        for (UIView *subview in tshirtViewController.mainScrollView.subviews) {
            if (subview != tshirtImageView) {
                subview.alpha = 0;
            }
        }

        [transitionContext.containerView insertSubview:toViewController.view
                                          belowSubview:fromViewController.view];

        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            tshirtImageView.frame = destinationFrame;
        } completion:^(BOOL finished) {

            for (UIView *subview in tshirtViewController.mainScrollView.subviews) {
                if (subview != tshirtImageView) {
                    subview.alpha = 1;
                }
            }

            [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        }];
    }
    else if ([fromViewController isKindOfClass:MTETShirtsViewController.class]
             && [toViewController isKindOfClass:MTETShirtViewController.class]) {
        // Push
        MTETShirtsViewController *tshirtsViewController = (MTETShirtsViewController *)fromViewController;
        MTETShirtViewController  *tshirtViewController  = (MTETShirtViewController *)toViewController;

        NSIndexPath                      *indexPath        = tshirtsViewController.selectedCellIndexPath;
        UICollectionViewLayoutAttributes *layoutAttributes = [tshirtsViewController.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath];
        UICollectionViewCell             *cell             = [tshirtsViewController collectionView:tshirtsViewController.collectionView
                                                                            cellForItemAtIndexPath:indexPath];

        UIImageView *originImageView      = cell.contentView.subviews.lastObject;
        UIImageView *destinationImageView = tshirtViewController.tshirtImageView;

        CGRect        originFrame      = originImageView.frame;
        UIScrollView *originScrollView = tshirtsViewController.collectionView;
        CGRect        originCellFrame  = layoutAttributes.frame;

        CGRect destinationFrame = CGRectMake(0,
                                             originScrollView.contentInset.top,
                                             CGRectGetWidth(destinationImageView.frame),
                                             CGRectGetHeight(destinationImageView.frame));

        [transitionContext.containerView insertSubview:toViewController.view
                                          belowSubview:fromViewController.view];

        originImageView.frame = CGRectMake(- originScrollView.contentOffset.x + originCellFrame.origin.x + originImageView.frame.origin.x,
                                           - originScrollView.contentOffset.y + originCellFrame.origin.y + originImageView.frame.origin.y,
                                           CGRectGetWidth(originImageView.frame),
                                           CGRectGetHeight(originImageView.frame));
        [transitionContext.containerView addSubview:originImageView];

        self.animating = YES;

        NSTimeInterval duration = [self transitionDuration:transitionContext];
        __weak typeof(self) weakSelf = self;

        [UIView animateWithDuration:duration animations:^{
            originImageView.frame = destinationFrame;
        } completion:^(BOOL finished) {
            typeof(self) strongSelf = weakSelf;

            originImageView.frame = originFrame;
            [cell.contentView addSubview:originImageView];
            [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
            strongSelf.animating = NO;
        }];
    }
    else {
        [transitionContext.containerView insertSubview:toViewController.view
                                          belowSubview:fromViewController.view];

        toViewController.view.transform = CGAffineTransformMakeTranslation(-80, 0);

        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            fromViewController.view.transform = CGAffineTransformMakeTranslation(CGRectGetWidth(fromViewController.view.frame), 0);
            toViewController.view.transform   = CGAffineTransformMakeTranslation(0, 0);
        } completion:^(BOOL finished) {
            toViewController.view.transform   = CGAffineTransformIdentity;
            fromViewController.view.transform = CGAffineTransformIdentity;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }
}

@end
