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


#import <Flutter/Flutter.h>

// This file is used for configuring various FlutterBoost configuration files

/// Startup parameters configuration
@interface FlutterBoostSetupOptions : NSObject

/// Initial route
@property (nonatomic, strong) NSString* initalRoute;

/// Dart entry point
@property (nonatomic, strong) NSString* dartEntryPoint;

/// Dart entry point arguments
@property (nonatomic, strong) NSArray<NSString*>* dartEntryPointArgs;

/// FlutterDartProject data
@property (nonatomic, strong) FlutterDartProject* dartObject;

/// Whether to pre-warm the engine. If pre-warmed, it can reduce the brief white screen when first opening a flutter page, as well as font size jumping
/// Default value is YES
@property (nonatomic, assign) BOOL warmUpEngine;

/// Create a default Options object
+ (FlutterBoostSetupOptions*)createDefault;

@end


/// Route parameters configuration
@interface FlutterBoostRouteOptions : NSObject

/// Page name in the route table
@property(nonatomic, strong) NSString* pageName;

/// Arguments
@property(nonatomic, strong) NSDictionary* arguments;

/// Callback closure for returning parameters, only useful when navigating native -> flutter page
@property(nonatomic, strong) void(^onPageFinished)(NSDictionary*);

/// Callback after open method is complete, only useful when navigating native -> flutter page
@property(nonatomic, strong) void(^completion)(BOOL);

/// Used internally by delegate, set this to nil when opening from native to flutter
@property(nonatomic, strong) NSString* uniqueId;

/// Whether this page is opaque. Note: default value = YES
@property(nonatomic,assign) BOOL opaque;
@end
