#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(RatifyeMultiScanViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(multiScanEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(authScanEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(onScanEvent, RCTDirectEventBlock)

@end
