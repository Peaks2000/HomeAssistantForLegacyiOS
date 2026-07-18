#import "HAURLCompatibility.h"

NSURL *HAURLWithString(NSString *string) {
    return [NSClassFromString(@"NSURL") URLWithString:string];
}

NSMutableURLRequest *HAMutableURLRequestWithURL(NSURL *url) {
    return [NSClassFromString(@"NSMutableURLRequest") requestWithURL:url];
}

NSURLConnection *HAStartURLConnection(NSURLRequest *request, id delegate) {
    return [[[NSClassFromString(@"NSURLConnection") alloc]
        initWithRequest:request delegate:delegate startImmediately:YES] autorelease];
}
