#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <sdkhooks>

#undef REQUIRE_EXTENSIONS

#pragma newdecls required
#pragma semicolon 1

#define TRAIL_NONE -1

enum struct TrailSettings
{
	int iRedChannel;
	int iGreenChannel;
	int iBlueChannel;
	int iSpecialColor;
	int iAlphaChannel;
}

int gI_BeamSprite;
int gI_SelectedTrail[MAXPLAYERS + 1] = {TRAIL_NONE, ...};

// Hiding trails globals
ArrayList aL_Clients = null;


// KeyValue globals
int gI_TrailAmount;
char gS_TrailTitle[128][128];
TrailSettings gI_TrailSettings[128];


// Spectrum cycle globals
int gI_CycleColor[MAXPLAYERS + 1][4];
bool gB_RedToYellow[MAXPLAYERS + 1];
bool gB_YellowToGreen[MAXPLAYERS + 1];
bool gB_GreenToCyan[MAXPLAYERS + 1];
bool gB_CyanToBlue[MAXPLAYERS + 1];
bool gB_BlueToMagenta[MAXPLAYERS + 1];
bool gB_MagentaToRed[MAXPLAYERS + 1];

// Cookie handles
Handle gH_TrailChoiceCookie;

public void OnPluginStart()
{
	HookEvent("player_spawn", OnPlayerSpawn);
	
	RegConsoleCmd("sm_trail", Command_Trail, "Opens the 'Trail Selection' menu.");
	RegConsoleCmd("sm_trails", Command_Trail, "Opens the 'Trail Selection' menu.");

	AutoExecConfig();
	gH_TrailChoiceCookie = RegClientCookie("trail_choice", "Trail Choice Cookie", CookieAccess_Protected);
	aL_Clients = new ArrayList();

	for(int i = 1; i <= MaxClients; i++)
	{
		if(AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
}

public void OnClientCookiesCached(int client)
{
	if(IsFakeClient(client))
	{
		return;
	}
	
	char[] sChoiceCookie = new char[8];
	GetClientCookie(client, gH_TrailChoiceCookie, sChoiceCookie, 8);
		
	if(sChoiceCookie[0] == '\0') // If the cookie is empty or the player doesn't have access
	{
		IntToString(TRAIL_NONE, sChoiceCookie, 8);
		SetClientCookie(client, gH_TrailChoiceCookie, sChoiceCookie);
	}
	else
	{
		gI_SelectedTrail[client] = StringToInt(sChoiceCookie);
	}
	
	if(IsValidClient(client) && aL_Clients.FindValue(client) == -1) // Only works after reloading the plugin
	{
		aL_Clients.Push(client);
	}
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(!IsValidClient(client))
	{
        if(aL_Clients.FindValue(client) == -1) // If the client isn't hiding trails, but somehow isn't on the list
        {
            aL_Clients.Push(client);
        }
    }
}

public void OnClientDisconnect(int client)
{
	int index = aL_Clients.FindValue(client);
	
	if(index != -1) // If the index is valid and the player was found on the list
	{
		aL_Clients.Erase(index);
	}
}

public void OnMapStart()
{
	if(!LoadColorsConfig())
	{
		SetFailState("Failed load \"configs/trails-colors.cfg\". File missing or invalid.");
	}
	
	/* gI_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt", true); */
	gI_BeamSprite = PrecacheModel("materials/trails/beam_01.vmt", true);
	
	AddFileToDownloadsTable("materials/trails/beam_01.vmt");
	AddFileToDownloadsTable("materials/trails/beam_01.vtf");
}

public void OnMapEnd()
{
	aL_Clients.Clear();
}

bool LoadColorsConfig()
{
	char[] sPath = new char[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/trails-colors.cfg");
	KeyValues kv = new KeyValues("trails-colors");
	
	if(!kv.ImportFromFile(sPath) || !kv.GotoFirstSubKey())
	{
		delete kv;
		return false;
	}
	
	int i = 0;
	
	do
	{
		kv.GetString("name", gS_TrailTitle[i], 128, "<MISSING TRAIL NAME>");
		
		gI_TrailSettings[i].iRedChannel = kv.GetNum("red", 255);
		gI_TrailSettings[i].iGreenChannel = kv.GetNum("green", 255);
		gI_TrailSettings[i].iBlueChannel = kv.GetNum("blue", 255);
		gI_TrailSettings[i].iSpecialColor = kv.GetNum("special", 0);
		gI_TrailSettings[i].iAlphaChannel = kv.GetNum("alpha", 128);
		
		i++;
	}
	while(kv.GotoNextKey());
	
	delete kv;
	gI_TrailAmount = i;
	return true;
}

Action OpenTrailMenu(int client, int page)
{
	Menu menu = new Menu(Menu_Handler);
	menu.SetTitle("Choose a trail:\n ");
	
	char[] sNone = new char[8];
	IntToString(TRAIL_NONE, sNone, 8);
	
	menu.AddItem(sNone, "None", (gI_SelectedTrail[client] == TRAIL_NONE)? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	
	for(int i = 0; i < gI_TrailAmount; i++)
	{
		char[] sInfo = new char[8];
		IntToString(i, sInfo, 8);
		
		if(StrEqual(gS_TrailTitle[i], "/empty/") || StrEqual(gS_TrailTitle[i], "/EMPTY/") || StrEqual(gS_TrailTitle[i], "{empty}") || StrEqual(gS_TrailTitle[i], "{EMPTY}"))
		{
			menu.AddItem("", "", ITEMDRAW_SPACER); // Empty line support
		}
		else
		{
			menu.AddItem(sInfo, gS_TrailTitle[i], (gI_SelectedTrail[client] == i)? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		}
	}
	
	menu.ExitButton = true;
	menu.DisplayAt(client, page, 60);
	
	return Plugin_Handled;
}

void MenuSelection(int client, char[] info)
{
	int choice = StringToInt(info);
	
	if(choice == TRAIL_NONE)
	{
		StopSpectrumCycle(client);
	}
	else
	{
		int color[3];
		color[0] = gI_TrailSettings[choice].iRedChannel;
		color[1] = gI_TrailSettings[choice].iGreenChannel;
		color[2] = gI_TrailSettings[choice].iBlueChannel;
		
		if(gI_TrailSettings[choice].iSpecialColor == 1)
		{
			gI_CycleColor[client][0] = 0;
			gI_CycleColor[client][1] = 0;
			gI_CycleColor[client][2] = 0;
			gB_RedToYellow[client] = true;
		}
		else
		{
			StopSpectrumCycle(client);
		}
	}
	
	gI_SelectedTrail[client] = choice;
	SetClientCookie(client, gH_TrailChoiceCookie, info);
}

void StopSpectrumCycle(int client)
{
	gB_RedToYellow[client] = false;
	gB_YellowToGreen[client] = false;
	gB_GreenToCyan[client] = false;
	gB_CyanToBlue[client] = false;
	gB_BlueToMagenta[client] = false;
	gB_MagentaToRed[client] = false;
}

int[] GetClientTrailColors(int client, int[] color)
{
	int choice = gI_SelectedTrail[client];
	color[3] = gI_TrailSettings[choice].iAlphaChannel;
	int stepsize = 0;
	
	if(gI_TrailSettings[choice].iSpecialColor == 1) // Spectrum trail
	{
		stepsize = 1;
	}
	else
	{
		color[0] = gI_TrailSettings[choice].iRedChannel;
		color[1] = gI_TrailSettings[choice].iGreenChannel;
		color[2] = gI_TrailSettings[choice].iBlueChannel;
	}
	
	return;
}

public Action Command_Trail(int client, int args)
{
	if (IsValidClient(client))
	{
		return OpenTrailMenu(client, 0);
	}
	return Plugin_Handled;
}

public int Menu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char[] sInfo = new char[8];
		menu.GetItem(param2, sInfo, 8);
		
		MenuSelection(param1, sInfo);
		OpenTrailMenu(param1, GetMenuSelectionPosition());
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	
	return 0;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrContains(classname, "_projectile", false) != -1)
	{
		Handle datapack = INVALID_HANDLE;
		CreateDataTimer(0.0, projectile, datapack, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(datapack, entity);
		WritePackString(datapack, classname);
		ResetPack(datapack);
	}
}

public Action projectile(Handle timer, Handle datapack)
{
	int entity = ReadPackCell(datapack);
	int client = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
	
	if (IsPlayerAlive(client))
	{
		if(0 < client <= MaxClients)
		{
			char classname[30];
			ReadPackString(datapack, classname, sizeof(classname));
			
			int color[4];
			GetClientTrailColors(client, color);
			
			TE_SetupBeamFollow(entity, gI_BeamSprite, 0, 1.0, 3.0, 3.0, 1, color);
			TE_SendToAll();
		}
    }
}

bool IsValidClient(int client)
{
	return 1 <= client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client);
}