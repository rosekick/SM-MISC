#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>

Database gH_SQL = null;

ArrayList gA_Map = null;
ArrayList gA_Maptier = null;

public void OnPluginStart()
{
	RegConsoleCmd("sm_init", Command_INIT);
	RegConsoleCmd("sm_findtier", Command_Find);
	RegConsoleCmd("sm_test", Command_Test);

	CONNECT();

	gA_Map = new ArrayList(734);
	gA_Maptier = new ArrayList(734);
}

public Action Command_INIT(int client, int args)
{
	InitMapdata();
}

public Action Command_Find(int client, int args)
{
	FindTier();
}

public Action Command_Test(int client, int args)
{
	for(int i = 0; i < 1000; i++)
	{
		char map[128];
		gA_Map.GetString(i, map, 128);
		PrintToChatAll("map:%s", map);
		PrintToChatAll("tier:%d", gA_Maptier.Get(i));
	}
}

void InitMapdata()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/mapdata.kv");

	KeyValues kv = new KeyValues("MapData");

	kv.ImportFromFile(sPath);
	kv.GotoFirstSubKey();

	for(int i = 0; i < 734; i++)
	{
		char map[128];
		gA_Map.GetString(i, map, 128);

		char sTier[8];
		int iTier = gA_Maptier.Get(i);
		Format(sTier, 8, "[T%d]", iTier);

		int iPrice;
		switch(iTier)
		{
		    case 1: iPrice = 30;
		    case 2: iPrice = 45;
		    case 3: iPrice = 60;
		    case 4: iPrice = 100;
		    case 5: iPrice = 250;
		    case 6: iPrice = 400;
		}
		char sPrice[4];
		IntToString(iPrice, sPrice, 4);

		if(kv.JumpToKey(map, true))
		{
			kv.SetString("m_Description", sTier);
			kv.SetString("m_CertainTimes", "all");
			kv.SetString("m_Price", sPrice);
			kv.SetString("m_PricePartyBlock", "300");
			kv.SetString("m_MinPlayers", "0");
			kv.SetString("m_MaxPlayers", "0");
			kv.SetString("m_MaxCooldown", "10");
			kv.SetString("m_NominateOnly", "0");
			kv.SetString("m_VipOnly", "0");
			kv.SetString("m_AdminOnly", "0");
		}

		kv.Rewind();
	}

	kv.ExportToFile(sPath);
}

void FindTier()
{
	char sQuery[128];
	FormatEx(sQuery, 128, "SELECT mapname, tier FROM `ck_maptier`;");

	gH_SQL.Query(SQL_FindTier_Callback, sQuery, 0, DBPrio_High);
}

public void SQL_FindTier_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	if(results == null)
	{
		LogError("what? %s", error);
		return;
	}

	while(results.FetchRow())
	{
	char map[128];
	results.FetchString(0, map, 128);
	gA_Map.PushString(map);
	gA_Maptier.Push(results.FetchInt(1));
	}
}

void CONNECT()
{
	char sError[255];
	gH_SQL = SQL_Connect("surftimer", true, sError, 255);

	if (gH_SQL == null)
	{
		SetFailState("Unable to connect to database (%s)", sError);
		return;
	}
}
