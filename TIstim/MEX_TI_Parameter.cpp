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
	cout << "Subnum:" << subnum << endl;
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

	int freq1 = mxGetScalar(prhs[4]), freq2 = mxGetScalar(prhs[5]);
	cout << "Freq1:" << freq1 << endl;
	outfile_stimInfo << freq1 << endl;
	cout << "Freq2:" << freq2 << endl;
	outfile_stimInfo << freq2 << endl;

	DWORD nWrite;
	const char c_OutputState1_close[] = ":w20=0,0.\n\r", c_OutputState2_close[] = ":w20=0,0.\n\r";
	const char c_amp11[] = ":w25=0.\n\r", c_amp12[] = ":w26=0.\n\r",
		c_amp21[] = ":w25=0.\n\r", c_amp22[] = ":w26=0.\n\r";
	char c_fre11[25] = "", c_fre12[25] = "",
		c_fre21[25] = "", c_fre22[25] = "";
	wsprintf(c_fre11, ":w23=%d.\n\r", freq1 * 100);
	wsprintf(c_fre12, ":w24=%d.\n\r", freq1 * 100);
	wsprintf(c_fre21, ":w23=%d.\n\r", freq2 * 100);
	wsprintf(c_fre22, ":w24=%d.\n\r", freq2 * 100);
	const char c_fresyn1[] = ":w54=1,0,0,0,0.\n\r", c_fresyn2[] = ":w54=1,0,0,0,0.\n\r";
	const char c_phase1[] = ":w31=1800.\n\r", c_phase2[] = ":w31=1800.\n\r";
	const char c_OutputState1[] = ":w20=1,1.\n\r", c_OutputState2[] = ":w20=1,1.\n\r";

	///波形的基本参数设置///
	//暂时先硬编程，调试通过后改成软编程
	//初始幅值为0
	//幅值
	nWrite = print_COM(hCOM1, c_OutputState1_close, sizeof(c_OutputState1_close) / sizeof(const char));
	Sleep(1000);
	nWrite = print_COM(hCOM2, c_OutputState2_close, sizeof(c_OutputState2_close) / sizeof(const char));

	nWrite = print_COM(hCOM1, c_amp11, sizeof(c_amp11) / sizeof(const char));
	cout << nWrite << endl;
	outfile_stimInfo << nWrite << endl;
	Sleep(1000);//太快容易漏掉命令
	nWrite = print_COM(hCOM1, c_amp12, sizeof(c_amp12) / sizeof(const char));
	cout << nWrite << endl;
	outfile_stimInfo << nWrite << endl;
	Sleep(1000);
	nWrite = print_COM(hCOM2, c_amp21, sizeof(c_amp21) / sizeof(const char));
	cout << nWrite << endl;
	outfile_stimInfo << nWrite << endl;
	Sleep(1000);
	nWrite = print_COM(hCOM2, c_amp22, sizeof(c_amp22) / sizeof(const char));
	cout << nWrite << endl;
	outfile_stimInfo << nWrite << endl;
	Sleep(1000);
	//频率
	nWrite = print_COM(hCOM1, c_fre11, sizeof(c_fre11) / sizeof(const char));
	cout << nWrite << endl;
	outfile_stimInfo << nWrite << endl;
	Sleep(1000);
	nWrite = print_COM(hCOM1, c_fre12, sizeof(c_fre12) / sizeof(const char));
	cout << nWrite << endl;
	outfile_stimInfo << nWrite << endl;
	Sleep(1000);
	nWrite = print_COM(hCOM2, c_fre21, sizeof(c_fre21) / sizeof(const char));
	cout << nWrite << endl;
	outfile_stimInfo << nWrite << endl;
	Sleep(1000);
	nWrite = print_COM(hCOM2, c_fre22, sizeof(c_fre22) / sizeof(const char));
	cout << nWrite << endl;
	outfile_stimInfo << nWrite << endl;
	Sleep(1000);
	//设置频率同步
	nWrite = print_COM(hCOM1, c_fresyn1, sizeof(c_fresyn1) / sizeof(const char));
	cout << nWrite << endl;
	outfile_stimInfo << nWrite << endl;
	Sleep(1000);
	nWrite = print_COM(hCOM2, c_fresyn2, sizeof(c_fresyn2) / sizeof(const char));
	cout << nWrite << endl;
	outfile_stimInfo << nWrite << endl;
	Sleep(1000);
	//相位
	nWrite = print_COM(hCOM1, c_phase1, sizeof(c_phase1) / sizeof(const char));
	cout << nWrite << endl;
	outfile_stimInfo << nWrite << endl;
	Sleep(1000);
	nWrite = print_COM(hCOM2, c_phase2, sizeof(c_phase2) / sizeof(const char));
	cout << nWrite << endl;
	outfile_stimInfo << nWrite << endl;
	Sleep(1000);

	///关闭///
	outfile_stimInfo.close();
	CloseHandle(hCOM1);
	CloseHandle(hCOM2);
}
