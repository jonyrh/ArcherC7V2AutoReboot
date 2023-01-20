program ArcherC7V2AutoReboot;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  //{$IFDEF UseCThreads}
  cthreads,
  cmem,
  //{$ENDIF}
  {$ENDIF}
  Classes, SysUtils, Interfaces, CustApp, StrUtils, LazUTF8, indylaz,
  IdHTTP, HTTPProtocol, pingsend, laz_synapse, Base64, md5;

type

  { TArcherC7V2AutoReboot }

  TArcherC7V2AutoReboot = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
    procedure RebootRouter(const aHost, aUser, aPassword, aCommand: String; aTest: Boolean);
    function PingRemoteHost(const aHost: String; const aTry: Integer): Boolean;
    function CheckRefererId(const aRefererId: String): Boolean;
  end;

{ TArcherC7V2AutoReboot }

function TArcherC7V2AutoReboot.PingRemoteHost(const aHost: String; const aTry: Integer): Boolean;
var
  i: Integer;
  aPingSend: TPingSend;
begin
  Result:= False;

  aPingSend:= TPINGSend.Create;
  aPingSend.Timeout:= 3000;

   try

    for i:=1 to aTry do
     begin

      try
       Result:= aPingSend.Ping(aHost.Trim);
      except
      end;

     if Result then Break else Sleep(3000);
     end;

   finally
    aPingSend.Free;
   end;
end;

function TArcherC7V2AutoReboot.CheckRefererId(const aRefererId: String): Boolean;
var
  i: Integer;
begin
  Result:= False;

  for i:=1 to UTF8Length(aRefererId) do
   begin
   Result:= CharInSet(UTF8Copy(aRefererId, i, 1)[1], ['A'..'Z']);
   if not Result then Break;
   end;
end;

procedure TArcherC7V2AutoReboot.RebootRouter(const aHost, aUser, aPassword, aCommand: String; aTest: Boolean);
var
  IdHTTP: TIdHTTP;
  aRefererId: String;
begin
  // Archer C7 v2 00000000
  // 3.15.3 Build 180308 Rel.37724n

  IdHTTP:= TIdHTTP.Create;

   try

    IdHTTP.Request.Clear;
    IdHTTP.Request.UserAgent:=' Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36 Edg/109.0.1518.55';
    IdHTTP.Request.Host:= aHost;
    IdHTTP.Request.Accept:= 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9';
    IdHTTP.Request.AcceptEncoding:= 'gzip, deflate';
    IdHTTP.Request.AcceptLanguage:= 'ru,en;q=0.9,en-GB;q=0.8,en-US;q=0.7';
    IdHTTP.Request.CacheControl:= 'no-cache';
    IdHTTP.Request.Connection:= 'keep-alive';
    IdHTTP.Request.CustomHeaders.Add('Cookie: Authorization=Basic%20' + EncodeStringBase64(aUser + ':' + MD5Print(MD5String(aPassword))));
    IdHTTP.Request.Referer:= 'http://' + aHost + '/';

    aRefererId:='';
    aRefererId:= IdHTTP.Get('http://' + aHost + '/userRpm/LoginRpm.htm?Save=Save').Trim;
    aRefererId:= UTF8StringReplace(aRefererId, '<body><script language="javaScript">window.parent.location.href = "http://' + aHost + '/', '', [rfReplaceAll, rfIgnoreCase]).Trim;
    aRefererId:= UTF8StringReplace(aRefererId, '/userRpm/Index.htm";', '', [rfReplaceAll, rfIgnoreCase]).Trim;
    aRefererId:= UTF8StringReplace(aRefererId, '</script></body></html>', '', [rfReplaceAll, rfIgnoreCase]).Trim;
    aRefererId:= aRefererId.Trim;

    if (not aRefererId.IsEmpty) and (CheckRefererId(aRefererId)) then
     begin
     if not aTest then
      begin
      IdHTTP.Request.Referer:='http://' + aHost + '/' + aRefererId + '/userRpm/SysRebootRpm.htm';
      IdHTTP.Get('http://' + aHost + '/' + aRefererId + '/userRpm/SysRebootRpm.htm?Reboot=' + aCommand);
      end
       else WriteLn('[' + FormatDateTime('YYYY-MM-DD hh:nn:ss', Now) + '] Test OK, RefererId = ' + aRefererId);
     end
      else
       begin
       if aTest then WriteLn('[' + FormatDateTime('YYYY-MM-DD hh:nn:ss', Now) + '] Test FAIL, incorrect RefererId from router...')
                else WriteLn('[' + FormatDateTime('YYYY-MM-DD hh:nn:ss', Now) + '] Cannot restart router: incorrect RefererId from router...');
       end;

   finally
    IdHTTP.Free;
   end;
end;

procedure TArcherC7V2AutoReboot.DoRun;
var
  aHostRemote,
  aHostRouter,
  aUser,
  aPassword,
  aCommand: String;
  aTest: Boolean;
begin

  if (HasOption('h', 'help')) or (HasOption('v', 'version')) then
   begin
   WriteHelp;
   Terminate;
   Exit;
   end;

  aTest:= False;
  aHostRemote:= '8.8.8.8';
  aHostRouter:= '192.168.0.1';
  aUser:=       'admin';
  aPassword:=   'admin';
  aCommand:=    HTTPEncode('Перезагрузить');

  if HasOption('t', 'test')   then aTest:=       True;
  if HasOption('w', 'watch')  then aHostRemote:= GetOptionValue('w', 'watch').Trim;
  if HasOption('r', 'router') then aHostRouter:= GetOptionValue('r', 'router').Trim;
  if HasOption('u', 'user')   then aUser:=       GetOptionValue('u', 'user').Trim;
  if HasOption('p', 'pass')   then aPassword:=   GetOptionValue('p', 'pass').Trim;
  if HasOption('c', 'cmd')    then aCommand:=    HTTPEncode(GetOptionValue('c', 'cmd').Trim);

  if not PingRemoteHost(aHostRemote, 3) then
   begin
   WriteLn('[' + FormatDateTime('YYYY-MM-DD hh:nn:ss', Now) + '] Remote IP not responding, restarting router...');
   RebootRouter(aHostRouter, aUser, aPassword, aCommand, aTest);
   end
    else
     begin
     if aTest then WriteLn('[' + FormatDateTime('YYYY-MM-DD hh:nn:ss', Now) + '] Test OK, Remote IP respond!')
     end;

  Terminate;
end;

constructor TArcherC7V2AutoReboot.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TArcherC7V2AutoReboot.Destroy;
begin
  inherited Destroy;
end;

procedure TArcherC7V2AutoReboot.WriteHelp;
begin
  WriteLn;
  WriteLn('Archer C7 V2 AutoReboot for FW 3.15.3 Build 180308 Rel.37724n (' +
          {$IFDEF MSWINDOWS}'Win64'   {$ENDIF}
          {$IFDEF LINUX}    'Linux64' {$ENDIF}
          + ') 2023.01.20.23.30');

  WriteLn('(c) Jony Rh, 2023');
  WriteLn('http://www.jonyrh.ru');
  WriteLn;
  WriteLn('--w, --watch' +  chr(9) + 'Remote IP address for ping, default "8.8.8.8"');
  WriteLn('--r, --router' + chr(9) + 'Router local IP address, default "192.168.0.1"');
  WriteLn('--u, --user' +   chr(9) + 'Router Username, default "admin"');
  WriteLn('--p, --pass' +   chr(9) + 'Router Password, default "admin"');
  WriteLn('--c, --cmd' +    chr(9) + 'Router reboot command (Depends on localization), default "Перезагрузить"');
  WriteLn('--t, --test' +   chr(9) + 'Only test, without reboot router');
  WriteLn;
  WriteLn('Examples:');
  WriteLn(ExtractFileName(ParamStr(0)) + ' --watch=8.8.8.8 --router=192.168.0.1 --user=admin --pass=admin --cmd=Перезагрузить');
  WriteLn(ExtractFileName(ParamStr(0)) + ' --watch=8.8.8.8 --router=192.168.0.1 --user=admin --pass=admin --cmd=reboot --test');
  WriteLn(ExtractFileName(ParamStr(0)) + ' --w=8.8.8.8 --r=192.168.0.1 --u=admin --p=admin --c=1 --t');
  WriteLn(ExtractFileName(ParamStr(0)) + ' --u=admin --p=admin');

  {$IFDEF UNIX} WriteLn; {$ENDIF}
end;

var
  Application: TArcherC7V2AutoReboot;
begin
  Application:=TArcherC7V2AutoReboot.Create(nil);
  Application.Title:='Archer C7 V2 AutoReboot';
  Application.Run;
  Application.Free;
end.

