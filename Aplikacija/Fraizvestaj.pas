unit fraIzvestaj;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.Layouts, FMX.ListBox,
  FireDAC.Comp.Client, uUserStore, uNavFrames;

type
  TfraIzvestaj = class(TFrame)
    Layout1: TLayout;
    Layout2: TLayout;
    rectHeader: TRectangle;
    lblBack: TLabel;
    lblTitle: TLabel;
    layTabovi: TLayout;
    rectTabNabavka: TRectangle;
    lblTabNabavka: TLabel;
    rectTabZalihe: TRectangle;
    lblTabZalihe: TLabel;
    rectTabAktivnosti: TRectangle;
    lblTabAktivnosti: TLabel;
    lstIzvestaj: TListBox;
    Layout4: TLayout;
    rectNav: TRectangle;
    procedure lblBackClick(Sender: TObject);
    procedure rectTabNabavkaClick(Sender: TObject);
    procedure rectTabZaliheClick(Sender: TObject);
    procedure rectTabAktivnostiClick(Sender: TObject);
    procedure Loaded; override;
  private
    FaktivniTab: Integer;
    procedure PostaviTab(Tab: Integer);
    procedure UcitajNabavke;
    procedure UcitajZalihe;
    procedure UcitajAktivnosti;
    procedure DodajRed(const Tekst1, Tekst2, Tekst3: string; Boja: TAlphaColor);
  public
  end;

implementation
{$R *.fmx}

procedure TfraIzvestaj.Loaded;
begin
  inherited;
  FaktivniTab := 0;
  PostaviTab(0);
end;

procedure TfraIzvestaj.lblBackClick(Sender: TObject);
begin
  TNavFrames.Back;
end;

procedure TfraIzvestaj.PostaviTab(Tab: Integer);
begin
  FaktivniTab := Tab;

  // Reset boja tabova
  rectTabNabavka.Fill.Color   := $FFE5E7EB;
  rectTabZalihe.Fill.Color    := $FFE5E7EB;
  rectTabAktivnosti.Fill.Color := $FFE5E7EB;
  lblTabNabavka.TextSettings.FontColor   := $FF6B7280;
  lblTabZalihe.TextSettings.FontColor    := $FF6B7280;
  lblTabAktivnosti.TextSettings.FontColor := $FF6B7280;

  // Aktivni tab
  case Tab of
    0: begin
         rectTabNabavka.Fill.Color := TAlphaColorRec.Yellow;
         lblTabNabavka.TextSettings.FontColor := $FF111827;
         lblTabNabavka.TextSettings.Font.Style := [TFontStyle.fsBold];
         UcitajNabavke;
       end;
    1: begin
         rectTabZalihe.Fill.Color := TAlphaColorRec.Yellow;
         lblTabZalihe.TextSettings.FontColor := $FF111827;
         lblTabZalihe.TextSettings.Font.Style := [TFontStyle.fsBold];
         UcitajZalihe;
       end;
    2: begin
         rectTabAktivnosti.Fill.Color := TAlphaColorRec.Yellow;
         lblTabAktivnosti.TextSettings.FontColor := $FF111827;
         lblTabAktivnosti.TextSettings.Font.Style := [TFontStyle.fsBold];
         UcitajAktivnosti;
       end;
  end;
end;

procedure TfraIzvestaj.DodajRed(const Tekst1, Tekst2, Tekst3: string;
                                  Boja: TAlphaColor);
var
  Item: TListBoxItem;
  rectKartica, rectTraka: TRectangle;
  layRed: TLayout;
  lbl1, lbl2, lbl3: TLabel;
begin
  Item := TListBoxItem.Create(lstIzvestaj);
  Item.Height := 70;
  Item.StyleLookup := '';

  rectKartica := TRectangle.Create(Item);
  rectKartica.Parent := Item;
  rectKartica.Align := TAlignLayout.Client;
  rectKartica.Margins.Left   := 4;
  rectKartica.Margins.Right  := 4;
  rectKartica.Margins.Top    := 3;
  rectKartica.Margins.Bottom := 3;
  rectKartica.Fill.Color := TAlphaColors.White;
  rectKartica.Stroke.Color := $FFE5E7EB;
  rectKartica.Stroke.Thickness := 1;
  rectKartica.XRadius := 8;
  rectKartica.YRadius := 8;

  rectTraka := TRectangle.Create(rectKartica);
  rectTraka.Parent := rectKartica;
  rectTraka.Align := TAlignLayout.Left;
  rectTraka.Width := 5;
  rectTraka.Fill.Color := Boja;
  rectTraka.Stroke.Kind := TBrushKind.None;
  rectTraka.XRadius := 8;
  rectTraka.YRadius := 8;

  layRed := TLayout.Create(rectKartica);
  layRed.Parent := rectKartica;
  layRed.Align := TAlignLayout.Client;
  layRed.Padding.Left   := 10;
  layRed.Padding.Right  := 10;
  layRed.Padding.Top    := 6;
  layRed.Padding.Bottom := 6;

  // Tekst3 ide prvi (dole)
  lbl3 := TLabel.Create(layRed);
  lbl3.Parent := layRed;
  lbl3.Align := TAlignLayout.Top;
  lbl3.Height := 16;
  lbl3.Text := Tekst3;
  lbl3.StyledSettings := [];
  lbl3.TextSettings.Font.Size := 10;
  lbl3.TextSettings.FontColor := $FF9CA3AF;

  // Tekst2
  lbl2 := TLabel.Create(layRed);
  lbl2.Parent := layRed;
  lbl2.Align := TAlignLayout.Top;
  lbl2.Height := 16;
  lbl2.Margins.Top := 2;
  lbl2.Text := Tekst2;
  lbl2.StyledSettings := [];
  lbl2.TextSettings.Font.Size := 11;
  lbl2.TextSettings.FontColor := Boja;

  // Tekst1 ide zadnji (gore)
  lbl1 := TLabel.Create(layRed);
  lbl1.Parent := layRed;
  lbl1.Align := TAlignLayout.Top;
  lbl1.Height := 20;
  lbl1.Text := Tekst1;
  lbl1.StyledSettings := [];
  lbl1.TextSettings.Font.Size := 13;
  lbl1.TextSettings.Font.Style := [TFontStyle.fsBold];
  lbl1.TextSettings.FontColor := $FF111827;

  lstIzvestaj.AddObject(Item);
end;

procedure TfraIzvestaj.UcitajNabavke;
var
  Q: TFDQuery;
  Naziv, Dobavljac, Datum, Kolicina: string;
begin
  lstIzvestaj.BeginUpdate;
  try
    lstIzvestaj.Clear;
    Q := TFDQuery.Create(nil);
    try
      Q.Connection := DB;
      Q.SQL.Text :=
        'SELECT R.Naziv, D.Naziv as Dobavljac, N.Datum, SN.KolicinaNarucena, R.JedinicaMere ' +
        'FROM NARUDZBINA N ' +
        'JOIN STAVKA_NARUDZBINE SN ON SN.BrojNarudzbine = N.BrojNarudzbine ' +
        'JOIN RESURS R ON R.SifraResursa = SN.SifraResursa ' +
        'JOIN DOBAVLJAC D ON D.SifraDobavljaca = N.SifraDobavljaca ' +
        'ORDER BY N.Datum DESC';
      Q.Open;

      if Q.Eof then
      begin
        var Item := TListBoxItem.Create(lstIzvestaj);
        Item.Height := 50;
        Item.Text := 'Nema podataka o nabavkama.';
        lstIzvestaj.AddObject(Item);
      end
      else
      while not Q.Eof do
      begin
        Naziv     := Q.FieldByName('Naziv').AsString;
        Dobavljac := Q.FieldByName('Dobavljac').AsString;
        Datum     := Q.FieldByName('Datum').AsString;
        Kolicina  := FormatFloat('0.#', Q.FieldByName('KolicinaNarucena').AsFloat) +
                     ' ' + Q.FieldByName('JedinicaMere').AsString;

        DodajRed(
          UpperCase(Naziv),
          'Kolicina: ' + Kolicina,
          Datum + '  |  ' + Dobavljac,
          $FF1D4ED8
        );
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    lstIzvestaj.EndUpdate;
  end;
end;

procedure TfraIzvestaj.UcitajZalihe;
var
  Q: TFDQuery;
  Naziv, JedinicaMere: string;
  Kolicina, Minimum: Double;
  Boja: TAlphaColor;
  Status: string;
begin
  lstIzvestaj.BeginUpdate;
  try
    lstIzvestaj.Clear;
    Q := TFDQuery.Create(nil);
    try
      Q.Connection := DB;
      Q.SQL.Text :=
        'SELECT Naziv, TrenutnaKolicina, MinimaKolicina, JedinicaMere ' +
        'FROM RESURS ORDER BY Naziv';
      Q.Open;

      while not Q.Eof do
      begin
        Naziv        := Q.FieldByName('Naziv').AsString;
        Kolicina     := Q.FieldByName('TrenutnaKolicina').AsFloat;
        Minimum      := Q.FieldByName('MinimaKolicina').AsFloat;
        JedinicaMere := Q.FieldByName('JedinicaMere').AsString;

        if (Minimum > 0) and (Kolicina < Minimum) then
        begin
          Boja   := $FFEF4444;
          Status := 'ISPOD MINIMUMA - potrebna nabavka!';
        end
        else if (Minimum > 0) and (Kolicina < Minimum * 1.5) then
        begin
          Boja   := $FFF59E0B;
          Status := 'Blizu minimuma - planirati nabavku';
        end
        else
        begin
          Boja   := $FF22C55E;
          Status := 'Stanje zadovoljavajuce';
        end;

        DodajRed(
          UpperCase(Naziv),
          'Na stanju: ' + FormatFloat('0.#', Kolicina) + ' ' + JedinicaMere +
          '  |  Min: ' + FormatFloat('0.#', Minimum) + ' ' + JedinicaMere,
          Status,
          Boja
        );
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    lstIzvestaj.EndUpdate;
  end;
end;

procedure TfraIzvestaj.UcitajAktivnosti;
var
  Q: TFDQuery;
  Aktivnost, Ljubimac, Datum, Resurs: string;
  Kolicina: Double;
begin
  lstIzvestaj.BeginUpdate;
  try
    lstIzvestaj.Clear;
    Q := TFDQuery.Create(nil);
    try
      Q.Connection := DB;
      Q.SQL.Text :=
        'SELECT DA.Vrsta_aktivnosti, DA.Vreme_Aktivnosti, ' +
        '       L.Ime as Ljubimac, ' +
        '       R.Naziv as Resurs, R.JedinicaMere, ' +
        '       DA.KolicinaUtrosena ' +
        'FROM DNEVNA_AKTIVNOST DA ' +
        'JOIN LJUBIMAC L ON L.Sifra_ljubimca = DA.Sifra_ljubimca ' +
        'LEFT JOIN RESURS R ON R.SifraResursa = DA.SifraResursa ' +
        'ORDER BY DA.Vreme_Aktivnosti DESC ' +
        'LIMIT 50';
      Q.Open;

      if Q.Eof then
      begin
        var Item := TListBoxItem.Create(lstIzvestaj);
        Item.Height := 50;
        Item.Text := 'Nema evidencija aktivnosti.';
        lstIzvestaj.AddObject(Item);
      end
      else
      while not Q.Eof do
      begin
        Aktivnost := Q.FieldByName('Vrsta_aktivnosti').AsString;
        Ljubimac  := Q.FieldByName('Ljubimac').AsString;
        Datum     := Q.FieldByName('Vreme_Aktivnosti').AsString;
        Resurs    := Q.FieldByName('Resurs').AsString;
        Kolicina  := Q.FieldByName('KolicinaUtrosena').AsFloat;

        var Detalj := '';
        if Resurs <> '' then
          Detalj := 'Utroseno: ' + FormatFloat('0.#', Kolicina) +
                    ' ' + Q.FieldByName('JedinicaMere').AsString +
                    ' (' + Resurs + ')'
        else
          Detalj := 'Bez utroska resursa';

        DodajRed(
          Ljubimac + ' — ' + Aktivnost,
          Detalj,
          Datum,
          $FF8B5CF6
        );
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    lstIzvestaj.EndUpdate;
  end;
end;

procedure TfraIzvestaj.rectTabNabavkaClick(Sender: TObject);
begin
  PostaviTab(0);
end;

procedure TfraIzvestaj.rectTabZaliheClick(Sender: TObject);
begin
  PostaviTab(1);
end;

procedure TfraIzvestaj.rectTabAktivnostiClick(Sender: TObject);
begin
  PostaviTab(2);
end;

end.
