/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2019 Alibaba Group
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import <Foundation/Foundation.h>
#import "FBFlutterViewContainer.h"
#import "FlutterBoost.h"
#import "FBLifecycle.h"
#import <objc/message.h>
#import <objc/runtime.h>

#define ENGINE [[FlutterBoost instance] engine]
#define FB_PLUGIN  [FlutterBoostPlugin getPlugin: [[FlutterBoost instance] engine]]

#define weakify(var) ext_keywordify __weak typeof(var) O2OWeak_##var = var;
#define strongify(var) ext_keywordify \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__strong typeof(var) var = O2OWeak_##var; \
_Pragma("clang diagnostic pop")
#if DEBUG
#   define ext_keywordify autoreleasepool {}
#else
#   define ext_keywordify try {} @catch (...) {}
#endif

@interface FlutterViewController (bridgeToviewDidDisappear)
- (void)flushOngoingTouches;
- (void)bridge_viewDidDisappear:(BOOL)animated;
- (void)bridge_viewWillAppear:(BOOL)animated;
- (void)surfaceUpdated:(BOOL)appeared;
- (void)updateViewportMetrics;
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation FlutterViewController (bridgeToviewDidDisappear)
- (void)bridge_viewDidDisappear:(BOOL)animated {
  [self flushOngoingTouches];
  [super viewDidDisappear:animated];
}

- (void)bridge_viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
}
@end
#pragma pop

@interface FBFlutterViewContainer ()
@property (nonatomic,strong,readwrite) NSDictionary *params;
@property (nonatomic,copy) NSString *uniqueId;
@property (nonatomic, copy) NSString *flbNibName;
@property (nonatomic, strong) NSBundle *flbNibBundle;
@property (nonatomic, assign) BOOL opaque;
@property (nonatomic, strong) FBVoidCallback removeEventCallback;
@property (nonatomic, strong) UIScreenEdgePanGestureRecognizer* leftEdgeGesture;
@end

@implementation FBFlutterViewContainer
- (instancetype)init {
  ENGINE.viewController = nil;
  if (self = [super initWithEngine:ENGINE
                          nibName:_flbNibName
                           bundle:_flbNibBundle]) {
    // NOTES: When presenting a page, the default is full screen, this can trigger page events of the underlying VC. Otherwise it won't trigger and cause exceptions
    self.modalPresentationStyle = UIModalPresentationFullScreen;
    [self _setup];
  }
  return self;
}

- (instancetype)initWithProject:(FlutterDartProject*)projectOrNil
                        nibName:(NSString*)nibNameOrNil
                         bundle:(NSBundle*)nibBundleOrNil {
  ENGINE.viewController = nil;
  if (self = [super initWithProject:projectOrNil
                            nibName:nibNameOrNil
                             bundle:nibBundleOrNil]) {
    [self _setup];
  }
  return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder: aDecoder]) {
    NSAssert(NO, @"unsupported init method!");
    [self _setup];
  }
  return self;
}
#pragma pop

- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil {
  _flbNibName = nibNameOrNil;
  _flbNibBundle = nibBundleOrNil;
  ENGINE.viewController = nil;
  return [self init];
}

- (void)setName:(NSString *)name
       uniqueId:(NSString *)uniqueId
         params:(NSDictionary *)params
         opaque:(BOOL) opaque {
  if (!_name && name) {
    _name = name;
    _params = params;
    _opaque = opaque;

    // Only set viewOpaque to false in the non-opaque case,
    // and set modalStyle to UIModalPresentationOverFullScreen
    // Because in UIModalPresentationOverFullScreen mode, when the VC below is shown again,
    // viewAppear lifecycle methods won't be called, so we need to manually call beginAppearanceTransition methods to trigger them
    if (!_opaque) {
      self.viewOpaque = opaque;
      self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }
    if (uniqueId != nil) {
      _uniqueId = uniqueId;
    }
  }

  [FB_PLUGIN containerCreated:self];

  // Set up event listener for events coming from flutter for this container
  [self setupEventListeningFromFlutter];
}

/// Set up event listener for events coming from flutter for this container
- (void)setupEventListeningFromFlutter {
  @weakify(self)
  // Register listener for this container to listen to events sent from internal flutterPage to this container
  self.removeEventCallback = [FlutterBoost.instance addEventListener:^(NSString *name, NSDictionary *arguments) {
    @strongify(self)
    // Event name
    NSString *event = arguments[@"event"];

    // Event arguments
    NSDictionary *args = arguments[@"args"];

    if ([event isEqualToString:@"enablePopGesture"]) {
      // Dynamic enable/disable swipe back gesture in multi-page scenario
      NSNumber *enableNum = args[@"enable"];
      BOOL enable = [enableNum boolValue];
      self.navigationController.interactivePopGestureRecognizer.enabled = enable;
    }
  } forName:self.uniqueId];
}

- (NSString *)uniqueIDString {
  return self.uniqueId;
}

- (void)_setup {
  self.uniqueId = [[NSUUID UUID] UUIDString];
  self.currentFBAppearState = FBDoneAppear;
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
  if (!parent) {
    // When VC is removed from parent, notify flutter layer to destroy the page
    [self detachFlutterEngineIfNeeded];
    [self notifyWillDealloc];
  }
  [super didMoveToParentViewController:parent];
}

- (void)dismissViewControllerAnimated:(BOOL)flag
                           completion:(void (^)(void))completion {
  [super dismissViewControllerAnimated:flag
                            completion:^() {
                              if (completion) {
                                completion();
                              }
                              // When VC is dismissed, notify flutter layer to destroy the page
                              [self detachFlutterEngineIfNeeded];
                              [self notifyWillDealloc];
                            }];
}

- (void)dealloc {
  if (self.removeEventCallback != nil) {
    self.removeEventCallback();
  }
  [NSNotificationCenter.defaultCenter removeObserver:self];
  _leftEdgeGesture.delegate = nil;
}

- (void)notifyWillDealloc {
  [FB_PLUGIN containerDestroyed:self];
}

- (void)viewDidLoad {
  // Ensure current view controller attach to Flutter engine
  [self attatchFlutterEngine];

  [super viewDidLoad];
  // Only set background color in opaque case, otherwise don't set color (which defaults to transparent)
  if (self.opaque) {
    self.view.backgroundColor = UIColor.whiteColor;
  }

  if (self.enableLeftPanBackGesture) {
    _leftEdgeGesture = [[UIScreenEdgePanGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(handleLeftEdgeGesture:)];
    _leftEdgeGesture.edges = UIRectEdgeLeft;
    _leftEdgeGesture.delegate = self;
    [self.view addGestureRecognizer:_leftEdgeGesture];
  }
}

- (void)handleLeftEdgeGesture:(UIScreenEdgePanGestureRecognizer *)gesture {
  if (UIGestureRecognizerStateEnded == gesture.state) {
    [FB_PLUGIN onBackSwipe];
  }
}

#pragma mark - ScreenShots
- (BOOL)isFlutterViewAttatched {
  return ENGINE.viewController.view.superview == self.view;
}

- (void)attatchFlutterEngine {
  if (ENGINE.viewController != self){
    ENGINE.viewController = self;
  }
}

- (void)detachFlutterEngineIfNeeded {
  if (self.engine.viewController == self) {
    // need to call [surfaceUpdated:NO] to detach the view controller's ref from
    // interal engine platformViewController,or dealloc will not be called after controller close.
    // detail:https://github.com/flutter/engine/blob/07e2520d5d8f837da439317adab4ecd7bff2f72d/shell/platform/darwin/ios/framework/Source/FlutterViewController.mm#L529
    [self surfaceUpdated:NO];

    if (ENGINE.viewController != nil) {
      ENGINE.viewController = nil;
    }
  }
}

- (void)surfaceUpdated:(BOOL)appeared {
  if (self.engine && self.engine.viewController == self) {
    if (appeared && self.currentFBAppearState == FBAlreadySurfaceUpdatedYes) return; 
    [super surfaceUpdated:appeared];
    if (appeared && self.currentFBAppearState == FBWaitForSurfaceUpdatedYes) self.currentFBAppearState = FBAlreadySurfaceUpdatedYes;
  }
}

- (void)updateViewportMetrics {
  if (self.engine && self.engine.viewController == self) {
    [super updateViewportMetrics];
  }
}

#pragma mark - Life circle methods

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
}

- (void)viewWillAppear:(BOOL)animated {
  self.currentFBAppearState = FBWaitForSurfaceUpdatedYes;
  [FB_PLUGIN containerWillAppear:self];

  // For new page we should attach flutter view in view will appear
  // for better performance.
  [self attatchFlutterEngine];

  [super bridge_viewWillAppear:animated];
  [self.view setNeedsLayout]; // TODO: Set through param
}

- (void)viewDidAppear:(BOOL)animated {
  //Ensure flutter view is attached.
  [self attatchFlutterEngine];

  // Based on Taobao Tejia logs, even in UIViewController's viewDidAppear, the application may be in inactive mode. In this case, submitting render will cause GPU background rendering and crash
  // Reference: https://github.com/flutter/flutter/issues/57973
  // https://github.com/flutter/engine/pull/18742
  if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive){
    // NOTES: Must update after show, otherwise there will be flickering; or it may cause the previous page to show the same content as top page when swiping back
    [self surfaceUpdated:YES];
  }
  [super viewDidAppear:animated];

  // Enable or disable pop gesture
  // note: if disablePopGesture is nil, do nothing
  if (self.disablePopGesture) {
    self.navigationController.interactivePopGestureRecognizer.enabled = ![self.disablePopGesture boolValue];
  }
  [FB_PLUGIN containerAppeared:self];
  self.currentFBAppearState = FBDoneAppear;
}

- (void)viewWillDisappear:(BOOL)animated {
  [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
  [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super bridge_viewDidDisappear:animated];
  [FB_PLUGIN containerDisappeared:self];
}

- (void)installSplashScreenViewIfNecessary {
  //Do nothing.
}

- (BOOL)loadDefaultSplashScreenView {
  return YES;
}
@end

