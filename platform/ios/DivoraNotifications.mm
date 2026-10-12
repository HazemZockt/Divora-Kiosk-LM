// Local timer notifications. No server, advertising identifier, or payment API.
// Included in Godot's existing Xcode source by prepare_ios.py after export.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#include <math.h>

@interface DivoraNotifications : NSObject
@property(nonatomic, strong) NSData *lastPlan;
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic) BOOL requestingPermission;
- (void)refresh;
- (void)start;
@end

@implementation DivoraNotifications
- (NSURL *)document:(NSString *)name {
    NSURL *directory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                              inDomains:NSUserDomainMask] firstObject];
    return [directory URLByAppendingPathComponent:name];
}
- (void)status:(NSString *)state {
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"status":state} options:0 error:nil];
    [data writeToURL:[self document:@"divora_notification_status.json"] atomically:YES];
}
- (void)refresh {
    NSData *data = [NSData dataWithContentsOfURL:[self document:@"divora_notifications.json"]];
    if (!data || data.length > 1000000 || [data isEqual:self.lastPlan]) return;
    id parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![parsed isKindOfClass:[NSDictionary class]]) return;
    NSDictionary *plan = parsed;
    if (![plan[@"enabled"] isKindOfClass:[NSNumber class]] ||
        ![plan[@"tasks"] isKindOfClass:[NSArray class]]) return;
    NSArray *tasks = plan[@"tasks"];
    if (tasks.count > 54) return;
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    self.lastPlan = data;
    if (![plan[@"enabled"] boolValue]) {
        [center removeAllPendingNotificationRequests];
        [self status:@"off"];
        return;
    }
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Ignore an obsolete asynchronous response after the user changes the setting.
            if (![self.lastPlan isEqual:data]) return;
            if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined) {
                self.lastPlan = nil;
                if (self.requestingPermission || UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return;
                self.requestingPermission = YES;
                [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
                                      completionHandler:^(BOOL granted, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.requestingPermission = NO;
                        self.lastPlan = nil;
                        [self status:(granted ? @"allowed" : @"denied")];
                        [self refresh];
                    });
                }];
                return;
            }
            if (settings.authorizationStatus == UNAuthorizationStatusDenied) {
                [center removeAllPendingNotificationRequests];
                [self status:@"denied"];
                return;
            }
            [self status:@"allowed"];
            [center removeAllPendingNotificationRequests];
            NSTimeInterval now = NSDate.date.timeIntervalSince1970;
            for (id raw in tasks) {
                if (![raw isKindOfClass:[NSDictionary class]]) continue;
                NSDictionary *task = raw;
                NSString *identifier = task[@"id"];
                NSString *title = task[@"title"];
                NSString *body = task[@"body"];
                NSNumber *due = task[@"due"];
                if (![identifier isKindOfClass:NSString.class] || ![identifier hasPrefix:@"divora-"] || identifier.length > 100 ||
                    ![title isKindOfClass:NSString.class] || title.length > 200 ||
                    ![body isKindOfClass:NSString.class] || body.length > 1000 ||
                    ![due isKindOfClass:NSNumber.class]) continue;
                NSTimeInterval delay = due.doubleValue-now;
                if (!isfinite(delay) || delay <= 0 || delay > 7*24*3600) continue;
                UNMutableNotificationContent *content = [UNMutableNotificationContent new];
                content.title = title;
                content.body = body;
                content.sound = UNNotificationSound.defaultSound;
                UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:MAX(1,delay) repeats:NO];
                UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
                [center addNotificationRequest:request withCompletionHandler:^(NSError *error) {
                    if (error) NSLog(@"Divora could not schedule a local timer notification: %@",error.localizedDescription);
                }];
            }
        });
    }];
}
- (void)start {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:2 repeats:YES block:^(NSTimer *timer) {
        [self refresh];
    }];
    [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
        [self refresh];
    }];
    [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
        self.lastPlan = nil; // Recheck permission after returning from iOS Settings.
        [self refresh];
    }];
    [self refresh];
}
@end

static DivoraNotifications *divoraNotifications;
__attribute__((constructor)) static void DivoraStartNotifications(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        divoraNotifications = [DivoraNotifications new];
        [divoraNotifications start];
    });
}
