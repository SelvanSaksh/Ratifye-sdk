#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(RatifyeSingleScanViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(singleScanEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(authScanEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(ingestURL, NSString)
RCT_EXPORT_VIEW_PROPERTY(bearerToken, NSString)
RCT_EXPORT_VIEW_PROPERTY(apiKey, NSString)
RCT_EXPORT_VIEW_PROPERTY(companyId, NSString)
RCT_EXPORT_VIEW_PROPERTY(ingestFormat, NSString)
RCT_EXPORT_VIEW_PROPERTY(extraHTTPHeaders, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(onScanEvent, RCTDirectEventBlock)

@end
