#import <Foundation/Foundation.h>

typedef void (^HAWatchReplyHandler)(NSDictionary *reply);

@interface HAWatchServiceRequest : NSObject
- (id)initWithHome:(NSDictionary *)home
           message:(NSDictionary *)message
      replyHandler:(HAWatchReplyHandler)replyHandler;
- (void)start;
@end
