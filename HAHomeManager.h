#import <Foundation/Foundation.h>

extern NSString *const HAHomeIdentifierKey;
extern NSString *const HAHomeNameKey;
extern NSString *const HAHomeBaseURLKey;
extern NSString *const HAHomeAccessTokenKey;
extern NSString *const HAHomeRefreshTokenKey;
extern NSString *const HAHomeSelectedEntityIDsKey;

@interface HAHomeManager : NSObject
+ (NSArray *)homes;
+ (NSDictionary *)selectedHome;
+ (NSDictionary *)saveHomeWithName:(NSString *)name
                      baseURLString:(NSString *)baseURLString
                        accessToken:(NSString *)accessToken
                       refreshToken:(NSString *)refreshToken;
+ (void)selectHomeWithIdentifier:(NSString *)identifier;
+ (void)removeHomeWithIdentifier:(NSString *)identifier;
+ (NSArray *)selectedEntityIDs;
+ (void)setSelectedEntityIDs:(NSArray *)entityIDs;
@end
