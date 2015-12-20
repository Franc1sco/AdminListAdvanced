#pragma semicolon 1
#include <sourcemod>
#include <colors>

#define DATA "v1.1"

new Handle:listadeadmins = INVALID_HANDLE;


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


	RegConsoleCmd("sm_admins",Comando_Admins);

        RegAdminCmd("sm_adminlist_reload", RecargarLista, ADMFLAG_ROOT);


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

        PrintToChat(client, "[SM_ADMINLIST_ADVANCED] admin list reloaded successfully");

}

public Action:Comando_Admins(client, args)
{
	new Adms[129],count = 0;
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && GetUserAdmin(i) != INVALID_ADMIN_ID) Adms[count++] = i;


        //PrintToChat(client,"admins: %i", count); 

	if (count)
	{
		PrintToChat(client,"\x01------------\x03ADMIN LIST ADVANCED\x01------------");
                PrintToChat(client,"---------------------------------------------------");
		for (new i = 0; i < count; i++)
		{
                   KvRewind(listadeadmins);
                   decl String:status_steamid[24];
                   GetClientAuthString(Adms[i], status_steamid, sizeof(status_steamid));

                   if (KvJumpToKey(listadeadmins, status_steamid))
                   {
                        decl String:tipo[64];
                        KvGetString(listadeadmins, "tag", tipo, sizeof(tipo));

			CPrintToChatEx(client,Adms[i],"{green}%s {teamcolor}%N",tipo,Adms[i]);

                   }
                   else CPrintToChatEx(client,Adms[i],"{green}[ADMIN] {teamcolor}%N",Adms[i]);
		}
		CPrintToChatEx(client,client,"---------------------------------------------------");
	}
	return Plugin_Handled;
}