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

#if defined _emperor_files_included
	#endinput
#endif
#define _emperor_files_included

enum EMP_MediaType
{
	emp_type_Generic = 0,
	emp_type_Sound,
	emp_type_Material,
	emp_type_Model,
	emp_type_Decal
};

/**
* Checks if the Directory exists. If not it creates it.
*
* @param path				Path to the directory (Example cfg/Something)
* @return					Returns true if the directory exists or generated. False if there was an error.
*/
stock bool EMP_DirExistsEx(const char[] path)
{
	if (!DirExists(path))
	{
		CreateDirectory(path, 511);

		if (!DirExists(path))
		{
			LogError("Couldn't create folder! (%s)", path);
			return false;
		}
	}

	return true;
}

/**
* Sets a new log file to use by the script.
*
* @param path				Path to the log file.
* @param file				File name without extension (Like "logfile")
* @param path				Subfolder to search the log in. (Like "Something" from EMP_DirExistsEx)
*/
stock void EMP_SetLogFile(char path[PLATFORM_MAX_PATH], char[] file, char[] folder)
{
	char sDate[12];
	FormatTime(sDate, sizeof(sDate), "%y-%m-%d");
	Format(path, sizeof(path), "logs/%s/%s-%s.log", folder, file, sDate);

	BuildPath(Path_SM, path, sizeof(path), path);
}

/**
* Chaches the file
*
* @param path				Path to the log file.
* @param filetype			Type of the file (emp_type_Generic, emp_type_Sound, emp_type_Material, emp_type_Model, emp_type_Decal)
*/
stock void EMP_CacheTheFile(const char[] path, EMP_MediaType filetype)
{
	char sDownloadPath[PLATFORM_MAX_PATH];
	switch (filetype)
	{
		case emp_type_Sound:
		{
			PrecacheSoundAny(path, true);
			Format(sDownloadPath, PLATFORM_MAX_PATH, "sound/%s", path);
			AddFileToDownloadsTable(sDownloadPath);
		}
		case emp_type_Decal, emp_type_Material:
		{
			PrecacheDecal(path, true);
			Format(sDownloadPath, PLATFORM_MAX_PATH, "materials/%s", path);
			AddFileToDownloadsTable(sDownloadPath);
		}
		case emp_type_Model:
		{
			PrecacheModel(path, true);
			Format(sDownloadPath, PLATFORM_MAX_PATH, "models/%s", path);
			AddFileToDownloadsTable(sDownloadPath);
		}
		default:
		{
			PrecacheGeneric(path, true);
			AddFileToDownloadsTable(path);			
		}
	}
}