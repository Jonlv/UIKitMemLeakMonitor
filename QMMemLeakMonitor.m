//
//  QMMemLeakMonitor.m
//
//
//  Created by jonllv on 15/8/26.
//
//  

#import "QMMemLeakMonitor.h"
#include <objc/runtime.h>
#import "UIView+MemLeakMonitor.h"

#define MONITOR_INTERVAL_TIME 10.f

@interface QMMemLeakMonitor ()

@property (nonatomic, strong) NSMapTable<id, NSDictionary *>    *objectTable;
@property (nonatomic, strong) NSArray<NSString *>               *vcMonitorWhiteList;
@property (nonatomic, strong) NSArray<NSString *>               *viewMonitorWhiteList;
@property (nonatomic, strong) NSMutableSet<NSString *>          *reportedVCName;
@end

@implementation QMMemLeakMonitor

static QMMemLeakMonitor *sharedInstance = nil;
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[QMMemLeakMonitor alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.objectTable = [NSMapTable weakToStrongObjectsMapTable];
        self.reportedVCName = [NSMutableSet set];
        //常驻内存的vc不监控
        self.vcMonitorWhiteList = @[@"YourWhiteListVC"];
        self.viewMonitorWhiteList = @[@"YourWhiteListView"];
        [NSTimer scheduledTimerWithTimeInterval:MONITOR_INTERVAL_TIME target:self selector:@selector(checkObjectTable) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)addMonitorObject:(id)object
{
    if (object)
    {
        NSString *className = NSStringFromClass([object class]);
        if (className.length > 0 && ![self.vcMonitorWhiteList containsObject:className])
        {
            NSDate *createDate = [NSDate dateWithTimeIntervalSinceNow:0];
            [self.objectTable setObject:@{@"className" : className, @"createTime" : createDate} forKey:object];
        }
    }
}

- (void)removeMonitorObject:(id)object
{
    if (object)
    {
        [self.objectTable removeObjectForKey:object];
    }
}

- (void)addUIViewsToCheck:(UIView *)view fromVC:(UIViewController *)vc
{
    if ([view isKindOfClass:[UIView class]] && vc)
    {
        NSString *vcClassName = NSStringFromClass([vc class]);
        if (vcClassName.length > 0 && ![self.viewMonitorWhiteList containsObject:vcClassName])
        {
            [view willDealloc:vcClassName];
        }
    }
}

- (BOOL)IfViewInWhiteList:(UIView *)view
{
    NSString *viewClassName = NSStringFromClass([view class]);
    return [self.viewMonitorWhiteList containsObject:viewClassName];
}

// 修改log输出，按持续时间降序输出
- (void)checkObjectTable
{
    if (self.objectTable.count > 0)
    {
        NSEnumerator *enumerator = [self.objectTable keyEnumerator];
        id key;
        
        NSMutableArray<NSNumber *> *timeArray = [[NSMutableArray alloc] initWithCapacity:5];
        NSMutableArray *keyArray = [[NSMutableArray alloc] initWithCapacity:5];
        
        while ((key = [enumerator nextObject]))
        {
            Class keyClass = object_getClass(key);
            if (![keyClass isSubclassOfClass:[UIViewController class]] || (![self isVCInNaviStack:key] && [self noParentVC:key]) || [self isLeakModalVC:key])
            {
                NSDictionary *classInfo = [self.objectTable objectForKey:key];
                NSDate *objCreateDate = [classInfo objectForKey:@"createTime"];
                NSTimeInterval objLastTime = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSinceDate:objCreateDate];
                if (objLastTime > MONITOR_INTERVAL_TIME)
                {
                    NSNumber *time = [NSNumber numberWithFloat:objLastTime];
                    int index = [self indexOfTime:time in:timeArray];
                    if(index >=0 && index <= [timeArray count])
                    {
                        [timeArray insertObject:time atIndex:index];
                        [keyArray insertObject:key atIndex:index];
                    }
                    
                }
            }
        }
        
        [keyArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            id orderedKey = obj;
            NSDictionary *orderedClassInfo = [self.objectTable objectForKey:orderedKey];
            int orderedTime = [(NSNumber *) timeArray[idx] intValue];
            NSLog(@"[内存监控] 对象 <%p>:%@ 仍存在，持续时间:%d分%d秒", orderedKey, [orderedClassInfo objectForKey:@"className"], orderedTime / 60, orderedTime % 60);
            [self reportVCLeak:[orderedClassInfo objectForKey:@"className"]];
        }];
    }
}

- (int)indexOfTime:(NSNumber *)time in:(NSMutableArray<NSNumber *> *)array
{
    __block NSUInteger i = 0;
    [array enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([time compare:obj] == NSOrderedDescending)
        {
            i = idx;
            *stop = YES;
        }
    }];
    return i;
}

- (BOOL)isVCInNaviStack:(id)vcObject
{
    NSArray *naviStack = [[(UIViewController *)vcObject navigationController] viewControllers];
    return [naviStack containsObject:vcObject];
}

- (BOOL)noParentVC:(id)vcObject
{
    UIViewController *vc = vcObject;
    return vc.parentViewController == nil;
}

- (BOOL)isLeakModalVC:(id)vcObject
{
    UIViewController *vc = vcObject;
    return vc.presentingViewController == nil;
}

- (void)reportVCLeak:(NSString *)vcName
{
    if (vcName.length > 0 && ![self.reportedVCName containsObject:vcName])
    {
        [self.reportedVCName addObject:vcName];
        // 你的上报逻辑
    }
}

@end
