#import <Foundation/Foundation.h>

NSURL *HAURLWithString(NSString *string);
NSMutableURLRequest *HAMutableURLRequestWithURL(NSURL *url);
NSURLConnection *HAStartURLConnection(NSURLRequest *request, id delegate);
