#import <UIKit/UIKit.h>

@class HAVerificationViewController;

@protocol HAVerificationViewControllerDelegate <NSObject>
- (void)verificationViewController:(HAVerificationViewController *)controller
                     didSubmitCode:(NSString *)code;
- (void)verificationViewControllerDidCancel:(HAVerificationViewController *)controller;
@end

@interface HAVerificationViewController : UIViewController <UITextFieldDelegate>
@property(nonatomic, assign) id<HAVerificationViewControllerDelegate> delegate;
- (id)initWithMessage:(NSString *)message;
@end

