unit r_constants;

//��������� ������� ����� ���������� � �������
//�������� CBlender_Compile__SetMapping, ��������� �� �������

interface
function Init():boolean;

implementation
uses BaseGameData, sysutils;
//////////////////////////////////////////////////////////////////
type R_constant = record
//todo:��������
end;
type pR_constant = ^R_constant;
/////////////////// R_constant_setup//////////////////////////////
type R_constant_setup_vftable  = record
  setup_proc:pointer;
  virtual_destructor:pointer;
end;
type pR_constant_setup_vftable = ^R_constant_setup_vftable;

type R_constant_setup  = record
  vftable:pR_constant_setup_vftable;
  setup_proc_addr:procedure(C:pR_constant); stdcall; //��� ������ ��������� setup, � ��������� ���! ����� ��� �������� ������
end;
type pR_constant_setup = ^R_constant_setup;

//////////////////////////////////////////////////////////////////////////

const
  eye_direction:PChar = 'eye_direction';

var
  CBlender_Compile__r_Constant_proc_addr:cardinal;
  RCache__set: procedure(C:pR_constant; x,y,z,w:single); stdcall;
  r_constant_vftable:R_constant_setup_vftable;
  binder_cur_zoom_factor:R_constant_setup;


//����� ������� ��������////////////////////////////////////////
// "���������" ��� �������� ������ � ������-����������
procedure R_constant_setup__setup_internal_caller(this:pR_constant_setup; C:pR_constant); stdcall;
begin
  this.setup_proc_addr(C);
end;

//��� ��������� ���������� �������
procedure R_constant_setup__setup(); stdcall;
asm
  push ebp
  mov ebp, esp
  pushad
    push [ebp+$8]
    push ecx
    call R_constant_setup__setup_internal_caller
  popad
  pop ebp
  ret 4
end;

////////////////////////////////////////////////////////////////
//��������� ����������� ����� ���������
procedure CBlender_Compile__r_Constant(this:pointer; name:PChar; addr:pR_constant_setup); stdcall;
asm
    pushad
      push name
      push this
      mov esi, addr
      call  CBlender_Compile__r_Constant_proc_addr
    popad
end;


////////////////////////////////////////////////////////////////////////
//���������� ������� ���������� ������� ����� ��������
procedure binder_cur_zoom_factor_setup(C:pR_constant); stdcall;
begin
  RCache__set(C, 0,1,0,0.5);
  //log('binder_cur_zoom_factor_setup called, '+inttohex(cardinal(C), 8));
end;

////////////////////////////////////////////////////////////////////////
procedure CBlender_Compile__SetMapping(this:pointer); stdcall;
begin
  //����� ��������� ���������� �����!
  //log(inttohex(cardinal(@binder_cur_zoom_factor), 8));

  binder_cur_zoom_factor.vftable:=@r_constant_vftable;
  binder_cur_zoom_factor.setup_proc_addr:=@binder_cur_zoom_factor_setup;
  CBlender_Compile__r_Constant(this, 'm_hud_params', @binder_cur_zoom_factor);
end;

//���� ��� ���������� ��������
procedure CBlender_Compile__SetMapping_Patch(); stdcall;
asm
  pushad
    push edi
    call CBlender_Compile__SetMapping
  popad
  push [esp]
  push eax
  mov eax, eye_direction
  mov [esp+8], eax
  pop eax
end;



//////////////��������� RCache::Set ��� ������� �� ��������/////////////
procedure RCache__Set_R1 (C:pR_constant; x,y,z,w:single); stdcall;
asm
  pushad

  mov ecx, C
  test ecx, ecx
  je @finish
  test byte ptr [ecx+$0C],01

  movss xmm0, x
  movss xmm1, y
  movss xmm2, z
  movss xmm3, w

  je @vertex

  //if pixel
  movzx eax,word ptr [ecx+$10]
  shl eax,04
  add eax, xrRender_R1_addr
  add eax, $B5B60
  movss [eax],xmm0
  movss [eax+$04],xmm1
  movss [eax+$08],xmm2
  movss [eax+$0C],xmm3
  movzx eax,word ptr [ecx+$10]
  mov ebx, xrRender_R1_addr
  add ebx, $B6B64
  cmp eax, [ebx]
  lea edx,[eax+$01]
  jae @p1
  mov [ebx], eax
  @p1:
  add ebx, $4
  cmp edx, [ebx]
  jna @p2
  mov [ebx], edx
  @p2:
  mov [ebx+$8], 1

  @vertex:
  test byte ptr [ecx+$0C],02
  je @finish
  movzx eax,word ptr [ecx+$14]
  shl eax,04
  add eax, xrRender_R1_addr
  add eax, $B6B80
  movss [eax],xmm0
  movss [eax+$04],xmm1
  movss [eax+$08],xmm2
  movss [eax+$0C],xmm3
  movzx eax,word ptr [ecx+$14]
  mov ebx, xrRender_R1_addr
  add ebx, $B7B84
  cmp eax, [ebx]
  lea ecx,[eax+$01]
  jae @v1
  mov [ebx], eax
  @v1:
  add ebx, $4
  cmp ecx, [ebx]
  jna @v2
  mov [ebx], ecx
  @v2:
  mov [ebx+$8], 1
  @finish:
  popad
end;


procedure RCache__Set_R2 (C:pR_constant; x,y,z,w:single); stdcall;
asm
  pushad

  mov ecx, C
  test ecx, ecx
  je @finish
  test byte ptr [ecx+$0C],01

  movss xmm0, x
  movss xmm1, y
  movss xmm2, z
  movss xmm3, w

  je @vertex

  //if pixel
  movzx eax,word ptr [ecx+$10]
  shl eax,04
  add eax, xrRender_R2_addr
  add eax, $DD090
  movss [eax],xmm0
  movss [eax+$04],xmm1
  movss [eax+$08],xmm2
  movss [eax+$0C],xmm3
  movzx eax,word ptr [ecx+$10]
  mov ebx, xrRender_R2_addr
  add ebx, $DE094
  cmp eax, [ebx]
  lea edx,[eax+$01]
  jae @p1
  mov [ebx], eax
  @p1:
  add ebx, $4
  cmp edx, [ebx]
  jna @p2
  mov [ebx], edx
  @p2:
  mov [ebx+$8], 1

  @vertex:
  test byte ptr [ecx+$0C],02
  je @finish
  movzx eax,word ptr [ecx+$14]
  shl eax,04
  add eax, xrRender_R2_addr
  add eax, $DE0B0
  movss [eax],xmm0
  movss [eax+$04],xmm1
  movss [eax+$08],xmm2
  movss [eax+$0C],xmm3
  movzx eax,word ptr [ecx+$14]
  mov ebx, xrRender_R2_addr
  add ebx, $DF0B4
  cmp eax, [ebx] 
  lea ecx,[eax+$01]
  jae @v1
  mov [ebx], eax
  @v1:
  add ebx, $4
  cmp ecx, [ebx]
  jna @v2
  mov [ebx], ecx
  @v2:
  mov [ebx+$8], 1
  @finish:
  popad
end;

procedure RCache__Set_R3_internal(); stdcall;
//fake arguments present!!!
//��� �����: ��� �������� - �� �� ����������!!!
asm
  mov ecx, esp
  sub esp, $10
  push esi

  mov esi, [ecx+$04]

  mov eax, [ecx+$08]
  mov [esp+$04], eax

  mov eax, [ecx+$0C]
  mov [esp+$08], eax

  mov eax, [ecx+$10]
  mov [esp+$0C], eax

  mov eax, [ecx+$14]
  mov [esp+$10], eax


  mov ecx, xrrender_r3_addr
  add ecx, $96F64
  mov eax, [esi+$0C]  
  test al, 01
  jmp ecx          //[hack] ���������� ����� ��������� �������
end;

procedure RCache__Set_R3 (C:pR_constant; x,y,z,w:single); stdcall;
asm
  pushad

  cmp C, 0
  je @finish

  push w
  push z
  push y
  push x
  push c
  call RCache__Set_R3_internal
  add esp, $10

  @finish:
  popad
end;

procedure RCache__Set_R4_internal(); stdcall;
//fake arguments present!!!
//��� �����: ��� �������� - �� �� ����������!!!
asm
  mov ecx, esp
  sub esp, $10
  push esi

  mov esi, [ecx+$04]

  mov eax, [ecx+$08]
  mov [esp+$04], eax

  mov eax, [ecx+$0C]
  mov [esp+$08], eax

  mov eax, [ecx+$10]
  mov [esp+$0C], eax

  mov eax, [ecx+$14]
  mov [esp+$10], eax


  mov ecx, xrrender_r4_addr
  add ecx, $9F15A
  mov eax, [esi+$0C]
  push ebx
  mov ebx, 1
  test bl, al
  jmp ecx          //[hack] ���������� ����� ��������� �������
end;

procedure RCache__Set_R4 (C:pR_constant; x,y,z,w:single); stdcall;
asm
  pushad

  cmp C, 0
  je @finish

  push w
  push z
  push y
  push x
  push c
  call RCache__Set_R4_internal
  add esp, $10

  @finish:
  popad
end;

////////////////////////////////////////////////////////////////////////

function Init():boolean;
var
  jmp_addr:cardinal;
begin
  result:=false;
  if xrRender_R1_addr<>0 then begin
    CBlender_Compile__r_Constant_proc_addr:=xrRender_R1_addr+$610A0;
    RCache__set:=RCache__Set_R1;
    jmp_addr:=xrRender_R1_addr+$6304B;
    r_constant_vftable.virtual_destructor:= pointer(xrRender_R1_addr+$616C0);
    
  end else if xrRender_R2_addr<>0 then begin
    CBlender_Compile__r_Constant_proc_addr:=xrRender_R2_addr+$89600;
    RCache__set:=RCache__Set_R2;
    jmp_addr:=xrRender_R2_addr+$8B5EB;
    r_constant_vftable.virtual_destructor:=pointer(xrRender_R2_addr+$89c60);

  end else if xrRender_R3_addr<>0 then begin
    CBlender_Compile__r_Constant_proc_addr:=xrRender_R3_addr+$95490;
    RCache__set:=RCache__Set_R3;
    jmp_addr:=xrRender_R3_addr+$9762B;
    r_constant_vftable.virtual_destructor:=pointer(xrRender_R3_addr+$15950);

  end else if xrRender_R4_addr<>0 then begin
    CBlender_Compile__r_Constant_proc_addr:=xrRender_R4_addr+$9D160;
    RCache__set:=RCache__Set_R4;
    jmp_addr:=xrRender_R4_addr+$9FF3B;
    r_constant_vftable.virtual_destructor:=pointer(xrRender_R4_addr+$9E1C0);

  end else begin
    CBlender_Compile__r_Constant_proc_addr :=0;
    RCache__set:=nil;
    r_constant_vftable.virtual_destructor:=nil;
    jmp_addr:=0;
  end;
  if jmp_addr>0 then
    if not WriteJump(jmp_addr, cardinal(@CBlender_Compile__SetMapping_Patch), 5, true) then exit;
  r_constant_vftable.setup_proc:=@R_constant_setup__setup;
  result:=true;
end;

end.