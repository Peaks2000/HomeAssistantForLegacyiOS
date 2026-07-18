#import <UIKit/UIKit.h>

@class HASettingsViewController;

@protocol HASettingsViewControllerDelegate <NSObject>
- (void)settingsViewController:(HASettingsViewController *)controller didAddHome:(NSDictionary *)home;
@end

@interface HASettingsViewController : UIViewController <UITextFieldDelegate>
@property(nonatomic, assign) id<HASettingsViewControllerDelegate> delegate;
- (id)initForAddingHome;
@end
