unit Crows;

interface
uses MatVectors;
function Init():boolean;

type
CAI_Crow = packed record
  _unknown:array[0..$31B] of Byte;
  st_current:cardinal; //31�
  st_target:cardinal;
  vGoalDir:FVector3;
  vCurrentDir:FVector3;
  //����������� �������...
end;

pCAI_Crow = ^CAI_Crow;
const
  ECrowStates__eUndef:integer = -1;
  ECrowStates__eDeathFall:integer = 0;
  ECrowStates__eDeathDead:integer = 1;
  ECrowStates__eFlyIdle:integer = 2;
  ECrowStates__eFlyUp:integer = 3;

implementation
uses BaseGameData, Misc, sysutils, gunsl_config, ScriptFunctors, ActorUtils, math, RayPick, ConsoleUtils;

procedure SaveFlags(crow:pCAI_Crow; flags:pbyte); stdcall;
begin
  flags^ := ((crow.st_current and $0000000F) shl 4)+(crow.st_target and $0000000F);
end;

procedure ApplyFlags(crow:pCAI_Crow; flags:byte); stdcall;
begin
  crow.st_target:=flags and $0F;
  crow.st_current:=(flags and $F0) shr 4;

end;

procedure CAICrow__net_Export_Flags_Patch(); stdcall;
asm
  push 0
  mov ecx, esp
  pushad
    push ecx
    push edi //crow
    call SaveFlags
  popad

  mov ecx, esi
  mov edx, xrgame_addr
  call [edx+$512804]
end;

procedure CAICrow__net_Import_Flags_Patch(); stdcall;
asm
  pushad
    push eax
    push esi
    call ApplyFlags
  popad
  //original
  lea eax, [esi+$80]
end;

procedure CAICrow__net_Spawn_Flags_Patch(); stdcall;
asm
  //������� �� ���������� ������� ����� (��� �� �������� $FC) � ������� �� ApplyFlags
  mov edi, [esp+$14]              //��� ��������� ������
  cmp edi, 0
  je @no_server_object

  movzx edi,  byte ptr [edi+$FC]  //�����
  pushad
    push edi  //�����
    push esi  //CAI_Crow
    call ApplyFlags
  popad
  @no_server_object:

  //������, ���� � ��� "�����" ����� (�� ���� ����� Die ���������, ��� Health>0) - ������������ ���������� ��������
  mov edi, [esi+CAI_Crow.st_target]
  cmp edi, ECrowStates__eDeathFall
  je @not_deactivate
  cmp edi, ECrowStates__eDeathDead
  je @not_deactivate
    mov ecx, esi
    mov edi, xrgame_addr
    call [edi+$512C44]   //processing_deactivate
    jmp @finish
  @not_deactivate:
    mov ecx, esi
    mov edi, xrgame_addr
    call [edi+$512D7C]   //processing_activate

    mov ecx, esi
    mov edi, xrgame_addr
    add edi, $1010C0
    call edi            //CAI_Crow::CreateSkeleton
  @finish:
end;

function GetCrowIdleSound(crow_section:PChar):PChar; stdcall;
begin
  result:=game_ini_read_string(crow_section, 'snd_idle');
end;

procedure CAI_Crow__Load_Sound_Patch(); stdcall;
asm
  push [esp]        //�������� ����� ��������
  lea ecx, [esp+4]  //����� ������ ��� ������
  pushad
    push ecx

    push edi //section
    call GetCrowIdleSound

    pop ecx
    mov [ecx], eax
  popad

  ret
end;

procedure CAI_Crow__CheckAttack(crow_sect:PChar; crow_pos:pFVector3; actor_pos:pFVector3); stdcall;
var
  dir, tmp:FVector3;
  dist_now:single;
begin
  if game_ini_r_bool_def(crow_sect, 'bomb_attack', false) then begin
    dir:=actor_pos^;
    v_sub(@dir, crow_pos);
    dist_now:=v_length(@dir);
    v_normalize(@dir);
    if (sqrt(dir.x*dir.x+dir.z*dir.z)<0.05) and (TraceAsView(crow_pos, @dir, nil)>=dist_now-0.4) and game_ini_line_exist(crow_sect, 'bomb_callback') then begin
      script_call(game_ini_read_string(crow_sect, 'bomb_callback'), crow_sect, 0); 
    end;
  end;

  if game_ini_r_bool_def(crow_sect, 'visibility_attack', false) and not IsDemoRecord() then begin
    dir:=FVector3_copyfromengine(CRenderDevice__GetCamPos());
    v_sub(@dir, crow_pos);
    dist_now:=v_length(@dir);
    v_normalize(@dir);

    tmp:=crow_pos^;
    tmp.y:=tmp.y-0.2;

    if (dist_now<game_ini_r_single_def(crow_sect, 'visibility_attack_max_dist', 0)) and (TraceAsView(crow_pos, @dir, nil)>=dist_now-0.4) and game_ini_line_exist(crow_sect, 'visibility_attack_callback') then begin
      script_call(game_ini_read_string(crow_sect, 'visibility_attack_callback'), crow_sect, 0);
    end;
  end;
end;

procedure CAI_Crow__shedule_Update_Attack_Patch();stdcall;
asm
  pushad
    call GetActor
    cmp eax, 0
    je @finish
    add eax, $80
    push eax

    mov eax, esi
    add eax, $3C
    push eax

    mov eax, esi
    mov eax, [eax+$68]
    add eax, $10
    push eax

    call CAI_Crow__CheckAttack

    @finish:
  popad
  xorps xmm0, xmm0
  comiss xmm0, [esi+$328]
end;

procedure CEntity__Die_Patch(); stdcall;
asm
  cmp dword ptr [edx+$424], 01         //IsGameTypeSingle() == true?
  jne @finish
  cmp byte ptr[esi+$232], 01 //m_registered_member == true?
  jne @finish
  mov byte ptr[esi+$232], 00
  @finish:
end;

function Init():boolean;
var
  jmp_addr:cardinal;
begin
    result:=false;


    //[bug] ������ ��� - ������� � CAICrow::net_Export � � CAICrow::net_Import/net_Spawn ���������� � �������� ��������� st_current � st_target
    //��� ����� ��� ������ ������ "����������" ��� ������������ ���� � �������� ����� ���� ����������� (�������� ������, ��� ��������� �� ������ �� �����)
    jmp_addr:=xrGame_addr+$100687;
    if not WriteJump(jmp_addr, cardinal(@CAICrow__net_Export_Flags_Patch), 10, true) then exit;
    jmp_addr:=xrGame_addr+$100EAC;
    if not WriteJump(jmp_addr, cardinal(@CAICrow__net_Import_Flags_Patch), 6, true) then exit;
    jmp_addr:=xrGame_addr+$100835;
    if not WriteJump(jmp_addr, cardinal(@CAICrow__net_Spawn_Flags_Patch), 8, true) then exit;

    //[bug] ������ ���, ����� ��� �� ����, �� ��������� � ���� ������������� ��� ��������
    //������ � void CEntity::Die(CObject* who): ���� ������ �� ��� ��������������� (m_registered_member	== false)
    //�� ���� ��� ��� ����� ����� �������� �����������������, ��� �������� � ������
    nop_code(xrGame_addr+$279650, 7);
    jmp_addr:=xrGame_addr+$27965F;
    if not WriteJump(jmp_addr, cardinal(@CEntity__Die_Patch), 7, true) then exit;

    //��������� ����������� �������� ������ ������ ��� ������ ����
    jmp_addr:=xrGame_addr+$101A40;
    if not WriteJump(jmp_addr, cardinal(@CAI_Crow__Load_Sound_Patch), 5, true) then exit;

    //����� ����
    jmp_addr:=xrGame_addr+$1013C8;
    if not WriteJump(jmp_addr, cardinal(@CAI_Crow__shedule_Update_Attack_Patch), 10, true) then exit;

    result:=true;
end;

end.