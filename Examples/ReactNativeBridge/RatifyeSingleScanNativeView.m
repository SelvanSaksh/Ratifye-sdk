#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(RatifyeSingleScanViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(singleScanEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(authScanEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(onScanEvent, RCTDirectEventBlock)

@end
