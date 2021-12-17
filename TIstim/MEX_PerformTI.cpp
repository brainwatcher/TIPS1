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
HANDLE hCOM1;//���ڻ�ȡ���ڴ򿪺����ķ���ֵ����������ֵ��
HANDLE hCOM2;//���ڻ�ȡ���ڴ򿪺����ķ���ֵ����������ֵ��
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
		//FILE_ATTRIBUTE_NORMAL | FILE_FLAG_OVERLAPPED, //�첽ͨ��
		0,//ͬ��ͨ��
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
	PurgeComm(hCom, PURGE_TXCLEAR | PURGE_RXCLEAR);//��ջ�����
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

	///��ü�������ʱ��Ƶ�ʣ��Խ��о�ȷ��ʱ///
	LARGE_INTEGER litmp;
	LONGLONG QPart1, QPart2;
	double dfMinus, dfFreq, dfTim;
	QueryPerformanceFrequency(&litmp);
	dfFreq = (double)litmp.QuadPart;

	//�����ļ��Ա�洢�����������
	int subnum = mxGetScalar(prhs[0]);
	cout << "SubNum:" << subnum << endl;
	int session = mxGetScalar(prhs[1]);
	cout << "Session:" << session << endl;
	char filename[50] = "";
	wsprintf(filename, "S%d_session%d_StimInfo.txt", subnum, session);
	ofstream outfile_stimInfo(filename, ofstream::app);//����ظ������Ų��Ḳ��

	///�򿪴���///
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
		exit(0);//���ڴ򿪲��ɹ����˳�����
	}
	bool state_COM2;
	state_COM2 = OpenCOM(hCOM2, nPort2, 115200);
	if (!state_COM2) {
		outfile_stimInfo.close();
		CloseHandle(hCOM1);
		//CloseHandle(hCOM2);
		mexErrMsgTxt("Fail to open port2");
		exit(0);//���ڴ򿪲��ɹ����˳�����
	}

	DWORD nWrite;
	const char c_OutputState1_close[] = ":w20=0,0.\n\r", c_OutputState2_close[] = ":w20=0,0.\n\r";
	const char c_amp11[] = ":w25=0.\n\r", c_amp12[] = ":w26=0.\n\r",
		c_amp21[] = ":w25=0.\n\r", c_amp22[] = ":w26=0.\n\r";
	const char c_OutputState1[] = ":w20=1,1.\n\r", c_OutputState2[] = ":w20=1,1.\n\r";

	///���εĻ�����������///
	//��ʱ��Ӳ��̣�����ͨ����ĳ�����
	//��ʼ��ֵΪ0
	//��ֵ
	nWrite = print_COM(hCOM1, c_OutputState1, sizeof(c_OutputState1) / sizeof(const char));
	Sleep(1000);
	nWrite = print_COM(hCOM2, c_OutputState2, sizeof(c_OutputState2) / sizeof(const char));

	//�̼���ֵ�ͳ���ʱ������
	double delaytime = 0.01;//ʱ�䲽��
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
	cout << "StimType (233 or 666):" << StimType << endl;//233Ϊ��ʵ�̼���666Ϊα�̼�
	outfile_stimInfo << StimType << endl;

	int Astep1 = round(TargetAmp1 / 500);
	int Astep2 = round(TargetAmp1 / 500);

	//��ʼ�������
	//��ֵ��������
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
		QPart1 = litmp.QuadPart;// ��ó�ʼֵ
		do {
			QueryPerformanceCounter(&litmp);
			QPart2 = litmp.QuadPart;//�����ֵֹ
			dfMinus = (double)(QPart2 - QPart1);
			dfTim = dfMinus / dfFreq;// ��ö�Ӧ��ʱ��ֵ����λΪ��
		} while (dfTim < delaytime);

		nWrite = print_COM(hCOM1, c_amp12, sizeof(c_amp12) / sizeof(char));
		cout << nWrite << endl;
		outfile_stimInfo << nWrite << endl;
		QueryPerformanceCounter(&litmp);
		QPart1 = litmp.QuadPart;// ��ó�ʼֵ
		do {
			QueryPerformanceCounter(&litmp);
			QPart2 = litmp.QuadPart;//�����ֵֹ
			dfMinus = (double)(QPart2 - QPart1);
			dfTim = dfMinus / dfFreq;// ��ö�Ӧ��ʱ��ֵ����λΪ��
		} while (dfTim < delaytime);

		nWrite = print_COM(hCOM2, c_amp21, sizeof(c_amp21) / sizeof(char));
		cout << nWrite << endl;
		outfile_stimInfo << nWrite << endl;
		QueryPerformanceCounter(&litmp);
		QPart1 = litmp.QuadPart;// ��ó�ʼֵ
		do {
			QueryPerformanceCounter(&litmp);
			QPart2 = litmp.QuadPart;//�����ֵֹ
			dfMinus = (double)(QPart2 - QPart1);
			dfTim = dfMinus / dfFreq;// ��ö�Ӧ��ʱ��ֵ����λΪ��
		} while (dfTim < delaytime);

		nWrite = print_COM(hCOM2, c_amp22, sizeof(c_amp22) / sizeof(char));
		cout << nWrite << endl;
		outfile_stimInfo << nWrite << endl;
		QueryPerformanceCounter(&litmp);
		QPart1 = litmp.QuadPart;// ��ó�ʼֵ
		do {
			QueryPerformanceCounter(&litmp);
			QPart2 = litmp.QuadPart;//�����ֵֹ
			dfMinus = (double)(QPart2 - QPart1);
			dfTim = dfMinus / dfFreq;// ��ö�Ӧ��ʱ��ֵ����λΪ��
		} while (dfTim < delaytime);
	}

	//�ﵽ�̼��ķ�ֵ
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
	QPart1 = litmp.QuadPart;// ��ó�ʼֵ
	do {
		QueryPerformanceCounter(&litmp);
		QPart2 = litmp.QuadPart;//�����ֵֹ
		dfMinus = (double)(QPart2 - QPart1);
		dfTim = dfMinus / dfFreq;// ��ö�Ӧ��ʱ��ֵ����λΪ��
	} while (dfTim < delaytime);

	nWrite = print_COM(hCOM1, C_amp12, sizeof(C_amp12) / sizeof(char));
	cout << nWrite << endl;
	outfile_stimInfo << nWrite << endl;
	QueryPerformanceCounter(&litmp);
	QPart1 = litmp.QuadPart;// ��ó�ʼֵ
	do {
		QueryPerformanceCounter(&litmp);
		QPart2 = litmp.QuadPart;//�����ֵֹ
		dfMinus = (double)(QPart2 - QPart1);
		dfTim = dfMinus / dfFreq;// ��ö�Ӧ��ʱ��ֵ����λΪ��
	} while (dfTim < delaytime);

	nWrite = print_COM(hCOM2, C_amp21, sizeof(C_amp21) / sizeof(char));
	cout << nWrite << endl;
	outfile_stimInfo << nWrite << endl;
	QueryPerformanceCounter(&litmp);
	QPart1 = litmp.QuadPart;// ��ó�ʼֵ
	do {
		QueryPerformanceCounter(&litmp);
		QPart2 = litmp.QuadPart;//�����ֵֹ
		dfMinus = (double)(QPart2 - QPart1);
		dfTim = dfMinus / dfFreq;// ��ö�Ӧ��ʱ��ֵ����λΪ��
	} while (dfTim < delaytime);

	nWrite = print_COM(hCOM2, C_amp22, sizeof(C_amp22) / sizeof(char));
	cout << nWrite << endl;
	outfile_stimInfo << nWrite << endl;
	QueryPerformanceCounter(&litmp);
	QPart1 = litmp.QuadPart;// ��ó�ʼֵ
	do {
		QueryPerformanceCounter(&litmp);
		QPart2 = litmp.QuadPart;//�����ֵֹ
		dfMinus = (double)(QPart2 - QPart1);
		dfTim = dfMinus / dfFreq;// ��ö�Ӧ��ʱ��ֵ����λΪ��
	} while (dfTim < delaytime);

	//��̼�ά��һ��ʱ�䣬α�̼�ֱ�ӵ����½�
	if (StimType == 233) {
		//�̼�����
		QueryPerformanceCounter(&litmp);
		QPart1 = litmp.QuadPart;// ��ó�ʼֵ
		do {
			QueryPerformanceCounter(&litmp);
			QPart2 = litmp.QuadPart;//�����ֵֹ
			dfMinus = (double)(QPart2 - QPart1);
			dfTim = dfMinus / dfFreq;// ��ö�Ӧ��ʱ��ֵ����λΪ��
		} while (dfTim < StimDuration);
	}

	//�̼���������ֵ�����½�
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
		QPart1 = litmp.QuadPart;// ��ó�ʼֵ
		do {
			QueryPerformanceCounter(&litmp);
			QPart2 = litmp.QuadPart;//�����ֵֹ
			dfMinus = (double)(QPart2 - QPart1);
			dfTim = dfMinus / dfFreq;// ��ö�Ӧ��ʱ��ֵ����λΪ��
		} while (dfTim < delaytime);

		nWrite = print_COM(hCOM1, c_amp12, sizeof(c_amp12) / sizeof(char));
		cout << nWrite << endl;
		outfile_stimInfo << nWrite << endl;
		QueryPerformanceCounter(&litmp);
		QPart1 = litmp.QuadPart;// ��ó�ʼֵ
		do {
			QueryPerformanceCounter(&litmp);
			QPart2 = litmp.QuadPart;//�����ֵֹ
			dfMinus = (double)(QPart2 - QPart1);
			dfTim = dfMinus / dfFreq;// ��ö�Ӧ��ʱ��ֵ����λΪ��
		} while (dfTim < delaytime);

		nWrite = print_COM(hCOM2, c_amp21, sizeof(c_amp21) / sizeof(char));
		cout << nWrite << endl;
		outfile_stimInfo << nWrite << endl;
		QueryPerformanceCounter(&litmp);
		QPart1 = litmp.QuadPart;// ��ó�ʼֵ
		do {
			QueryPerformanceCounter(&litmp);
			QPart2 = litmp.QuadPart;//�����ֵֹ
			dfMinus = (double)(QPart2 - QPart1);
			dfTim = dfMinus / dfFreq;// ��ö�Ӧ��ʱ��ֵ����λΪ��
		} while (dfTim < delaytime);

		nWrite = print_COM(hCOM2, c_amp22, sizeof(c_amp22) / sizeof(char));
		cout << nWrite << endl;
		outfile_stimInfo << nWrite << endl;
		QueryPerformanceCounter(&litmp);
		QPart1 = litmp.QuadPart;// ��ó�ʼֵ
		do {
			QueryPerformanceCounter(&litmp);
			QPart2 = litmp.QuadPart;//�����ֵֹ
			dfMinus = (double)(QPart2 - QPart1);
			dfTim = dfMinus / dfFreq;// ��ö�Ӧ��ʱ��ֵ����λΪ��
		} while (dfTim < delaytime);
	}
	//α�̼�,�����½���ɺ��ٳ���һ��ʱ����ʾ"�̼���ֹͣ"
	if (StimType == 666) {
		//�̼�����
		QueryPerformanceCounter(&litmp);
		QPart1 = litmp.QuadPart;// ��ó�ʼֵ
		do {
			QueryPerformanceCounter(&litmp);
			QPart2 = litmp.QuadPart;//�����ֵֹ
			dfMinus = (double)(QPart2 - QPart1);
			dfTim = dfMinus / dfFreq;// ��ö�Ӧ��ʱ��ֵ����λΪ��
		} while (dfTim < StimDuration);
	}
	//�ر����
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
	///�ر�///
	outfile_stimInfo.close();
	CloseHandle(hCOM1);
	CloseHandle(hCOM2);
}
