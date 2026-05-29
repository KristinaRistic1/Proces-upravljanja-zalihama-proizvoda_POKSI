unit fraDashboard;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.Layouts, FMX.ListBox,
  FireDAC.Comp.Client, uUserStore, uNavFrames;

type
  TfraDashboard = class(TFrame)
    Layout1: TLayout;
    Layout2: TLayout;
    rectHeader: TRectangle;
    lblTitle: TLabel;
    lblDatum: TLabel;
    Layout3: TVertScrollBox;
    layKartice: TLayout;
    rectCrveno: TRectangle;
    lblCrvenoBroj: TLabel;
    lblCrvenoTekst: TLabel;
    rectZuto: TRectangle;
    lblZutoBroj: TLabel;
    lblZutoTekst: TLabel;
    rectZeleno: TRectangle;
    lblZelenoBroj: TLabel;
    lblZelenoTekst: TLabel;
    lblAlarmiTitle: TLabel;
    lstAlarmi: TListBox;
    Layout4: TLayout;
    rectNav: TRectangle;
    procedure Loaded; override;
    procedure lblBackClick(Sender: TObject);
  private
    procedure UcitajDashboard;
    procedure UcitajAlarme;
    procedure DodajAlarmKarticu(const Naziv, Poruka: string;
                                Boja: TAlphaColor);
  public
  end;

implementation
{$R *.fmx}

procedure TfraDashboard.Loaded;
begin
  inherited;
  lblDatum.Text := 'Danas: ' + FormatDateTime('dd.mm.yyyy', Now);
  UcitajDashboard;
  UcitajAlarme;
end;

procedure TfraDashboard.lblBackClick(Sender: TObject);
begin
  TNavFrames.Back;
end;

procedure TfraDashboard.UcitajDashboard;
var
  Q: TFDQuery;
  BrojCrvenih, BrojZutih, BrojZelenih: Integer;
  Kolicina, Minimum: Double;
  DanaDo: Integer;
  RokStr: string;
  ImaRok: Boolean;
begin
  BrojCrvenih := 0;
  BrojZutih   := 0;
  BrojZelenih := 0;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DB;
    Q.SQL.Text := 'SELECT TrenutnaKolicina, MinimaKolicina, RokTrajanja FROM RESURS';
    Q.Open;

    while not Q.Eof do
    begin
      Kolicina := Q.FieldByName('TrenutnaKolicina').AsFloat;
      Minimum  := Q.FieldByName('MinimaKolicina').AsFloat;
      RokStr   := Q.FieldByName('RokTrajanja').AsString;
      ImaRok   := RokStr <> '';

      // Provjeri rok
      if ImaRok then
      begin
        try
          DanaDo := Trunc(Q.FieldByName('RokTrajanja').AsDateTime - Now);
          if DanaDo < 0 then
          begin
            Inc(BrojCrvenih);
            Q.Next;
            Continue;
          end
          else if DanaDo <= 30 then
          begin
            Inc(BrojZutih);
            Q.Next;
            Continue;
          end;
        except
        end;
      end;

      // Provjeri zalihe
      if (Minimum > 0) and (Kolicina < Minimum) then
        Inc(BrojCrvenih)
      else if (Minimum > 0) and (Kolicina < Minimum * 1.5) then
        Inc(BrojZutih)
      else
        Inc(BrojZelenih);

      Q.Next;
    end;

  finally
    Q.Free;
  end;

  lblCrvenoBroj.Text := IntToStr(BrojCrvenih);
  lblZutoBroj.Text   := IntToStr(BrojZutih);
  lblZelenoBroj.Text := IntToStr(BrojZelenih);
end;

procedure TfraDashboard.DodajAlarmKarticu(const Naziv, Poruka: string;
                                           Boja: TAlphaColor);
var
  Item: TListBoxItem;
  rectKartica, rectTraka: TRectangle;
  layKart: TLayout;
  lblNazivLbl, lblPoruka: TLabel;
begin
  Item := TListBoxItem.Create(lstAlarmi);
  Item.Height := 72;
  Item.StyleLookup := '';

  rectKartica := TRectangle.Create(Item);
  rectKartica.Parent := Item;
  rectKartica.Align := TAlignLayout.Client;
  rectKartica.Margins.Left   := 4;
  rectKartica.Margins.Right  := 4;
  rectKartica.Margins.Top    := 4;
  rectKartica.Margins.Bottom := 4;
  rectKartica.Fill.Color := TAlphaColors.White;
  rectKartica.Stroke.Color := $FFE5E7EB;
  rectKartica.Stroke.Thickness := 1;
  rectKartica.XRadius := 10;
  rectKartica.YRadius := 10;

  rectTraka := TRectangle.Create(rectKartica);
  rectTraka.Parent := rectKartica;
  rectTraka.Align := TAlignLayout.Left;
  rectTraka.Width := 6;
  rectTraka.Fill.Color := Boja;
  rectTraka.Stroke.Kind := TBrushKind.None;
  rectTraka.XRadius := 10;
  rectTraka.YRadius := 10;

  layKart := TLayout.Create(rectKartica);
  layKart.Parent := rectKartica;
  layKart.Align := TAlignLayout.Client;
  layKart.Padding.Left   := 12;
  layKart.Padding.Right  := 12;
  layKart.Padding.Top    := 8;
  layKart.Padding.Bottom := 8;

  // Poruka ide prva (bice dole)
  lblPoruka := TLabel.Create(layKart);
  lblPoruka.Parent := layKart;
  lblPoruka.Align := TAlignLayout.Top;
  lblPoruka.Height := 18;
  lblPoruka.Margins.Top := 2;
  lblPoruka.Text := Poruka;
  lblPoruka.StyledSettings := [];
  lblPoruka.TextSettings.Font.Size := 11;
  lblPoruka.TextSettings.FontColor := Boja;

  // Naziv ide zadnji (bice gore)
  lblNazivLbl := TLabel.Create(layKart);
  lblNazivLbl.Parent := layKart;
  lblNazivLbl.Align := TAlignLayout.Top;
  lblNazivLbl.Height := 22;
  lblNazivLbl.Text := UpperCase(Naziv);
  lblNazivLbl.StyledSettings := [];
  lblNazivLbl.TextSettings.Font.Size := 13;
  lblNazivLbl.TextSettings.Font.Style := [TFontStyle.fsBold];
  lblNazivLbl.TextSettings.FontColor := $FF111827;

  lstAlarmi.AddObject(Item);
end;

procedure TfraDashboard.UcitajAlarme;
var
  Q: TFDQuery;
  Naziv: string;
  Kolicina, Minimum: Double;
  DanaDo: Integer;
  RokStr: string;
  ImaRok: Boolean;
  ImaAlarma: Boolean;
begin
  lstAlarmi.BeginUpdate;
  try
    lstAlarmi.Clear;
    ImaAlarma := False;

    Q := TFDQuery.Create(nil);
    try
      Q.Connection := DB;
      Q.SQL.Text :=
        'SELECT Naziv, TrenutnaKolicina, MinimaKolicina, JedinicaMere, RokTrajanja ' +
        'FROM RESURS ORDER BY Naziv';
      Q.Open;

      while not Q.Eof do
      begin
        Naziv    := Q.FieldByName('Naziv').AsString;
        Kolicina := Q.FieldByName('TrenutnaKolicina').AsFloat;
        Minimum  := Q.FieldByName('MinimaKolicina').AsFloat;
        RokStr   := Q.FieldByName('RokTrajanja').AsString;
        ImaRok   := RokStr <> '';

        // Alarm za istekao rok
        if ImaRok then
        begin
          try
            DanaDo := Trunc(Q.FieldByName('RokTrajanja').AsDateTime - Now);
            if DanaDo < 0 then
            begin
              DodajAlarmKarticu(Naziv,
                'ISTEKAO ROK TRAJANJA - hitno ukloniti iz magacina!',
                $FFEF4444);
              ImaAlarma := True;
            end
            else if DanaDo <= 7 then
            begin
              DodajAlarmKarticu(Naziv,
                'Rok istice za ' + IntToStr(DanaDo) + ' dana - hitna akcija!',
                $FFEF4444);
              ImaAlarma := True;
            end
            else if DanaDo <= 30 then
            begin
              DodajAlarmKarticu(Naziv,
                'Rok istice za ' + IntToStr(DanaDo) + ' dana',
                $FFF59E0B);
              ImaAlarma := True;
            end;
          except
          end;
        end;

        // Alarm za zalihe
        if (Minimum > 0) and (Kolicina < Minimum) then
        begin
          DodajAlarmKarticu(Naziv,
            'Zalihe ISPOD minimuma: ' +
            FormatFloat('0.#', Kolicina) + ' ' +
            Q.FieldByName('JedinicaMere').AsString +
            ' (min: ' + FormatFloat('0.#', Minimum) + ')',
            $FFEF4444);
          ImaAlarma := True;
        end
        else if (Minimum > 0) and (Kolicina < Minimum * 1.5) then
        begin
          DodajAlarmKarticu(Naziv,
            'Zalihe blizu minimuma: ' +
            FormatFloat('0.#', Kolicina) + ' ' +
            Q.FieldByName('JedinicaMere').AsString +
            ' (min: ' + FormatFloat('0.#', Minimum) + ')',
            $FFF59E0B);
          ImaAlarma := True;
        end;

        Q.Next;
      end;

      if not ImaAlarma then
      begin
        var Item := TListBoxItem.Create(lstAlarmi);
        Item.Height := 60;
        Item.Text := 'Nema aktivnih alarma - sve je u redu!';
        lstAlarmi.AddObject(Item);
      end;

    finally
      Q.Free;
    end;
  finally
    lstAlarmi.EndUpdate;
  end;
end;

end.
