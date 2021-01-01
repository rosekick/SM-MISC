#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


int g_mdlColor[MAXPLAYERS + 1];

public void OnPluginStart()
{
	RegConsoleCmd("sm_mc", cmd_fbcolor);
	RegConsoleCmd("sm_modelcolor", cmd_fbcolor);
	AddCommandListener(cmdlistener_block, "sm_block");

	return;
}

public Action cmdlistener_block(int client, const char[] command , int argc)
{
	CreateTimer(0.1, timer1, client);
	return;
}

public Action timer1(Handle timer, any client)
{
	new color[4];
	GetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
	switch (g_mdlColor[client])
	{
		case 1:
		{
			ChangeModel(client, 255, 0, 0, color[3]);
		}
		case 2:
		{
			ChangeModel(client, 0, 255, 0, color[3]);
		}
		case 3:
		{
			ChangeModel(client, 0, 0, 255, color[3]);
		}
		case 4:
		{
			ChangeModel(client, 0, 200, 255, color[3]);
		}
		case 5:
		{
			ChangeModel(client, 255, 0, 255, color[3]);
		}
		case 6:
		{
			ChangeModel(client, 255, 255, 255, color[3]);
		}
		case 7:
		{
			SetEntityModel(client, "models/autistgang/ct_gsg9_unlit/ct_gsg9_unlit.mdl");
			SetEntityRenderColor(client, 255, 255, 255, color[3]);
		}
		default:
		{
		}
	}
	return;
}

public void OnClientDisconnect(int client)
{
	g_mdlColor[client] = 0;
	return;
}

public void OnMapStart()
{
	PrecacheModel("models/autistgang/ct_gsg9/ct_gsg9.mdl", false);
	PrecacheModel("models/autistgang/ct_gsg9_unlit/ct_gsg9_unlit.mdl", false);
	PrecacheModel("models/player/ct_gsg9.mdl", false);
	AddFileToDownloadsTable("models/autistgang/ct_gsg9_unlit/ct_gsg9_unlit.mdl");
	AddFileToDownloadsTable("models/autistgang/ct_gsg9_unlit/ct_gsg9_unlit.dx80.vtx");
	AddFileToDownloadsTable("models/autistgang/ct_gsg9_unlit/ct_gsg9_unlit.dx90.vtx");
	AddFileToDownloadsTable("models/autistgang/ct_gsg9_unlit/ct_gsg9_unlit.phy");
	AddFileToDownloadsTable("models/autistgang/ct_gsg9_unlit/ct_gsg9_unlit.sw.vtx");
	AddFileToDownloadsTable("models/autistgang/ct_gsg9_unlit/ct_gsg9_unlit.vvd");
	AddFileToDownloadsTable("models/autistgang/ct_gsg9/ct_gsg9.mdl");
	AddFileToDownloadsTable("models/autistgang/ct_gsg9/ct_gsg9.dx80.vtx");
	AddFileToDownloadsTable("models/autistgang/ct_gsg9/ct_gsg9.dx90.vtx");
	AddFileToDownloadsTable("models/autistgang/ct_gsg9/ct_gsg9.phy");
	AddFileToDownloadsTable("models/autistgang/ct_gsg9/ct_gsg9.sw.vtx");
	AddFileToDownloadsTable("models/autistgang/ct_gsg9/ct_gsg9.vvd");
	AddFileToDownloadsTable("materials/autistgang/ct_gsg9/noshadows.vmt");
	AddFileToDownloadsTable("materials/autistgang/ct_gsg9_unlit/unlit.vmt");
	return;
}

public Action cmd_fbcolor(int client, int args)
{
	Menu menu = new Menu(menu_handler);
	menu.AddItem("default", "默认");
	menu.AddItem("lighter", "变亮");
	menu.AddItem("red", "红色");
	menu.AddItem("green", "绿色");
	menu.AddItem("blue", "蓝色");
	menu.AddItem("lightblue", "浅蓝");
	menu.AddItem("pink", "粉色");
	menu.AddItem("white", "白色");

	menu.Display(client, -1);
}

public menu_handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, 32);
			if (StrEqual(info, "default", true))
			{
				SetEntityModel(param1, "models/player/ct_gsg9.mdl");
				SetEntityRenderColor(param1, 255, 255, 255, 255);
				g_mdlColor[param1] = 0;
			}
			if (StrEqual(info, "lighter", true))
			{
				ChangeModel(param1, 255, 0, 0, 255);
				g_mdlColor[param1] = 1;
			}
			if (StrEqual(info, "red", true))
			{
				ChangeModel(param1, 0, 255, 0, 255);
				g_mdlColor[param1] = 2;
			}
			if (StrEqual(info, "green", true))
			{
				ChangeModel(param1, 0, 0, 255, 255);
				g_mdlColor[param1] = 3;
			}
			if (StrEqual(info, "blue", true))
			{
				ChangeModel(param1, 0, 200, 255, 255);
				g_mdlColor[param1] = 4;
			}
			if (StrEqual(info, "lightblue", true))
			{
				ChangeModel(param1, 255, 0, 255, 255);
				g_mdlColor[param1] = 5;
			}
			if (StrEqual(info, "pink", true))
			{
				ChangeModel(param1, 255, 255, 255, 255);
				g_mdlColor[param1] = 6;
			}
			if (StrEqual(info, "white", true))
			{
				SetEntityModel(param1, "models/autistgang/ct_gsg9_unlit/ct_gsg9_unlit.mdl");
				SetEntityRenderColor(param1, 255, 255, 255, 255);
				g_mdlColor[param1] = 7;
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public void ChangeModel(int client, int r, int g, int b, int a)
{
	SetEntityModel(client, "models/autistgang/ct_gsg9/ct_gsg9.mdl");
	SetEntityRenderColor(client, r, g, b, a);
	return;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (IsValidEntity(entity))
	{
		SDKHook(entity, SDKHookType:24, OnEntitySpawned);
	}
	return;
}

public OnEntitySpawned(int entity)
{
	char class_name[32];
	GetEdictClassname(entity, class_name, 32);
	if (StrContains(class_name, "player", true) != -1 && IsValidEntity(entity))
	{
		switch (g_mdlColor[entity])
		{
			case 1:
			{
				ChangeModel(entity, 255, 0, 0, 255);
			}
			case 2:
			{
				ChangeModel(entity, 0, 255, 0, 255);
			}
			case 3:
			{
				ChangeModel(entity, 0, 0, 255, 255);
			}
			case 4:
			{
				ChangeModel(entity, 0, 200, 255, 255);
			}
			case 5:
			{
				ChangeModel(entity, 255, 0, 255, 255);
			}
			case 6:
			{
				ChangeModel(entity, 255, 255, 255, 255);
			}
			case 7:
			{
				SetEntityModel(entity, "models/autistgang/ct_gsg9_unlit/ct_gsg9_unlit.mdl");
				SetEntityRenderColor(entity, 255, 255, 255, 255);
			}
		}
	}
	return;
}