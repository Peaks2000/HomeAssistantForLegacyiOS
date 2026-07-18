#import <Foundation/Foundation.h>

@class HAAuthClient;

@protocol HAAuthClientDelegate <NSObject>
- (void)authClient:(HAAuthClient *)client didAuthenticateWithAccessToken:(NSString *)accessToken;
- (void)authClient:(HAAuthClient *)client didRequestVerificationCodeWithMessage:(NSString *)message;
- (void)authClient:(HAAuthClient *)client didFailWithMessage:(NSString *)message;
@end

@interface HAAuthClient : NSObject
@property(nonatomic, assign) id<HAAuthClientDelegate> delegate;
- (id)initWithBaseURLString:(NSString *)baseURLString;
- (void)authenticateUsername:(NSString *)username password:(NSString *)password;
- (void)submitVerificationCode:(NSString *)code;
@end
