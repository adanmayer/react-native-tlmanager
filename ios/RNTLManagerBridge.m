//
//  RNTLManagerBridge
//
//  Created by Alexander Danmayer on 12.12.18.
//  Copyright © 2018 Faria. All rights reserved.
//

#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(TLManager, NSObject)
RCT_EXTERN_METHOD(reloadVisitable)
RCT_EXTERN_METHOD(reloadSession)
RCT_EXTERN_METHOD(changeLocale:(NSString*))
RCT_EXTERN_METHOD(dismiss)
RCT_EXTERN_METHOD(popToRoot)
RCT_EXTERN_METHOD(back)
RCT_EXTERN_METHOD(backTo:(NSDictionary *))
RCT_EXTERN_METHOD(visit:(NSDictionary *))
RCT_EXTERN_METHOD(mountViewManager:(nonnull NSNumber *) route:(NSDictionary *) options:(NSDictionary *))
RCT_EXTERN_METHOD(unmountViewManager)
RCT_EXTERN_METHOD(showRNView:(NSString*) route:(NSDictionary *))
RCT_EXTERN_METHOD(showTabBarCustomizer)
RCT_EXTERN_METHOD(updateTabBar:(NSDictionary*))
RCT_EXTERN_METHOD(selectTabBarItem:(NSString*))
RCT_EXTERN_METHOD(updateShareAuthentication:(NSDictionary *))
RCT_EXTERN_METHOD(updateNavigation:(NSString*) actionButtons:(NSArray *) options:(NSDictionary *))
RCT_EXTERN_METHOD(executeAction:(NSDictionary *) resolve:(RCTPromiseResolveBlock *) reject:(RCTPromiseRejectBlock *))
RCT_EXTERN_METHOD(injectJavaScript:(NSString *) resolve:(RCTPromiseResolveBlock *) reject:(RCTPromiseRejectBlock *))
RCT_EXTERN_METHOD(injectJavaScriptWithTarget:(NSString *) script:(NSString *) resolve:(RCTPromiseResolveBlock *) reject:(RCTPromiseRejectBlock *))
RCT_EXTERN_METHOD(debugMsg:(NSString*))
RCT_EXTERN_METHOD(trackEvent:(NSString*) data:(NSDictionary *))
@end
