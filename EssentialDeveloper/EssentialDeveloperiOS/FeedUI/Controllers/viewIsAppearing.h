#import "Availability.h"

#if defined(__IPHONE_17_0)
#warning "The iOS 17+ SDK already has viewIsAppearing:"
#else

@import UIKit;

@interface UIViewController (UpcomingLifecycleMethods)

- (void)viewIsAppearing:(BOOL)animated API_AVAILABLE(ios(13.0), tvos(13.0)) API_UNAVAILABLE(watchos);

@end
#endif
