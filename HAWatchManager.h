#import <Foundation/Foundation.h>

@interface HAWatchManager : NSObject
+ (HAWatchManager *)sharedManager;
- (void)start;
- (void)updateEntities:(NSArray *)entities;
- (void)syncCurrentContext;
@end
