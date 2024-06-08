/*

OSClstrk
v0.1 240603 https://github.com/GapVR
------------
Sends an OSC int packet to /avatar/parameters/OSClstrk with OpenVR device tracking state.

Bit	Int	Device

	0	None

TrackedDeviceClass_Controller:

0	1	LeftHand
1	2	RightHand

TrackedDeviceClass_GenericTracker:

2	4	LeftFoot
3	8	RightFoot
4	16	LeftShoulder
5	32	RightShoulder
6	64	LeftElbow
7	128	RightElbow
8	256	LeftKnee
9	512	RightKnee
10	1024	Waist
11	2048	Chest


References:
https://github.com/clarte53/openvr-tracking

*/

#define _CRT_SECURE_NO_WARNINGS

#include <signal.h>
#include <Ws2tcpip.h>

#include <iomanip>
#include <iostream>
#include <sstream>
#include <thread>
#include <list>
#include <chrono>

#include "openvr.h"

bool lastTrack[20] = {0};
vr::TrackedDevicePose_t poses[vr::k_unMaxTrackedDeviceCount];

std::string OSChost{"127.0.0.1"};
int OSCport = 9000;

void sendOSC(const int OSClstrk)
{
	WSADATA wsaData;
	if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0)
	{
		std::cerr << "Winsock: Startup error." << std::endl;
		return;
	}

	SOCKET sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
	if (sock == INVALID_SOCKET)
	{
		std::cerr << "Winsock: Invalid socket." << std::endl;
		WSACleanup();
		return;
	}

	sockaddr_in dest;
	dest.sin_family = AF_INET;
	dest.sin_port = htons(OSCport);
	inet_pton(AF_INET, OSChost.c_str(), &dest.sin_addr.s_addr);

	std::string payload("/avatar/parameters/OSClstrk\0,i\0\0\0\0\0\0",36);

	// memcpy(&payload[28], &OSClstrk, sizeof(OSClstrk)); // debugging
	memcpy(&payload[34], (char*)&OSClstrk + 1, 1);
	memcpy(&payload[35], (char*)&OSClstrk, 1);

	int n_bytes = ::sendto(sock, payload.data(), int(36), 0, reinterpret_cast <sockaddr*> (&dest), sizeof(dest));

	closesocket(sock);

	WSACleanup();
}

void exit_handler(int signum)
{
	std::cout << "Interrupt signal (" << signum << ") received.\n";
	vr::VR_Shutdown();
	sendOSC(0);
	exit(0);
}

int main(int argc, const char* argv[])
{
	const unsigned int default_frequency = 200; // In milliseconds
	int parameter_frequency = (argc > 1 ? atoi(argv[1]) : 0);
	unsigned int frequency = (parameter_frequency > default_frequency ? parameter_frequency : default_frequency);

	vr::EVRInitError error;
	vr::IVRSystem* vr_system = vr::VR_Init(&error, vr::EVRApplicationType::VRApplication_Background);

	if (error == vr::EVRInitError::VRInitError_None)
	{
		signal(SIGINT, &exit_handler);
		signal(SIGBREAK, &exit_handler);	// window close

		while (true)
		{

			// collect data
			vr_system->GetDeviceToAbsoluteTrackingPose(vr::ETrackingUniverseOrigin::TrackingUniverseStanding, 0, poses, vr::k_unMaxTrackedDeviceCount);

			int OSClstrk = 0;

			for (vr::TrackedDeviceIndex_t idx = 1; idx < vr::k_unMaxTrackedDeviceCount; ++idx)
			{
				if (!(vr_system->IsTrackedDeviceConnected(idx))) continue;

				int currtype = 0;

				vr::ETrackedDeviceClass trackedDeviceClass = vr_system->GetTrackedDeviceClass(idx);

				char buffer[1024];

				vr_system->GetStringTrackedDeviceProperty(idx, vr::ETrackedDeviceProperty::Prop_ControllerType_String, buffer, 1024);
				std::string type(buffer);

				if (trackedDeviceClass == vr::ETrackedDeviceClass::TrackedDeviceClass_Controller)
				{
					vr::ETrackedControllerRole role = vr_system->GetControllerRoleForTrackedDeviceIndex(idx);
					if (role == vr::ETrackedControllerRole::TrackedControllerRole_LeftHand)
					{
						currtype = 0;
					}
					if (role == vr::ETrackedControllerRole::TrackedControllerRole_RightHand)
					{
						currtype = 1;
					}
				}
				else if (trackedDeviceClass == vr::ETrackedDeviceClass::TrackedDeviceClass_GenericTracker)
				{
					if (type[type.length() - 5] == 'w') { currtype = 10; } // waist
					else if (type[type.length() - 5] == 'c') { currtype = 11; } // chest
					else if (type[type.length() - 1] == 't') { if (type[type.length() - 7] == 'f') currtype = 2; else currtype = 3; } // left_foot, right_foot
					else if (type[type.length() - 1] == 'e') { if (type[type.length() - 7] == 'f') currtype = 8; else currtype = 9; } // left_knee, right_knee
					else if (type[type.length() - 1] == 'w') { if (type[type.length() - 8] == 'f') currtype = 6; else currtype = 7; } // left_elbow, right_elbow
					else if (type[type.length() - 11] == 'f') { currtype = 4; } // left_shoulder
					else if (type[type.length() - 11] == 'h') { currtype = 5; } // right_shoulder
				}
				else
				{
					continue;
				}

				if (poses[idx].bPoseIsValid == false)
					OSClstrk += 1 << currtype;

				vr_system->GetStringTrackedDeviceProperty(idx, vr::ETrackedDeviceProperty::Prop_SerialNumber_String, buffer, 1024);
				std::string serial(buffer);

				const auto now = std::chrono::system_clock::now();
				const std::time_t now_c = std::chrono::system_clock::to_time_t(now);
				const std::chrono::milliseconds nowms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()) % 1000;
				const std::string timestr = (std::ostringstream {} << std::put_time(std::localtime(&now_c), "%H:%M:%S") << "." << std::setfill('0') << std::setw(3) << nowms.count()).str();

				if (lastTrack[currtype] == true)
				{
					if (poses[idx].bPoseIsValid == false)
					{
						std::cout << timestr << " #" << idx << " [" << type << "|" << serial << "] LOST !" << std::endl;
						lastTrack[currtype] = false;
					}
				} else {
					if (poses[idx].bPoseIsValid == true)
					{
						std::cout << timestr << " #" << idx << " [" << type << "|" << serial << "] Tracking" << std::endl;
						lastTrack[currtype] = true;
					}
				}
			}

			sendOSC(OSClstrk);

			std::this_thread::sleep_for(std::chrono::milliseconds(frequency));
		}
	}
	else
		std::cout << "OpenVR Error: " << VR_GetVRInitErrorAsSymbol(error) << std::endl;

	return 1;
}
