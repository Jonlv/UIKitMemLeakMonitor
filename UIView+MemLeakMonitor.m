//
//  UIView+MemLeakMonitor.m
// 
//
//  Created by jonllv on 15/12/30.
//
//

#import "UIView+MemMonitor.h"
#import "QMMemLeakMonitor.h"

#define VIEW_MONITOR_INTERVAL_TIME 10.f

@implementation UIView (MemLeakMonitor)

- (void)willDealloc:(NSString *)fromVC
{
    if (![[QMMemLeakMonitor sharedInstance] IfViewInWhiteList:self]) {
        __weak UIView *weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(VIEW_MONITOR_INTERVAL_TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf checkIfDealloc:fromVC];
        });
    }
    for (UIView *view in self.subviews)
    {
        if (![[QMMemLeakMonitor sharedInstance] IfViewInWhiteList:view])
        {
            [view willDealloc:fromVC];
        }
    }
}

- (void)checkIfDealloc:(NSString *)fromVC
{
    NSLog(@"UIView发生泄漏了,属于%@的%@",fromVC,self);
    //ASSERT(0);
}

@end
