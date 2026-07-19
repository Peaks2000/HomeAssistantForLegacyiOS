#import "HAWatchManager.h"
#import "HAHomeManager.h"
#import "HAWatchServiceRequest.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
#import <WatchConnectivity/WatchConnectivity.h>

@interface HAWatchManager () <WCSessionDelegate>
@property(nonatomic, retain) WCSession *session;
@property(nonatomic, retain) NSArray *entities;
@end
#endif

@implementation HAWatchManager

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
@synthesize session = _session;
@synthesize entities = _entities;
#endif

+ (HAWatchManager *)sharedManager {
    static HAWatchManager *manager = nil;
    if (manager == nil) {
        manager = [[HAWatchManager alloc] init];
    }
    return manager;
}

- (void)start {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    if (NSClassFromString(@"WCSession") == nil || ![WCSession isSupported]) {
        return;
    }
    self.session = [WCSession defaultSession];
    self.session.delegate = self;
    [self.session activateSession];
#endif
}

- (void)updateEntities:(NSArray *)entities {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    NSMutableArray *watchEntities = [NSMutableArray array];
    for (NSDictionary *entity in entities) {
        NSString *entityID = [entity objectForKey:@"entity_id"];
        NSString *state = [entity objectForKey:@"state"];
        NSDictionary *attributes = [entity objectForKey:@"attributes"];
        if ([entityID length] == 0 || [state length] == 0) {
            continue;
        }
        NSMutableDictionary *watchEntity = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            entityID, @"entity_id",
            state, @"state",
            [attributes objectForKey:@"friendly_name"] ?: entityID, @"name",
            nil];
        id brightness = [attributes objectForKey:@"brightness"];
        if ([brightness isKindOfClass:[NSNumber class]]) {
            [watchEntity setObject:brightness forKey:@"brightness"];
        }
        [watchEntities addObject:watchEntity];
    }
    self.entities = watchEntities;
    [self syncCurrentContext];
#endif
}

- (void)syncCurrentContext {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    if (self.session == nil) {
        return;
    }
    NSDictionary *home = [HAHomeManager selectedHome];
    if (home == nil) {
        return;
    }
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys:
        @1, @"protocol_version",
        [home objectForKey:HAHomeIdentifierKey] ?: @"", @"home_id",
        [home objectForKey:HAHomeNameKey] ?: @"Home", @"home_name",
        [HAHomeManager selectedEntityIDs], @"selected_entity_ids",
        self.entities ?: [NSArray array], @"entities",
        nil];
    [self.session updateApplicationContext:context error:nil];
#endif
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
- (void)session:(WCSession *)session
    activationDidCompleteWithState:(WCSessionActivationState)activationState
                             error:(NSError *)error {
    if (error == nil) {
        [self syncCurrentContext];
    }
}

- (void)sessionDidBecomeInactive:(WCSession *)session {
}

- (void)sessionDidDeactivate:(WCSession *)session {
    [session activateSession];
}

- (void)session:(WCSession *)session
    didReceiveMessage:(NSDictionary<NSString *, id> *)message
         replyHandler:(void (^)(NSDictionary<NSString *, id> *replyMessage))replyHandler {
    if (![[message objectForKey:@"type"] isEqualToString:@"call_service"]) {
        replyHandler([NSDictionary dictionaryWithObjectsAndKeys:
            @NO, @"ok", @"Unsupported watch message.", @"message", nil]);
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *home = [HAHomeManager selectedHome];
        NSString *requestedHomeID = [message objectForKey:@"home_id"];
        if (home == nil || ![[home objectForKey:HAHomeIdentifierKey] isEqualToString:requestedHomeID]) {
            replyHandler([NSDictionary dictionaryWithObjectsAndKeys:
                @NO, @"ok", @"Open the selected home on the iPhone first.", @"message", nil]);
            return;
        }
        HAWatchServiceRequest *request = [[[HAWatchServiceRequest alloc]
            initWithHome:home message:message replyHandler:replyHandler] autorelease];
        [request start];
    });
}
#endif

- (void)dealloc {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    _session.delegate = nil;
    [_session release];
    [_entities release];
#endif
    [super dealloc];
}

@end
