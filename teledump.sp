#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

ArrayList g_aTeleDestination;

StringMap g_smSites[MAXPLAYERS + 1] = { null, ... };

public void OnPluginStart()
{
    RegConsoleCmd("sm_hook", Command_HookTeles);
}

public Action Command_HookTeles(int client, int args)
{
	HookTelesMenu(client);
	return Plugin_Handled;
}

public void HookTelesMenu(int client)
{
	if (g_aTeleDestination.Length < 1)
	{
		PrintToChat(client, "No Map Teleports Found");
		return;
	}

	Menu menu = new Menu(HookTeleMenuHandler);

	for(int i = 0; i < g_aTeleDestination.Length; i++)
	{
		int iEnt = g_aTeleDestination.Get(i);

		char name[64];
		GetEntPropString(iEnt, Prop_Data, "m_iName", name, 64, 0);
		menu.AddItem(name, name);
	}

	int iSite;
	g_smSites[client].GetValue("HookTelesMenu", iSite);
	menu.DisplayAt(client, iSite, -1);
}

public void OnClientPutInServer(int client)
{
	g_smSites[client] = new StringMap();
}

public void OnClientDisconnect(int client)
{
	delete g_smSites[client];
}

public void OnMapStart()
{
	int iEnt = -1;

	delete g_aTeleDestination;
	g_aTeleDestination = new ArrayList();

	while ((iEnt = FindEntityByClassname(iEnt, "info_teleport_destination")) != -1)
	{
		g_aTeleDestination.Push(iEnt);
	}
}

public int HookTeleMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		g_smSites[param1].SetValue("HookTelesMenu", menu.Selection);

		char buffer[64];
		menu.GetItem(param2, buffer, 64);

		int ent_index = g_aTeleDestination.Get(param2);

		float position[3];
		float angles[3];
		GetEntPropVector(ent_index, Prop_Send, "m_vecOrigin", position);
		GetClientEyeAngles(param1, angles);
		GetEntPropString(ent_index, Prop_Data, "m_iName", buffer, 64, 0);

		TeleportEntity(param1, position, angles, view_as<float>( { 0.0, 0.0, 0.0 } ));

		HookTelesMenu(param1);
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}