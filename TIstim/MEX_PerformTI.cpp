#include "mex.h"
//#include "StdAfx.h"
#include<iostream>
#include <fstream>
#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>
#include <math.h>
HANDLE hCOM1;//用于获取串口打开函数的返回值（句柄或错误值）
HANDLE hCOM2;//用于获取串口打开函数的返回值（句柄或错误值）
OVERLAPPED m_OverlappedRead, m_OverlappedWrite;
using namespace std;

bool OpenCOM(HANDLE &hCom, int nPort, int nBaud) {
	char szPort[15];
	wsprintf(szPort, "\\\\.\\COM%d", nPort);
	hCom = CreateFile(szPort,
		GENERIC_READ | GENERIC_WRITE,
		0,
		NULL,
		OPEN_EXISTING,
		//FILE_ATTRIBUTE_NORMAL | FILE_FLAG_OVERLAPPED, //异步通信
		0,//同步通信
		NULL);
	if (hCom == NULL) return(FALSE);
	memset(&m_OverlappedRead, 0, sizeof(OVERLAPPED));
	memset(&m_OverlappedWrite, 0, sizeof(OVERLAPPED));
	COMMTIMEOUTS CommTimeOuts;
	CommTimeOuts.ReadIntervalTimeout = 0xFFFFFFFF;
	CommTimeOuts.ReadTotalTimeoutMultiplier = 0;
	CommTimeOuts.ReadTotalTimeoutConstant = 0;
	CommTimeOuts.WriteTotalTimeoutMultiplier = 0;
	CommTimeOuts.WriteTotalTimeoutConstant = 5000;
	SetCommTimeouts(hCom, &CommTimeOuts);
	m_OverlappedRead.hEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
	m_OverlappedWrite.hEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
	DCB dcb;
	dcb.DCBlength = sizeof(DCB);
	GetCommState(hCom, &dcb);
	dcb.BaudRate = nBaud;
	dcb.ByteSize = 8;
	if (!SetCommState(hCom, &dcb) ||
		!SetupComm(hCom, 10000, 10000) ||
		m_OverlappedRead.hEvent == NULL ||
		m_OverlappedWrite.hEvent == NULL)
	{
		DWORD dwError = GetLastError();
		if (m_OverlappedRead.hEvent != NULL)
			CloseHandle(m_OverlappedRead.hEvent);
		if (m_OverlappedWrite.hEvent != NULL)
			CloseHandle(m_OverlappedWrite.hEvent);
		CloseHandle(hCom);
		return FALSE;
	}
	GetCommState(hCom, &dcb);
	bool m_bOpened = TRUE;
	cout << "Correctly open the port." << endl;
	return m_bOpened;
}


DWORD print_COM(HANDLE &hCom, const char *buffer, DWORD dwBytesWritten)
{
	if (hCom == NULL) return(0);
	PurgeComm(hCom, PURGE_TXCLEAR | PURGE_RXCLEAR);//清空缓冲区
	BOOL bWriteStat;
	bWriteStat = WriteFile(hCom, buffer, dwBytesWritten, &dwBytesWritten, &m_OverlappedWrite);
	if (!bWriteStat)
	{
		if (GetLastError() == ERROR_IO_PENDING)
		{
			WaitForSingleObject(m_OverlappedWrite.hEvent, 1000);
			return dwBytesWritten;
		}
		return 0;
	}
	return dwBytesWritten;
}

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {

	///获得计数器的时钟频率，以进行精确计时///
	LARGE_INTEGER litmp;
	LONGLONG QPart1, QPart2;
	double dfMinus, dfFreq, dfTim;
	QueryPerformanceFrequency(&litmp);
	dfFreq = (double)litmp.QuadPart;

	//创建文件以便存储各项输入输出
	int subnum = mxGetScalar(prhs[0]);
	cout << "SubNum:" << subnum << endl;
	int session = mxGetScalar(prhs[1]);
	cout << "Session:" << session << endl;
	char filename[50] = "";
	wsprintf(filename, "S%d_session%d_StimInfo.txt", subnum, session);
	ofstream outfile_stimInfo(filename, ofstream::app);//如果重复输入编号不会覆盖

	///打开串口///
	int nPort1 = mxGetScalar(prhs[2]), nPort2 = mxGetScalar(prhs[3]);;
	cout << "Port1: COM" << nPort1 << endl;
	outfile_stimInfo << nPort1 << endl;
	cout << "Port2: COM" << nPort2 << endl;
	outfile_stimInfo << nPort2 << endl;
	bool state_COM1;
	state_COM1 = OpenCOM(hCOM1, nPort1, 115200);
	if (!state_COM1) {
		outfile_stimInfo.close();
		//		CloseHandle(hCOM1);
		mexErrMsgTxt("Fail to open port1");
		exit(0);//串口打开不成功，退出程序
	}
	bool state_COM2;
	state_COM2 = OpenCOM(hCOM2, nPort2, 115200);
	if (!state_COM2) {
		outfile_stimInfo.close();
		CloseHandle(hCOM1);
		//CloseHandle(hCOM2);
		mexErrMsgTxt("Fail to open port2");
		exit(0);//串口打开不成功，退出程序
	}

	DWORD nWrite;
	const char c_OutputState1_close[] = ":w20=0,0.\n\r", c_OutputState2_close[] = ":w20=0,0.\n\r";
	const char c_amp11[] = ":w25=0.\n\r", c_amp12[] = ":w26=0.\n\r",
		c_amp21[] = ":w25=0.\n\r", c_amp22[] = ":w26=0.\n\r";
	const char c_OutputState1[] = ":w20=1,1.\n\r", c_OutputState2[] = ":w20=1,1.\n\r";

	///波形的基本参数设置///
	//暂时先硬编程，调试通过后改成软编程
	//初始幅值为0
	//幅值
	nWrite = print_COM(hCOM1, c_OutputState1, sizeof(c_OutputState1) / sizeof(const char));
	Sleep(1000);
	nWrite = print_COM(hCOM2, c_OutputState2, sizeof(c_OutputState2) / sizeof(const char));

	//刺激幅值和持续时间设置
	double delaytime = 0.01;//时间步长
	int TargetAmp1 = mxGetScalar(prhs[4]) * 1070;
	cout << "Amp1:" << TargetAmp1 << endl;
	outfile_stimInfo << TargetAmp1 << endl;
	int TargetAmp2 = mxGetScalar(prhs[5]) * 1070;
	cout << "Amp2:" << TargetAmp2 << endl;
	outfile_stimInfo << TargetAmp2 << endl;
	int StimDuration = mxGetScalar(prhs[6]);
	cout << "Duration(s):" << StimDuration << endl;
	outfile_stimInfo << StimDuration << endl;
	int StimType = mxGetScalar(prhs[7]);
	cout << "StimType (233 or 666):" << StimType << endl;//233为真实刺激，666为伪刺激
	outfile_stimInfo << StimType << endl;

	int Astep1 = round(TargetAmp1 / 500);
	int Astep2 = round(TargetAmp1 / 500);

	//开始输出波形
	//幅值线性上升
	for (int i_timepoint = 0; i_timepoint < 500; i_timepoint++) {
		char c_amp11[25] = "", c_amp12[25] = "",
			c_amp21[25] = "", c_amp22[25] = "";
		wsprintf(c_amp11, ":w25=%d.\n\r", i_timepoint * Astep1);
		wsprintf(c_amp12, ":w26=%d.\n\r", i_timepoint * Astep1);
		wsprintf(c_amp21, ":w25=%d.\n\r", i_timepoint * Astep2);
		wsprintf(c_amp22, ":w26=%d.\n\r", i_timepoint * Astep2);

		nWrite = print_COM(hCOM1, c_amp11, sizeof(c_amp11) / sizeof(char));
		cout << nWrite << endl;
		outfile_stimInfo << nWrite << endl;
		QueryPerformanceCounter(&litmp);
		QPart1 = litmp.QuadPart;// 获得初始值
		do {
			QueryPerformanceCounter(&litmp);
			QPart2 = litmp.QuadPart;//获得中止值
			dfMinus = (double)(QPart2 - QPart1);
			dfTim = dfMinus / dfFreq;// 获得对应的时间值，单位为秒
		} while (dfTim < delaytime);

		nWrite = print_COM(hCOM1, c_amp12, sizeof(c_amp12) / sizeof(char));
		cout << nWrite << endl;
		outfile_stimInfo << nWrite << endl;
		QueryPerformanceCounter(&litmp);
		QPart1 = litmp.QuadPart;// 获得初始值
		do {
			QueryPerformanceCounter(&litmp);
			QPart2 = litmp.QuadPart;//获得中止值
			dfMinus = (double)(QPart2 - QPart1);
			dfTim = dfMinus / dfFreq;// 获得对应的时间值，单位为秒
		} while (dfTim < delaytime);

		nWrite = print_COM(hCOM2, c_amp21, sizeof(c_amp21) / sizeof(char));
		cout << nWrite << endl;
		outfile_stimInfo << nWrite << endl;
		QueryPerformanceCounter(&litmp);
		QPart1 = litmp.QuadPart;// 获得初始值
		do {
			QueryPerformanceCounter(&litmp);
			QPart2 = litmp.QuadPart;//获得中止值
			dfMinus = (double)(QPart2 - QPart1);
			dfTim = dfMinus / dfFreq;// 获得对应的时间值，单位为秒
		} while (dfTim < delaytime);

		nWrite = print_COM(hCOM2, c_amp22, sizeof(c_amp22) / sizeof(char));
		cout << nWrite << endl;
		outfile_stimInfo << nWrite << endl;
		QueryPerformanceCounter(&litmp);
		QPart1 = litmp.QuadPart;// 获得初始值
		do {
			QueryPerformanceCounter(&litmp);
			QPart2 = litmp.QuadPart;//获得中止值
			dfMinus = (double)(QPart2 - QPart1);
			dfTim = dfMinus / dfFreq;// 获得对应的时间值，单位为秒
		} while (dfTim < delaytime);
	}

	//达到刺激的幅值
	char C_amp11[25] = "", C_amp12[25] = "",
		C_amp21[25] = "", C_amp22[25] = "";
	wsprintf(C_amp11, ":w25=%d.\n\r", TargetAmp1);
	wsprintf(C_amp12, ":w26=%d.\n\r", TargetAmp1);
	wsprintf(C_amp21, ":w25=%d.\n\r", TargetAmp2);
	wsprintf(C_amp22, ":w26=%d.\n\r", TargetAmp2);

	nWrite = print_COM(hCOM1, C_amp11, sizeof(C_amp11) / sizeof(char));
	cout << nWrite << endl;
	outfile_stimInfo << nWrite << endl;
	QueryPerformanceCounter(&litmp);
	QPart1 = litmp.QuadPart;// 获得初始值
	do {
		QueryPerformanceCounter(&litmp);
		QPart2 = litmp.QuadPart;//获得中止值
		dfMinus = (double)(QPart2 - QPart1);
		dfTim = dfMinus / dfFreq;// 获得对应的时间值，单位为秒
	} while (dfTim < delaytime);

	nWrite = print_COM(hCOM1, C_amp12, sizeof(C_amp12) / sizeof(char));
	cout << nWrite << endl;
	outfile_stimInfo << nWrite << endl;
	QueryPerformanceCounter(&litmp);
	QPart1 = litmp.QuadPart;// 获得初始值
	do {
		QueryPerformanceCounter(&litmp);
		QPart2 = litmp.QuadPart;//获得中止值
		dfMinus = (double)(QPart2 - QPart1);
		dfTim = dfMinus / dfFreq;// 获得对应的时间值，单位为秒
	} while (dfTim < delaytime);

	nWrite = print_COM(hCOM2, C_amp21, sizeof(C_amp21) / sizeof(char));
	cout << nWrite << endl;
	outfile_stimInfo << nWrite << endl;
	QueryPerformanceCounter(&litmp);
	QPart1 = litmp.QuadPart;// 获得初始值
	do {
		QueryPerformanceCounter(&litmp);
		QPart2 = litmp.QuadPart;//获得中止值
		dfMinus = (double)(QPart2 - QPart1);
		dfTim = dfMinus / dfFreq;// 获得对应的时间值，单位为秒
	} while (dfTim < delaytime);

	nWrite = print_COM(hCOM2, C_amp22, sizeof(C_amp22) / sizeof(char));
	cout << nWrite << endl;
	outfile_stimInfo << nWrite << endl;
	QueryPerformanceCounter(&litmp);
	QPart1 = litmp.QuadPart;// 获得初始值
	do {
		QueryPerformanceCounter(&litmp);
		QPart2 = litmp.QuadPart;//获得中止值
		dfMinus = (double)(QPart2 - QPart1);
		dfTim = dfMinus / dfFreq;// 获得对应的时间值，单位为秒
	} while (dfTim < delaytime);

	//真刺激维持一段时间，伪刺激直接电流下降
	if (StimType == 233) {
		//刺激持续
		QueryPerformanceCounter(&litmp);
		QPart1 = litmp.QuadPart;// 获得初始值
		do {
			QueryPerformanceCounter(&litmp);
			QPart2 = litmp.QuadPart;//获得中止值
			dfMinus = (double)(QPart2 - QPart1);
			dfTim = dfMinus / dfFreq;// 获得对应的时间值，单位为秒
		} while (dfTim < StimDuration);
	}

	//刺激结束，幅值线性下降
	outfile_stimInfo << "ramp down" << endl;
	for (int i_timepoint = 500-1; i_timepoint > -1; i_timepoint--) {
		char c_amp11[25] = "", c_amp12[25] = "",
			c_amp21[25] = "", c_amp22[25] = "";
		wsprintf(c_amp11, ":w25=%d.\n\r", i_timepoint * 4);
		wsprintf(c_amp12, ":w26=%d.\n\r", i_timepoint * 4);
		wsprintf(c_amp21, ":w25=%d.\n\r", i_timepoint * 4);
		wsprintf(c_amp22, ":w26=%d.\n\r", i_timepoint * 4);

		nWrite = print_COM(hCOM1, c_amp11, sizeof(c_amp11) / sizeof(char));
		cout << nWrite << endl;
		outfile_stimInfo << nWrite << endl;
		QueryPerformanceCounter(&litmp);
		QPart1 = litmp.QuadPart;// 获得初始值
		do {
			QueryPerformanceCounter(&litmp);
			QPart2 = litmp.QuadPart;//获得中止值
			dfMinus = (double)(QPart2 - QPart1);
			dfTim = dfMinus / dfFreq;// 获得对应的时间值，单位为秒
		} while (dfTim < delaytime);

		nWrite = print_COM(hCOM1, c_amp12, sizeof(c_amp12) / sizeof(char));
		cout << nWrite << endl;
		outfile_stimInfo << nWrite << endl;
		QueryPerformanceCounter(&litmp);
		QPart1 = litmp.QuadPart;// 获得初始值
		do {
			QueryPerformanceCounter(&litmp);
			QPart2 = litmp.QuadPart;//获得中止值
			dfMinus = (double)(QPart2 - QPart1);
			dfTim = dfMinus / dfFreq;// 获得对应的时间值，单位为秒
		} while (dfTim < delaytime);

		nWrite = print_COM(hCOM2, c_amp21, sizeof(c_amp21) / sizeof(char));
		cout << nWrite << endl;
		outfile_stimInfo << nWrite << endl;
		QueryPerformanceCounter(&litmp);
		QPart1 = litmp.QuadPart;// 获得初始值
		do {
			QueryPerformanceCounter(&litmp);
			QPart2 = litmp.QuadPart;//获得中止值
			dfMinus = (double)(QPart2 - QPart1);
			dfTim = dfMinus / dfFreq;// 获得对应的时间值，单位为秒
		} while (dfTim < delaytime);

		nWrite = print_COM(hCOM2, c_amp22, sizeof(c_amp22) / sizeof(char));
		cout << nWrite << endl;
		outfile_stimInfo << nWrite << endl;
		QueryPerformanceCounter(&litmp);
		QPart1 = litmp.QuadPart;// 获得初始值
		do {
			QueryPerformanceCounter(&litmp);
			QPart2 = litmp.QuadPart;//获得中止值
			dfMinus = (double)(QPart2 - QPart1);
			dfTim = dfMinus / dfFreq;// 获得对应的时间值，单位为秒
		} while (dfTim < delaytime);
	}
	//伪刺激,电流下降完成后再持续一段时间显示"刺激已停止"
	if (StimType == 666) {
		//刺激持续
		QueryPerformanceCounter(&litmp);
		QPart1 = litmp.QuadPart;// 获得初始值
		do {
			QueryPerformanceCounter(&litmp);
			QPart2 = litmp.QuadPart;//获得中止值
			dfMinus = (double)(QPart2 - QPart1);
			dfTim = dfMinus / dfFreq;// 获得对应的时间值，单位为秒
		} while (dfTim < StimDuration);
	}
	//关闭输出
	//const char c_OutputState1_close[] = ":w20=0,0.\n\r", c_OutputState2_close[] = ":w20=0,0.\n\r";
	nWrite = print_COM(hCOM1, c_OutputState1_close, sizeof(c_OutputState1_close) / sizeof(const char));
	cout << nWrite << endl;
	outfile_stimInfo << nWrite << endl;
	Sleep(1000);
	nWrite = print_COM(hCOM2, c_OutputState2_close, sizeof(c_OutputState2_close) / sizeof(const char));
	cout << nWrite << endl;
	outfile_stimInfo << nWrite << endl;
	Sleep(1000);
	cout << "The end of the stimulation" << endl;
	cin.get();
	///关闭///
	outfile_stimInfo.close();
	CloseHandle(hCOM1);
	CloseHandle(hCOM2);
}
