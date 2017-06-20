/*  SM Admin List Advanced
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#pragma semicolon 1
#include <sourcemod>
#include <multicolors>

#define DATA "v4.0"

new Handle:listadeadmins = INVALID_HANDLE;
new Handle:cvar_menu = INVALID_HANDLE;

enum Numeros
{
	String:steamid[24],
	String:tag[64],
	String:hide[24]
}

new g_list[1024][Numeros];
new g_ListCount;

new Handle:g_ListIndex = INVALID_HANDLE;

new bool:usemenu;


public Plugin:myinfo =
{
	name = "SM Admin List Advanced",
	author = "Franc1sco franug",
	description = "A configurable admin list sytem",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	CreateConVar("sm_adminlist_advanced", DATA, "version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cvar_menu = CreateConVar("sm_adminlist_menu", "0", "1 = show admins in menu. 0 = show admins in chat");

	AddCommandListener(Command_Admins,"sm_admins");
	
	RegAdminCmd("sm_adminlist_reload", RecargarLista, ADMFLAG_ROOT);

	HookConVarChange(cvar_menu, CVarChange2);

}

public CVarChange2(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
}

public GetCVars()
{
	usemenu = GetConVarBool(cvar_menu);

}

public OnMapStart()
{
	if (listadeadmins != INVALID_HANDLE)
		CloseHandle(listadeadmins);
    
	listadeadmins = CreateKeyValues("adminlist_advanced");
    
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/adminlist_advanced.txt");
    
	if (!FileToKeyValues(listadeadmins, path))
	{
		SetFailState("\"%s\" missing from server", path);
	}
	if (!KvGotoFirstSubKey(listadeadmins))
	{
		SetFailState("Can't parse items config file.");
	}
	
	
	GetCVars();
	RecargarListaCache();
}

public Action:Command_Admins(client,const char[] command, args)
{
	Comando_Admins(client);
	return Plugin_Stop;

}

public Action:RecargarLista(client, args)
{
	if (listadeadmins != INVALID_HANDLE)
		CloseHandle(listadeadmins);
    
	listadeadmins = CreateKeyValues("adminlist_advanced");
    
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/adminlist_advanced.txt");
    
	if (!FileToKeyValues(listadeadmins, path))
	{
		SetFailState("\"%s\" missing from server", path);
	}
	if (!KvGotoFirstSubKey(listadeadmins))
	{
		SetFailState("Can't parse items config file.");
	}
	
	RecargarListaCache();

	if(client == 0)
		PrintToServer("[SM_ADMINLIST_ADVANCED] admin list reloaded successfully");
	else
		PrintToChat(client, "[SM_ADMINLIST_ADVANCED] admin list reloaded successfully");

	return Plugin_Handled;

}

RecargarListaCache()
{
	if (g_ListIndex != INVALID_HANDLE)
		CloseHandle(g_ListIndex);
		
	g_ListIndex = CreateTrie();
	g_ListCount = 0;
	
	decl String:steamid_kv[24];
	
	do
	{
			KvGetSectionName(listadeadmins, steamid_kv, sizeof(steamid_kv));
			strcopy(g_list[g_ListCount][steamid], sizeof(steamid_kv), steamid_kv);
			
			//PrintToChatAll(g_list[g_ListCount][steamid]);
			
			SetTrieValue(g_ListIndex, g_list[g_ListCount][steamid], g_ListCount);
			
			KvGetString(listadeadmins, "tag", g_list[g_ListCount][tag], 64);
			KvGetString(listadeadmins, "hide", g_list[g_ListCount][hide], 24);
			
			g_ListCount++;
			
	} while (KvGotoNextKey(listadeadmins));
	KvRewind(listadeadmins);
}

Comando_Admins(client)
{
	new Adms[129],count = 0;
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && GetUserAdmin(i) != INVALID_ADMIN_ID) Adms[count++] = i;

	if (count)
	{
		if(usemenu)
		{
			new Handle:menu = CreateMenu(DIDMenuHandler);
			SetMenuTitle(menu, "ADMIN LIST ADVANCED");
			for (new i = 0; i < count; i++)
			{
				//KvRewind(listadeadmins);
				decl String:status_steamid[24];
				GetClientAuthId(Adms[i], AuthId_Engine, status_steamid, sizeof(status_steamid));

				new listado = -1;
				if (GetTrieValue(g_ListIndex, status_steamid, listado))
				{

					if (StrContains(g_list[listado][hide], "yes", true) == -1)
					{

						decl String:paraelmenu[128];
						Format(paraelmenu,sizeof(paraelmenu),"%s %N", g_list[listado][tag],Adms[i]);

						AddMenuItem(menu, paraelmenu, paraelmenu);
					}

				}
				else 
				{
					decl String:paraelmenu2[128];
					Format(paraelmenu2,sizeof(paraelmenu2), "[ADMIN] %N",Adms[i]);
					AddMenuItem(menu, paraelmenu2, paraelmenu2);
				}
			}
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, client, MENU_TIME_FOREVER);

			return;
		}

		CPrintToChat(client,"{default}------------{lightgreen}ADMIN LIST ADVANCED{default}------------");
		PrintToChat(client,"---------------------------------------------------");
		for (new i = 0; i < count; i++)
		{
			//KvRewind(listadeadmins);
			decl String:status_steamid[24];
			GetClientAuthId(Adms[i], AuthId_Engine, status_steamid, sizeof(status_steamid));

			new listado = -1;
			if (GetTrieValue(g_ListIndex, status_steamid, listado))
			{

				if (StrContains(g_list[listado][hide], "yes", true) == -1)
				{

					CPrintToChatEx(client,Adms[i],"{green}%s {teamcolor}%N",g_list[listado][tag],Adms[i]);
				}

			}
			else CPrintToChatEx(client,Adms[i],"{green}[ADMIN] {teamcolor}%N",Adms[i]);
		}
		CPrintToChatEx(client,client,"---------------------------------------------------");
	}
}

public DIDMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		new String:info[128];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		PrintToChat(client, info);
	}
	else if (action == MenuAction_Cancel) 
	{ 
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", client, itemNum); 
	} 

	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}