//
//  HIViewController.m
//  HIScrollDisplayEventTracking
//
//  Created by HiIgor on 06/18/2018.
//  Copyright (c) 2018 HiIgor. All rights reserved.
//

#import "HIViewController.h"
#import <Masonry/Masonry.h>
#import <HIScrollDisplayEventTracking/UIScrollView+HIScrollDisplayEventTracking.h>

@interface HIViewController () <UIScrollViewDelegate>

@property (nonatomic, assign) BOOL didSetupConstratins;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *stackView;

@end

@implementation HIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view addSubview:self.scrollView];
    [self.scrollView addSubview:self.stackView];
    [self setupLabels];
}

- (void)updateViewConstraints {
    if (!self.didSetupConstratins) {

        [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];

        [self.stackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.and.bottom.and.centerX.and.width.equalTo(self.scrollView);
        }];

        [self.stackView.arrangedSubviews mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@200);
        }];

        self.didSetupConstratins = YES;
    }

    [super updateViewConstraints];
}

- (void)setupLabels {
    for (NSInteger i = 0; i < 8; i++) {
        UILabel *label = [[UILabel alloc] init];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:20];
        label.text = [NSString stringWithFormat:@"Text 🐸🐸🐸🐸🐸🐸🐸🐸🐸🐸🐸 ~~ %td", i];
        [self.stackView addArrangedSubview:label];

        // after added to super view.
        label.HI_scrollDisplayEventId = [NSString stringWithFormat:@"label -> %td displayName", i];
    }
}

- (UIStackView *)stackView {
    if (!_stackView) {
        _stackView = [[UIStackView alloc] init];
        _stackView.axis = UILayoutConstraintAxisVertical;
    }

    return _stackView;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.HI_shouldTrackScrollEvent = YES;
        _scrollView.delegate = self;
        _scrollView.bounces = NO;
        _scrollView.HI_scrollDisplayEventTrackingBlock = ^BOOL(UIView *view) {
            // track the event by calling your method.
            NSLog(@"event = %@, content = %@", view.HI_scrollDisplayEventId, NSStringFromCGRect(view.frame));
            return YES;
        };
    }

    return _scrollView;
}

@end
