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
import common from '@ohos.app.ability.common';
import {
  FlutterEngine,
  FlutterEngineCache,
  FlutterInjector,
  PlatformViewsController
} from '@ohos/flutter_ohos';
import { DartEntrypoint } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/dart/DartExecutor';
import CommonParams from './messages/CommonParams';
import FlutterBoostDelegate from './FlutterBoostDelegate';
import FlutterBoostUtils from './FlutterBoostUtils';
import { FlutterBoostRouteOptionsBuilder } from './FlutterBoostRouteOptions';
import { FlutterBoostSetupOptions } from './FlutterBoostSetupOptions';
import { FlutterBoostPlugin } from './plugin/FlutterBoostPlugin';
import FlutterContainerManager from './containers/FlutterContainerManager';
import { FlutterViewContainer } from './containers/FlutterViewContainer';
import Log from './util/Log';

const TAG = "FlutterBoost";

/**
 * FlutterBoost core class
 *
 * Implementing NativeRouterApi is for users to receive messages from dart side
 */
export class FlutterBoost {
  private static instance: FlutterBoost;
  public static ENGINE_ID = 'flutter_boost_default_engine'

  private flutterEngine: FlutterEngine | null = null
  private delegate: FlutterBoostDelegate | null = null
  private plugin: FlutterBoostPlugin | null = null
  private isInBackground: boolean = false;

  public static getInstance(): FlutterBoost {
    if (!FlutterBoost.instance) {
      FlutterBoost.instance = new FlutterBoost();
    }
    return FlutterBoost.instance;
  }

  public isAppInBackground(): boolean {
    return this.isInBackground;
  }

  /**
   * Set FlutterBoost configuration information
   * @param delegate FlutterBoost delegate object
   * @param context Context object
   * @param onEngineReady Callback function
   * @param options FlutterBoost configuration options
   */
  public async setup(delegate: FlutterBoostDelegate,
                     context: common.Context,
                     onEngineReady: (engine: FlutterEngine) => void,
                     options: FlutterBoostSetupOptions | null) {

    this.delegate = delegate;

    if (options == null) {
      // Specify default settings (initial route is /, entry point is main)
      options = FlutterBoostSetupOptions.createDefault();
    }
    FlutterBoostUtils.setDebugLoggingEnabled(options.isDebugLoggingEnabled());

    // 1. Initialize engine
    let engine: FlutterEngine | null = this.getEngine()
    if (engine == null) {
      const engineProvider = options.getFlutterEngineProvider();
      if (engineProvider) {
        engine = engineProvider.provideFlutterEngine(context);
      }
      if (engine == null) {
        engine = new FlutterEngine(context, null, null, new PlatformViewsController());
        await engine.init(context, options.getShellArgs(), true);
      }
      FlutterEngineCache.getInstance().put(FlutterBoost.ENGINE_ID, engine);
    }
    this.flutterEngine = engine;

    // 2. Notify business that engine is ready
    onEngineReady(engine);

    // 3. Set message channel message delegate
    this.getPlugin()!.setDelegate(this.delegate);

    // 4. DartVM pre-warm
    if (!engine.getDartExecutor().isExecutingDart()) {
      const navigationChannel = engine.getNavigationChannel()
      if (navigationChannel) {
        navigationChannel.setInitialRoute(options.getInitialRoute())
      }
      // TODO: Not fully aligned here
      const dartEntrypoint: DartEntrypoint = new DartEntrypoint(
        FlutterInjector.getInstance().getFlutterLoader().findAppBundlePath(),
        '',
        options.getDartEntrypoint()
      );
      engine.getDartExecutor().executeDartEntrypoint(dartEntrypoint, options.getDartEntrypointArgs());
    }
  }


  /**
   * Set FlutterBoost configuration information (Promise)
   * @param delegate FlutterBoost delegate object
   * @param context Context object
   * @param options FlutterBoost configuration options
   */
  public setupSync(delegate: FlutterBoostDelegate,
                   context: common.Context,
                   options: FlutterBoostSetupOptions | null): Promise<FlutterEngine> {
    return new Promise<FlutterEngine>((resolve, reject) => {
      try {
        this.setup(delegate, context, (engine: FlutterEngine) => {
          resolve(engine);
        }, options)
      } catch (error) {
        // If an error occurs, reject the Promise
        reject(error);
      }
    });
  }

  /**
   * Open page
   * @param pageName Page name
   * @param param Parameters
   */
  public open(pageName: string, param: Record<string, Object>, opaque?: boolean, onPageResult?: (pageName: string, result: Record<string, Object>) => void) {
    let options = new FlutterBoostRouteOptionsBuilder()
      .setPageName(pageName)
      .setArguments(param)
      .setOpaque(opaque ?? true)
      .build();
    const plugin: FlutterBoostPlugin | null = this.getPlugin()
    if (plugin) {
      const delegate = plugin.getDelegate() as FlutterBoostDelegate;
      if (delegate) {
        delegate.pushFlutterRoute(options, onPageResult);
      } else {
        Log.e(TAG, 'open fail. get delegate fail! Maybe setup function has not been invoked.');
      }
    } else {
      Log.e(TAG, 'open fail. get plugin fail! Maybe setup function has not been invoked.');
    }
  }

  /**
   * Get engine object
   * @returns Engine object, returns null if not exists
   */
  public getEngine(): FlutterEngine | null {
    return FlutterEngineCache.getInstance().get(FlutterBoost.ENGINE_ID);
  }

  /**
   * Get plugin object
   * @returns {FlutterBoostPlugin | null} Plugin object or null
   */
  public getPlugin(): FlutterBoostPlugin | null {
    if (this.plugin == null) {
      let engine = this.getEngine();
      if (engine) {
        const plugin: FlutterBoostPlugin | null = FlutterBoostUtils.getPlugin(engine);
        if (plugin != null) {
          this.plugin = plugin;
        } else {
          throw new Error('Oops! Failed to get |FlutterBoostPlugin|.')
        }
      } else {
        Log.e(TAG, 'Oops! Failed to get |FlutterEngine|. Maybe setup function has not been invoked.');
      }
    }
    return this.plugin;
  }

  /**
   * Send event to Flutter
   * @param key Event key
   * @param args Event arguments
   */
  public sendEventToFlutter(key: string, args: Record<string, Object>) {
    this.getPlugin()?.sendEventToFlutter(key, args);
  }

  /**
   * Ability has brought to foreground
   */
  public onBackground() {
    this.isInBackground = true;
    this.getPlugin()?.onBackground();
  }

  /**
   * Ability has back to background
   */
  public onForeground() {
    this.getPlugin()?.onForeground();
    this.isInBackground = false;
  }

  public isTopContainer(container: FlutterViewContainer): boolean {
    return FlutterContainerManager.getInstance().getTopContainer() == container;
  }
}