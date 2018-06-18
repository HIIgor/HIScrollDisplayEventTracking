//
//  UIScrollView+HIScrollDisplayEventTracking.h
//  HIScrollDisplayEventTracking
//
//  Created by HiIgor on 2018/6/17.
//  Copyright (c) 2018 HiIgor. All rights reserved
//

#import <UIKit/UIKit.h>

@protocol HIUIScrollViewDisplayTrackProtocol <NSObject>

/**
 the descendant views that needs to track event;
 after view has been added to scrollView view tree node, when setting the property HI_scrollDisplayEventId of UIView instance, the view will be added to HI_trackScrollDisplayEventSubviews automatically,
 */
@property (nonatomic, strong) NSArray *HI_trackScrollDisplayEventSubviews;

/**
 if YES, when the scorllView stops, scorllView will track the scrollDisplayEvent automatically. default is NO.
 */
@property (nonatomic, assign) BOOL HI_shouldTrackScrollEvent;


/**
 block for calling user's method to track event.
 */
@property (nonatomic, copy) BOOL (^HI_scrollDisplayEventTrackingBlock)(UIView *view);

@end


@interface UIView (HIScrollDisplayEventTracking)

/**
 setting a nonnull string, then the eventId will be tracked when scrollView stops.
 */
@property (nonatomic, copy) NSString *HI_scrollDisplayEventId;


/**
 make sure the scrollDisplayEvent will only be tracked once.
 */
@property (nonatomic, assign) BOOL HI_hasTrackedScrollDisplayEvent;

@end


@interface UIScrollView (HIScrollDisplayTracking) <HIUIScrollViewDisplayTrackProtocol>

@end
