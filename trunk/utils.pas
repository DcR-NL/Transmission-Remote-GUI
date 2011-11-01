{*************************************************************************************
  This file is part of Transmission Remote GUI.
  Copyright (c) 2008-2010 by Yury Sidorov.

  Transmission Remote GUI is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  Transmission Remote GUI is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Transmission Remote GUI; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*************************************************************************************}

unit utils;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Controls, Forms,
{$ifdef windows}
  Windows, win32int, InterfaceBase
{$endif}
{$ifdef unix}
  baseunix, unix, unixutil, process
{$endif}
  ;

function GetTimeZoneDelta: TDateTime;

procedure ShowTaskbarButton;
procedure HideTaskbarButton;

function OpenURL(const URL: string; const Params: string = ''): boolean;

function CompareFilePath(const p1, p2: string): integer;

procedure AppBusy;
procedure AppNormal;
procedure ForceAppNormal;

{$ifdef mswindows}
procedure AllowSetForegroundWindow(dwProcessId: DWORD);
{$endif mswindows}

implementation

uses FileUtil;

function GetTimeZoneDelta: TDateTime;
{$ifdef windows}
var
  t: TIME_ZONE_INFORMATION;
  res: dword;
{$endif}
begin
  Result:=0;
{$ifdef windows}
  res:=GetTimeZoneInformation(t);
  if res<> TIME_ZONE_ID_INVALID then begin
    case res of
      TIME_ZONE_ID_STANDARD:
        Result:=-t.StandardBias;
      TIME_ZONE_ID_DAYLIGHT:
        Result:=-t.DaylightBias;
    end;
    Result:=(-t.Bias + Result)/MinsPerDay;
  end;
{$endif}
{$ifdef unix}
  Result:=Tzseconds/SecsPerDay;
{$endif}
end;

procedure ShowTaskbarButton;
begin
{$ifdef mswindows}
  ShowWindow(TWin32WidgetSet(WidgetSet).AppHandle, SW_SHOW);
{$else}
  Application.MainForm.Visible:=True;
{$endif mswindows}
end;

procedure HideTaskbarButton;
begin
{$ifdef mswindows}
  ShowWindow(TWin32WidgetSet(WidgetSet).AppHandle, SW_HIDE);
{$else}
  Application.MainForm.Visible:=False;
{$endif mswindows}
end;

{$ifdef unix}
function UnixOpenURL(const FileName: String):Integer;
var
  WrkProcess: TProcess;
  cmd, fn: String;
begin
  Result:=-1;
  cmd:=FindDefaultExecutablePath('xdg-open');
  if cmd = '' then begin
    cmd:=FindDefaultExecutablePath('gnome-open');
    if cmd = '' then begin
      cmd:=FindDefaultExecutablePath('kioclient');
      if cmd <> '' then
        cmd:=cmd + ' exec'
      else begin
        cmd:=FindDefaultExecutablePath('kfmclient');
        if cmd = '' then
          exit;
        cmd:=cmd + ' exec';
      end;
    end;
  end;

  fn:=FileName;
  if Pos('://', fn) > 0 then
    fn:=StringReplace(fn, '#', '%23', [rfReplaceAll]);

  WrkProcess:=TProcess.Create(nil);
  try
    WrkProcess.Options:=[poNoConsole];
    WrkProcess.CommandLine:=cmd + ' "' + fn + '"';
    WrkProcess.Execute;
    Result:=WrkProcess.ExitStatus;
  finally
    WrkProcess.Free;
  end;
end;
{$endif unix}

function OpenURL(const URL, Params: string): boolean;
{$ifdef mswindows}
var
  s, p: string;
{$endif mswindows}
begin
{$ifdef mswindows}
  s:=UTF8Decode(URL);
  p:=UTF8Decode(Params);
  Result:=ShellExecute(0, 'open', PChar(s), PChar(p), nil, SW_SHOWNORMAL) > 32;
{$endif mswindows}

{$ifdef darwin}
  Result:=fpSystem('Open "' + URL + '"') = 0;
{$else darwin}

  {$ifdef unix}
    Result:=UnixOpenURL(URL) = 0;
  {$endif unix}

{$endif darwin}
end;

var
  BusyCount: integer = 0;

procedure AppBusy;
begin
  Inc(BusyCount);
  Screen.Cursor:=crHourGlass;
end;

procedure AppNormal;
begin
  Dec(BusyCount);
  if BusyCount <= 0 then begin
    BusyCount:=0;
    Screen.Cursor:=crDefault;
  end;
end;

procedure ForceAppNormal;
begin
  BusyCount:=0;
  AppNormal;
end;

{$ifdef mswindows}
procedure AllowSetForegroundWindow(dwProcessId: DWORD);
type
  TAllowSetForegroundWindow = function(dwProcessId: DWORD): BOOL; stdcall;
var
  _AllowSetForegroundWindow: TAllowSetForegroundWindow;
begin
  _AllowSetForegroundWindow:=TAllowSetForegroundWindow(GetProcAddress(GetModuleHandle('user32.dll'), 'AllowSetForegroundWindow'));
  if Assigned(_AllowSetForegroundWindow) then
    _AllowSetForegroundWindow(dwProcessId);
end;
{$endif mswindows}

function CompareFilePath(const p1, p2: string): integer;
begin
{$ifdef windows}
  Result:=AnsiCompareText(UTF8Decode(p1), UTF8Decode(p2));
{$else}
  Result:=AnsiCompareStr(UTF8Decode(p1), UTF8Decode(p2));
{$endif windows}
end;

end.

