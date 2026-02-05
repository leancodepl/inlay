//
//  MyFlutterBoostDelegate.m
//  Runner
//
//  Created by wubian on 2021/1/21.
//  Copyright © 2021 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyFlutterBoostDelegate.h"
#import "UIViewControllerDemo.h"
#import <flutter_boost/FlutterBoost.h>

@implementation MyFlutterBoostDelegate


- (void) pushNativeRoute:(NSString *) pageName arguments:(NSDictionary *) arguments {
    BOOL animated = [arguments[@"animated"] boolValue];
    BOOL present= [arguments[@"present"] boolValue];
    UIViewControllerDemo *nvc = [[UIViewControllerDemo alloc] initWithNibName:@"UIViewControllerDemo" bundle:[NSBundle mainBundle]];
    if(present){
        [self.navigationController presentViewController:nvc animated:animated completion:^{
        }];
    }else{
        [self.navigationController pushViewController:nvc animated:animated];
    }
}

- (void)pushFlutterRoute:(FlutterBoostRouteOptions *)options {
    FBFlutterViewContainer *vc = [[FBFlutterViewContainer alloc] init];
    [vc setName:options.pageName uniqueId:options.uniqueId params:options.arguments opaque:options.opaque];

    // Whether to accompany animation
    BOOL animated = YES;
    NSNumber * animatedValue = options.arguments[@"animated"];
    if(animatedValue){
        animated = [animatedValue boolValue];
    }

    // Whether to open in present mode, if the page to be pushed is transparent, it should also be opened in present mode
    BOOL present = [options.arguments[@"present"] boolValue] || !options.opaque;

    if(present){
        [self.navigationController presentViewController:vc animated:animated completion:^{
            options.completion(YES);
        }];
    }else{
        [self.navigationController pushViewController:vc animated:animated];
        options.completion(YES);
    }
}

- (void) popRoute:(FlutterBoostRouteOptions *)options {
    // Get the current vc
    FBFlutterViewContainer *vc = (id)self.navigationController.presentedViewController;

    // Whether to accompany animation, default is true
    BOOL animated = YES;
    NSNumber * animatedValue = options.arguments[@"animated"];
    if(animatedValue){
        animated = [animatedValue boolValue];
    }

    // For present case, use dismiss logic
    if([vc isKindOfClass:FBFlutterViewContainer.class] && [vc.uniqueIDString isEqual: options.uniqueId]){

        // There are two cases here, since UIModalPresentationOverFullScreen has lifecycle display issues
        // Manual calling is needed so that the underlying vc calls viewAppear related logic
        if(vc.modalPresentationStyle == UIModalPresentationOverFullScreen){

            // Manually trigger page lifecycle with beginAppearanceTransition
            [self.navigationController.topViewController beginAppearanceTransition:YES animated:NO];

            [vc dismissViewControllerAnimated:YES completion:^{
                [self.navigationController.topViewController endAppearanceTransition];
            }];
        }else{
            // Normal case, dismiss directly
            [vc dismissViewControllerAnimated:YES completion:^{}];
        }
    }else{
        // Otherwise use pop logic
        [self.navigationController popViewControllerAnimated:animated];
    }

    options.completion(YES);
}



@end
