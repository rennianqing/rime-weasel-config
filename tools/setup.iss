; Inno Setup Script for Rime Weasel Custom Package
; Generated for rennianqing/rime-weasel-config

#define MyAppName "小狼毫输入法"
#define MyAppVersion "1.1.0"
#define MyAppPublisher "rennianqing"
#define MyAppURL "https://github.com/rennianqing/rime-weasel-config"
#define MyAppExeName "WeaselServer.exe"

[Setup]
AppId={{5A8D293E-0518-4712-B2A4-F2D7103CE8B9}
AppName={#MyAppName} (Rime Weasel) 定制增强版
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName=D:\Program Files\Rime
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=D:\Program Files\Rime\dist
OutputBaseFilename=Weasel-Setup-v1.1.0-Enhanced
Compression=lzma2/ultra64
SolidCompression=yes
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64
WizardStyle=modern
DisableDirPage=no
DirExistsWarning=no
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Files]
; 1. 自动安装并注册鸿蒙黑体（全系列无依赖支持）
Source: "fonts\HarmonyOS_Sans_SC_Regular.ttf"; DestDir: "{autofonts}"; FontInstall: "HarmonyOS Sans SC"; Flags: onlyifdoesntexist uninsneveruninstall
Source: "fonts\HarmonyOS_Sans_SC_Bold.ttf"; DestDir: "{autofonts}"; FontInstall: "HarmonyOS Sans SC Bold"; Flags: onlyifdoesntexist uninsneveruninstall
Source: "fonts\HarmonyOS_Sans_SC_Medium.ttf"; DestDir: "{autofonts}"; FontInstall: "HarmonyOS Sans SC Medium"; Flags: onlyifdoesntexist uninsneveruninstall

; 2. 小狼毫引擎核心程序
Source: "weasel-0.17.4\*"; DestDir: "{app}\weasel-0.17.4"; Flags: ignoreversion recursesubdirs createallsubdirs

; 3. 定制用户配置、字典及预编译二进制缓存（零等待秒开）
Source: "user\*"; DestDir: "{app}\user"; Flags: ignoreversion recursesubdirs createallsubdirs

[Registry]
; HKLM 注册表路径配置
Root: HKLM; Subkey: "Software\Rime\Weasel"; ValueType: string; ValueName: "WeaselServerRoot"; ValueData: "{app}\weasel-0.17.4"; Flags: uninsdeletevalue
Root: HKLM; Subkey: "Software\Rime\Weasel"; ValueType: string; ValueName: "RimeUserDir"; ValueData: "{app}\user"; Flags: uninsdeletevalue

; HKCU 注册表路径配置
Root: HKCU; Subkey: "Software\Rime\Weasel"; ValueType: string; ValueName: "WeaselServerRoot"; ValueData: "{app}\weasel-0.17.4"; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Rime\Weasel"; ValueType: string; ValueName: "RimeUserDir"; ValueData: "{app}\user"; Flags: uninsdeletevalue

[Icons]
Name: "{group}\小狼毫输入法设定"; Filename: "{app}\weasel-0.17.4\WeaselDeployer.exe"; WorkingDir: "{app}\weasel-0.17.4"
Name: "{group}\重新部署"; Filename: "{app}\weasel-0.17.4\WeaselDeployer.exe"; Parameters: "/deploy"; WorkingDir: "{app}\weasel-0.17.4"
Name: "{group}\用户文件夹"; Filename: "{app}\user"
Name: "{group}\卸载小狼毫输入法"; Filename: "{uninstallexe}"

[Code]
// 安装前静默结束可能正在运行的 Weasel 进程，避免文件占用
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ResultCode: Integer;
begin
  Exec('taskkill.exe', '/F /IM WeaselServer.exe /IM WeaselDeployer.exe /T', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := '';
end;

[Run]
; 向 Windows 注册小狼毫 TSF 输入法服务（32位+64位）
Filename: "{app}\weasel-0.17.4\WeaselSetup.exe"; Parameters: "/i"; StatusMsg: "正在向 Windows 注册输入法服务..."; Flags: runhidden

; 启动小狼毫常驻服务，实现装完立即可打字
Filename: "{app}\weasel-0.17.4\WeaselServer.exe"; Parameters: "/run"; Description: "立即启动小狼毫输入法服务"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; 卸载前结束服务并注销输入法
Filename: "taskkill.exe"; Parameters: "/F /IM WeaselServer.exe /IM WeaselDeployer.exe /T"; Flags: runhidden; RunOnceId: "KillWeasel"
Filename: "{app}\weasel-0.17.4\WeaselSetup.exe"; Parameters: "/u"; StatusMsg: "正在从 Windows 注销输入法服务..."; Flags: runhidden
