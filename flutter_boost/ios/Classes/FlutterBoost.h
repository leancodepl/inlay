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
#import "FlutterBoostDelegate.h"
#import "FlutterBoostPlugin.h"
#import "FBFlutterViewContainer.h"
#import "FlutterBoostDelegate.h"
#import "FlutterBoostPlugin.h"
#import "FBFlutterViewContainer.h"
#import "Options.h"
#import "messages.h"


@interface FlutterBoost : NSObject

#pragma mark

- (FlutterEngine*)engine;

- (FlutterBoostPlugin*)plugin;

- (FlutterViewController *)currentViewController;

#pragma mark

/// Boost global singleton
+ (instancetype)instance;

/// Initialize
/// @param application Global Application instance. If engine parameter is not set, the engine binding is done from the Application by default
/// @param delegate Instance of FlutterBoostDelegate, used to implement specific Push and Pop strategies (how Native side performs Push, and specific actions when a new FlutterViewController needs to be pushed), as well as some engine initialization strategies
/// @param callback Callback after initialization is complete
/// TODO Design needs review - callback is not async so may not be necessary
- (void)setup:(UIApplication*)application delegate:(id<FlutterBoostDelegate>)delegate callback:(void (^)(FlutterEngine *engine))callback;


/// Initialize with custom configuration
/// @param application Global Application instance. If engine parameter is not set, the engine binding is done from the Application by default
/// @param delegate Instance of FlutterBoostDelegate, used to implement specific Push and Pop strategies
/// @param callback Callback after initialization is complete
/// @param options Startup configuration, use this parameter if customization is needed
- (void)setup:(UIApplication*)application delegate:(id<FlutterBoostDelegate>)delegate callback:(void (^)(FlutterEngine *engine))callback options:(FlutterBoostSetupOptions*)options;

/// Close a page, recommended interface for page operations in hybrid stack
/// @param uniqueId Unique ID of the page to close
- (void)close:(NSString *)uniqueId;

/// (DEPRECATED - new parameters may not support this method in the future!!!)
/// Open a new page (default is push method), recommended interface for page operations in hybrid stack
/// You can set to open page in present mode via arguments: arguments:@{@"present":@(YES)}
/// @param pageName Page resource locator to open
/// @param arguments Parameters to pass to the page; if there is special logic, callback id can be set through this parameter
/// @param completion Callback when page open operation is complete. Note: this parameter only works when called from native side
- (void)open:(NSString *)pageName arguments:(NSDictionary *)arguments completion:(void(^)(BOOL)) completion;


/// (Recommended) Open a new page with configuration options
/// @param options Configuration parameters
- (void)open:(FlutterBoostRouteOptions* )options;


/// Method to pass data from native page back to flutter page
/// @param pageName Name of this page in the route table, same as the name in BoostNavigator.push(name) on flutter side
/// @param arguments Parameters you want to pass
- (void)sendResultToFlutterWithPageName:(NSString*)pageName arguments:(NSDictionary*) arguments;

/// Add an event listener
/// @param listener Function of FBEventListener type
/// @param key Event identifier
/// @return A function to remove the listener, call this function directly to remove the listener and avoid memory leaks
- (FBVoidCallback)addEventListener:(FBEventListener)listener
                           forName:(NSString *)key;

/// Pass custom events to flutter side
/// @param key Event identifier
/// @param arguments Event parameters
- (void)sendEventToFlutterWith:(NSString*)key arguments:(NSDictionary*)arguments;

/// Unload the engine
- (void)unsetFlutterBoost;

@end

