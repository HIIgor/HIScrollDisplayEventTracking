//
//  UIScrollView+HIScrollDisplayEventTracking.m
//  HIScrollDisplayEventTracking
//
//  Created by HiIgor on 2018/6/17.
//  Copyright (c) 2018 HiIgor. All rights reserved
//

#import "UIScrollView+HIScrollDisplayEventTracking.h"
#import <objc/runtime.h>

static NSString *const kUIViewScrollDisplayTrackEventId = @"UIView.HI_scrollDisplayTrackEventId";
static NSString *const kUIViewHasTrackedScrollDisplayEventId = @"UIView.HI_scrollDisplayTrackEventId";
static NSString *const kUIScrollViewTrackEventSubviews = @"UIScrollView.HI_trackEventSubviews";
static NSString *const kUIScrollViewShouldTrackEvent = @"UIScrollView.HI_shoudTrackEvent";
static NSString *const kUIScrollViewEventTrackingBlock = @"UIScrollView.HI_scrollEventTrackingBlock";


@implementation UIView (HIScrollDisplayEventTracking)

- (void)setHI_scrollDisplayEventId:(NSString *)scrollDisplayEventId {
    objc_setAssociatedObject(self, &kUIViewScrollDisplayTrackEventId, scrollDisplayEventId, OBJC_ASSOCIATION_COPY_NONATOMIC);

    UIScrollView *scrollView = [self trackEventScrollView];
    if (scrollDisplayEventId.length > 0) {
        NSMutableArray *trackEventSubviews = @[ self ].mutableCopy;
        [trackEventSubviews addObjectsFromArray:scrollView.HI_trackScrollDisplayEventSubviews];
        scrollView.HI_trackScrollDisplayEventSubviews = trackEventSubviews.copy;
    } else {
        NSArray *array = scrollView.HI_trackScrollDisplayEventSubviews;
        if ([array containsObject:self]) {
            NSMutableArray *trackEventSubviews = array.mutableCopy;
            [trackEventSubviews removeObject:self];
            scrollView.HI_trackScrollDisplayEventSubviews = trackEventSubviews.copy;
        }
    }
}

- (NSString *)HI_scrollDisplayEventId {
    return objc_getAssociatedObject(self, &kUIViewScrollDisplayTrackEventId);
}

- (void)setHI_hasTrackedScrollDisplayEvent:(BOOL)hasTrackedScrollDisplayEvent {
    objc_setAssociatedObject(self, &kUIViewHasTrackedScrollDisplayEventId, @(hasTrackedScrollDisplayEvent), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)HI_hasTrackedScrollDisplayEvent {
    NSObject *obj = objc_getAssociatedObject(self, &kUIViewHasTrackedScrollDisplayEventId);
    if (obj && [obj isKindOfClass:[NSNumber class]]) {
        return ((NSNumber *)obj).boolValue;
    }

    return NO;
}

- (UIScrollView<HIUIScrollViewDisplayTrackProtocol> *)trackEventScrollView {
    UIView *view = self.superview;
    while (view) {
        if ([view isMemberOfClass:[UIScrollView class]] && [view conformsToProtocol:@protocol(HIUIScrollViewDisplayTrackProtocol)]) {
            return (UIScrollView<HIUIScrollViewDisplayTrackProtocol> *)view;
        }

        view = view.superview;
    }

    return nil;
}

@end


@implementation UIScrollView (HIScrollDisplayTracking)

static void Hook_Method(Class originalClass, SEL originalSel, Class replacedClass, SEL replacedSel, SEL noneSel) {
    Method originalMethod = class_getInstanceMethod(originalClass, originalSel);
    Method replacedMethod = class_getInstanceMethod(replacedClass, replacedSel);
    if (!originalMethod) {
        Method noneMethod = class_getInstanceMethod(replacedClass, noneSel);
        class_addMethod(originalClass, originalSel, method_getImplementation(noneMethod), method_getTypeEncoding(noneMethod));

        return;
    }
    BOOL addMethod = class_addMethod(originalClass, replacedSel, method_getImplementation(replacedMethod), method_getTypeEncoding(replacedMethod));
    if (addMethod) {
        Method newMethod = class_getInstanceMethod(originalClass, replacedSel);
        method_exchangeImplementations(originalMethod, newMethod);
    }
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method originalMethod = class_getInstanceMethod([UIScrollView class], @selector(setDelegate:));
        Method replaceMethod = class_getInstanceMethod([UIScrollView class], @selector(__HI_setDelegate:));
        method_exchangeImplementations(originalMethod, replaceMethod);
    });
}

- (void)__HI_setDelegate:(id<UIScrollViewDelegate>)delegate {
    [self __HI_setDelegate:delegate];

    if (![self isMemberOfClass:[UIScrollView class]] || ![self HI_shouldTrackScrollEvent]) return;

    [self methodSwizzleOfDelegate:delegate];
}

- (void)methodSwizzleOfDelegate:delegate {
    Hook_Method([delegate class], @selector(scrollViewDidEndDecelerating:), [self class], @selector(__HI_scrollViewDidEndDecelerating:), @selector(__HI_add_scrollViewDidEndDecelerating:));

    Hook_Method([delegate class], @selector(scrollViewDidEndDragging:willDecelerate:), [self class], @selector(__HI_scrollViewDidEndDragging:willDecelerate:), @selector(__HI_add_scrollViewDidEndDragging:willDecelerate:));

    Hook_Method([delegate class], @selector(scrollViewWillBeginDecelerating:), [self class], @selector(__HI_scrollViewWillBeginDecelerating:), @selector(__HI_add_scrollViewWillBeginDecelerating:));
}

- (void)__HI_scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self __HI_scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    if (!decelerate && scrollView.tracking && !scrollView.dragging) {
        [scrollView __HI_scrollViewDidStopped];
    }
}

- (void)__HI_add_scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate && scrollView.tracking && !scrollView.dragging) {
        [scrollView __HI_scrollViewDidStopped];
    }
}

- (void)__HI_scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    [self __HI_scrollViewWillBeginDecelerating:scrollView];
    if (!scrollView.tracking && !scrollView.dragging && !scrollView.decelerating) {
        [scrollView __HI_scrollViewDidStopped];
    }
}

- (void)__HI_add_scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if (!scrollView.tracking && !scrollView.dragging && !scrollView.decelerating) {
        [scrollView __HI_scrollViewDidStopped];
    }
}

- (void)__HI_scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self __HI_scrollViewDidEndDecelerating:scrollView];
    if (!scrollView.tracking && !scrollView.dragging && !scrollView.decelerating) {
        [scrollView __HI_scrollViewDidStopped];
    }
}

- (void)__HI_add_scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (!scrollView.tracking && !scrollView.dragging && !scrollView.decelerating) {
        [scrollView __HI_scrollViewDidStopped];
    }
}

- (void)__HI_scrollViewDidStopped {
    [self.HI_trackScrollDisplayEventSubviews enumerateObjectsUsingBlock:^(UIView *_Nonnull view, NSUInteger idx, BOOL *_Nonnull stop) {
        if (!view.HI_hasTrackedScrollDisplayEvent && !view.hidden) {
            CGRect convertedRect = [view.superview convertRect:view.frame toView:[UIApplication sharedApplication].keyWindow];
            CGRect interSection = CGRectIntersection(convertedRect, [UIApplication sharedApplication].keyWindow.frame);
            if (interSection.size.width > 0 && interSection.size.height > 0) {
                if (self.HI_scrollDisplayEventTrackingBlock) {
                    view.HI_hasTrackedScrollDisplayEvent = self.HI_scrollDisplayEventTrackingBlock(view);
                }
            }
        }
    }];
}

#pragma mark - setter & getter
- (void)setHI_trackScrollDisplayEventSubviews:(NSArray *)trackEventSubviews {
    objc_setAssociatedObject(self, &kUIScrollViewTrackEventSubviews, trackEventSubviews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray *)HI_trackScrollDisplayEventSubviews {
    NSArray *trackEventSubviews = objc_getAssociatedObject(self, &kUIScrollViewTrackEventSubviews);

    if ([trackEventSubviews isKindOfClass:[NSArray class]]) {
        return trackEventSubviews;
    }

    return nil;
}

- (void)setHI_shouldTrackScrollEvent:(BOOL)shouldTrackScrollEvent {
    objc_setAssociatedObject(self, &kUIScrollViewShouldTrackEvent, @(shouldTrackScrollEvent), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)HI_shouldTrackScrollEvent {
    id obj = objc_getAssociatedObject(self, &kUIScrollViewShouldTrackEvent);
    if (obj && [obj isKindOfClass:[NSNumber class]]) {
        return ((NSNumber *)obj).boolValue;
    }

    return NO;
}

- (void)setHI_scrollDisplayEventTrackingBlock:(BOOL (^)(UIView *))HIEventTrackBlock {
    objc_setAssociatedObject(self, &kUIScrollViewEventTrackingBlock, HIEventTrackBlock, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL (^)(UIView *))HI_scrollDisplayEventTrackingBlock {
    return objc_getAssociatedObject(self, &kUIScrollViewEventTrackingBlock);
}


@end
