unit ScriptFunctors;

interface

procedure script_call(name:PChar; arg1:PChar; arg2:single); stdcall;

type bind_data = packed record
  ptr1:cardinal;
  ptr2:cardinal;
  id:cardinal;    
end;
type pbinddata = ^bind_data;

type script_functor_pchar_single = packed record
  bind:pbinddata;
  str:^PChar;
  number:psingle;
  status:byte;
  unused1:byte;
  unused2:word;
end;


type pscript_functor_pchar_single = ^script_functor_pchar_single;

implementation
uses BaseGameData, Misc;

const
  CAISPACE_SZ:cardinal=$2C;

function CAISpace_new():pointer; stdcall;
begin
  result:=xrMemory__allocate(CAISPACE_SZ);
  if result = nil then exit;

  FillChar(PChar(result)^, CAISPACE_SZ, 0);
  PCardinal(result)^:=xrgame_addr+$547064;
end;



function Get_script_engine():pointer; stdcall;
asm
  pushad
    mov eax, xrgame_addr
    mov ebx, [eax+$64DA98]
    cmp ebx, 0
    jne @get

    call CAISpace_new
    mov [eax+$64DA98], eax

    @get:
    mov eax, xrgame_addr
    mov eax, [eax+$64DA98]
    cmp eax, 0
    je @finish
    mov eax, [eax+$1c]
    mov @result, eax
    
    @finish:
  popad
end;

procedure luabind_detail_unref(p:cardinal; id:cardinal); stdcall;
asm
  pushad
    push id
    push p
    mov eax, xrgame_addr
    call [eax+$512490]
    add esp, 8
  popad
end;

procedure clear_functor(f:pscript_functor_pchar_single); stdcall;
begin
  if ((f.bind.ptr2) = 0) or ((f.bind.id) = $FFFFFFFE) then exit;
  luabind_detail_unref(f.bind.ptr2, f.bind.id);
end;


function bind_functor(name:PChar; b:pbinddata):boolean; stdcall;
asm
  pushad
    mov @result, 0
    call Get_script_engine
    cmp eax, 0
    je @finish

    push b
    push name

    mov ecx, eax
    mov eax, xrgame_addr
    add eax, $96740
    call eax
    mov @result,al

    @finish:
  popad
end;


procedure script_call(name:PChar; arg1:PChar; arg2:single); stdcall;
var
  b:bind_data;
  f:script_functor_pchar_single;
  p:pointer;
begin
  f.bind:=@b;
  f.bind.ptr1:=0;
  f.bind.ptr2:=0;
  f.bind.id:=$FFFFFFFE;
  if not bind_functor(name, f.bind) then exit;
  f.str:=@arg1;
  f.number:=@arg2;
  f.status:=0;

  p:=@f;
  asm
    pushad
    mov ecx, p
    mov eax, xrgame_addr
    add eax, $468d10
    call eax 
    popad
  end;

  clear_functor(@f);
end;

end.
