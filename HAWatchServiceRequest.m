#import "HAWatchServiceRequest.h"
#import "HAHomeManager.h"
#import "HAURLCompatibility.h"

@interface HAWatchServiceRequest () <NSURLConnectionDataDelegate>
@property(nonatomic, retain) NSDictionary *home;
@property(nonatomic, retain) NSDictionary *message;
@property(nonatomic, copy) HAWatchReplyHandler replyHandler;
@property(nonatomic, retain) NSURLConnection *connection;
@property(nonatomic, retain) NSMutableData *responseData;
@property(nonatomic, assign) NSInteger statusCode;
@end

@implementation HAWatchServiceRequest

@synthesize home = _home;
@synthesize message = _message;
@synthesize replyHandler = _replyHandler;
@synthesize connection = _connection;
@synthesize responseData = _responseData;
@synthesize statusCode = _statusCode;

- (id)initWithHome:(NSDictionary *)home
           message:(NSDictionary *)message
      replyHandler:(HAWatchReplyHandler)replyHandler {
    self = [super init];
    if (self) {
        self.home = home;
        self.message = message;
        self.replyHandler = replyHandler;
    }
    return self;
}

- (void)start {
    [self retain];
    NSString *domain = [self.message objectForKey:@"domain"];
    NSString *service = [self.message objectForKey:@"service"];
    NSString *entityID = [self.message objectForKey:@"entity_id"];
    if (![self isAllowedService:service domain:domain] || [entityID length] == 0) {
        [self finishWithSuccess:NO message:@"Unsupported watch action."];
        return;
    }

    NSString *baseURL = [self.home objectForKey:HAHomeBaseURLKey];
    NSString *accessToken = [HAHomeManager accessTokenForBaseURLString:baseURL];
    NSString *path = [NSString stringWithFormat:@"/api/services/%@/%@", domain, service];
    NSMutableURLRequest *request = HAMutableURLRequestWithURL(
        HAURLWithString([baseURL stringByAppendingString:path]));
    if (request == nil || [accessToken length] == 0) {
        [self finishWithSuccess:NO message:@"The selected home is not signed in."];
        return;
    }

    NSMutableDictionary *body = [NSMutableDictionary dictionaryWithObject:entityID forKey:@"entity_id"];
    NSDictionary *serviceData = [self.message objectForKey:@"service_data"];
    if ([serviceData isKindOfClass:[NSDictionary class]]) {
        [body addEntriesFromDictionary:serviceData];
    }
    request.HTTPMethod = @"POST";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", accessToken]
        forHTTPHeaderField:@"Authorization"];
    self.responseData = [NSMutableData data];
    self.connection = HAStartURLConnection(request, self);
    if (self.connection == nil) {
        [self finishWithSuccess:NO message:@"Could not contact Home Assistant."];
    }
}

- (BOOL)isAllowedService:(NSString *)service domain:(NSString *)domain {
    NSDictionary *allowedServices = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSArray arrayWithObjects:@"toggle", @"turn_on", @"turn_off", nil], @"homeassistant",
        [NSArray arrayWithObjects:@"turn_on", @"turn_off", nil], @"light",
        [NSArray arrayWithObjects:@"turn_on", @"turn_off", nil], @"switch",
        [NSArray arrayWithObjects:@"lock", @"unlock", nil], @"lock",
        [NSArray arrayWithObjects:@"open_cover", @"stop_cover", @"close_cover", nil], @"cover",
        [NSArray arrayWithObject:@"turn_on"], @"scene",
        [NSArray arrayWithObject:@"turn_on"], @"script",
        [NSArray arrayWithObject:@"turn_on"], @"automation",
        [NSArray arrayWithObject:@"press"], @"button",
        nil];
    return [[allowedServices objectForKey:domain] containsObject:service];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.responseData setLength:0];
    self.statusCode = [response respondsToSelector:@selector(statusCode)]
        ? [(id)response statusCode]
        : 0;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    BOOL success = self.statusCode >= 200 && self.statusCode < 300;
    [self finishWithSuccess:success
                    message:success ? @"Action completed." : @"Home Assistant rejected the action."];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self finishWithSuccess:NO message:[error localizedDescription]];
}

- (void)finishWithSuccess:(BOOL)success message:(NSString *)message {
    self.connection = nil;
    self.responseData = nil;
    if (self.replyHandler != nil) {
        self.replyHandler([NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithBool:success], @"ok",
            message ?: @"", @"message",
            nil]);
    }
    self.replyHandler = nil;
    [self release];
}

- (void)dealloc {
    [_connection cancel];
    [_connection release];
    [_responseData release];
    [_replyHandler release];
    [_message release];
    [_home release];
    [super dealloc];
}

@end
