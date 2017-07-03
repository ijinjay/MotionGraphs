//
//  testCeres.m
//  MotionGraphs
//
//  Created by Jay on 2017/6/29.
//  Copyright © 2017年 Apple. All rights reserved.
//

#include "testCeres.h"
#include <iostream>

#include "imu_tk/io_utils.h"
#include "imu_tk/calibration.h"
#include "imu_tk/filters.h"
#include "imu_tk/integration.h"

using namespace std;
using namespace imu_tk;
using namespace Eigen;

extern void hello(){
    cout<< "Hello C++" << endl;
}

extern void calibrateIMU(const char * accFileName, const char * gyrFileName){
    vector< TriadData > acc_data, gyro_data;
    
    importAsciiData( accFileName, acc_data, imu_tk::TIMESTAMP_UNIT_SEC);
    importAsciiData( gyrFileName, gyro_data, imu_tk::TIMESTAMP_UNIT_SEC);
    
    CalibratedTriad init_acc_calib, init_gyro_calib;
    init_acc_calib.setBias( Vector3d(32768, 32768, 32768) );
    init_gyro_calib.setScale( Vector3d(1.0/6258.0, 1.0/6258.0, 1.0/6258.0) );
    
    MultiPosCalibration mp_calib;
    
    mp_calib.setInitStaticIntervalDuration(50.0);
    mp_calib.setInitAccCalibration( init_acc_calib );
    mp_calib.setInitGyroCalibration( init_gyro_calib );
    mp_calib.setGravityMagnitude(9.8009492468906);
    mp_calib.enableVerboseOutput(true);
    mp_calib.enableAccUseMeans(false);
    //mp_calib.setGyroDataPeriod(0.01);
    mp_calib.calibrateAccGyro(acc_data, gyro_data );
    
    char accFileCalib[128];
    strcpy(accFileCalib, accFileName);
    strcat(accFileCalib, ".calib");
    
    mp_calib.getAccCalib().save(accFileCalib);
    char gyrFileCalib[128];
    strcpy(gyrFileCalib, gyrFileName);
    strcat(gyrFileCalib, ".calib");
    mp_calib.getGyroCalib().save(gyrFileCalib);
    
}
