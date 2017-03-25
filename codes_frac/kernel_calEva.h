/*************************************************************************
	> File Name: kernel_calEva.h
	> Author: 
	> Mail: 
	> Created Time: 2017年03月21日 星期二 18时20分53秒
 ************************************************************************/

#ifndef _KERNEL_CALEVA_H
#define _KERNEL_CALEVA_H
#include <vector>
#include "calEva.h"
#include "PWA_PARAS.h"
    int initialize_data(std::vector<PWA_PARAS>&, DataPointers&); // 把vector数据和指针数据对应起来，并copy到gpu里面去
    int data_distribution(DataPointers&, CudaDataPointers&); // 把vector数据和指针数据对应起来，并copy到gpu里面去
    my_float calEva(const PWA_PARAS &pp, int idp);
    my_float kernel_calEva(const PWA_PARAS &pp,int idp);
    void func(DataPointers& cpu_data_pointers);
#endif
