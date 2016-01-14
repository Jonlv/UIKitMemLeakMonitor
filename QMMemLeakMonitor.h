//
//  QMMemLeakMonitor.h
//  
//
//  
//
//  监控内存对象dealloc情况

#import <Foundation/Foundation.h>

@interface QMMemLeakMonitor : NSObject

+ (instancetype)sharedInstance;

- (void)addMonitorObject:(id)object;
- (void)removeMonitorObject:(id)object;
- (void)addUIViewsToCheck:(UIView *)view fromVC:(UIViewController *)vc;
- (BOOL)IfViewInWhiteList:(UIView *)view;
@end
