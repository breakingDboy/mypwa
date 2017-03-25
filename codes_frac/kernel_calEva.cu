#include <cuda_runtime.h>
#include "cuComplex.h"
#include <iostream>
#include "calEva.h"
#include "PWA_PARAS.h"
#include <vector>
#include <fstream>
#include <math.h>
#include "DPFPropogator.h"
#include "kernel_calEva.h"
#include "conf.h"

using namespace std;

#define CUDA_CALL(x) {const cudaError_t a=(x); if(a != cudaSuccess) {printf("\nCUDAError:%s(err_num=%d)\n",cudaGetErrorString(a),a); cudaDeviceReset(); }}

    int _CN_spinList;
    int _CN_massList;
    int _CN_mass2List;
    int _CN_widthList;
    int _CN_g1List;
    int _CN_g2List;
    int _CN_b1List;
    int _CN_b2List;
    int _CN_b3List;
    int _CN_b4List;
    int _CN_b5List;
    int _CN_rhoList;
    int _CN_fracList;
    int _CN_phiList;
    int _CN_propList;
    int nAmps;
    int Nmc,Nmc_data;
    std::vector<double> paraList;
    my_float **mlk;

__global__ void
convert(const my_float *A, my_float *BB, int numElements)
{
    int i = blockDim.x * blockIdx.x + threadIdx.x;
    if (i < numElements)
    {
        int pwa_paras_size = sizeof(PWA_PARAS) / sizeof(my_float);
        //my_float *pp = (my_float *)malloc(sizeof(PWA_PARAS));
        //for(int j = 0; j < pwa_paras_size; j++) {
           // pp[j] = A[i * pwa_paras_size + j];
       // }
        //PWA_PARAS tt = ((PWA_PARAS*)pp)[0];
        PWA_PARAS *tt = (PWA_PARAS*)&A[i*pwa_paras_size];
        BB[i] = tt->wu[0] + tt->wu[1] + tt->wu[2] + tt->wu[3];
    }
}


 __device__ my_float calEva(const PWA_PARAS *pp, const int * parameter , const double * d_paraList,int idp) 
    ////return square of complex amplitude
{
    //	static int A=0;
    //	A++;
    
    int _N_spinList     =parameter[0];
    int _N_massList     =parameter[1];
    int _N_mass2List    =parameter[2];
    int _N_widthList    =parameter[3];
    int _N_g1List       =parameter[4];
    int _N_g2List       =parameter[5];
    int _N_b1List       =parameter[6];
    int _N_b2List       =parameter[7];
    int _N_b3List       =parameter[8];
    int _N_b4List       =parameter[9];
    int _N_b5List       =parameter[10];
    int _N_rhoList      =parameter[11];
    int _N_fracList     =parameter[12];
    int _N_phiList      =parameter[13];
    int _N_propList     =parameter[14];
    const int const_nAmps=parameter[15];
    my_float value = 0.;
    //TComplex fCF[const_nAmps][4];
    TComplex (*fCF)[4]=(TComplex (*)[4])malloc(sizeof(TComplex)*const_nAmps*4);
    //TComplex fCP[const_nAmps];
    TComplex * fCP=(TComplex *)malloc(sizeof(TComplex)*const_nAmps);
    //TComplex pa[const_nAmps][const_nAmps];
    TComplex **pa,**fu;
    pa=(TComplex **)malloc(sizeof(TComplex *)*const_nAmps);
    fu=(TComplex **)malloc(sizeof(TComplex *)*const_nAmps);
    for(int i=0;i<const_nAmps;i++)
    {
        pa[i]=(TComplex *)malloc(sizeof(TComplex)*const_nAmps);
        fu[i]=(TComplex *)malloc(sizeof(TComplex)*const_nAmps);
    }
    //TComplex fu[const_nAmps][const_nAmps];
    //TComplex crp1[const_nAmps];
    TComplex * crp1=(TComplex *)malloc(sizeof(TComplex)*const_nAmps);
    //TComplex crp11[const_nAmps];
    TComplex * crp11=(TComplex *)malloc(sizeof(TComplex)*const_nAmps);
    TComplex cr0p11;
    //TComplex ca2p1;
    TComplex cw2p11;
    TComplex cw2p12;
    TComplex cw2p15;
    TComplex cw;
    TComplex c1p12_12,c1p13_12,c1p12_13,c1p13_13,c1p12_14,c1p13_14;
    TComplex cr1m12_1,cr1m13_1;
    TComplex crpf1,crpf2;

    for(int index=0; index<const_nAmps; index++) {
        my_float rho0 = d_paraList[_N_rhoList++];
        my_float frac0 = d_paraList[_N_fracList++];
        my_float phi0 = d_paraList[_N_phiList++];
        int spin_now = d_paraList[_N_spinList++];
        int propType_now = d_paraList[_N_propList++];
    //cout<<"haha: "<< __LINE__ << endl;

        rho0 *= std::exp(frac0);
        fCP[index]=make_complex(rho0*std::cos(phi0),rho0*std::sin(phi0));
        //        //cout<<"fCP[index]="<<fCP[index]<<endl;
        //std::cout << __FILE__ << __LINE__ << " : " << propType_now << std::endl;
        switch(propType_now)
        {
            //  //cout<<"haha: "<< __LINE__ << endl;
            //                     ordinary  Propagator  Contribution
            case 1:
                {
                    //RooRealVar *width = (RooRealVar*)_widthIterV[omp_id]->Next();
                    my_float mass0 = d_paraList[_N_massList++];
                    my_float width0 = d_paraList[_N_widthList++];
                    //					//cout<<"mass0="<<mass0<<endl;
                    //					//cout<<"width0="<<width0<<endl;
                    crp1[index]=propogator(mass0,width0,pp->s23);
                }
                break;
            //	Flatte   Propagator Contribution
            case 2:
                {
                    //RooRealVar *g1 = (RooRealVar*)_g1IterV[omp_id]->Next();
                    //RooRealVar *g2 = (RooRealVar*)_g2IterV[omp_id]->Next();
                    my_float mass980 = d_paraList[_N_massList++];
                    my_float g10 = d_paraList[_N_g1List++];
                    my_float g20 = d_paraList[_N_g2List++];
                    //my_float g10=g1->getVal();
                    //my_float g20=g2->getVal();
     //               			//cout<<"mass980="<<mass980<<endl;
     //               			//cout<<"g10="<<g10<<endl;
     //               			//cout<<"g20="<<g20<<endl;
     //                           //cout<<"pp.s23="<<pp.s23<< endl;
                    crp1[index]=propogator980(mass980,g10,g20,pp->s23);
     //               			//cout<<"crp1[index]="<<crp1[index]<<endl;
                }
                break;
                // sigma  Propagator Contribution
            case 3:
                {
                    //RooRealVar *b1 = (RooRealVar*)_b1IterV[omp_id]->Next();
                    //RooRealVar *b2 = (RooRealVar*)_b2IterV[omp_id]->Next();
                    //RooRealVar *b3 = (RooRealVar*)_b3IterV[omp_id]->Next();
                    //RooRealVar *b4 = (RooRealVar*)_b4IterV[omp_id]->Next();
                    //RooRealVar *b5 = (RooRealVar*)_b5IterV[omp_id]->Next();
                    //my_float mass600=mass->getVal();
                    //my_float b10=b1->getVal();
                    //my_float b20=b2->getVal();
                    //my_float b30=b3->getVal();
                    //my_float b40=b4->getVal();
                    //my_float b50=b5->getVal();
                    my_float mass600 = d_paraList[_N_massList++];
                    my_float b10 = d_paraList[_N_b1List++];
                    my_float b20 = d_paraList[_N_b2List++];
                    my_float b30 = d_paraList[_N_b3List++];
                    my_float b40 = d_paraList[_N_b4List++];
                    my_float b50 = d_paraList[_N_b5List++];
                    crp1[index]=propogator600(mass600,b10,b20,b30,b40,b50,pp->s23);
                    //			//cout<<"crp1[index]3="<<crp1[index]<<endl;
                }
                break;
                // 1- or 1+  Contribution
            case 4:
                {
                    //RooRealVar *width = (RooRealVar*)_widthIterV[omp_id]->Next();
                    //my_float mass0=mass->getVal();
                    //my_float width0=width->getVal();
                    my_float mass0 = d_paraList[_N_massList++];
                    my_float width0 = d_paraList[_N_widthList++];
                    crp1[index]=propogator(mass0,width0,pp->sv2);
                    crp11[index]=propogator(mass0,width0,pp->sv3);
                }
                break;
                //  phi(1650) f0(980) include flatte and ordinary Propagator joint Contribution
            case 5:
                {
                    //RooRealVar *mass2  = (RooRealVar*)_mass2IterV[omp_id]->Next();
                    //RooRealVar *g1 = (RooRealVar*)_g1IterV[omp_id]->Next();
                    //RooRealVar *g2 = (RooRealVar*)_g2IterV[omp_id]->Next();
                    //my_float mass980=mass2->getVal();
                    //my_float g10=g1->getVal();
                    //my_float g20=g2->getVal();
                    my_float mass980 = d_paraList[_N_mass2List++];
                    my_float g10 = d_paraList[_N_g1List++];
                    my_float g20 = d_paraList[_N_g2List++];
                    //					//cout<<"mass980="<<mass980<<endl;
                    //					//cout<<"g10="<<g10<<endl;
                    //					//cout<<"g20="<<g20<<endl;
                    crp1[index]=propogator980(mass980,g10,g20,pp->sv);
                    //					//cout<<"crp1[index]="<<crp1[index]<<endl;
                    //RooRealVar *width = (RooRealVar*)_widthIterV[omp_id]->Next();
                    //my_float mass1680=mass->getVal();
                    //my_float width1680=width->getVal();
                    my_float mass1680 = d_paraList[_N_massList++];
                    my_float width1680 = d_paraList[_N_widthList++];
                    //					//cout<<"mass1680="<<mass1680<<endl;
                    //					//cout<<"width1680="<<width1680<<endl;
                    crp11[index]=propogator(mass1680,width1680,pp->s23);
                    //					//cout<<"crp11[index]="<<crp11[index]<<endl;
                }
                break;
            case 6:
                {
                    //RooRealVar *width = (RooRealVar*)_widthIterV[omp_id]->Next();
                    //my_float mass0=mass->getVal();
                    //my_float width0=width->getVal();
                    my_float mass0 = d_paraList[_N_massList++];
                    my_float width0 = d_paraList[_N_widthList++];
                    //					//cout<<"mass0="<<mass0<<endl;
                    //					//cout<<"width0="<<width0<<endl;
                    crp1[index]=propogator1270(mass0,width0,pp->s23);
                    //			//cout<<"crp1[index]6="<<crp1[index]<<endl;
                }
            default :
                ;
        }
    //cout << "LINE: " << __LINE__ << endl;
        for(int i=0;i<2;i++){
            ////cout<<"haha: "<< __LINE__ << endl;
            //		//cout<<"spin_now="<<spin_now<<endl;
            switch(spin_now)
            {
                case 11:
                    //1+_1 contribution
                    //fCF[index][i]=pp.w1p12_1[i]*crp1[index]+pp.w1p13_1[i]*crp11[i];
                    fCF[index][i]=cuCadd( cuCmuldc(pp->w1p12_1[i],crp1[index]),cuCmuldc(pp->w1p13_1[i],crp11[i]) );

                    break;
                case 12:
                    //1+_2 contribution
                    //c1p12_12=crp1[index]/pp.b2qbv2;
                    c1p12_12=cuCdivcd(crp1[index],pp->b2qbv2);
                    //c1p13_12=crp11[index]/pp.b2qbv3;
                    c1p13_12=cuCdivcd(crp11[index],pp->b2qbv3);
                    //fCF[index][i]=pp.w1p12_2[i]*c1p12_12+pp.w1p13_2[i]*c1p13_12;
                    fCF[index][i]=cuCadd( cuCmuldc(pp->w1p12_2[i],c1p12_12) , cuCmuldc(pp->w1p13_2[i],c1p13_12) );
                
                    break;
                case 13:
                    //1+_3 contribution
                    //c1p12_13=crp1[index]/pp.b2qjv2;
                    c1p12_13=cuCdivcd(crp1[index],pp->b2qjv2);
                    //c1p13_13=crp11[index]/pp.b2qjv3;
                    c1p13_13=cuCdivcd(crp11[index],pp->b2qjv3);
                    //fCF[index][i]=pp.w1p12_3[i]*c1p12_13+pp.w1p13_3[i]*c1p13_13;
                    fCF[index][i]=cuCadd( cuCmuldc(pp->w1p12_3[i],c1p12_13) , cuCmuldc(pp->w1p13_3[i],c1p13_13) );

                    break;
                case 14:
                    //1+_4 contribution
                    //c1p12_12=crp1[index]/pp.b2qbv2;
                    c1p12_12=cuCdivcd(crp1[index],pp->b2qbv2);
                    
                    c1p13_12=cuCdivcd(crp11[index],pp->b2qbv3);
                    c1p12_14=cuCdivcd(c1p12_12,pp->b2qjv2);
                    c1p13_14=cuCdivcd(c1p13_12,pp->b2qjv3);
                    fCF[index][i]=cuCadd( cuCmuldc(pp->w1p12_4[i],c1p12_14), cuCmuldc(pp->w1p13_4[i],c1p13_14));

                    break;
                case 111:
                    //1-__1 contribution
                    cr1m12_1=cuCdivcd( cuCdivcd(crp1[index],pp->b1qjv2) , pp->b1qbv2);
                    cr1m13_1=cuCdivcd( cuCdivcd(crp11[index],pp->b1qjv3) , pp->b1qbv3);
                    fCF[index][i]=cuCadd( cuCmuldc(pp->w1m12[i],cr1m12_1), cuCmuldc(pp->w1m13[i],cr1m13_1));

                    break;
                case 191:
                    //phi(1650)f0(980)_1 contribution
                    //		//cout<<"b1q2r23="<<b1q2r23<<endl;
                    crpf1=cuCdivcd( cuCmul(crp1[index],crp11[index]),pp->b1q2r23 );
                    //		//cout<<"crpf1="<<crpf1<<endl;
                    fCF[index][i]=cuCmuldc(pp->ak23w[i],crpf1);
                    //	//cout<<"fCF[index][i]="<<fCF[index][i]<<endl;

                    break;
                case 192:
                    //phi(1650)f0(980)_2 contribution
                    crpf1=cuCdivcd( cuCmul(crp1[index],crp11[index]) , pp->b1q2r23);
                    crpf2=cuCdivcd(crpf1,pp->b2qjvf2);
                    fCF[index][i]=cuCmuldc(pp->wpf22[i],crpf2);

                    break;
                case 1:
                    //  //cout<<"haha: "<< __LINE__ << endl;
                    //01 contribution
                    //	//cout<<"wu[i]="<<wu[i]<<endl;
                    //	//cout<<"crp1[index]="<<crp1[index]<<endl;
                    //	//cout<<"index="<<index<<endl;
                    fCF[index][i]=cuCmuldc(pp->wu[i],crp1[index]);
                    //	//cout<<"fCF[index][i]="<<fCF[index][i]<<endl;
                    //	//cout<<"i="<<i<<endl;

                    break;
                case 2:
                    //02 contribution
                    cr0p11=cuCdivcd(crp1[index],pp->b2qjvf2);
                    fCF[index][i]=cuCmuldc(pp->w0p22[i],cr0p11);
                    //	//cout<<"fCF[index][i]02="<<fCF[index][i]<<endl;

                    break;
                case 21:
                    //21 contribution
                    //	//cout<<"b2qf2xx="<<b2qf2xx<<endl;
                    cw2p11=cuCdivcd(crp1[index],pp->b2qf2xx);
                    //	//cout<<"cw2p11="<<cw2p11<<endl;
                    //	//cout<<"w2p1[0]="<<w2p1[0]<<endl;
                    //	//cout<<"w2p1[1]="<<w2p1[1]<<endl;
                    fCF[index][i]=cuCmuldc(pp->w2p1[i],cw2p11);
                    //	//cout<<"fCF[index][i]21="<<fCF[index][i]<<endl;

                    break;
                case 22:
                    //22 contribution
                    cw2p11=cuCdivcd(crp1[index],pp->b2qf2xx);
                    cw2p12=cuCdivcd(cw2p11,pp->b2qjvf2);
                    fCF[index][i]=cuCmuldc(pp->w2p2[i],cw2p12);

                    break;
                case 23:
                    //23 contribution
                    cw2p11=cuCdivcd(crp1[index],pp->b2qf2xx);
                    cw2p12=cuCdivcd(cw2p11,pp->b2qjvf2);
                    fCF[index][i]=cuCmuldc(pp->w2p3[i],cw2p12);

                    break;
                case 24:
                    //24 contribution
                    cw2p11=cuCdivcd(crp1[index],pp->b2qf2xx);
                    cw2p12=cuCdivcd(cw2p11,pp->b2qjvf2);
                    fCF[index][i]=cuCmuldc(pp->w2p4[i],cw2p12);

                    break;
                case 25:
                    //25 contribution
                    cw2p11=cuCdivcd(crp1[index],pp->b2qf2xx);
                    cw2p15=cuCdivcd(cw2p11,pp->b4qjvf2);
                    fCF[index][i]=cuCmuldc(pp->w2p5[i],cw2p15);

                default:		;
            }
        }

    }
    my_float carry(0);
    //#pragma omp parallel for reduction(+:value)
    for(int i=0;i<const_nAmps;i++){
        //  //cout<<"haha: "<< __LINE__ << endl;
        for(int j=0;j<const_nAmps;j++){
            cw=cuCmul(fCP[i],cuConj(fCP[j]));
            //    //cout<<"cw="<<cw<<endl;
            if(i==j) pa[i][j]=make_complex(cuCreal(cw),0.0);
            else if(i<j) pa[i][j]=make_complex(2*cuCreal(cw),0.0);
            else pa[i][j]=make_complex(0.0,2*cuCimag(cw));
            cw=make_complex(0.0,0.0);
            for(int k=0;k<2;k++){
                cw=cuCadd(cw,cuCdivcd( cuCmul( fCF[i][k],cuConj(fCF[j][k]) ),(my_float)2.0) );
                //   //cout<<"cwfu="<<cw<<endl;

            }
            if(i<=j) fu[i][j]=make_complex(cuCreal(cw),0.0);
            if(i>j) fu[i][j]=make_complex(0.0,-cuCimag(cw));
            //      //cout<<"pa[i][j]="<<pa[i][j]<<endl;
            //      //cout<<"fu[i][j]="<<fu[i][j]<<endl;
            my_float temp = cuCreal( cuCmul(pa[i][j],fu[i][j]) );//i have a big change here 
            my_float y = temp - carry;
            my_float t = value + y;
            carry = (t - value) - y;

            value = t; // Kahan Summation
        }
    }

    for(int i=0;i<const_nAmps;i++){
        TComplex cw=cuCmul(fCP[i],cuConj(fCP[i]));
        my_float pa=cuCreal(cw);

        cw=make_complex(0.0,0.0);
        for(int k=0;k<2;k++){
            //cw+=fCF[i][k]*cuConj(fCF[i][k])/(my_float)2.0;
            cw=cuCadd(cw,cuCdivcd( cuCmul( fCF[i][k],cuConj(fCF[i][k]) ),(my_float)2.0) );
        }
        my_float fu=cuCreal(cw);
       // mlk[idp][i] = pa * fu;
    }
    return (value <= 0) ? 1e-20 : value;
}

__global__ void kernel_store_fx(const my_float * float_pp,const int *parameter,const double *d_paraList,my_float * d_fx,int numElements,int begin)
{
    int i = blockDim.x * blockIdx.x + threadIdx.x;
    if(i<numElements && i>= begin)
    {
        int pwa_paras_size = sizeof(PWA_PARAS) / sizeof(my_float);
        PWA_PARAS *pp = (PWA_PARAS*)&float_pp[i*pwa_paras_size];
        d_fx[i]=calEva(pp,parameter,d_paraList,i);
    }
    //if(i==1)
    //{
    //    printf("pp[0]:%f pp[end]:%f parameter[0]:%d parameter[17]:%d paraList[0]:%f \n",float_pp[0],float_pp[numElements*sizeof(PWA_PARAS)/sizeof(my_float)],parameter[0],parameter[17],d_paraList[0]);
    //}
}

int host_store_fx(my_float *h_float_pp,int *h_parameter,double *h_paraList,int para_size, my_float *h_fx,int numElements,int begin)
{
    int array_size = sizeof(PWA_PARAS) / sizeof(my_float) * iEnd;
    int mem_size = array_size * sizeof(my_float);
    //std::cout << __LINE__ << endl;
    my_float *d_float_pp;
    CUDA_CALL(cudaMalloc((void **)&d_float_pp, mem_size));
    CUDA_CALL(cudaMemcpy(d_float_pp , h_float_pp, mem_size, cudaMemcpyHostToDevice));
     //std::cout << __LINE__ << endl;
    my_float *d_fx;
    CUDA_CALL(cudaMalloc((void **)&(d_fx),numElements * sizeof(my_float)));
     //std::cout << __LINE__ << endl;
    int *d_parameter;
    CUDA_CALL(cudaMalloc((void **)&(d_parameter),18 * sizeof(int)));
    CUDA_CALL(cudaMemcpy(d_parameter , h_parameter, 18*sizeof(int), cudaMemcpyHostToDevice));
     //std::cout << __LINE__ << endl;
    //std::cout << "d_paralist[0]: "<< h_paraList[0] << std::endl;
    //std::cout << "paralist[0]: "<< paraList[0] << std::endl;
    double *d_paraList;
    CUDA_CALL(cudaMalloc((void **)&(d_paraList),para_size * sizeof(double)));
    CUDA_CALL(cudaMemcpy(d_paraList , h_paraList, para_size * sizeof(double), cudaMemcpyHostToDevice));
     //std::cout << __LINE__ << endl;
    int threadsPerBlock = 256;
    int blocksPerGrid =(numElements + threadsPerBlock - 1) / threadsPerBlock;
    printf("CUDA kernel launch with %d blocks of %d threads\n", blocksPerGrid, threadsPerBlock);
    kernel_store_fx<<<blocksPerGrid, threadsPerBlock>>>(d_float_pp, d_parameter,d_paraList,d_fx, numElements,begin);
     //std::cout << __LINE__ << endl;
    h_fx[0]=0;
    CUDA_CALL(cudaMemcpy(h_fx , d_fx, numElements * sizeof(my_float), cudaMemcpyDeviceToHost));
    ofstream cout("data_fx_cal");
    //std::cout << __LINE__ << endl;
    for(int i=begin;i<numElements;i++)
    {
        cout << h_fx[i] << endl;
    }
    cout.close();
    return 0;
}

void func(DataPointers& cpu_data_pointers)
{
    my_float * h_float_pp=cpu_data_pointers.pointer_data;

    int * h_parameter=(int *)malloc(18*sizeof(int));
    h_parameter[0] =  _CN_spinList;
    h_parameter[1] =  _CN_massList;
    h_parameter[2] =  _CN_mass2List;
    h_parameter[3] =  _CN_widthList;
    h_parameter[4] =  _CN_g1List;
    h_parameter[5] =  _CN_g2List;
    h_parameter[6] =  _CN_b1List;
    h_parameter[7] =  _CN_b2List;
    h_parameter[8] =  _CN_b3List;
    h_parameter[9] =  _CN_b4List;
    h_parameter[10] =  _CN_b5List;
    h_parameter[11] =  _CN_rhoList;
    h_parameter[12] =  _CN_fracList;
    h_parameter[13] =  _CN_phiList;
    h_parameter[14] =  _CN_propList;
    h_parameter[15] =  nAmps;
    h_parameter[16] =  Nmc;
    h_parameter[17] = Nmc_data; 

    double * h_paraList=(double *)malloc(paraList.size()*sizeof(double));
    for(int i=0;i<paraList.size();i++)
    {
        h_paraList[i]=paraList[i];
    }
    
    my_float *h_fx=(my_float *)malloc(iEnd*sizeof(my_float));

    host_store_fx(h_float_pp,h_parameter,h_paraList,paraList.size(),h_fx,iEnd,iBegin);
}
//将文件中的数据pwa_paras读出来，存在数组中，内存中的存储是一定的。但是结构题的指针可以随意转化
int initialize_data(std::vector<PWA_PARAS> &pwa_paras, DataPointers& cpu_data_points)
{
    mlk = new my_float*[Nmc + Nmc_data];
    for(int i = 0; i < Nmc + Nmc_data; i++) {
        mlk[i] = new my_float[nAmps];
    }
    //init mlk
    //init private num
    std::fstream cin("data_of_private_member");
         cin >> _CN_spinList ;
        cin >>  _CN_massList ;
        cin >>  _CN_mass2List ;
        cin >>  _CN_widthList ;
        cin >>  _CN_g1List ;
        cin >>  _CN_g2List ;
        cin >>  _CN_b1List ;
        cin >>  _CN_b2List ;
        cin >>  _CN_b3List ;
        cin >>  _CN_b4List ;
        cin >>  _CN_b5List ;
        cin >>  _CN_rhoList ;
        cin >>  _CN_fracList ;
        cin >>  _CN_phiList ;
        cin >>  _CN_propList ;
        cin >>  nAmps ;
        cin >>  Nmc ;
        cin >> Nmc_data ;
        int paraList_size;
        cin >> paraList_size;
        paraList.resize(paraList_size);
        for(int i=0;i<paraList_size;i++)
        {
            cin >> paraList[i] ;
        }
        cin.close();
    ///////////////////////////////
    pwa_paras.resize(iEnd);
    int array_size = sizeof(PWA_PARAS) / sizeof(my_float) * iEnd;
    int mem_size = array_size * sizeof(my_float);
    std::cout << "array_size=" << array_size << std::endl;

    cpu_data_points.pointer_data = (my_float *)malloc(mem_size);
    cpu_data_points.pointer_data_pwa_paras_type = (PWA_PARAS*)cpu_data_points.pointer_data;

    cpu_data_points.result_data = (my_float*)malloc(array_size);
    std::cout << "finish cpu memory malloc" << std::endl;
    std::ifstream in("data_pwa_paras");
    my_float temp_num;
    for(int i = 0; i < array_size; i++) {
        in >> temp_num;
        cpu_data_points.pointer_data[i] = temp_num;
    }
    in.close();
std::cout << "haha" << __LINE__ << std::endl;
    for(int i = 0; i < iEnd; i++) {
        pwa_paras[i] = cpu_data_points.pointer_data_pwa_paras_type[i];
    }
    return 0;
}

int data_distribution(DataPointers& cpu_data_pointers, CudaDataPointers& cuda_data_pointers)
{
    int array_size = sizeof(PWA_PARAS) / sizeof(my_float) * iEnd;
    int mem_size = array_size * sizeof(my_float);
    CUDA_CALL(cudaMalloc((void **)&(cuda_data_pointers.input_data), mem_size));
    CUDA_CALL(cudaMalloc((void **)&(cuda_data_pointers.output_data), iEnd * sizeof(my_float)));
    CUDA_CALL(cudaMemcpy(cuda_data_pointers.input_data, cpu_data_pointers.pointer_data, mem_size, cudaMemcpyHostToDevice));

    int threadsPerBlock = 256;
    int blocksPerGrid =(iEnd + threadsPerBlock - 1) / threadsPerBlock;
    printf("CUDA kernel launch with %d blocks of %d threads\n", blocksPerGrid, threadsPerBlock);
    convert<<<blocksPerGrid, threadsPerBlock>>>(cuda_data_pointers.input_data, cuda_data_pointers.output_data, iEnd);
    
    CUDA_CALL(cudaMemcpy(cpu_data_pointers.result_data, cuda_data_pointers.output_data, sizeof(my_float) * iEnd, cudaMemcpyDeviceToHost));

    std::vector<my_float> aa(iEnd);
    for(int i = 0; i < iEnd; i++) {
        aa[i] = cpu_data_pointers.pointer_data_pwa_paras_type[i].wu[0] + cpu_data_pointers.pointer_data_pwa_paras_type[i].wu[1] + cpu_data_pointers.pointer_data_pwa_paras_type[i].wu[2] + cpu_data_pointers.pointer_data_pwa_paras_type[i].wu[3];
    }
    for(int i = 0; i < iEnd; i++)
    {
        if(cpu_data_pointers.result_data[i]-aa[i] != 0.0) {std::cout << "test failed!!!!!!! the result is not same!!"<< std::endl; return 0;}
    }
    std::cout << "test finish !!!! the result is same!" << std::endl;
    return 0;
}
