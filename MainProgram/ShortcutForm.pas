{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit ShortcutForm;

{$INCLUDE 'Source\APK_Defs.inc'}

interface

uses
  SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls,
  ExtCtrls,
  APK_Keyboard;

type
  TfShortcutForm = class(TForm)
    lblHintText: TLabel;
    pnlShortcutPanel: TPanel;
    btnRetry: TButton;
    btnAccept: TButton;    
    btnCancel: TButton;
    procedure btnRetryClick(Sender: TObject);
    procedure btnAcceptClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    fKeyboard: TAPKKeyboard;
  protected
    procedure OnShortcutSelect(Sender: TObject; Shortcut: TAPKShortcut);
    procedure InitSelection;
  public
    Accepted: Boolean;
    Shortcut: TAPKShortcut;
    Function ShowAsPrompt(Keyboard: TAPKKeyboard): Boolean;
  end;

var
  fShortcutForm: TfShortcutForm;

implementation

{$IFDEF FPC}
  {$R *.lfm}
{$ELSE}
  {$R *.dfm}
{$ENDIF}

uses
  APK_Strings;

procedure TfShortcutForm.OnShortcutSelect(Sender: TObject; Shortcut: TAPKShortcut);
begin
Self.Shortcut := Shortcut;
btnRetry.Enabled := True;
btnAccept.Enabled := True;
pnlShortcutPanel.Caption := Format('[%s]',[TAPKKeyboard.ShortcutAsText(Shortcut)]);
fKeyboard.Mode := kmNone;
end;

//------------------------------------------------------------------------------

procedure TfShortcutForm.InitSelection;
begin
pnlShortcutPanel.Caption := APKSTR_SW_ShortcutSelect;
btnRetry.Enabled := False;
btnAccept.Enabled := False;
fKeyboard.Mode := kmSelect;
fKeyboard.InputManager.Keyboard.Invalidate;
end;
 
//------------------------------------------------------------------------------

Function TfShortcutForm.ShowAsPrompt(Keyboard: TAPKKeyboard): Boolean;
begin
Accepted := False;
fKeyboard := Keyboard;
fKeyboard.OnShortcut := OnShortcutSelect;
InitSelection;
try
  ShowModal;
finally
  Keyboard.Mode := kmIntercept;
end;
Result := Accepted;
end;

//==============================================================================

procedure TfShortcutForm.btnRetryClick(Sender: TObject);
begin
InitSelection;
end;
 
//------------------------------------------------------------------------------

procedure TfShortcutForm.btnAcceptClick(Sender: TObject);
begin
Accepted := True;
Close;
end;

//------------------------------------------------------------------------------

procedure TfShortcutForm.btnCancelClick(Sender: TObject);
begin
Close;
end;

end.
