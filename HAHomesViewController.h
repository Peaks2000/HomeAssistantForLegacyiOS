#import <UIKit/UIKit.h>

@protocol HAHomesViewControllerDelegate <NSObject>
- (void)homesViewControllerDidChooseHome:(NSDictionary *)home;
@end

@interface HAHomesViewController : UITableViewController
@property(nonatomic, assign) id<HAHomesViewControllerDelegate> delegate;
@end
