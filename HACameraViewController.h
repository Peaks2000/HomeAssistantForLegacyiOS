#import <UIKit/UIKit.h>

@interface HACameraViewController : UIViewController <NSURLConnectionDataDelegate>
- (id)initWithEntity:(NSDictionary *)entity
        baseURLString:(NSString *)baseURLString
           accessToken:(NSString *)accessToken;
@end
