//
//  ObjectiveC.h
//  MotionGraphs
//
//  Created by Jay on 2017/6/30.
//  Copyright © 2017年 Apple. All rights reserved.
//

#ifndef ObjectiveC_h
#define ObjectiveC_h
#import <Foundation/Foundation.h>
@interface CPP_Wrapper : NSObject
+(void)hello_cpp_wrapped;
+(void)calibrate_cpp_wrapped:(const char *) accfilename andGyr: (const char *)gyrfilename;
@end

#endif /* ObjectiveC_h */
