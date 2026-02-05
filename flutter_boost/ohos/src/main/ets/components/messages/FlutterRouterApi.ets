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
import { BinaryMessenger, BasicMessageChannel, } from '@ohos/flutter_ohos';
import CommonParams from './CommonParams';
import FlutterRouterApiCodec from './FlutterRouterApiCodec';

/**
 * Send messages to Flutter side
 */
export default class FlutterRouterApi {
  private binaryMessenger: BinaryMessenger;

  constructor(argBinaryMessenger: BinaryMessenger) {
    this.binaryMessenger = argBinaryMessenger;
  }

  /**
   * Will send push route event
   *
   * @param argInput Route input parameters.
   * @param callback Callback function called after route push.
   */
  pushRoute(argInput: CommonParams, callback: () => void) {
    const channel = new BasicMessageChannel<Object>(
      this.binaryMessenger,
      "dev.flutter.pigeon.FlutterRouterApi.pushRoute",
      FlutterRouterApiCodec.INSTANCE
    );
    try {
      channel.send([argInput], (channelReply) => {
        callback();
      });
    } catch (e) {
      console.log('e:' + e)
    }
  }


  /**
   * Send pop route event
   * @param argInput Pop route parameters
   * @param callback Callback function after pop route completes
   */
  popRoute(argInput: CommonParams, callback: () => void) {
    const channel = new BasicMessageChannel<Object>(
      this.binaryMessenger,
      "dev.flutter.pigeon.FlutterRouterApi.popRoute",
      FlutterRouterApiCodec.INSTANCE
    );
    channel.send([argInput], (toMap) => {
      callback();
    });
  }


  /**
   * Remove route
   * @param argInput Remove route parameters
   * @param callback Callback function after remove route completes
   */
  removeRoute(argInput: CommonParams, callback: () => void) {
    const channel = new BasicMessageChannel<Object>(
      this.binaryMessenger,
      "dev.flutter.pigeon.FlutterRouterApi.removeRoute",
      FlutterRouterApiCodec.INSTANCE
    );
    channel.send([argInput], (toMap) => {
      callback();
    });
  }

  /**
   * Return to foreground
   * @param argInput - Common parameters
   * @param callback - Callback function
   */
  onForeground(argInput: CommonParams, callback: () => void) {
    const channel = new BasicMessageChannel<Object>(
      this.binaryMessenger,
      "dev.flutter.pigeon.FlutterRouterApi.onForeground",
      FlutterRouterApiCodec.INSTANCE
    );
    channel.send([argInput], (toMap) => {
      callback();
    });
  }

  /**
   * Enter background
   * @param argInput - Common parameters
   * @param callback - Callback function
   */
  onBackground(argInput: CommonParams, callback: () => void) {
    const channel = new BasicMessageChannel<Object>(
      this.binaryMessenger,
      "dev.flutter.pigeon.FlutterRouterApi.onBackground",
      FlutterRouterApiCodec.INSTANCE
    );
    channel.send([argInput], (toMap) => {
      callback();
    });
  }

  /**
   * Handle native return result
   * @param argInput Parameter input
   * @param callback Callback function
   */
  onNativeResult(argInput: CommonParams, callback: () => void) {
    const channel = new BasicMessageChannel<Object>(
      this.binaryMessenger,
      "dev.flutter.pigeon.FlutterRouterApi.onNativeResult",
      FlutterRouterApiCodec.INSTANCE
    );
    channel.send([argInput], (toMap) => {
      callback();
    });
  }

  /**
   * Send to flutter side when container shows
   * @param argInput - Common parameters
   * @param callback - Callback function
   */
  onContainerShow(argInput: CommonParams, callback: () => void) {
    const channel = new BasicMessageChannel<Object>(
      this.binaryMessenger,
      "dev.flutter.pigeon.FlutterRouterApi.onContainerShow",
      FlutterRouterApiCodec.INSTANCE
    );
    channel.send([argInput], (toMap) => {
      callback()
    });
  }


  /**
   * Send to flutter side when container hides
   * @param argInput - Common parameters
   * @param callback - Callback function
   */
  onContainerHide(argInput: CommonParams, callback: () => void) {
    const channel = new BasicMessageChannel<Object>(
      this.binaryMessenger,
      "dev.flutter.pigeon.FlutterRouterApi.onContainerHide",
      FlutterRouterApiCodec.INSTANCE
    );
    channel.send([argInput], (toMap) => {
      callback()
    });
  }

  /**
   * Send event to Flutter
   * @param argInput Input parameters
   * @param callback Callback function
   */
  sendEventToFlutter(argInput: CommonParams, callback: () => void) {
    const channel = new BasicMessageChannel<Object>(
      this.binaryMessenger,
      "dev.flutter.pigeon.FlutterRouterApi.sendEventToFlutter",
      FlutterRouterApiCodec.INSTANCE
    );
    channel.send([argInput], (toMap) => {
      callback()
    });
  }

  /**
   * Send back button event
   * @param callback Callback function, executed when back button is pressed.
   */
  onBackPressed(callback: () => void) {
    const channel = new BasicMessageChannel<Object>(
      this.binaryMessenger,
      "dev.flutter.pigeon.FlutterRouterApi.onBackPressed",
      FlutterRouterApiCodec.INSTANCE
    );
    channel.send(null, (channelReply) => {
      callback()
    });
  }
}
