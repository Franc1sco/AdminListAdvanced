#pragma semicolon 1
#include <sourcemod>
#include <colors>

#define DATA "v2.1"

new Handle:listadeadmins = INVALID_HANDLE;
new Handle:cvar_menu = INVALID_HANDLE;
new Handle:cvar_cmd = INVALID_HANDLE;


// Quien quiera aprender a programar que vaya a 
// www.servers-cfg.foroactivo.com que ahi tenemos un subforo para usuarios registrados


public Plugin:myinfo =
{
	name = "SM Admin List Advanced",
	author = "Franc1sco Steam: franug",
	description = "A configurable admin list sytem",
	version = DATA,
	url = "www.servers-cfg.foroactivo.com"
};

public OnPluginStart()
{
	CreateConVar("sm_adminlist_advanced", DATA, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cvar_menu = CreateConVar("sm_adminlist_menu", "0", "1 = show admins in menu. 0 = show admins in chat");

	cvar_cmd = CreateConVar("sm_adminlist_command", "sm_admins", "the command to show admins");

        RegAdminCmd("sm_adminlist_reload", RecargarLista, ADMFLAG_ROOT);

	decl String:comando[64];
	GetConVarString(cvar_cmd, comando, sizeof(comando));
	RegConsoleCmd(comando,Comando_Admins);


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

	if(client == 0)
		PrintToServer("[SM_ADMINLIST_ADVANCED] admin list reloaded successfully");
	else
        	PrintToChat(client, "[SM_ADMINLIST_ADVANCED] admin list reloaded successfully");

	return Plugin_Handled;

}

public Action:Comando_Admins(client, args)
{
	new Adms[129],count = 0;
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && GetUserAdmin(i) != INVALID_ADMIN_ID) Adms[count++] = i;


        //PrintToChat(client,"admins: %i", count); 

	if (count)
	{
		if(GetConVarBool(cvar_menu))
		{
			new Handle:menu = CreateMenu(DIDMenuHandler);
			SetMenuTitle(menu, "ADMIN LIST ADVANCED");
			for (new i = 0; i < count; i++)
			{
                  		KvRewind(listadeadmins);
                   		decl String:status_steamid[24];
                   		GetClientAuthString(Adms[i], status_steamid, sizeof(status_steamid));

                   		if (KvJumpToKey(listadeadmins, status_steamid))
                   		{
					decl String:noadmin[24];
					KvGetString(listadeadmins, "hide", noadmin, 24, "no");

					if (StrContains(noadmin, "yes", true) == -1)
					{
                        			decl String:tipo[64];
                        			KvGetString(listadeadmins, "tag", tipo, sizeof(tipo));

						decl String:paraelmenu[128];
						Format(paraelmenu,sizeof(paraelmenu),"%s %N", tipo,Adms[i]);

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

			return Plugin_Handled;
		}

		PrintToChat(client,"\x01------------\x03ADMIN LIST ADVANCED\x01------------");
                PrintToChat(client,"---------------------------------------------------");
		for (new i = 0; i < count; i++)
		{
                   KvRewind(listadeadmins);
                   decl String:status_steamid[24];
                   GetClientAuthString(Adms[i], status_steamid, sizeof(status_steamid));

                   if (KvJumpToKey(listadeadmins, status_steamid))
                   {
					decl String:noadmin[24];
					KvGetString(listadeadmins, "hide", noadmin, 24, "no");

					if (StrContains(noadmin, "yes", true) == -1)
					{
                        			decl String:tipo[64];
                        			KvGetString(listadeadmins, "tag", tipo, sizeof(tipo));

						CPrintToChatEx(client,Adms[i],"{green}%s {teamcolor}%N",tipo,Adms[i]);
					}

                   }
                   else CPrintToChatEx(client,Adms[i],"{green}[ADMIN] {teamcolor}%N",Adms[i]);
		}
		CPrintToChatEx(client,client,"---------------------------------------------------");
	}
	return Plugin_Handled;
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