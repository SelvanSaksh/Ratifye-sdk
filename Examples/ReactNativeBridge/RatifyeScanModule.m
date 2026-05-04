#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(RatifyeScan, NSObject)

RCT_EXTERN_METHOD(scan:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

@end
