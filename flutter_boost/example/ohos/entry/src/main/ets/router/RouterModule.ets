
export class RouterOptions {
    constructor(uri: string, params: Record<string, Object>, uniqueId: string | null) {
        this.uri = uri;
        this.params = params;
        this.uniqueId = uniqueId;
    }
    // !!! In custom route parameters, make sure the names of uri, params, uniqueId are consistent with the example !!!
    uri: string;
    params: Record<string, Object>;
    uniqueId: string | null = null;  // !!! Custom route parameters must include uniqueId to avoid losing uniqueId passed from dart side !!!
}

export class RouterModule {
    static routeStack: NavPathStack | null = null;

    public static setRouteStack(stack: NavPathStack): void {
        RouterModule.routeStack = stack;
    }

    public static push(name: string, options: RouterOptions | Record<string, Object> = {}, onPageResult?: (pageName: string, result: Record<string, Object>) => void): void {
        if (RouterModule.routeStack != null) {
            RouterModule.routeStack.pushPath({name: name, param: options, onPop: (popInfo: PopInfo) => {
              if (onPageResult) {
                // If the previous page is a flutter page, make sure to cast popInfo.result to Record<string, Object> !!!
                onPageResult((options instanceof RouterOptions) ? (options as RouterOptions).uri : name,
                    (popInfo && popInfo.result) ? (popInfo.result as Record<string, Object>) : ({} as Record<string, Object>));
              }
            }});
        } else {
            throw new Error('routeStack is null!');
        }
    }

    public static pop(result: Record<string, Object> = {}): void {
        if (RouterModule.routeStack != null) {
            RouterModule.routeStack.pop(result);
        } else {
            throw new Error('routeStack is null!');
        }
    }
}