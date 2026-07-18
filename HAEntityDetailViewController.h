#import <UIKit/UIKit.h>

@interface HAEntityDetailViewController : UIViewController
- (id)initWithEntity:(NSDictionary *)entity
        baseURLString:(NSString *)baseURLString
           accessToken:(NSString *)accessToken;
@end
