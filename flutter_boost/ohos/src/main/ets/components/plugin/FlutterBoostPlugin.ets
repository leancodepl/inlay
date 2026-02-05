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

import {
  FlutterEngine,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodResult,
} from '@ohos/flutter_ohos';

import { FlutterViewContainer } from '../containers/FlutterViewContainer';
import FlutterContainerManager from '../containers/FlutterContainerManager';
import FlutterRouterApi from '../messages/FlutterRouterApi';
import NativeRouterApi, { NativeRouterApiSetup } from '../messages/NativeRouterApi';
import FlutterBoostDelegate from '../FlutterBoostDelegate';
import CommonParams from '../messages/CommonParams';
import Log from '../util/Log'
import StackInfo from '../messages/StackInfo';
import FlutterBoostRouteOptions, { FlutterBoostRouteOptionsBuilder } from '../FlutterBoostRouteOptions';
import EventListener from '../util/EventListener';
import ListenerRemover from '../util/ListenerRemover';
import FlutterBoostUtils from '../FlutterBoostUtils';

const TAG = 'FlutterBoostPlugin'

/**
 * FlutterBoostPlugin plugin class.
 */
export class FlutterBoostPlugin implements FlutterPlugin, MethodCallHandler, NativeRouterApi {
  public static className = 'FlutterBoostPlugin'
  public static APP_LIFECYCLE_CHANGED_KEY = 'app_lifecycle_changed_key'
  public static LIFECYCLE_STATE = 'lifecycleState'
  public static FLUTTER_APP_STATE_RESUMED = 0
  public static FLUTTER_APP_STATE_PAUSED = 2

  private channel: FlutterRouterApi | null // Send to dart
  private engine: FlutterEngine | null
  private delegate: FlutterBoostDelegate | null
  private dartStack: StackInfo
  private listenersTable: Record<string, EventListener[]> = {};

  constructor() {
    this.engine = null
    this.delegate = null
    this.channel = null
    this.dartStack = new StackInfo()
  }

  private isTraceEnabled(): boolean {
    return FlutterBoostUtils.isDebugLoggingEnabled();
  }

  onMethodCall(call: MethodCall, result: MethodResult) {
    throw new Error('Method not implemented.');
  }

  // override FlutterPlugin interface ==> start
  getUniqueClassName(): string {
    return FlutterBoostPlugin.className
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.engine = binding.getFlutterEngine()
    this.channel = new FlutterRouterApi(binding.getBinaryMessenger())
    NativeRouterApiSetup(binding.getBinaryMessenger(), this)
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.engine = null
    this.channel = null
  }

  // override FlutterPlugin interface ==> end

  // NativeRouterApi override ==> start
  onPushNativeRoute(params: CommonParams) {
    if (this.isTraceEnabled()) Log.i(TAG, `#onPushNativeRoute: ${JSON.stringify(params, this.bigIntReplacer)}`);
    if (this.delegate) {
      const builder = new FlutterBoostRouteOptionsBuilder()
      if (params.pageName) {
        builder.setPageName(params.pageName)
      }
      if (params.arguments) {
        builder.setArguments(params.arguments)
      }
      this.delegate.pushNativeRoute(builder.build(), (pageName: string, result: Record<string, Object>) => {
        this.onPageResult(pageName, result)
      });
    } else {
      throw new Error("FlutterBoostPlugin might *NOT* set delegate!");
    }
  }

  onPushFlutterRoute(params: CommonParams) {
    if (this.isTraceEnabled()) Log.i(TAG, `#onPushFlutterRoute: ${JSON.stringify(params, this.bigIntReplacer)}`);
    if (this.delegate) {
      const builder = new FlutterBoostRouteOptionsBuilder()
      if (params.pageName) {
        builder.setPageName(params.pageName)
      }
      if (params.arguments) {
        builder.setArguments(params.arguments)
      }
      if (params.opaque) {
        builder.setOpaque(params.opaque)
      }
      if (params.uniqueId) {
        builder.setUniqueId(params.uniqueId)
      }
      this.delegate.pushFlutterRoute(builder.build());
    } else {
      throw new Error("FlutterBoostPlugin might *NOT* set delegate!");
    }
  }

  onPopRoute(params: CommonParams, completion: () => void) {
    if (this.isTraceEnabled()) Log.i(TAG, `#onPopRoute: ${JSON.stringify(params, this.bigIntReplacer)}`);
    if (this.delegate) {
      const options: FlutterBoostRouteOptions = new FlutterBoostRouteOptionsBuilder()
                                                  .setPageName(params.pageName ?? '')
                                                  .setUniqueId(params.uniqueId!)
                                                  .setArguments(params.arguments ?? {})
                                                  .build();
      let isHandled: boolean = this.delegate.popRoute(options);
      if (isHandled) {
        completion();
      } else {
        const uniqueId = params.uniqueId;
        if (uniqueId) {
          const container = FlutterContainerManager.getInstance().findContainerById(uniqueId);
          if (container) {
            container.finishContainer(params.arguments ? params.arguments : {})
            completion();
          } else {
            throw new Error("Oops!! Can not find the page. uniqueId:" + uniqueId);
          }
        } else {
          throw new Error(`Oops!! The unique id is invalid: ${uniqueId}`);
        }
      }
    } else {
      throw new Error("FlutterBoostPlugin might *NOT* set delegate!");
    }
  }

  onGetStackFromHost(): StackInfo {
    if (this.isTraceEnabled()) Log.i(TAG, "#getStackFromHost: " + this.dartStack)
    return this.dartStack
  }

  onSaveStackToHost(args: StackInfo) {
    if (this.isTraceEnabled()) Log.i(TAG, "#saveStackToHost: " + this.dartStack);
    this.dartStack = args;
  }

  onSendEventToNative(params: CommonParams) {
    // Handle events from Flutter side
    const key = params.key
    let args: Record<string, Object> = params.arguments ? params.arguments : {}
    if (!key) {
      throw new Error("Key cannot be null");
    }
    if (!arguments) {
      args = {} // Use empty object instead of HashMap
    }
    const listeners = this.listenersTable[key];
    if (!listeners) {
      return;
    }
    listeners.forEach((listener) => {
      listener.onEvent(key, args);
    });
  }

  // NativeRouterApi override ==> end

  // public method
  public getChannel(): FlutterRouterApi | null {
    return this.channel
  }

  // public method
  public setDelegate(delegate: FlutterBoostDelegate) {
    this.delegate = delegate;
  }

  // public method
  public getDelegate(): FlutterBoostDelegate | null {
    return this.delegate
  }

  // public method
  public onBackPressed() {
    if (this.isTraceEnabled()) Log.i(TAG, "#onBackPressed");
    if (this.channel) {
      this.checkEngineState();
      this.channel.onBackPressed(() => {
      });
    } else {
      throw new Error("FlutterBoostPlugin might *NOT* have attached to engine yet!");
    }
  }

  addEventListener(key: string, listener: EventListener): ListenerRemover {
    if (!key || !listener) {
      throw new Error("Key and listener cannot be null");
    }

    let listeners = this.listenersTable[key];
    if (!listeners) {
      listeners = [];
      this.listenersTable[key] = listeners;
    }
    listeners.push(listener);

    // Return an object that conforms to the ListenerRemover interface
    return {
      remove: () => {
        const index = listeners.indexOf(listener);
        if (index !== -1) {
          listeners.splice(index, 1);
        }
      }
    }
  }

  /*
   * Send pushRoute event to Flutter side
   * */
  public pushRoute(uniqueId: string, pageName: string, args: Record<string, Object>, callback: () => void) {
    if (this.isTraceEnabled()) Log.i(TAG, "#pushRoute start: " + pageName);
    const timestamp = (new Date()).getTime();
    if (this.channel) {
      this.checkEngineState();
      let params = new CommonParams()
      params.uniqueId = uniqueId
      params.pageName = pageName
      params.arguments = args
      this.channel.pushRoute(params, () => {
        if (this.isTraceEnabled()) Log.i(TAG, "#pushRoute end: " + pageName + ", cost: " + ((new Date()).getTime()-timestamp) + "ms.");
        if (callback) {
          callback();
        }
      })
    } else {
      throw new Error('pushRoute fail.this.channel is null')
    }
  }

  /*
   * Send popRoute event to Flutter side
   * */
  public popRoute(uniqueId: string, callback: () => void) {
    if (this.isTraceEnabled()) Log.i(TAG, "#popRoute: " + uniqueId);
    if (this.channel != null) {
      this.checkEngineState();
      let params = new CommonParams()
      params.uniqueId = uniqueId
      this.channel.popRoute(params, () => {
        if (callback) {
          callback();
        }
      });
    } else {
      throw new Error("FlutterBoostPlugin might *NOT* have attached to engine yet!");
    }
  }

  // public method
  // Create [1/4]
  public onContainerCreated(container: FlutterViewContainer) {
    let uniqueId = container.getUniqueId()
    if (this.isTraceEnabled()) Log.i(TAG, "#onContainerCreated: " + uniqueId);
    FlutterContainerManager.getInstance().addContainer(uniqueId, container);
    if (FlutterContainerManager.getInstance().getContainerSize() == 1) {
      this.changeFlutterAppLifecycle(FlutterBoostPlugin.FLUTTER_APP_STATE_RESUMED);
    }
  }

  // Show [2/4]
  public onContainerAppeared(container: FlutterViewContainer, callback: () => void) {
    let uniqueId = container.getUniqueId()
    if (this.isTraceEnabled()) Log.i(TAG, "## onContainerAppeared: " + uniqueId);
    FlutterContainerManager.getInstance().activateContainer(uniqueId, container)
    // Align with Android here. Combine pushRoute+onContainerShow together
    this.pushRoute(uniqueId, container.getUrl(), container.getUrlParams(), () => {
      if (FlutterContainerManager.getInstance().isTopContainer(uniqueId)) {
          if (callback) {
            callback();
          }
      }
    })
    this._sendContainerShow(uniqueId);
  }

  // Hide [3/4]
  public onContainerDisappeared(container: FlutterViewContainer) {
    let uniqueId = container.getUniqueId()
    if (this.isTraceEnabled()) Log.i(TAG, "## onContainerDisappeared: " + uniqueId);
    let args: Record<string, Object>;
    if (container && container.paramsForDisappear) {
      args = container!.paramsForDisappear() ? container!.paramsForDisappear()! : {};
    } else {
      args = {};
    }

    this._sendContainerHide(uniqueId, args);
  }

  // Destroy [4/4]
  public onContainerDestroyed(container: FlutterViewContainer, callback?: () => void) {
    let uniqueId = container.getUniqueId()
    if (this.isTraceEnabled()) Log.i(TAG, "## onContainerDestroyed: " + uniqueId);
    let args = container.getUrlParams()
    // 1. Send remove message to dart side
    this._sendRemoveRoute(uniqueId, args, () => {
      if (callback) {
        callback()
      }
    });
    // 2. Remove container from FlutterContainerManager
    FlutterContainerManager.getInstance().removeContainer(uniqueId);
  }

  /**
   * Change Flutter app lifecycle state
   * @param state State value
   */
  public changeFlutterAppLifecycle(state: Number) {
    // assert (state == FLUTTER_APP_STATE_PAUSED || state == FLUTTER_APP_STATE_RESUMED);
    let args: Record<string, Object> = {}
    args[FlutterBoostPlugin.LIFECYCLE_STATE] = state;
    this.sendEventToFlutter(FlutterBoostPlugin.APP_LIFECYCLE_CHANGED_KEY, args);
  }

  /**
   * Send event to Flutter
   * @param key Event key
   * @param args Event arguments
   */
  public sendEventToFlutter(key: string, args: Record<string, Object>) {
    if (this.channel) {
      let params = new CommonParams();
      params.key = key;
      params.arguments = args as Record<string, Object>;
      this.channel.sendEventToFlutter(params, () => {});
    } else {
      throw new Error("FlutterBoostPlugin might *NOT* have attached to engine yet!");
    }
  }

  public onForeground() {
    if (this.isTraceEnabled()) Log.d(TAG, "## onForeground start");
    if (this.channel != null) {
      this.checkEngineState();
      let params = new CommonParams()
      this.channel.onForeground(params, () => {
        if (this.isTraceEnabled()) Log.d(TAG, "## onForeground end");
      });

      // The scheduling frames are resumed when [onForeground] is called.
      this.changeFlutterAppLifecycle(FlutterBoostPlugin.FLUTTER_APP_STATE_RESUMED);
    } else {
      throw new Error("FlutterBoostPlugin might *NOT* have attached to engine yet!");
    }
  }

  public onBackground() {
    if (this.isTraceEnabled()) Log.d(TAG, "## onBackground start");
    if (this.channel != null) {
      this.checkEngineState();
      let params = new CommonParams()
      this.channel.onBackground(params, () => {
        if (this.isTraceEnabled()) Log.d(TAG, "## onBackground end");
      });

      // The scheduling frames are paused when [onBackground] is called.
      this.changeFlutterAppLifecycle(FlutterBoostPlugin.FLUTTER_APP_STATE_PAUSED);
    } else {
      throw new Error("FlutterBoostPlugin might *NOT* have attached to engine yet!");
    }
  }

  private _sendContainerShow(uniqueId: string) {
    if (this.isTraceEnabled()) Log.i(TAG, "## _sendContainerShow: " + uniqueId);
    // Send onContainerShow message to flutter side
    if (this.channel) {
      this.checkEngineState();
      let params = new CommonParams()
      params.uniqueId = uniqueId
      this.channel.onContainerShow(params, () => {
      });
    } else {
      throw new Error("FlutterBoostPlugin might *NOT* have attached to engine yet! When call _onContainerShow");
    }
  }

  private _sendContainerHide(uniqueId: string, args: Record<string, Object>) {
    if (this.isTraceEnabled()) Log.i(TAG, "## _sendContainerHide: " + uniqueId);
    // Send onContainerHide message to flutter side
    if (this.channel) {
      this.checkEngineState();
      let params = new CommonParams();
      params.uniqueId = uniqueId;
      params.arguments = args;
      this.channel.onContainerHide(params, () => {
      });
    } else {
      throw new Error("FlutterBoostPlugin might *NOT* have attached to engine yet! When call _onContainerHide");
    }
  }

  private _sendRemoveRoute(uniqueId: string, args: Record<string, Object>, callback: () => void) {
    if (this.isTraceEnabled()) Log.i(TAG, "## _sendRemoveRoute: " + uniqueId);
    // Send _sendRemoveRoute message to flutter side
    if (this.channel) {
      this.checkEngineState();
      let params = new CommonParams()
      params.uniqueId = uniqueId
      params.arguments = args
      this.channel.removeRoute(params, () => {
        if (callback) {
          callback()
        }
      });
    } else {
      throw new Error("FlutterBoostPlugin might *NOT* have attached to engine yet! When call _removeRoute");
    }
  }

  private checkEngineState() {
    if (!this.engine || !this.engine.getDartExecutor().isExecutingDart()) {
      throw new Error("The engine is not ready for use. " +
        "The message may be drop silently by the engine. " +
        "You should check 'DartExecutor.isExecutingDart()' first!");
    }
  }

  private onPageResult(pageName: string, result: Record<string, Object>) {
    if (this.channel) {
      this.checkEngineState();
      let params = new CommonParams();
      if (pageName) {
        params.pageName = pageName;
        if (result) {
          params.arguments = result;
        }

        // Get a result back from an page when it ends.
        this.channel.onNativeResult(params, () => {
          if (this.isTraceEnabled()) Log.d(TAG, "#onNativeResult return, pageName=" + pageName + ", " + this);
        });
      }
    } else {
      throw new Error("FlutterBoostPlugin might *NOT* have attached to engine yet!");
    }
  }

  private bigIntReplacer(key: string, value: Object): Object {
    if (typeof value === 'bigint') {
      return value.toString();
    }
    return value;
  }
}