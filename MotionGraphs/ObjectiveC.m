//
//  ObjectiveC.m
//  MotionGraphs
//
//  Created by Jay on 2017/6/30.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "ObjectiveC.h"
#include "testCeres.h"

@implementation CPP_Wrapper
+(void)hello_cpp_wrapped {
//    NSLog("hello cpp wrapped");
    hello();
}

+(void)calibrate_cpp_wrapped:(const char *) accfilename andGyr: (const char *)gyrfilename{
    calibrateIMU(accfilename, gyrfilename);
}
@end

