//
//  QMMemMonitor.h
//  
//
//  Created by jonllv on 15/8/26.
//
//  监控内存对象dealloc情况

#import <Foundation/Foundation.h>

@interface QMMemMonitor : NSObject

+ (instancetype)sharedInstance;

- (void)addMonitorObject:(id)object;
- (void)removeMonitorObject:(id)object;
- (void)addUIViewsToCheck:(UIView *)view fromVC:(UIViewController *)vc;
- (BOOL)IfViewInWhiteList:(UIView *)view;
@end
