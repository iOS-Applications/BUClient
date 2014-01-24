//
//  IBULoginViewController.m
//  iBU
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCLoginViewController.h"
#import "NSString+NSString_Extended.h"

@interface BUCLoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;

@end

@implementation BUCLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)login:(id)sender {
    NSString *username = self.username.text;
    NSString *password = self.password.text;
    
    
    if ([username length] == 0 || [password length] == 0) {
        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:nil
                                                           message:@"请输入用户信息"
                                                          delegate:self
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        [theAlert show];
        return;
    }
    
    
    NSDictionary *postDicUnencoded = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @"login", @"action",
                                      username, @"username",
                                      password, @"password", nil];
    
    
    NSMutableDictionary *postDic = [[NSMutableDictionary alloc] init];
    for (NSString *key in postDicUnencoded) {
        [postDic setValue:[[postDicUnencoded objectForKey:key] urlencode] forKey:key];
    }
    
    
    NSError *err = nil;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:postDic options:0 error:&err];
    
    
    if (!postData) {
        NSLog(@"Error parsing JSON: %@", err);
    } else {
        NSURL *url = [NSURL URLWithString:@"http://out.bitunion.org/open_api/bu_logging.php"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:postData];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // Peform the request
            NSURLResponse *response;
            NSError *error = nil;
            NSData *receivedData = [NSURLConnection sendSynchronousRequest:request
                                                         returningResponse:&response
                                                                     error:&error];
            if (error) {
                // Deal with your error
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
                    NSLog(@"HTTP Error: %ld %@", (long)httpResponse.statusCode, error);
                    return;
                }
                NSLog(@"Error %@", error);
                return;
            }
            if ([receivedData length] > 0) {
                
                NSString * jsonString = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
                NSLog(@"%@", jsonString);
                
            } else {
                NSLog(@"failed :(");
            }
            
            // Assume lowercase
        });
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField
{
    
    [theTextField resignFirstResponder];
    
    return YES;
}

- (BOOL)shouldAutorotate
{
    return NO;
}
@end
