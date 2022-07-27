#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>

/* ~ [ Pistol Settings ] ~ */
new const PISTOL_MODEL_VIEW[] = "x";
new const PISTOL_MODEL_PLAYER[] = "x";
new const PISTOL_MODEL_WORLD[] = "x";

new const PISTOL_REFERENCE[] = "x";
const PISTOL_SPECIAL_CODE = x;

new const CHAT_COMMAND[] = "x";

const PISTOL_BPAMMO = x;
const PISTOL_AMMO = x;

/* ~ [ Pistol Primary Attack ] ~ */
new const PISTOL_SHOOT_SOUND[] = "x";
const Float: PISTOL_SHOOT_RATE = x;
const Float: PISTOL_SHOOT_PUNCHANGLE = x;
const Float: PISTOL_SHOOT_DAMAGE = x;

/* ~ [ Pistol WeaponList ] ~ */
new const PISTOL_WEAPONLIST[] = "x";
new const iPistolList[] = { x, x, x, x, x, x, x, x };
// https://wiki.alliedmods.net/CS_WeaponList_Message_Dump

/* ~ [ Pistol Conditions ] ~ */
#define IsCustomPistol(%0) (pev(%0, pev_impulse) == PISTOL_SPECIAL_CODE)
#define IsValidEntity(%0) (pev_valid(%0) == 2)

/* ~ [ Pistol Animations (Frames/FPS) ] ~ */
const Float: PISTOL_ANIM_IDLE_TIME = x;
const Float: PISTOL_ANIM_RELOAD_TIME = x;
const Float: PISTOL_ANIM_DRAW_TIME = x;
const Float: PISTOL_ANIM_SHOOT_TIME = x;

enum _: iPistolAnims
{
	PISTOL_ANIM_IDLE = 0,
	PISTOL_ANIM_RELOAD,
	PISTOL_ANIM_DRAW,
	PISTOL_ANIM_SHOOT
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
const m_rgpPlayerItems_iWeaponBox = 34;

/* ~ [ Global Parameters ] ~ */
new HamHook: gl_HamHook_TraceAttack[4],

    gl_iszAllocString_Entity,
    gl_iszAllocString_ModelView,
    gl_iszAllocString_ModelPlayer,

    gl_iMsgID_Weaponlist;

/* ~ [ AMX Mod X ] ~ */
public plugin_init()
{
    register_plugin("Custom Pistol Template", "3.0", "Cristian505 \ Batcoh: Code Base");

    // Fakemeta
    register_forward(FM_UpdateClientData,      "FM_Hook_UpdateClientData_Post",      true);
    register_forward(FM_SetModel, 			   "FM_Hook_SetModel_Pre",              false);

    // Pistol
    RegisterHam(Ham_Item_Deploy,             PISTOL_REFERENCE,    "CPistol__Deploy_Post",           true);
    RegisterHam(Ham_Weapon_PrimaryAttack,    PISTOL_REFERENCE,    "CPistol__PrimaryAttack_Pre",    false);
    RegisterHam(Ham_Weapon_Reload,           PISTOL_REFERENCE,	  "CPistol__Reload_Pre",           false);
    RegisterHam(Ham_Item_PostFrame,          PISTOL_REFERENCE,	  "CPistol__PostFrame_Pre",        false);
    RegisterHam(Ham_Item_Holster,            PISTOL_REFERENCE,	  "CPistol__Holster_Post",          true);
    RegisterHam(Ham_Item_AddToPlayer,		 PISTOL_REFERENCE,    "CPistol__AddToPlayer_Post",      true);
    RegisterHam(Ham_Weapon_WeaponIdle,       PISTOL_REFERENCE,	  "CPistol__Idle_Pre",             false);

    // Trace Attack
    gl_HamHook_TraceAttack[0] = RegisterHam(Ham_TraceAttack,	"func_breakable",	"CEntity__TraceAttack_Pre",  false);
    gl_HamHook_TraceAttack[1] = RegisterHam(Ham_TraceAttack,	"info_target",		"CEntity__TraceAttack_Pre",  false);
    gl_HamHook_TraceAttack[2] = RegisterHam(Ham_TraceAttack,	"player",			"CEntity__TraceAttack_Pre",  false);
    gl_HamHook_TraceAttack[3] = RegisterHam(Ham_TraceAttack,	"hostage_entity",	"CEntity__TraceAttack_Pre",  false);

    // Alloc String
    gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, PISTOL_REFERENCE);
    gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, PISTOL_MODEL_VIEW);
    gl_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, PISTOL_MODEL_PLAYER);

    // Messages
    gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");

    // Chat Command
    register_clcmd(CHAT_COMMAND, "Command_GivePistol");
    
    // Ham Hook
    fm_ham_hook(false);
}

public plugin_precache()
{
    // Precache Models
    engfunc(EngFunc_PrecacheModel, PISTOL_MODEL_VIEW);
    engfunc(EngFunc_PrecacheModel, PISTOL_MODEL_PLAYER);
    engfunc(EngFunc_PrecacheModel, PISTOL_MODEL_WORLD);

    // Precache Sounds
    engfunc(EngFunc_PrecacheSound, PISTOL_SHOOT_SOUND);

    // Precache generic
    new szWeaponList[128]; formatex(szWeaponList, charsmax(szWeaponList), "sprites/%s.txt", PISTOL_WEAPONLIST);
    engfunc(EngFunc_PrecacheGeneric, szWeaponList);

    // Hook weapon
    register_clcmd(PISTOL_WEAPONLIST, "Command_HookWeapon");
}

public Command_HookWeapon(iPlayer)
{
    engclient_cmd(iPlayer, PISTOL_REFERENCE);
    return PLUGIN_HANDLED;
}

public Command_GivePistol(iPlayer)
{
    static iPistol; iPistol = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_Entity);
    if(!IsValidEntity(iPistol)) return FM_NULLENT;

    set_pev(iPistol, pev_impulse, PISTOL_SPECIAL_CODE);
    ExecuteHam(Ham_Spawn, iPistol);
    set_pdata_int(iPistol, m_iClip, PISTOL_AMMO, linux_diff_weapon);
    UTIL_DropWeapon(iPlayer, ExecuteHamB(Ham_Item_ItemSlot, iPistol));

    if(!ExecuteHamB(Ham_AddPlayerItem, iPlayer, iPistol))
    {
	set_pev(iPistol, pev_flags, pev(iPistol, pev_flags) | FL_KILLME);
	return 0;
    }

    ExecuteHamB(Ham_Item_AttachToPlayer, iPistol, iPlayer);
    UTIL_WeaponList(iPlayer, true);

    static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iPistol, m_iPrimaryAmmoType, linux_diff_weapon);

    if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) < PISTOL_BPAMMO)
    set_pdata_int(iPlayer, iAmmoType, PISTOL_BPAMMO, linux_diff_player);

    emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    return 1;
}

/* ~ [ Hamsandwich ] ~ */
public CPistol__Deploy_Post(iPistol)
{
    if(!IsValidEntity(iPistol) || !IsCustomPistol(iPistol)) return;

    static iPlayer; iPlayer = get_pdata_cbase(iPistol, m_pPlayer, linux_diff_weapon);

    set_pev_string(iPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);
    set_pev_string(iPlayer, pev_weaponmodel2, gl_iszAllocString_ModelPlayer);

    UTIL_SendWeaponAnim(iPlayer, PISTOL_ANIM_DRAW);

    set_pdata_float(iPlayer, m_flNextAttack, PISTOL_ANIM_DRAW_TIME, linux_diff_player);
    set_pdata_float(iPistol, m_flTimeWeaponIdle, PISTOL_ANIM_DRAW_TIME, linux_diff_weapon);
}

public CPistol__PrimaryAttack_Pre(iPistol)
{
    if(!IsValidEntity(iPistol) || !IsCustomPistol(iPistol)) return HAM_IGNORED;
    if(get_pdata_int(iPistol, m_iShotsFired, 4) != 0) return HAM_SUPERCEDE;

    static iAmmo; iAmmo = get_pdata_int(iPistol, m_iClip, linux_diff_weapon);
    if(!iAmmo)
    {
        ExecuteHam(Ham_Weapon_PlayEmptySound, iPistol);
	set_pdata_float(iPistol, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

	return HAM_SUPERCEDE;
    }

    static fw_TraceLine; fw_TraceLine = register_forward(FM_TraceLine, "FM_Hook_TraceLine_Post", true);
    static fw_PlayBackEvent; fw_PlayBackEvent = register_forward(FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false);
    fm_ham_hook(true);		

    ExecuteHam(Ham_Weapon_PrimaryAttack, iPistol);
		
    unregister_forward(FM_TraceLine, fw_TraceLine, true);
    unregister_forward(FM_PlaybackEvent, fw_PlayBackEvent);
    fm_ham_hook(false);

    static iPlayer; iPlayer = get_pdata_cbase(iPistol, m_pPlayer, linux_diff_weapon);

    static Float: vecPunchangle[3];
    pev(iPlayer, pev_punchangle, vecPunchangle);
    vecPunchangle[0] *= PISTOL_SHOOT_PUNCHANGLE
    vecPunchangle[1] *= PISTOL_SHOOT_PUNCHANGLE
    vecPunchangle[2] *= PISTOL_SHOOT_PUNCHANGLE
    set_pev(iPlayer, pev_punchangle, vecPunchangle);

    UTIL_SendWeaponAnim(iPlayer, PISTOL_ANIM_SHOOT);
    emit_sound(iPlayer, CHAN_WEAPON, PISTOL_SHOOT_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    set_pdata_float(iPlayer, m_flNextAttack, PISTOL_SHOOT_RATE, linux_diff_player);
    set_pdata_float(iPistol, m_flTimeWeaponIdle, PISTOL_ANIM_SHOOT_TIME, linux_diff_weapon);
    set_pdata_float(iPistol, m_flNextPrimaryAttack, PISTOL_SHOOT_RATE, linux_diff_weapon);
    set_pdata_float(iPistol, m_flNextSecondaryAttack, PISTOL_SHOOT_RATE, linux_diff_weapon);

    return HAM_SUPERCEDE;
}

public CPistol__Reload_Pre(iPistol)
{
    if(!IsValidEntity(iPistol) || !IsCustomPistol(iPistol)) return HAM_IGNORED;

    static iAmmo; iAmmo = get_pdata_int(iPistol, m_iClip, linux_diff_weapon);
    if(iAmmo >= PISTOL_AMMO) return HAM_SUPERCEDE;

    static iPlayer; iPlayer = get_pdata_cbase(iPistol, m_pPlayer, linux_diff_weapon);
    static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iPistol, m_iPrimaryAmmoType, linux_diff_weapon);

    if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE;

    set_pdata_int(iPistol, m_iClip, 0, linux_diff_weapon);
    ExecuteHam(Ham_Weapon_Reload, iPistol);
    set_pdata_int(iPistol, m_iClip, iAmmo, linux_diff_weapon);
    set_pdata_int(iPistol, m_fInReload, 1, linux_diff_weapon);

    UTIL_SendWeaponAnim(iPlayer, PISTOL_ANIM_RELOAD);

    set_pdata_float(iPlayer, m_flNextAttack, PISTOL_ANIM_RELOAD_TIME, linux_diff_player);
    set_pdata_float(iPistol, m_flTimeWeaponIdle, PISTOL_ANIM_RELOAD_TIME, linux_diff_weapon);
    set_pdata_float(iPistol, m_flNextPrimaryAttack, PISTOL_ANIM_RELOAD_TIME, linux_diff_weapon);
    set_pdata_float(iPistol, m_flNextSecondaryAttack, PISTOL_ANIM_RELOAD_TIME, linux_diff_weapon);

    return HAM_SUPERCEDE;
}

public CPistol__PostFrame_Pre(iPistol)
{ 
    if(!IsValidEntity(iPistol) || !IsCustomPistol(iPistol)) return HAM_IGNORED;

    static iClip; iClip = get_pdata_int(iPistol, m_iClip, linux_diff_weapon);
    if(get_pdata_int(iPistol, m_fInReload, linux_diff_weapon) == 1)
    {
        static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iPistol, m_iPrimaryAmmoType, linux_diff_weapon);
	static iPlayer; iPlayer = get_pdata_cbase(iPistol, m_pPlayer, linux_diff_weapon);
        static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, linux_diff_player);
        static j; j = min(PISTOL_AMMO - iClip, iAmmo);
        
	set_pdata_int(iPistol, m_iClip, iClip + j, linux_diff_weapon);
	set_pdata_int(iPlayer, iAmmoType, iAmmo - j, linux_diff_player);
        set_pdata_int(iPistol, m_fInReload, 0, linux_diff_weapon);
    }

    return HAM_IGNORED;
}

public CPistol__Holster_Post(iPistol)
{
    if(!IsValidEntity(iPistol) || !IsCustomPistol(iPistol)) return;

    static iPlayer; iPlayer = get_pdata_cbase(iPistol, m_pPlayer, linux_diff_weapon);

    set_pdata_float(iPistol, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
    set_pdata_float(iPistol, m_flNextSecondaryAttack, 0.0, linux_diff_weapon);
    set_pdata_float(iPistol, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
    set_pdata_float(iPlayer, m_flNextAttack, 0.0, linux_diff_player);
}

public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float: flDamage)
{
    if(!is_user_connected(iAttacker)) return;
	
    static iPistol; iPistol = get_pdata_cbase(iAttacker, 373, 5);
    if(!IsValidEntity(iPistol) || !IsCustomPistol(iPistol)) return;

    flDamage *= PISTOL_SHOOT_DAMAGE
    SetHamParamFloat(3, flDamage);
}

public CPistol__Idle_Pre(iPistol)
{
	if(!IsValidEntity(iPistol) || !IsCustomPistol(iPistol) || get_pdata_float(iPistol, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	
	static iPlayer; iPlayer = get_pdata_cbase(iPistol, m_pPlayer, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, PISTOL_ANIM_IDLE);
	set_pdata_float(iPistol, m_flTimeWeaponIdle, PISTOL_ANIM_IDLE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CPistol__AddToPlayer_Post(iPistol, iPlayer)
{
    if(IsValidEntity(iPistol) && IsCustomPistol(iPistol)) UTIL_WeaponList(iPlayer, true);
    else if(!pev(iPistol, pev_impulse)) UTIL_WeaponList(iPlayer, false);
}

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle)
{
    if(!is_user_alive(iPlayer)) return;

    static iPistol; iPistol = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
    if(!IsValidEntity(iPistol) || !IsCustomPistol(iPistol)) return;

    set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

public FM_Hook_SetModel_Pre(iEntity)
{
    static i, szClassName[32], iPistol;
    pev(iEntity, pev_classname, szClassName, charsmax(szClassName));

    if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;

    for(i = 0; i < 6; i++)
    {
	iPistol = get_pdata_cbase(iEntity, m_rgpPlayerItems_iWeaponBox + i, linux_diff_weapon);
		
	if(IsValidEntity(iPistol) && IsCustomPistol(iPistol))
	{
		engfunc(EngFunc_SetModel, iEntity, PISTOL_MODEL_WORLD);
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
    write_string(bEnabled ? PISTOL_WEAPONLIST : PISTOL_REFERENCE);
    write_byte(iPistolList[0]);
    write_byte(bEnabled ? PISTOL_AMMO : iPistolList[1]);
    write_byte(iPistolList[2]);
    write_byte(iPistolList[3]);
    write_byte(iPistolList[4]);
    write_byte(iPistolList[5]);
    write_byte(iPistolList[6]);
    write_byte(iPistolList[7]);
    message_end();
}
