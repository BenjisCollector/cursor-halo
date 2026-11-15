# Cursor Halo - Windows 10 (PowerShell 5.1, no install needed)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Windows.Forms,System.Drawing -TypeDefinition @"
using System; using System.Drawing; using System.Windows.Forms;
public class HaloForm : Form {
  public Color HaloColor = Color.Yellow; public bool Ring = false; public int Thickness = 6;
  public static readonly Color Key = Color.FromArgb(255,0,254);
  public HaloForm() {
    FormBorderStyle = FormBorderStyle.None; ShowInTaskbar = false; TopMost = true;
    StartPosition = FormStartPosition.Manual; BackColor = Key; TransparencyKey = Key;
  }
  protected override bool ShowWithoutActivation { get { return true; } }
  protected override CreateParams CreateParams { get {
    CreateParams cp = base.CreateParams;
    cp.ExStyle |= 0x80000 | 0x20 | 0x80 | 0x08000000; // layered, click-through, toolwindow, noactivate
    return cp; } }
  protected override void OnPaintBackground(PaintEventArgs e) { e.Graphics.Clear(Key); }
  protected override void OnPaint(PaintEventArgs e) {
    e.Graphics.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.None;
    if (Ring) {
      using (Pen p = new Pen(HaloColor, Thickness)) {
        int h = Thickness / 2;
        e.Graphics.DrawEllipse(p, h, h, Width - Thickness - 1, Height - Thickness - 1);
      }
    } else {
      using (Brush b = new SolidBrush(HaloColor)) e.Graphics.FillEllipse(b, 0, 0, Width - 1, Height - 1);
    }
  }
}
"@

$cfgDir  = Join-Path $env:APPDATA 'CursorHalo'
$cfgFile = Join-Path $cfgDir 'settings.json'
$cfg = @{ Size = 80; Opacity = 40; Thickness = 6; Ring = $false; Enabled = $true; Color = '#FFD400' }
if (Test-Path $cfgFile) {
  try { $j = Get-Content $cfgFile -Raw | ConvertFrom-Json
        foreach ($k in @($cfg.Keys)) { if ($null -ne $j.$k) { $cfg[$k] = $j.$k } } } catch {}
}
function Save-Cfg { New-Item -ItemType Directory -Force $cfgDir | Out-Null
  $cfg | ConvertTo-Json | Set-Content $cfgFile }

$halo = New-Object HaloForm
function Apply-Halo {
  $c = [System.Drawing.ColorTranslator]::FromHtml($cfg.Color)
  if ($c.R -eq 255 -and $c.G -eq 0 -and $c.B -eq 254) { $c = [System.Drawing.Color]::FromArgb(255,0,253) }
  $halo.HaloColor = $c; $halo.Ring = [bool]$cfg.Ring; $halo.Thickness = [int]$cfg.Thickness
  $s = [int]$cfg.Size; $halo.Size = New-Object System.Drawing.Size($s,$s)
  $halo.Opacity = [double]$cfg.Opacity / 100.0
  $halo.Invalidate()
  if ($cfg.Enabled) { if (-not $halo.Visible) { $halo.Show() } } else { $halo.Hide() }
}

# ---- Settings UI ----
$ui = New-Object System.Windows.Forms.Form
$ui.Text = 'Cursor Halo'; $ui.Size = New-Object System.Drawing.Size(360,380)
$ui.FormBorderStyle = 'FixedDialog'; $ui.MaximizeBox = $false; $ui.StartPosition = 'CenterScreen'
$ui.BackColor = [System.Drawing.Color]::FromArgb(30,30,34); $ui.ForeColor = [System.Drawing.Color]::White
$ui.Font = New-Object System.Drawing.Font('Segoe UI',9.5)

function Add-Label($t,$y){ $l = New-Object System.Windows.Forms.Label; $l.Text=$t; $l.Location="20,$y"; $l.AutoSize=$true; $ui.Controls.Add($l); $l }
function Add-Slider($y,$min,$max,$val){ $t = New-Object System.Windows.Forms.TrackBar
  $t.Location="14,$y"; $t.Size="320,45"; $t.Minimum=$min; $t.Maximum=$max; $t.Value=[Math]::Min($max,[Math]::Max($min,[int]$val))
  $t.TickFrequency=[int](($max-$min)/10); $ui.Controls.Add($t); $t }

$lblSize = Add-Label "Size: $($cfg.Size) px" 15
$tbSize  = Add-Slider 35 20 400 $cfg.Size
$lblOp   = Add-Label "Opacity: $($cfg.Opacity)%" 85
$tbOp    = Add-Slider 105 5 100 $cfg.Opacity
$lblTh   = Add-Label "Ring thickness: $($cfg.Thickness) px" 155
$tbTh    = Add-Slider 175 2 40 $cfg.Thickness

$cbRing = New-Object System.Windows.Forms.CheckBox; $cbRing.Text='Ring (hollow)'; $cbRing.Location='20,230'; $cbRing.AutoSize=$true
$cbRing.Checked=[bool]$cfg.Ring; $ui.Controls.Add($cbRing)
$cbOn = New-Object System.Windows.Forms.CheckBox; $cbOn.Text='Halo enabled'; $cbOn.Location='180,230'; $cbOn.AutoSize=$true
$cbOn.Checked=[bool]$cfg.Enabled; $ui.Controls.Add($cbOn)

$btnColor = New-Object System.Windows.Forms.Button; $btnColor.Text='Pick colour...'; $btnColor.Location='20,270'; $btnColor.Size='130,32'
$btnColor.FlatStyle='Flat'; $ui.Controls.Add($btnColor)
$sw = New-Object System.Windows.Forms.Panel; $sw.Location='160,270'; $sw.Size='32,32'; $sw.BorderStyle='FixedSingle'
$sw.BackColor=[System.Drawing.ColorTranslator]::FromHtml($cfg.Color); $ui.Controls.Add($sw)

$x = 205
foreach ($hex in '#FFD400','#FF3B30','#34C759','#0A84FF','#FFFFFF') {
  $p = New-Object System.Windows.Forms.Panel; $p.Size='22,22'; $p.Location="$x,275"; $x += 26
  $p.BackColor=[System.Drawing.ColorTranslator]::FromHtml($hex); $p.Tag=$hex; $p.Cursor='Hand'
  $p.Add_Click({ $cfg.Color=$this.Tag; $sw.BackColor=$this.BackColor; Apply-Halo; Save-Cfg })
  $ui.Controls.Add($p)
}

$tbSize.Add_ValueChanged({ $cfg.Size=$tbSize.Value; $lblSize.Text="Size: $($tbSize.Value) px"; Apply-Halo; Save-Cfg })
$tbOp.Add_ValueChanged({ $cfg.Opacity=$tbOp.Value; $lblOp.Text="Opacity: $($tbOp.Value)%"; Apply-Halo; Save-Cfg })
$tbTh.Add_ValueChanged({ $cfg.Thickness=$tbTh.Value; $lblTh.Text="Ring thickness: $($tbTh.Value) px"; Apply-Halo; Save-Cfg })
$cbRing.Add_CheckedChanged({ $cfg.Ring=$cbRing.Checked; Apply-Halo; Save-Cfg })
$cbOn.Add_CheckedChanged({ $cfg.Enabled=$cbOn.Checked; Apply-Halo; Save-Cfg })
$btnColor.Add_Click({
  $d = New-Object System.Windows.Forms.ColorDialog; $d.FullOpen=$true; $d.Color=$sw.BackColor
  if ($d.ShowDialog() -eq 'OK') { $c=$d.Color
    $cfg.Color = '#{0:X2}{1:X2}{2:X2}' -f $c.R,$c.G,$c.B; $sw.BackColor=$c; Apply-Halo; Save-Cfg } })

# ---- Follow cursor ----
$timer = New-Object System.Windows.Forms.Timer; $timer.Interval = 8
$timer.Add_Tick({
  if (-not $cfg.Enabled) { return }
  $p = [System.Windows.Forms.Cursor]::Position; $r = [int]($halo.Width / 2)
  $halo.Location = New-Object System.Drawing.Point(($p.X - $r), ($p.Y - $r))
})
$ui.Add_FormClosing({ $timer.Stop(); $halo.Close() })

Apply-Halo; $timer.Start()
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::Run($ui)
