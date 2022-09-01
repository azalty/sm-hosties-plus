/*
 * SourceMod Entity Projects
 * by: Entity
 *
 * Copyright (C) 2020 Kőrösfalvi "Entity" Martin
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <profiler>

#if defined _emperor_debug_included
	#endinput
#endif
#define _emperor_debug_included

Handle EMP_Benchmark = null;

float emp_min, emp_max, emp_avg;
int  emp_runcount;

/**
* Sends a chat message only for Entity
*
* @param message				Message to send
*/
stock void EMP_PrintToEntity(char[] message)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(EMP_IsValidClient(i))
		{
			char SteamID[50];
			GetClientAuthId(i, AuthId_Steam2, SteamID, sizeof(SteamID));
			if(StrContains(SteamID, ":192658869"))
			{
				PrintToChat(i, message);
			}
		}
	}
}

/**
* Creates the Benchmark profiler
*/
stock void EMP_CreateProfiler()
{
	if (EMP_Benchmark != null)
		delete EMP_Benchmark;
	EMP_Benchmark = CreateProfiler();
}

/**
* Starts the Benchmark profiler
*/
stock void EMP_StartProfiler(bool reset = true)
{
	if (EMP_Benchmark == null)
		EMP_CreateProfiler();
	
	if (reset)
	{
		emp_min = 10.0;
		emp_max = 0.0;
		emp_avg = 0.0;
		emp_runcount = 0;
	}
	else
	{
		emp_runcount++;
	}
	
	EMP_PrintToEntity("\x02[DEBUG]\x10 Profiler started.");
	StartProfiling(EMP_Benchmark);
}

/**
* Starts / Stops debug tracing
*/
stock void EMP_Debugger(bool emp_state)
{
	if (!emp_state)
	{
		ConVar ConVar_LogFile = FindConVar("con_logfile");
		char origpath[256];
		
		ConVar_LogFile.GetString(origpath, sizeof(origpath));
		
		ServerCommand("sm prof stop; con_logfile vprof.log; sm prof dump vprof; con_logfile \"%s\";", origpath);
		ServerExecute();
		
		EMP_PrintToEntity("\x02[DEBUG]\x10 Results are saved and debugger stopped.");
		delete ConVar_LogFile;
	}
	else
	{
		EMP_PrintToEntity("\x02[DEBUG]\x10 Starting debug...");
		
		ServerCommand("sm prof start");
		ServerExecute();
	}
}

/**
* Resets the profiler variables
*/
stock void EMP_ResetProfiler()
{
	emp_min = 10.0;
	emp_max = 0.0;
	emp_avg = 0.0;
	emp_runcount = 0;
}

/**
* Stops the Benchmark profiler and saves the result
*
* @param name				The name of the profiling to save the values with
*/
stock void EMP_StopProfiler(char[] name, bool last = true)
{
	if (EMP_Benchmark != null)
	{
		StopProfiling(EMP_Benchmark);
		
		char gShadow_Emperor_Benchmark_LogFile[PLATFORM_MAX_PATH], gShadow_Emperor_Benchmark_LogFolder[PLATFORM_MAX_PATH];
		
		BuildPath(Path_SM, gShadow_Emperor_Benchmark_LogFolder, sizeof(gShadow_Emperor_Benchmark_LogFolder), "logs/Emperor");
		
		EMP_DirExistsEx(gShadow_Emperor_Benchmark_LogFolder);
		EMP_SetLogFile(gShadow_Emperor_Benchmark_LogFile, "Benchmark", "Emperor");
		
		float emp_speed = GetProfilerTime(EMP_Benchmark);
		if( emp_speed < emp_min ) emp_min = emp_speed;
		if( emp_speed > emp_max ) emp_max = emp_speed;
		emp_avg += emp_speed;

		if (last)
		{
			emp_avg /= emp_runcount;
			LogToFileEx(gShadow_Emperor_Benchmark_LogFile, "Benchmark - Profiling: %s -> Min %f. Avg %f. Max %f", name, emp_min, emp_avg, emp_max);
			EMP_PrintToEntity("\x02[DEBUG]\x10 Profiler stopped and saved.");
			delete EMP_Benchmark;
		}
	}
}