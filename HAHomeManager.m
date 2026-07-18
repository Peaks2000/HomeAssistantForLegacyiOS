#import "HAHomeManager.h"

NSString *const HAHomeIdentifierKey = @"identifier";
NSString *const HAHomeNameKey = @"name";
NSString *const HAHomeBaseURLKey = @"base_url";
NSString *const HAHomeAccessTokenKey = @"access_token";
NSString *const HAHomeRefreshTokenKey = @"refresh_token";
NSString *const HAHomeSelectedEntityIDsKey = @"selected_entity_ids";

static NSString *const HAHomesDefaultsKey = @"HAHomes";
static NSString *const HASelectedHomeIdentifierDefaultsKey = @"HASelectedHomeIdentifier";

@implementation HAHomeManager

+ (void)migrateLegacyHomeIfNeeded {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[defaults arrayForKey:HAHomesDefaultsKey] count] > 0) {
        return;
    }
    NSString *baseURL = [defaults stringForKey:@"HABaseURL"];
    NSString *accessToken = [defaults stringForKey:@"HAAccessToken"];
    if ([baseURL length] == 0 || [accessToken length] == 0) {
        return;
    }
    NSString *identifier = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *name = [[NSURL URLWithString:baseURL] host] ?: @"Home";
    NSDictionary *home = [NSDictionary dictionaryWithObjectsAndKeys:
        identifier, HAHomeIdentifierKey,
        name, HAHomeNameKey,
        baseURL, HAHomeBaseURLKey,
        accessToken, HAHomeAccessTokenKey,
        [defaults stringForKey:@"HARefreshToken"] ?: @"", HAHomeRefreshTokenKey,
        [defaults arrayForKey:@"HAFavoriteEntityIDs"] ?: [NSArray array], HAHomeSelectedEntityIDsKey,
        nil];
    [defaults setObject:[NSArray arrayWithObject:home] forKey:HAHomesDefaultsKey];
    [defaults setObject:identifier forKey:HASelectedHomeIdentifierDefaultsKey];
    [defaults synchronize];
}

+ (NSArray *)homes {
    [self migrateLegacyHomeIfNeeded];
    return [[NSUserDefaults standardUserDefaults] arrayForKey:HAHomesDefaultsKey] ?: [NSArray array];
}

+ (NSDictionary *)selectedHome {
    NSArray *homes = [self homes];
    NSString *selectedIdentifier = [[NSUserDefaults standardUserDefaults]
        stringForKey:HASelectedHomeIdentifierDefaultsKey];
    for (NSDictionary *home in homes) {
        if ([[home objectForKey:HAHomeIdentifierKey] isEqualToString:selectedIdentifier]) {
            return home;
        }
    }
    return [homes count] > 0 ? [homes objectAtIndex:0] : nil;
}

+ (NSDictionary *)saveHomeWithName:(NSString *)name
                      baseURLString:(NSString *)baseURLString
                        accessToken:(NSString *)accessToken
                       refreshToken:(NSString *)refreshToken {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *homes = [NSMutableArray arrayWithArray:[self homes]];
    NSMutableDictionary *savedHome = nil;
    NSUInteger existingIndex = NSNotFound;
    for (NSUInteger index = 0; index < [homes count]; index++) {
        NSDictionary *home = [homes objectAtIndex:index];
        if ([[home objectForKey:HAHomeBaseURLKey] caseInsensitiveCompare:baseURLString] == NSOrderedSame) {
            savedHome = [NSMutableDictionary dictionaryWithDictionary:home];
            existingIndex = index;
            break;
        }
    }
    if (savedHome == nil) {
        savedHome = [NSMutableDictionary dictionary];
        [savedHome setObject:[[NSProcessInfo processInfo] globallyUniqueString] forKey:HAHomeIdentifierKey];
        [savedHome setObject:[NSArray array] forKey:HAHomeSelectedEntityIDsKey];
    }
    NSString *displayName = [name length] > 0 ? name : [[NSURL URLWithString:baseURLString] host];
    [savedHome setObject:displayName ?: @"Home" forKey:HAHomeNameKey];
    [savedHome setObject:baseURLString forKey:HAHomeBaseURLKey];
    [savedHome setObject:accessToken forKey:HAHomeAccessTokenKey];
    [savedHome setObject:refreshToken ?: @"" forKey:HAHomeRefreshTokenKey];
    if (existingIndex == NSNotFound) {
        [homes addObject:savedHome];
    } else {
        [homes replaceObjectAtIndex:existingIndex withObject:savedHome];
    }
    [defaults setObject:homes forKey:HAHomesDefaultsKey];
    [defaults setObject:[savedHome objectForKey:HAHomeIdentifierKey]
                 forKey:HASelectedHomeIdentifierDefaultsKey];
    [self mirrorSelectedHome:savedHome defaults:defaults];
    [defaults synchronize];
    return savedHome;
}

+ (void)selectHomeWithIdentifier:(NSString *)identifier {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for (NSDictionary *home in [self homes]) {
        if ([[home objectForKey:HAHomeIdentifierKey] isEqualToString:identifier]) {
            [defaults setObject:identifier forKey:HASelectedHomeIdentifierDefaultsKey];
            [self mirrorSelectedHome:home defaults:defaults];
            [defaults synchronize];
            return;
        }
    }
}

+ (void)removeHomeWithIdentifier:(NSString *)identifier {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *homes = [NSMutableArray arrayWithArray:[self homes]];
    for (NSInteger index = (NSInteger)[homes count] - 1; index >= 0; index--) {
        if ([[[homes objectAtIndex:index] objectForKey:HAHomeIdentifierKey] isEqualToString:identifier]) {
            [homes removeObjectAtIndex:index];
        }
    }
    [defaults setObject:homes forKey:HAHomesDefaultsKey];
    NSDictionary *selectedHome = [homes count] > 0 ? [homes objectAtIndex:0] : nil;
    NSString *selectedIdentifier = [defaults stringForKey:HASelectedHomeIdentifierDefaultsKey];
    if ([selectedIdentifier isEqualToString:identifier] || [homes count] == 0) {
        if (selectedHome != nil) {
            [defaults setObject:[selectedHome objectForKey:HAHomeIdentifierKey]
                         forKey:HASelectedHomeIdentifierDefaultsKey];
            [self mirrorSelectedHome:selectedHome defaults:defaults];
        } else {
            [defaults removeObjectForKey:HASelectedHomeIdentifierDefaultsKey];
            [defaults removeObjectForKey:@"HABaseURL"];
            [defaults removeObjectForKey:@"HAAccessToken"];
            [defaults removeObjectForKey:@"HARefreshToken"];
            [defaults removeObjectForKey:@"HAFavoriteEntityIDs"];
        }
    }
    [defaults synchronize];
}

+ (NSArray *)selectedEntityIDs {
    return [[self selectedHome] objectForKey:HAHomeSelectedEntityIDsKey] ?: [NSArray array];
}

+ (void)setSelectedEntityIDs:(NSArray *)entityIDs {
    NSDictionary *selectedHome = [self selectedHome];
    if (selectedHome == nil) {
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *homes = [NSMutableArray arrayWithArray:[self homes]];
    for (NSUInteger index = 0; index < [homes count]; index++) {
        NSDictionary *home = [homes objectAtIndex:index];
        if ([[home objectForKey:HAHomeIdentifierKey]
                isEqualToString:[selectedHome objectForKey:HAHomeIdentifierKey]]) {
            NSMutableDictionary *updatedHome = [NSMutableDictionary dictionaryWithDictionary:home];
            [updatedHome setObject:entityIDs ?: [NSArray array] forKey:HAHomeSelectedEntityIDsKey];
            [homes replaceObjectAtIndex:index withObject:updatedHome];
            break;
        }
    }
    [defaults setObject:homes forKey:HAHomesDefaultsKey];
    [defaults setObject:entityIDs ?: [NSArray array] forKey:@"HAFavoriteEntityIDs"];
    [defaults synchronize];
}

+ (void)mirrorSelectedHome:(NSDictionary *)home defaults:(NSUserDefaults *)defaults {
    [defaults setObject:[home objectForKey:HAHomeBaseURLKey] forKey:@"HABaseURL"];
    [defaults setObject:[home objectForKey:HAHomeAccessTokenKey] forKey:@"HAAccessToken"];
    [defaults setObject:[home objectForKey:HAHomeRefreshTokenKey] ?: @"" forKey:@"HARefreshToken"];
    [defaults setObject:[home objectForKey:HAHomeSelectedEntityIDsKey] ?: [NSArray array]
                 forKey:@"HAFavoriteEntityIDs"];
}

@end
