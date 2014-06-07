//
//  ASDepthModalViewController.m
//  ASDepthModal
//
//  Created by Philippe Converset on 03/10/12.
//  Copyright (c) 2012 AutreSphere.
//

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ASDepthModalViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImage+Blur.h"

static NSTimeInterval const kModalViewAnimationDuration = 0.3;
static CGFloat const kBlurValue = 0.2;
static CGFloat const kDefaultiPhoneCornerRadius = 4;
static CGFloat const kDefaultiPadCornerRadius = 6;

static NSInteger const kDepthModalOptionAnimationMask = 3 << 0;
static NSInteger const kDepthModalOptionBlurMask = 1 << 8;
static NSInteger const kDepthModalOptionTapMask = 1 << 9;

@interface ASDepthModalViewController ()
@property (nonatomic, strong) UIViewController *rootViewController;
@property (nonatomic, strong) UIView *coverView;
@property (nonatomic, strong) UIView *popupView;
@property (nonatomic, assign) CGAffineTransform initialPopupTransform;
@property (nonatomic, strong) UIImageView *backgroundView;
@property (nonatomic, strong) void(^completionHandler)();
@property (nonatomic, strong) UIWindow *originalWindow;
@property (nonatomic, strong) UIWindow *popupWindow;
@property (nonatomic) CGFloat keyboardHeight;

- (void)keyboardWillShow:(NSNotification *)note;
- (void)keyboardWillHide:(NSNotification *)note;

@end

@implementation ASDepthModalViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.view.backgroundColor = [UIColor whiteColor];
        self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)restoreRootViewController
{
//    UIWindow *window;
//    
//    window = [UIApplication sharedApplication].keyWindow;
//    [self.rootViewController.view removeFromSuperview];
//    self.rootViewController.view.transform = window.rootViewController.view.transform;
//    window.rootViewController = self.rootViewController;
    [self.originalWindow makeKeyAndVisible];
    [self setOriginalWindow:nil];
}

- (void)dismiss
{
    [UIView animateWithDuration:kModalViewAnimationDuration
                     animations:^{
                         self.view.alpha = 0;
                         self.popupView.transform = self.initialPopupTransform;
                         [self.popupWindow setBackgroundColor:[UIColor clearColor]];
                         [self.backgroundView setTransform:CGAffineTransformIdentity];
                     }
                     completion:^(BOOL finished) {
                         [self.view.window setRootViewController:nil];
                         [self.originalWindow makeKeyAndVisible];
                         [self setOriginalWindow:nil];
                         [self setPopupWindow:nil];
                         
                         if (self.completionHandler) {
                             self.completionHandler();
                         }
                     }];
}

- (void)animatePopupWithStyle:(ASDepthModalOptions)options
{
    NSInteger style = (options & kDepthModalOptionAnimationMask);
    
    switch (style) {
        case ASDepthModalOptionAnimationGrow:
        {
            self.popupView.transform = CGAffineTransformMakeScale(0.8, 0.8);
            self.initialPopupTransform = self.popupView.transform;
            [UIView animateWithDuration:kModalViewAnimationDuration
                             animations:^{
                                 self.popupView.transform = CGAffineTransformIdentity;
                             }];
        }
            break;
            
        case ASDepthModalOptionAnimationShrink:
        {
            self.popupView.transform = CGAffineTransformMakeScale(1.5, 1.5);
            self.initialPopupTransform = self.popupView.transform;
            [UIView animateWithDuration:kModalViewAnimationDuration
                             animations:^{
                                 self.popupView.transform = CGAffineTransformIdentity;
                             }];
        }
            break;
            
        default:
            self.initialPopupTransform = self.popupView.transform;
            break;
    }
}

- (void)presentView:(UIView *)view withBackgroundColor:(UIColor *)color options:(ASDepthModalOptions)options completionHandler:(void(^)())handler
{
    UIWindow *window;
    
    if(color != nil)
    {
        self.view.backgroundColor = color;
    }

    window = [UIApplication sharedApplication].keyWindow;
    [self setOriginalWindow:window];

    // take a screenshot of the original window, and add it into ourselves.
    UIImage *screenshot = [self screenshotForView:window];
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:screenshot];

    if ((options & kDepthModalOptionBlurMask) == ASDepthModalOptionBlur)
    {
        [backgroundView setImage:[backgroundView.image boxblurImageWithBlur:kBlurValue]];
        [backgroundView setAlpha:0.0f];
    }
    [self setBackgroundView:backgroundView];

    [self.view addSubview:backgroundView];
    [self setPopupWindow:[[UIWindow alloc] initWithFrame:window.frame]];
    [self.popupWindow setBackgroundColor:[UIColor clearColor]];
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.popupWindow setWindowLevel:UIWindowLevelAlert];
    [self.popupWindow setRootViewController:self];
    [self.popupWindow makeKeyAndVisible];

    self.coverView = [[UIView alloc] initWithFrame:window.frame];
    self.coverView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.coverView.backgroundColor = [UIColor colorWithRed:00/255.0 green:00/255.0 blue:00/255.0 alpha:0.5];
    [self.view addSubview:self.coverView];
    
    if ((options & kDepthModalOptionTapMask) == ASDepthModalOptionTapOutsideToClose)
    {
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleCloseAction:)];
        tapGesture.delegate = self;
        [self.coverView addGestureRecognizer:tapGesture];
    }
    [self.coverView setAlpha:0.0f];

    self.popupView = [[UIView alloc] initWithFrame:view.frame];
    self.popupView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.popupView addSubview:view];
    
    
    [self.coverView addSubview:self.popupView];
    self.popupView.center = CGPointMake(self.coverView.bounds.size.width/2, (self.coverView.bounds.size.height - self.keyboardHeight)/2);

    
    [UIView animateWithDuration:kModalViewAnimationDuration
                     animations:^{
//                         self.rootViewController.view.transform = CGAffineTransformMakeScale(0.9, 0.9);
//                         self.coverView.alpha = 1;
                         [backgroundView setTransform:CGAffineTransformMakeScale(0.9f, 0.9f)];
                         backgroundView.alpha = 1;
                         [self.popupWindow setBackgroundColor:color];
                         [self.coverView setAlpha:1.0f];
                     } completion:^(BOOL finished) {
                         if (handler != nil)
                             handler();
                     }];
    
    [self animatePopupWithStyle:options];
    return;
}

- (UIImage*)screenshotForView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, [UIScreen mainScreen].scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // hack, helps w/ our colors when blurring
    NSData *imageData = UIImagePNGRepresentation(image);
    image = [UIImage imageWithData:imageData scale:[UIScreen mainScreen].scale];
    
    return image;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (touch.view == self.coverView)
        return YES;
    return NO;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    self.view.transform = CGAffineTransformIdentity;
    self.view.bounds = self.view.bounds;
    self.view.transform = CGAffineTransformMakeScale(0.9, 0.9);
}

+ (void)presentView:(UIView *)view
{
    [self presentView:view backgroundColor:nil options:0 completionHandler:nil];
}

+ (void)presentView:(UIView *)view backgroundColor:(UIColor *)color options:(ASDepthModalOptions)options completionHandler:(void(^)())handler
{
    ASDepthModalViewController *modalViewController = [[ASDepthModalViewController alloc] init];
    
    [modalViewController presentView:view withBackgroundColor:(UIColor *)color options:options completionHandler:handler];
}

+ (NSInteger)optionsWithStyle:(ASDepthModalOptions)style blur:(BOOL)blur tapOutsideToClose:(BOOL)tapToClose
{
    NSInteger options;
    
    options = (NSInteger)style;
    
    if (blur)
        options |= ASDepthModalOptionBlur;
    else
        options |= ASDepthModalOptionBlurNone;
    
    
    if (tapToClose)
        options |= ASDepthModalOptionTapOutsideToClose;
    else
        options |= ASDepthModalOptionTapOutsideInactive;
    
    return options;
}

+ (void)dismiss
{
    UIWindow *window;
    
    window = [UIApplication sharedApplication].keyWindow;
    if([window.rootViewController isKindOfClass:[ASDepthModalViewController class]])
    {
        ASDepthModalViewController *controller;
        
        controller = (ASDepthModalViewController *)window.rootViewController;
        [controller dismiss];
    }
}

+ (void)replaceView:(UIView *)view
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if([window.rootViewController isKindOfClass:[ASDepthModalViewController class]])
    {
        ASDepthModalViewController *controller = (ASDepthModalViewController *)window.rootViewController;
        UIView *popupView = [[UIView alloc] initWithFrame:view.frame];
        [popupView setCenter:controller.popupView.center];
        popupView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        [popupView addSubview:view];
        
        [controller.popupView removeFromSuperview];
        controller.popupView.center = CGPointMake(controller.coverView.bounds.size.width/2, (controller.coverView.bounds.size.height - controller.keyboardHeight)/2);
        [controller.coverView addSubview:popupView];
        [controller setPopupView:popupView];
    }
}

#pragma mark - Action

- (void)handleCloseAction:(id)sender
{
    [self dismiss];
}

- (void)keyboardWillShow:(NSNotification *)note
{
    CGRect keyboardFrame = [[note.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [self setKeyboardHeight:keyboardFrame.size.height];
    
    // we're already showing the popup, re-center it
    if (self.popupView != nil)
    {
        [UIView animateWithDuration:[[note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^
        {
            self.popupView.center = CGPointMake(self.coverView.bounds.size.width/2, (self.coverView.bounds.size.height - self.keyboardHeight)/2);
        }];
    }
}

- (void)keyboardWillHide:(NSNotification *)note
{
    [self setKeyboardHeight:0.0f];
    
    // we're already showing the popup, re-center it
    if (self.popupView != nil)
    {
        [UIView animateWithDuration:[[note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^
        {
            self.popupView.center = CGPointMake(self.coverView.bounds.size.width/2, self.coverView.bounds.size.height/2);
        }];
    }
}

@end
