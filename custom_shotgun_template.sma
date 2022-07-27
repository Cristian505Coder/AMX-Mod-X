#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>

/* ~ [ Shotgun Settings ] ~ */
new const SHOTGUN_MODEL_VIEW[] = "x.mdl";
new const SHOTGUN_MODEL_PLAYER[] = "x.mdl";
new const SHOTGUN_MODEL_WORLD[] = "x.mdl";

new const SHOTGUN_REFERENCE[] = "x";
const SHOTGUN_SPECIAL_CODE = x;

new const CHAT_COMMAND[] = "x";

const SHOTGUN_BPAMMO = x;
const SHOTGUN_AMMO = x;

/* ~ [ Shotgun Primary Attack ] ~ */
new const SHOTGUN_SHOOT_SOUND[] = "x";
const Float: SHOTGUN_SHOOT_RATE = x.x;
const Float: SHOTGUN_SHOOT_PUNCHANGLE = x.x;
const Float: SHOTGUN_SHOOT_DAMAGE = x.x;

/* ~ [ Shotgun WeaponList ] ~ */
new const SHOTGUN_WEAPONLIST[] = "x";
new const iShotgunList[] = { x, x, x, x, x, x, x, x };
// https://wiki.alliedmods.net/CS_WeaponList_Message_Dump

/* ~ [ Shotgun Conditions ] ~ */
#define IsCustomShotgun(%0) (pev(%0, pev_impulse) == SHOTGUN_SPECIAL_CODE)
#define IsValidEntity(%0) (pev_valid(%0) == 2)

/* ~ [ Shotgun Animations (Frames/FPS) ] ~ */
const Float: SHOTGUN_ANIM_IDLE_TIME = x.x;
const Float: SHOTGUN_ANIM_SHOOT_TIME = x.x;
const Float: SHOTGUN_ANIM_INSERT_TIME = x.x;
const Float: SHOTGUN_ANIM_AFTER_RELOAD_TIME = x.x;
const Float: SHOTGUN_ANIM_START_RELOAD_TIME = x.x;
const Float: SHOTGUN_ANIM_DRAW_TIME = x.x;

enum _: iShotgunAnims
{
    SHOTGUN_ANIM_IDLE = 0,
    SHOTGUN_ANIM_SHOOT,
    SHOTGUN_ANIM_INSERT,
    SHOTGUN_ANIM_AFTER_RELOAD,
    SHOTGUN_ANIM_START_RELOAD,
    SHOTGUN_ANIM_DRAW
}

/* ~ [ Offsets ] ~ */
const m_iClip = 51;
const linux_diff_player = 5;
const linux_diff_weapon = 4;
const m_rpgPlayerItems = 367;
const m_pNext = 42
const m_iShotsFired = 64;
const m_iId = 43;
const m_iPrimaryAmmoType = 49;
const m_rgAmmo = 376;
const m_flNextAttack = 83;
const m_flTimeWeaponIdle = 48;
const m_flNextPrimaryAttack = 46;
const m_flNextSecondaryAttack = 47;
const m_pPlayer = 41;
const m_fInReload = 54;
const m_pActiveItem = 373;
const m_rgpPlayerItems_iShotgunBox = 34;
const m_fInSpecialReload = 55;

/* ~ [ Global Parameters ] ~ */
new HamHook: gl_HamHook_TraceAttack[4],

    gl_iszAllocString_Entity,
    gl_iszAllocString_ModelView,
    gl_iszAllocString_ModelPlayer,

    gl_iMsgID_Weaponlist;

/* ~ [ AMX Mod X ] ~ */
public plugin_init()
{
    register_plugin("Custom Shotgun Template", "1.0", "Cristian505 \ Batcoh: Code Base");

    // Fakemeta
    register_forward(FM_UpdateClientData,      "FM_Hook_UpdateClientData_Post",      true);
    register_forward(FM_SetModel, 			   "FM_Hook_SetModel_Pre",              false);

    // Shotgun
    RegisterHam(Ham_Item_Deploy,             SHOTGUN_REFERENCE,    "CShotgun__Deploy_Post",           true);
    RegisterHam(Ham_Weapon_PrimaryAttack,    SHOTGUN_REFERENCE,    "CShotgun__PrimaryAttack_Pre",    false);
    RegisterHam(Ham_Weapon_Reload,           SHOTGUN_REFERENCE,	  "CShotgun__Reload_Pre",           false);
    RegisterHam(Ham_Item_PostFrame,          SHOTGUN_REFERENCE,	  "CShotgun__PostFrame_Pre",        false);
    RegisterHam(Ham_Item_Holster,            SHOTGUN_REFERENCE,	  "CShotgun__Holster_Post",          true);
    RegisterHam(Ham_Item_AddToPlayer,		 SHOTGUN_REFERENCE,    "CShotgun__AddToPlayer_Post",      true);
    RegisterHam(Ham_Weapon_WeaponIdle,       SHOTGUN_REFERENCE,	  "CShotgun__Idle_Pre",             false);

    // Trace Attack
    gl_HamHook_TraceAttack[0] = RegisterHam(Ham_TraceAttack,	"func_breakable",	"CEntity__TraceAttack_Pre",  false);
    gl_HamHook_TraceAttack[1] = RegisterHam(Ham_TraceAttack,	"info_target",		"CEntity__TraceAttack_Pre",  false);
    gl_HamHook_TraceAttack[2] = RegisterHam(Ham_TraceAttack,	"player",			"CEntity__TraceAttack_Pre",  false);
    gl_HamHook_TraceAttack[3] = RegisterHam(Ham_TraceAttack,	"hostage_entity",	"CEntity__TraceAttack_Pre",  false);

    // Alloc String
    gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, SHOTGUN_REFERENCE);
    gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, SHOTGUN_MODEL_VIEW);
    gl_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, SHOTGUN_MODEL_PLAYER);

    // Messages
    gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");

    // Chat Command
    register_clcmd(CHAT_COMMAND, "Command_GiveShotgun");
    
    // Ham Hook
    fm_ham_hook(false);
}

public plugin_precache()
{
    // Precache Models
    engfunc(EngFunc_PrecacheModel, SHOTGUN_MODEL_VIEW);
    engfunc(EngFunc_PrecacheModel, SHOTGUN_MODEL_PLAYER);
    engfunc(EngFunc_PrecacheModel, SHOTGUN_MODEL_WORLD);

    // Precache Sounds
    engfunc(EngFunc_PrecacheSound, SHOTGUN_SHOOT_SOUND);

    // Precache generic
    new szWeaponList[128]; formatex(szWeaponList, charsmax(szWeaponList), "sprites/%s.txt", SHOTGUN_WEAPONLIST);
    engfunc(EngFunc_PrecacheGeneric, szWeaponList);

    // Hook weapon
    register_clcmd(SHOTGUN_WEAPONLIST, "Command_HookShotgun");
}

public Command_HookShotgun(iPlayer)
{
    engclient_cmd(iPlayer, SHOTGUN_REFERENCE);
    return PLUGIN_HANDLED;
}

public Command_GiveShotgun(iPlayer)
{
    static iShotgun; iShotgun = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_Entity);
    if(!IsValidEntity(iShotgun)) return FM_NULLENT;

    set_pev(iShotgun, pev_impulse, SHOTGUN_SPECIAL_CODE);
    ExecuteHam(Ham_Spawn, iShotgun);
    set_pdata_int(iShotgun, m_iClip, SHOTGUN_AMMO, linux_diff_weapon);
    UTIL_DropWeapon(iPlayer, ExecuteHamB(Ham_Item_ItemSlot, iShotgun));

    if(!ExecuteHamB(Ham_AddPlayerItem, iPlayer, iShotgun))
    {
	set_pev(iShotgun, pev_flags, pev(iShotgun, pev_flags) | FL_KILLME);
	return 0;
    }

    ExecuteHamB(Ham_Item_AttachToPlayer, iShotgun, iPlayer);
    UTIL_WeaponList(iPlayer, true);

    static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iShotgun, m_iPrimaryAmmoType, linux_diff_weapon);

    if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) < SHOTGUN_BPAMMO)
    set_pdata_int(iPlayer, iAmmoType, SHOTGUN_BPAMMO, linux_diff_player);

    emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    return 1;
}

/* ~ [ Hamsandwich ] ~ */
public CShotgun__Deploy_Post(iShotgun)
{
    if(!IsValidEntity(iShotgun) || !IsCustomShotgun(iShotgun)) return;

    static iPlayer; iPlayer = get_pdata_cbase(iShotgun, m_pPlayer, linux_diff_weapon);

    set_pev_string(iPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);
    set_pev_string(iPlayer, pev_weaponmodel2, gl_iszAllocString_ModelPlayer);

    UTIL_SendWeaponAnim(iPlayer, SHOTGUN_ANIM_DRAW);

    set_pdata_float(iPlayer, m_flNextAttack, SHOTGUN_ANIM_DRAW_TIME, linux_diff_player);
    set_pdata_float(iShotgun, m_flTimeWeaponIdle, SHOTGUN_ANIM_DRAW_TIME, linux_diff_weapon);
}

public CShotgun__PrimaryAttack_Pre(iShotgun)
{
    if(!IsValidEntity(iShotgun) || !IsCustomShotgun(iShotgun)) return HAM_IGNORED;

    static iAmmo; iAmmo = get_pdata_int(iShotgun, m_iClip, linux_diff_weapon);
    if(!iAmmo)
    {
        ExecuteHam(Ham_Weapon_PlayEmptySound, iShotgun);
	set_pdata_float(iShotgun, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

	return HAM_SUPERCEDE;
    }

    static fw_TraceLine; fw_TraceLine = register_forward(FM_TraceLine, "FM_Hook_TraceLine_Post", true);
    static fw_PlayBackEvent; fw_PlayBackEvent = register_forward(FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false);
    fm_ham_hook(true);		

    ExecuteHam(Ham_Weapon_PrimaryAttack, iShotgun);
		
    unregister_forward(FM_TraceLine, fw_TraceLine, true);
    unregister_forward(FM_PlaybackEvent, fw_PlayBackEvent);
    fm_ham_hook(false);

    static iPlayer; iPlayer = get_pdata_cbase(iShotgun, m_pPlayer, linux_diff_weapon);

    static Float: vecPunchangle[3];
    pev(iPlayer, pev_punchangle, vecPunchangle);
    vecPunchangle[0] *= SHOTGUN_SHOOT_PUNCHANGLE
    vecPunchangle[1] *= SHOTGUN_SHOOT_PUNCHANGLE
    vecPunchangle[2] *= SHOTGUN_SHOOT_PUNCHANGLE
    set_pev(iPlayer, pev_punchangle, vecPunchangle);

    UTIL_SendWeaponAnim(iPlayer, SHOTGUN_ANIM_SHOOT);
    emit_sound(iPlayer, CHAN_WEAPON, SHOTGUN_SHOOT_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    set_pdata_float(iPlayer, m_flNextAttack, SHOTGUN_SHOOT_RATE, linux_diff_player);
    set_pdata_float(iShotgun, m_flTimeWeaponIdle, SHOTGUN_ANIM_SHOOT_TIME, linux_diff_weapon);
    set_pdata_float(iShotgun, m_flNextPrimaryAttack, SHOTGUN_SHOOT_RATE, linux_diff_weapon);
    set_pdata_float(iShotgun, m_flNextSecondaryAttack, SHOTGUN_SHOOT_RATE, linux_diff_weapon);

    return HAM_SUPERCEDE;
}

public CShotgun__Reload_Pre(iShotgun)
{
    if(!IsValidEntity(iShotgun) || !IsCustomShotgun(iShotgun)) return HAM_IGNORED;
    
    UTIL_ShotgunReload(iShotgun, SHOTGUN_ANIM_START_RELOAD, SHOTGUN_ANIM_START_RELOAD_TIME, SHOTGUN_ANIM_INSERT, SHOTGUN_ANIM_INSERT_TIME);

    return HAM_SUPERCEDE;
}

public CShotgun__PostFrame_Pre(iShotgun)
{ 
    if(!IsValidEntity(iShotgun) || !IsCustomShotgun(iShotgun)) return HAM_IGNORED;

    static iClip; iClip = get_pdata_int(iShotgun, m_iClip, linux_diff_weapon);
    if(get_pdata_int(iShotgun, m_fInReload, linux_diff_weapon) == 1)
    {
        static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iShotgun, m_iPrimaryAmmoType, linux_diff_weapon);
	static iPlayer; iPlayer = get_pdata_cbase(iShotgun, m_pPlayer, linux_diff_weapon);
        static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, linux_diff_player);
        static j; j = min(SHOTGUN_AMMO - iClip, iAmmo);
        
	set_pdata_int(iShotgun, m_iClip, iClip + j, linux_diff_weapon);
	set_pdata_int(iPlayer, iAmmoType, iAmmo - j, linux_diff_player);
        set_pdata_int(iShotgun, m_fInReload, 0, linux_diff_weapon);
    }

    return HAM_IGNORED;
}

public CShotgun__Holster_Post(iShotgun)
{
    if(!IsValidEntity(iShotgun) || !IsCustomShotgun(iShotgun)) return;

    static iPlayer; iPlayer = get_pdata_cbase(iShotgun, m_pPlayer, linux_diff_weapon);

    set_pdata_float(iShotgun, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
    set_pdata_float(iShotgun, m_flNextSecondaryAttack, 0.0, linux_diff_weapon);
    set_pdata_float(iShotgun, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
    set_pdata_float(iPlayer, m_flNextAttack, 0.0, linux_diff_player);
    set_pdata_int(iShotgun, m_fInSpecialReload, 0, linux_diff_weapon);
}

public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float: flDamage)
{
    if(!is_user_connected(iAttacker)) return;
	
    static iShotgun; iShotgun = get_pdata_cbase(iAttacker, 373, 5);
    if(!IsValidEntity(iShotgun) || !IsCustomShotgun(iShotgun)) return;

    flDamage *= SHOTGUN_SHOOT_DAMAGE
    SetHamParamFloat(3, flDamage);
}

public CShotgun__Idle_Pre(iShotgun)
{
    if(!IsValidEntity(iShotgun) || !IsCustomShotgun(iShotgun) || get_pdata_float(iShotgun, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
    
    UTIL_ShotgunIdle(iShotgun, SHOTGUN_AMMO, SHOTGUN_ANIM_IDLE, SHOTGUN_ANIM_IDLE_TIME, SHOTGUN_ANIM_AFTER_RELOAD, SHOTGUN_ANIM_AFTER_RELOAD_TIME);

    return HAM_SUPERCEDE;
}

public CShotgun__AddToPlayer_Post(iShotgun, iPlayer)
{
    if(IsValidEntity(iShotgun) && IsCustomShotgun(iShotgun)) UTIL_WeaponList(iPlayer, true);
    else if(!pev(iShotgun, pev_impulse)) UTIL_WeaponList(iPlayer, false);
}

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle)
{
    if(!is_user_alive(iPlayer)) return;

    static iShotgun; iShotgun = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
    if(!IsValidEntity(iShotgun) || !IsCustomShotgun(iShotgun)) return;

    set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

public FM_Hook_SetModel_Pre(iEntity)
{
    static i, szClassName[32], iShotgun;
    pev(iEntity, pev_classname, szClassName, charsmax(szClassName));

    if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;

    for(i = 0; i < 6; i++)
    {
	iShotgun = get_pdata_cbase(iEntity, m_rgpPlayerItems_iShotgunBox + i, linux_diff_weapon);
		
	if(IsValidEntity(iShotgun) && IsCustomShotgun(iShotgun))
	{
		engfunc(EngFunc_SetModel, iEntity, SHOTGUN_MODEL_WORLD);
		return FMRES_SUPERCEDE;
	}
    }

    return FMRES_IGNORED;
}

public FM_Hook_PlaybackEvent_Pre() return FMRES_SUPERCEDE;
public FM_Hook_TraceLine_Post(const Float: vecOrigin1[3], const Float: vecOrigin2[3], iFlags, iAttacker, iTrace)
{
    if(iFlags & IGNORE_MONSTERS) return FMRES_IGNORED;
    if(!is_user_alive(iAttacker)) return FMRES_IGNORED;

    static pHit; pHit = get_tr2(iTrace, TR_pHit);
    static Float: vecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, vecEndPos);

    if(pHit > 0) if(pev(pHit, pev_solid) != SOLID_BSP) return FMRES_IGNORED;

    engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEndPos, 0);
    write_byte(TE_WORLDDECAL);
    engfunc(EngFunc_WriteCoord, vecEndPos[0]);
    engfunc(EngFunc_WriteCoord, vecEndPos[1]);
    engfunc(EngFunc_WriteCoord, vecEndPos[2]);
    write_byte(random_num(41, 45));
    message_end();
	
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_STREAK_SPLASH);
    engfunc(EngFunc_WriteCoord, vecEndPos[0]);
    engfunc(EngFunc_WriteCoord, vecEndPos[1]);
    engfunc(EngFunc_WriteCoord, vecEndPos[2]);
    write_coord(random_num(-20, 20));
    write_coord(random_num(-20, 20));
    write_coord(random_num(-20, 20)); 
    write_byte(5);
    write_short(70);
    write_short(3);
    write_short(75);
    message_end();

    return FMRES_IGNORED;
}

/* ~ [ Ham Hook ] ~ */
public fm_ham_hook(bool: bEnabled)
{
    if(bEnabled)
    {
	EnableHamForward(gl_HamHook_TraceAttack[0]);
	EnableHamForward(gl_HamHook_TraceAttack[1]);
	EnableHamForward(gl_HamHook_TraceAttack[2]);
	EnableHamForward(gl_HamHook_TraceAttack[3]);
    }
    else 
    {
	DisableHamForward(gl_HamHook_TraceAttack[0]);
	DisableHamForward(gl_HamHook_TraceAttack[1]);
	DisableHamForward(gl_HamHook_TraceAttack[2]);
	DisableHamForward(gl_HamHook_TraceAttack[3]);
    }
}

/* ~ [ Stocks ] ~ */
stock UTIL_SendWeaponAnim(const iPlayer, const iAnim)
{
    set_pev(iPlayer, pev_weaponanim, iAnim);

    message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
    write_byte(iAnim);
    write_byte(0);
    message_end();
}

stock UTIL_DropWeapon(const iPlayer, const iSlot)
{
    static iEntity, iNext, szWeaponName[32];
    iEntity = get_pdata_cbase(iPlayer, m_rpgPlayerItems + iSlot, linux_diff_player);

    if(iEntity > 0)
    {       
	do 
	{
                iNext = get_pdata_cbase(iEntity, m_pNext, linux_diff_weapon);
		if(get_weaponname(get_pdata_int(iEntity, m_iId, linux_diff_weapon), szWeaponName, charsmax(szWeaponName)))
		engclient_cmd(iPlayer, "drop", szWeaponName);
	} 
		
	while((iEntity = iNext) > 0);
    }
}

stock UTIL_WeaponList(const iPlayer, bool: bEnabled)
{
    message_begin(MSG_ONE, gl_iMsgID_Weaponlist, _, iPlayer);
    write_string(bEnabled ? SHOTGUN_WEAPONLIST : SHOTGUN_REFERENCE);
    write_byte(iShotgunList[0]);
    write_byte(bEnabled ? SHOTGUN_AMMO : iShotgunList[1]);
    write_byte(iShotgunList[2]);
    write_byte(iShotgunList[3]);
    write_byte(iShotgunList[4]);
    write_byte(iShotgunList[5]);
    write_byte(iShotgunList[6]);
    write_byte(iShotgunList[7]);
    message_end();
}

stock UTIL_ShotgunReload(iItem, iAnimReloadStart, Float: flReloadStartDelay, iAnimReload, Float: flReloadDelay)
{
	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);

	if(iClip >= SHOTGUN_AMMO) return;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, linux_diff_player);

	if(!iAmmo) return;

	if(get_pdata_float(iItem, m_flNextPrimaryAttack, linux_diff_weapon) > 0.0) return;

	static iSpecialReload; iSpecialReload = get_pdata_int(iItem, m_fInSpecialReload, linux_diff_weapon);

	switch(iSpecialReload)
	{
		case 0:
		{
			UTIL_SendWeaponAnim(iPlayer, iAnimReloadStart);
			iSpecialReload = 1;
			set_pdata_float(iItem, m_flNextPrimaryAttack, flReloadStartDelay, linux_diff_weapon);
			set_pdata_float(iItem, m_flNextSecondaryAttack, flReloadStartDelay, linux_diff_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, flReloadStartDelay, linux_diff_weapon);
		}
		case 1:
		{
			if(get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return;

			UTIL_SendWeaponAnim(iPlayer, iAnimReload);
			iSpecialReload = 2;
			set_pdata_float(iItem, m_flTimeWeaponIdle, flReloadDelay, linux_diff_weapon);
		}
		case 2:
		{
			if(get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return;

			iSpecialReload = 1;
			set_pdata_int(iItem, m_iClip, iClip + 1, linux_diff_weapon);
			set_pdata_int(iPlayer, iAmmoType, iAmmo - 1, linux_diff_player);
		}
	}

	set_pdata_int(iItem, m_fInSpecialReload, iSpecialReload, linux_diff_weapon);
}

stock UTIL_ShotgunIdle(iItem, iMaxClip, iAnimIdle, Float: flAnimIdleTime, iAnimReloadEnd, Float: flAnimReloadEndTime)
{
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, linux_diff_player);
	static iSpecialReload; iSpecialReload = get_pdata_int(iItem, m_fInSpecialReload, linux_diff_weapon);
        static iItem_iClip; iItem_iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);

	if(!iItem_iClip && !iSpecialReload && iAmmo) CShotgun__Reload_Pre(iItem);

	else if(iSpecialReload)
	{
		if(iItem_iClip != iMaxClip && iAmmo) CShotgun__Reload_Pre(iItem);
		else
		{
			UTIL_SendWeaponAnim(iPlayer, iAnimReloadEnd);

			set_pdata_int(iItem, m_fInSpecialReload, 0, linux_diff_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, flAnimReloadEndTime, linux_diff_weapon);
		}
	}
	else
	{
		UTIL_SendWeaponAnim(iPlayer, iAnimIdle);
		set_pdata_float(iItem, m_flTimeWeaponIdle, flAnimIdleTime, linux_diff_weapon);
	}
}
