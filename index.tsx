// Type definitions for react-native-tlmanager 1.0

import { NativeEventEmitter, NativeModules, processColor, Platform } from 'react-native'

const RNTLManager = NativeModules.TLManager // || android: NativeModules.RNTLModule
const RNTLManagerEmitter = new NativeEventEmitter(RNTLManager);

import { Image } from 'native-base';

export enum TLEventNames {
    Visit = "turbolinksVisit",
    VisitCompleted = "turbolinksVisitCompleted",
    Redirect = "turbolinksRedirect",
    Message = "turbolinksMessage",
    Error = "turbolinksError",
    TitlePress = "turbolinksTitlePress",
    ExecuteAction = "turbolinksExecuteAction",
    SessionFinished = "turbolinksSessionFinished",
    ViewMounted = "turbolinksViewMounted",
    ShowMenu = "turbolinksShowMenu",
    ActiveTabItemsChanged = "turbolinksActiveTabItemsChanged",
    AppBecomeActive = "turbolinksAppBecomeActive",
    AppResignActive = "turbolinksAppResignActive",
    RNViewAppear = "turbolinksRNViewAppear",
    RNViewDisappear = "turbolinksRNViewDisappear",
    Unmount = "turbolinksUnmount",
    RestoreState = "turbolinksRestoreState"
}

export enum TLScriptTarget {
    default   = 'default'
}

export enum TLRequestSource {
    generic = 'generic',
    tabBar  = 'tabBar',
    replaceLink = 'replaceLink', 
    subPageLink = 'subPageLink'
}

export interface TLAppOptions {
    userAgent?: string,
    locale: string,
    baseURL?: string,
    nativeBaseURL?: string,
    messageHandler?: string, 
    loadingView?: string, 
    leftView?: string, 
    rightView?: string,
    navBarStyle?: {
        barTintColor?: number,
        tintColor?: number, 
        textTextColor?: number,
        titleTextColor?: number,
        subtitleTextColor?: number
    }, 
    tabBarStyle?: {
        barTintColor?: number,
        tintColor?: number, 
    },
    shareAuthentication?: any}

export interface TLActionButton {
    name: string, 
    icon?: string,
    buttonIdx?: number
}

export interface TabBarEntry {
    id: string,
    title?: string, 
    icon?: string,
    href: string,
    badgeValue?: string,
}

export type TLActionButtons = Array<TLActionButton>
export type TabBarEntries = Array<TabBarEntry>

export interface TabBarConfig {
    menuIcon?: string, 
    items: TabBarEntries,
    activeItems: Array<string>,
    defaultItems: Array<string>
    selectedItem?: string
}

export interface TLRoute {
    title?: string,
    subtitle?: string, 
    titleImage?: Image,
    action?: string, 
    source?: TLRequestSource,
    href?: string, 
    leftButton?: TLActionButton
    actionButtons?: TLActionButtons
    popToRoot?: boolean
}

export class TLManager {

    appVersion(): string {
        return NativeModules.TLManager.appVersion
    }

    buildVersion(): string {
        return NativeModules.TLManager.buildVersion
    }

    releaseInfo(): string {
        return NativeModules.TLManager.releaseInfo
    }

    isBeta(): boolean {
        return (this.releaseInfo() == "beta")
    }

    isSimulator(): boolean {
        return (this.releaseInfo() == "simulator")
    }

    isProduction(): boolean {
        return (this.releaseInfo() == "production")
    }

    constructor() {
        // console.log('Turbolinks instance created')
    }


    isUnmounted(): boolean {
        return !RNTLManager.isMounted()
    }

    /*
        Mounting Turbolinks manager at a specific viewTag and initialize route with specific app options 
    */

    mountViewManager(viewTag: number, route: TLRoute, options: TLAppOptions) {
        options = this._processAppOptions(options)
        if (Platform.OS == 'ios') {
            RNTLManager.mountViewManager(viewTag, route, options)
        } else {
            RNTLManager.mountViewManager(route, options)
        }
    }

    /*
        Unmounting Turbolinks manager
    */
    unmountViewManager() {
        RNTLManager.unmountViewManager()
    }

    /*
        Change locale for I18n support
    */

    changeLocale(locale: string) {
        RNTLManager.changeLocale(locale)
    }

    /* 
        Show React Native view by moduleName and additional route options
    */
    showRNView(moduleName: string, route: TLRoute) {
        RNTLManager.showRNView(moduleName, route)
    }

    /*
        Show TabBar customization view to customize bottom tab bar
    */
    showTabBarCustomizer() {
        RNTLManager.showTabBarCustomizer()
    }

    /* 
        Update authentication eg.: for share extension
    */
    updateShareAuthentication(sharedValues: {}) {
        RNTLManager.updateShareAuthentication(sharedValues)
    }

    /* 
        Update navigation with title subMenuData and additional actionButtons (quick links, auxiliary page button)
    */
    updateNavigation(title: string, buttons: TLActionButtons, options: {}) {
        RNTLManager.updateNavigation(title, buttons, options)
    }

    /* 
        Selected navbar item
    */
    selectTabBarItem(item: string) {
        RNTLManager.selectTabBarItem(item)
    }

    /*
        Update TabBar with configuration data
    */
    updateTabBar(tabBarConfig: TabBarConfig) {
        RNTLManager.updateTabBar(tabBarConfig)
    }

    /* 
        Toggle, hide left menu view 
    */

    toggleLeftMenu(): Promise<any> {
        return this.executeAction('toggleLeftMenu')
    }

    showLeftMenu(): Promise<any> {
        return this.executeAction('showLeftMenu')
    }

    hideLeftMenu(): Promise<any> {
        return this.executeAction('hideLeftMenu')
    }

    executeAction(actionName: String): Promise<any> {
        return RNTLManager.executeAction({ action: actionName })
    }

    executeActionWithData(actionName: String, data: any): Promise<any> {
        return RNTLManager.executeAction({ action: actionName, data })
    }
    /* 

    /* 
        Turbolinks related functions
    */

    reloadVisitable() {
        RNTLManager.reloadVisitable()
    }

    reloadSession() {
        RNTLManager.reloadSession()
    }

    dismiss() {
        RNTLManager.dismiss()
    }

    popToRoot() {
        RNTLManager.popToRoot()
    }

    back() {
        RNTLManager.back()
    }

    backTo(route: TLRoute): Promise<any> {
        return RNTLManager.backTo(route)
    }

    visit(route: TLRoute): Promise<any> {
        return RNTLManager.visit(route)
    }

    debugMsg(message: string) {
        RNTLManager.debugMsg(message);
    }

    trackEvent(eventName: string, data: any) {
        RNTLManager.trackEvent(eventName, data);
    }

    showDialog(title: string, message: string, okButton: string): Promise<any> {
        return RNTLManager.showDialog(title, message, okButton);
    }

    showOkCancelDialog(title: string, message: string, okButton: string, cancelButton: String): Promise<boolean> {
        return RNTLManager.showOkCancelDialog(title, message, okButton, cancelButton);
    }

    showOptionDialog(title: string, message: string, okButton: string, neutralButton: String, cancelButton: String): Promise<string> {
        return RNTLManager.showOptionDialog(title, message, okButton, neutralButton, cancelButton);
    }

    async delay(ms: number) {
        return new Promise( resolve => setTimeout(resolve, ms) );
    }
    /*
        Inject javascript & execute into Turbolinks WebView
    */

    injectJavaScriptWithRetry(script: string, retries: number): Promise<any> {
        var promise: Promise<any> = new Promise(async (resolve, reject) => {
            var retryCount = retries
            var reqError : any
            var response : Response | null = null

            do {
                reqError = null
                try {
                    response = await this.injectJavaScript(script)
                } catch (error) {
                    reqError = error
                }
                if (reqError) {
                    await this.delay(500) // wait 500ms
                }
            } while ((retryCount-- > 0) && (reqError))

            if (!reqError && response) {
                resolve(response) 
            } else {
                reject(reqError)
            }
        })
        return promise
    }

    injectJavaScript(script: string): Promise<any> {
        if (Platform.OS == 'ios') {
            return RNTLManager.injectJavaScript(script)
        } else {
            return RNTLManager.injectJavaScript(script).then((r: any) => { 
                return JSON.parse(r)
            })
        }
    }

    injectJavaScriptWithTarget(target: string, script: string): Promise<any> {
        if (Platform.OS == 'ios') {
            return RNTLManager.injectJavaScriptWithTarget(target, script)
        } else {
            return RNTLManager.injectJavaScriptWithTarget(target, script).then((r: any) => {
                return JSON.parse(r)
            })
        }
    }

    /*
        Register to Turbolink events
    */

    addEventListener(eventName: TLEventNames, callback: (data: any) => void) {
        RNTLManagerEmitter.addListener(eventName, callback)
    }

    removeEventListener(eventName: TLEventNames, callback: (data: any) => void) {
        RNTLManagerEmitter.removeListener(eventName, callback)
    }
    
    _processAppOptions(options: TLAppOptions): TLAppOptions {
        var ops: TLAppOptions = options
        if (options.navBarStyle) {
            ops = {...options, navBarStyle: {
                    barTintColor: processColor(options.navBarStyle.barTintColor),
                    tintColor: processColor(options.navBarStyle.tintColor),
                    titleTextColor: processColor(options.navBarStyle.titleTextColor),
                    subtitleTextColor: processColor(options.navBarStyle.subtitleTextColor)
                }
            }
        }
        if (options.tabBarStyle) {
            ops = {
                ...options, tabBarStyle: {
                    barTintColor: processColor(options.tabBarStyle.barTintColor),
                    tintColor: processColor(options.tabBarStyle.tintColor)
                }
            }
        }
        return ops
    }
}

export const TLManagerSingleton = new TLManager();