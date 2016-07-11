unit APK_TrayIcon;

{$INCLUDE APK_Defs.inc}

interface

uses
  Windows, Messages, Graphics, Menus,
  UtilityWindow;

type
  TNotifyIconData = record
    cbSize:             DWORD;
    hWnd:               HWND;
    uID:                UINT;
    uFlags:             UINT;
    uCallbackMessage:   UINT;
    hIcon:              HICON;
    szTip:              Array[0..127] of Char;
    dwState:            DWORD;
    dwStateMask:        DWORD;
    szInfo:             Array[0..255] of Char;
    case Integer of
      0: (uTimeout:     DWORD);
      1: (uVersion:     DWORD;
          szInfoTitle:  Array[0..63] of Char;
          dwInfoFlags:  DWORD;
         {guidItem:     TGUID;}
         {hBalloonIcon: HICON});
  end;
  PNotifyIconData = ^TNotifyIconData;

const
  TI_MI_ACTION_Restore = 1;
  TI_MI_ACTION_Start   = 2;
  TI_MI_ACTION_Close   = 3;

{==============================================================================}
{------------------------------------------------------------------------------}
{                                  TTrayIcon                                   }
{------------------------------------------------------------------------------}
{==============================================================================}

type
  TPopupMenuItemEvent = procedure(Sender: TObject; Action: Integer) of object;

  TAPKTrayIcon = class(TObject)
  private
    fUtilityWindow:     TUtilityWindow;
    fPopupMenu:         TPopupMenu;
    fMessageID:         UINT;
    fIcon:              TIcon;
    fIconData:          TNotifyIconData;
    fVisible:           Boolean;
    fOnPopupMenuItem:   TPopupMenuItemEvent;
  protected
    procedure LoadIconFromResources; virtual;
    procedure BuildPopupMenu; virtual;
    procedure MessageHandler(var Msg: TMessage; var Handled: Boolean); virtual;
    procedure DoPopupMenuItem(Sender: TObject); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetTipText(IconTipText: String); virtual;
    procedure UpdateTrayIcon; virtual;
    procedure ShowTrayIcon; virtual;
    procedure HideTrayIcon; virtual;
  published
    property Visible: Boolean read fVisible;
    property OnPopupMenuItem: TPopupMenuItemEvent read fOnPopupMenuItem write fOnPopupMenuItem;
  end;

implementation

uses
  Classes, Math, ShellAPI, Forms,
  APK_Strings;

{$R '..\Resources\tray_icon.res'}

{==============================================================================}
{------------------------------------------------------------------------------}
{                                  TTrayIcon                                   }
{------------------------------------------------------------------------------}
{==============================================================================}

{------------------------------------------------------------------------------}
{   TTrayIcon // Protected methods                                             }
{------------------------------------------------------------------------------}

procedure TAPKTrayIcon.LoadIconFromResources;
var
  ResStream:  TResourceStream;
begin
ResStream := TResourceStream.Create(hInstance,'tray_icon',RT_RCDATA);
try
  fIcon.LoadFromStream(ResStream);
finally
  ResStream.Free;
end;
end;

//------------------------------------------------------------------------------

procedure TAPKTrayIcon.BuildPopupMenu;

  Function CreateMenuItem(const Caption: String; Handler: TNotifyEvent; Tag: Integer): TMenuItem;
  begin
    Result := TMenuItem.Create(fPopupMenu);
    Result.Caption := Caption;
    Result.Tag := Tag;
    Result.OnClick := Handler;
  end;

begin
fPopupMenu := TPopupMenu.Create(nil);
fPopupMenu.Items.Add(CreateMenuItem(APKSTR_TI_MI_Restore,DoPopupMenuItem,TI_MI_ACTION_Restore));
fPopupMenu.Items.Add(CreateMenuItem(APKSTR_TI_MI_Splitter,nil,0));
fPopupMenu.Items.Add(CreateMenuItem(APKSTR_TI_MI_Start,DoPopupMenuItem,TI_MI_ACTION_Start));
fPopupMenu.Items.Add(CreateMenuItem(APKSTR_TI_MI_Splitter,nil,0));
fPopupMenu.Items.Add(CreateMenuItem(APKSTR_TI_MI_Close,DoPopupMenuItem,TI_MI_ACTION_Close));
end;

//------------------------------------------------------------------------------

procedure TAPKTrayIcon.MessageHandler(var Msg: TMessage; var Handled: Boolean);
var
  PopupPoint: TPoint;
begin
If Msg.Msg = fMessageID then
  case Msg.LParam of
    WM_RBUTTONDOWN:   begin
                        SetForegroundWindow(Application.MainForm.Handle);
                        GetCursorPos({%H-}PopupPoint);
                        fPopupMenu.Popup(PopupPoint.X,PopupPoint.Y);
                        Handled := True;
                      end;
    WM_LBUTTONDBLCLK: If Assigned(fOnPopupMenuItem) then
                        fOnPopupMenuItem(Self,TI_MI_ACTION_Restore);
  end;
end;

//------------------------------------------------------------------------------

procedure TAPKTrayIcon.DoPopupMenuItem(Sender: TObject);
begin
If Assigned(fOnPopupMenuItem) and (Sender is TMenuItem) then
  fOnPopupMenuItem(Self,TMenuItem(Sender).Tag);
end;

{------------------------------------------------------------------------------}
{   TTrayIcon // Public methods                                                }
{------------------------------------------------------------------------------}

constructor TAPKTrayIcon.Create;
begin
inherited Create;
fIcon := TIcon.Create;
LoadIconFromResources;
BuildPopupMenu;
fUtilityWindow := TUtilityWindow.Create;
fUtilityWindow.OnMessage.Add(MessageHandler);
{$IF Defined(FPC) and not Defined(Unicode)}
fMessageID := RegisterWindowMessage(PChar(UTF8ToWinCP(APKSTR_TI_MessageName)));
{$ELSE}
fMessageID := RegisterWindowMessage(PChar(APKSTR_TI_MessageName));
{$IFEND}
with fIconData do
  begin
    cbSize := SizeOf(fIconData);
    hWnd := fUtilityWindow.WindowHandle;
    uID := 0;
    uFlags := NIF_MESSAGE or NIF_ICON or NIF_TIP;
    uCallbackMessage := fMessageID;
    hicon := fIcon.Handle;
    fIconData.szTip := '';
  end;
fVisible := False;
end;

//------------------------------------------------------------------------------

destructor TAPKTrayIcon.Destroy;
begin
HideTrayIcon;
fUtilityWindow.Free;
fPopupMenu.Free;
fIcon.Free;
inherited;
end;

//------------------------------------------------------------------------------

procedure TAPKTrayIcon.SetTipText(IconTipText: String);
begin
FillChar(fIconData.szTip,SizeOf(fIconData.szTip),0);
{$IF Defined(FPC) and not Defined(Unicode)}
IconTipText := UTF8ToWinCP(IconTipText);
{$IFEND}
Move(PChar(IconTipText)^,Addr(fIconData.szTip)^,Min(Length(IconTipText),Length(fIconData.szTip) - 1) * SizeOf(Char));
UpdateTrayIcon;
end;

//------------------------------------------------------------------------------

procedure TAPKTrayIcon.UpdateTrayIcon;
begin
Shell_NotifyIcon(NIM_MODIFY,@fIconData);
end;

//------------------------------------------------------------------------------

procedure TAPKTrayIcon.ShowTrayIcon;
begin
Shell_NotifyIcon(NIM_ADD,@fIconData);
fVisible := True;
end;

//------------------------------------------------------------------------------

procedure TAPKTrayIcon.HideTrayIcon;
begin
Shell_NotifyIcon(NIM_DELETE,@fIconData);
fVisible := False;
end;

end.
