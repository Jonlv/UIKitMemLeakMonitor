//
//  UIView+MemMonitor.h
//
//
//  Created by jonllv on 15/12/30.
//
//

#import <Foundation/Foundation.h>

@interface UIView (MemLeakMonitor)

- (void)willDealloc:(NSString *)fromVC;
- (void)checkIfDealloc:(NSString *)fromVC;
@end
