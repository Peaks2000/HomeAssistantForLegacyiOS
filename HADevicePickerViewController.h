#import <UIKit/UIKit.h>

@class HADevicePickerViewController;

@protocol HADevicePickerViewControllerDelegate <NSObject>
- (void)devicePicker:(HADevicePickerViewController *)picker didAddEntityID:(NSString *)entityID;
- (void)devicePickerDidCancel:(HADevicePickerViewController *)picker;
@end

@interface HADevicePickerViewController : UITableViewController <UISearchBarDelegate>
@property(nonatomic, assign) id<HADevicePickerViewControllerDelegate> delegate;
- (id)initWithEntities:(NSArray *)entities;
@end

