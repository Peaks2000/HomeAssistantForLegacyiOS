#import "HAAuthClient.h"

typedef enum {
    HAAuthStageIdle,
    HAAuthStageCreateFlow,
    HAAuthStageSubmitCredentials,
    HAAuthStageExchangeCode
} HAAuthStage;

static NSString *const HAClientID = @"https://home-assistant.io/iOS";
static NSString *const HARedirectURI = @"homeassistant://auth-callback";

@interface HAAuthClient () <NSURLConnectionDataDelegate>
@property(nonatomic, copy) NSString *baseURLString;
@property(nonatomic, copy) NSString *username;
@property(nonatomic, copy) NSString *password;
@property(nonatomic, copy) NSString *flowID;
@property(nonatomic, retain) NSURLConnection *connection;
@property(nonatomic, retain) NSMutableData *responseData;
@property(nonatomic, assign) NSInteger statusCode;
@property(nonatomic, assign) HAAuthStage stage;
@end

@implementation HAAuthClient

@synthesize delegate = _delegate;
@synthesize baseURLString = _baseURLString;
@synthesize username = _username;
@synthesize password = _password;
@synthesize flowID = _flowID;
@synthesize connection = _connection;
@synthesize responseData = _responseData;
@synthesize statusCode = _statusCode;
@synthesize stage = _stage;

- (id)initWithBaseURLString:(NSString *)baseURLString {
    self = [super init];
    if (self) {
        while ([baseURLString hasSuffix:@"/"]) {
            baseURLString = [baseURLString substringToIndex:[baseURLString length] - 1];
        }
        self.baseURLString = baseURLString;
    }
    return self;
}

- (void)authenticateUsername:(NSString *)username password:(NSString *)password {
    self.username = username;
    self.password = password;
    self.stage = HAAuthStageCreateFlow;
    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:
        HAClientID, @"client_id",
        [NSArray arrayWithObjects:@"homeassistant", [NSNull null], nil], @"handler",
        HARedirectURI, @"redirect_uri",
        nil];
    [self startJSONRequestPath:@"/auth/login_flow" body:body];
}

- (void)submitVerificationCode:(NSString *)code {
    if ([self.flowID length] == 0 || self.stage != HAAuthStageSubmitCredentials) {
        [self fail:@"The two-factor login session has expired. Please sign in again."];
        return;
    }
    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:
        code ?: @"", @"code",
        HAClientID, @"client_id",
        nil];
    [self startJSONRequestPath:[@"/auth/login_flow/" stringByAppendingString:self.flowID] body:body];
}

- (void)startJSONRequestPath:(NSString *)path body:(NSDictionary *)body {
    NSError *jsonError = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];
    if (data == nil) {
        [self fail:@"Could not create the authentication request."];
        return;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self URLForPath:path]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = data;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [self startRequest:request];
}

- (void)startTokenRequestWithCode:(NSString *)code {
    self.stage = HAAuthStageExchangeCode;
    NSString *body = [NSString stringWithFormat:@"grant_type=authorization_code&code=%@&client_id=%@",
        [self formEncodedString:code], [self formEncodedString:HAClientID]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self URLForPath:@"/auth/token"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [self startRequest:request];
}

- (void)startRequest:(NSURLRequest *)request {
    [self.connection cancel];
    self.responseData = [NSMutableData data];
    self.connection = [[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES] autorelease];
    if (self.connection == nil) {
        [self fail:@"Could not connect to Home Assistant."];
    }
}

- (NSURL *)URLForPath:(NSString *)path {
    return [NSURL URLWithString:[self.baseURLString stringByAppendingString:path]];
}

- (NSString *)formEncodedString:(NSString *)value {
    CFStringRef encoded = CFURLCreateStringByAddingPercentEscapes(
        kCFAllocatorDefault,
        (CFStringRef)value,
        NULL,
        CFSTR(":/?#[]@!$&'()*+,;="),
        kCFStringEncodingUTF8);
    return [(NSString *)encoded autorelease];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.responseData setLength:0];
    self.statusCode = [response isKindOfClass:[NSHTTPURLResponse class]]
        ? [(NSHTTPURLResponse *)response statusCode]
        : 0;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSError *error = nil;
    id response = [NSJSONSerialization JSONObjectWithData:self.responseData options:0 error:&error];
    self.connection = nil;
    self.responseData = nil;
    if (![response isKindOfClass:[NSDictionary class]]) {
        [self fail:@"Home Assistant returned an unreadable authentication response."];
        return;
    }
    if (self.statusCode < 200 || self.statusCode >= 300) {
        NSString *message = [response objectForKey:@"message"] ?: [response objectForKey:@"error_description"];
        [self fail:message ?: @"Home Assistant rejected the authentication request."];
        return;
    }
    if (self.stage == HAAuthStageCreateFlow) {
        [self handleCreatedFlow:response];
    } else if (self.stage == HAAuthStageSubmitCredentials) {
        [self handleCredentialResult:response];
    } else if (self.stage == HAAuthStageExchangeCode) {
        [self handleTokenResult:response];
    }
}

- (void)handleCreatedFlow:(NSDictionary *)response {
    NSString *flowID = [response objectForKey:@"flow_id"];
    if ([flowID length] == 0) {
        [self fail:@"The built-in Home Assistant login provider is unavailable."];
        return;
    }
    self.flowID = flowID;
    self.stage = HAAuthStageSubmitCredentials;
    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:
        self.username ?: @"", @"username",
        self.password ?: @"", @"password",
        HAClientID, @"client_id",
        nil];
    [self startJSONRequestPath:[@"/auth/login_flow/" stringByAppendingString:flowID] body:body];
}

- (void)handleCredentialResult:(NSDictionary *)response {
    NSString *type = [response objectForKey:@"type"];
    NSString *code = [response objectForKey:@"result"];
    if ([type isEqualToString:@"create_entry"] && [code length] > 0) {
        self.password = nil;
        self.flowID = nil;
        [self startTokenRequestWithCode:code];
        return;
    }
    NSString *stepID = [response objectForKey:@"step_id"];
    if ([type isEqualToString:@"form"] && [stepID isEqualToString:@"mfa"]) {
        self.password = nil;
        NSDictionary *errors = [response objectForKey:@"errors"];
        NSString *message = [[errors objectForKey:@"base"] isEqualToString:@"invalid_code"]
            ? @"That verification code was invalid. Enter a new code."
            : @"Enter the verification code from your authenticator or notification.";
        [self.delegate authClient:self didRequestVerificationCodeWithMessage:message];
        return;
    }
    if ([type isEqualToString:@"form"] && [stepID isEqualToString:@"select_mfa_module"]) {
        [self fail:@"This account has multiple two-factor methods. Selecting between them is not supported yet."];
        return;
    }
    NSDictionary *errors = [response objectForKey:@"errors"];
    NSString *errorCode = [errors objectForKey:@"base"];
    if ([errorCode isEqualToString:@"invalid_auth"]) {
        [self fail:@"The username or password is incorrect."];
    } else {
        [self fail:@"Home Assistant requires an authentication step this app does not support yet."];
    }
}

- (void)handleTokenResult:(NSDictionary *)response {
    NSString *accessToken = [response objectForKey:@"access_token"];
    NSString *refreshToken = [response objectForKey:@"refresh_token"];
    if ([accessToken length] == 0 || [refreshToken length] == 0) {
        [self fail:@"Home Assistant did not return valid tokens."];
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:accessToken forKey:@"HAAccessToken"];
    [defaults setObject:refreshToken forKey:@"HARefreshToken"];
    [defaults synchronize];
    self.username = nil;
    self.password = nil;
    self.flowID = nil;
    self.stage = HAAuthStageIdle;
    [self.delegate authClient:self didAuthenticateWithAccessToken:accessToken];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.connection = nil;
    self.responseData = nil;
    [self fail:[NSString stringWithFormat:@"Connection failed: %@", [error localizedDescription]]];
}

- (void)fail:(NSString *)message {
    self.username = nil;
    self.password = nil;
    self.flowID = nil;
    self.stage = HAAuthStageIdle;
    [self.delegate authClient:self didFailWithMessage:message];
}

- (void)dealloc {
    [_connection cancel];
    [_connection release];
    [_responseData release];
    [_baseURLString release];
    [_username release];
    [_password release];
    [_flowID release];
    [super dealloc];
}

@end
