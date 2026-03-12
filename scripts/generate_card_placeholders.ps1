Add-Type -AssemblyName System.Drawing

$assetsDir = Join-Path $PSScriptRoot "..\assets\cards\placeholders"
$assetsDir = [System.IO.Path]::GetFullPath($assetsDir)
if (!(Test-Path $assetsDir)) { New-Item -ItemType Directory -Path $assetsDir | Out-Null }

$cardWidth = 480
$cardHeight = 680

function New-Canvas([int]$width, [int]$height) {
    $bmp = New-Object System.Drawing.Bitmap($width, $height)
    $gfx = [System.Drawing.Graphics]::FromImage($bmp)
    $gfx.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    return [PSCustomObject]@{ Bitmap = $bmp; Gfx = $gfx }
}

function Save-Canvas($canvas, [string]$name) {
    $path = Join-Path $assetsDir $name
    $canvas.Bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $canvas.Gfx.Dispose()
    $canvas.Bitmap.Dispose()
}

function Fill-VerticalGradient($gfx, [int]$width, [int]$height, $topColor, $bottomColor) {
    $rect = New-Object System.Drawing.Rectangle(0, 0, $width, $height)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $topColor, $bottomColor, 90)
    $gfx.FillRectangle($brush, 0, 0, $width, $height)
    $brush.Dispose()
}

# bg_canvas
$canvas = New-Canvas -width $cardWidth -height $cardHeight
Fill-VerticalGradient -gfx $canvas.Gfx -width $cardWidth -height $cardHeight `
    -topColor ([System.Drawing.Color]::FromArgb(255, 26, 35, 60)) `
    -bottomColor ([System.Drawing.Color]::FromArgb(255, 10, 14, 24))
for ($i = 0; $i -lt 45; $i++) {
    $x = Get-Random -Minimum 0 -Maximum $cardWidth
    $y = Get-Random -Minimum 0 -Maximum $cardHeight
    $r = Get-Random -Minimum 2 -Maximum 8
    $a = Get-Random -Minimum 12 -Maximum 28
    $dot = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($a, 185, 210, 255))
    $canvas.Gfx.FillEllipse($dot, $x, $y, $r, $r)
    $dot.Dispose()
}
Save-Canvas -canvas $canvas -name "bg_canvas.png"

# overlay_gloss
$canvas = New-Canvas -width $cardWidth -height $cardHeight
$canvas.Gfx.Clear([System.Drawing.Color]::Transparent)
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$path.AddEllipse(-180, -220, 820, 420)
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(48, 255, 255, 255))
$canvas.Gfx.FillPath($brush, $path)
$brush.Dispose(); $path.Dispose()
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$path.AddEllipse(-120, 300, 760, 300)
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 120, 180, 255))
$canvas.Gfx.FillPath($brush, $path)
$brush.Dispose(); $path.Dispose()
Save-Canvas -canvas $canvas -name "overlay_gloss.png"

function Create-Frame([string]$name, [int]$r, [int]$g, [int]$b) {
    $canvas = New-Canvas -width $cardWidth -height $cardHeight
    $canvas.Gfx.Clear([System.Drawing.Color]::Transparent)

    $penOuter = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, $r, $g, $b), 12)
    $canvas.Gfx.DrawRectangle($penOuter, 8, 8, $cardWidth - 16, $cardHeight - 16)
    $penOuter.Dispose()

    $penInner = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(210, [Math]::Max(0,$r-36), [Math]::Max(0,$g-36), [Math]::Max(0,$b-36)), 4)
    $canvas.Gfx.DrawRectangle($penInner, 26, 26, $cardWidth - 52, $cardHeight - 52)
    $penInner.Dispose()

    $topBand = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(92, $r, $g, $b))
    $canvas.Gfx.FillRectangle($topBand, 26, 26, $cardWidth - 52, 76)
    $topBand.Dispose()

    Save-Canvas -canvas $canvas -name $name
}

Create-Frame -name "frame_common.png" -r 168 -g 176 -b 192
Create-Frame -name "frame_uncommon.png" -r 88 -g 182 -b 120
Create-Frame -name "frame_rare.png" -r 82 -g 128 -b 232
Create-Frame -name "frame_legendary.png" -r 232 -g 172 -b 60

function Create-Portrait([string]$name, [int]$r, [int]$g, [int]$b, [string]$style) {
    $canvas = New-Canvas -width $cardWidth -height $cardHeight
    $canvas.Gfx.Clear([System.Drawing.Color]::Transparent)

    $body = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, $r, $g, $b))
    $fx = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(44, 255, 255, 255))

    if ($style -eq "warrior") {
        $canvas.Gfx.FillEllipse($body, 120, 120, 240, 240)
        $canvas.Gfx.FillRectangle($body, 145, 300, 190, 220)
        $canvas.Gfx.FillPolygon($body, @(
            (New-Object System.Drawing.Point(240, 100)),
            (New-Object System.Drawing.Point(275, 180)),
            (New-Object System.Drawing.Point(205, 180))
        ))
    } elseif ($style -eq "strategist") {
        $canvas.Gfx.FillEllipse($body, 145, 130, 190, 190)
        $canvas.Gfx.FillRectangle($body, 135, 280, 210, 245)
        $canvas.Gfx.FillRectangle($fx, 110, 365, 260, 18)
        $canvas.Gfx.FillRectangle($fx, 110, 410, 260, 14)
    } else {
        $canvas.Gfx.FillEllipse($body, 130, 115, 220, 220)
        $canvas.Gfx.FillRectangle($body, 120, 280, 240, 260)
        $canvas.Gfx.FillEllipse($fx, 65, 325, 350, 210)
    }

    $body.Dispose(); $fx.Dispose()
    Save-Canvas -canvas $canvas -name $name
}

Create-Portrait -name "portrait_warrior.png" -r 196 -g 70 -b 70 -style "warrior"
Create-Portrait -name "portrait_strategist.png" -r 90 -g 170 -b 220 -style "strategist"
Create-Portrait -name "portrait_guardian.png" -r 145 -g 120 -b 205 -style "guardian"

function Create-Badge([string]$name, [int]$r, [int]$g, [int]$b, [string]$label) {
    $size = 120
    $canvas = New-Canvas -width $size -height $size
    $canvas.Gfx.Clear([System.Drawing.Color]::Transparent)

    $fill = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(235, $r, $g, $b))
    $canvas.Gfx.FillEllipse($fill, 6, 6, 108, 108)
    $fill.Dispose()

    $ring = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 4)
    $canvas.Gfx.DrawEllipse($ring, 8, 8, 104, 104)
    $ring.Dispose()

    $font = New-Object System.Drawing.Font("Arial", 34, [System.Drawing.FontStyle]::Bold)
    $fmt = New-Object System.Drawing.StringFormat
    $fmt.Alignment = [System.Drawing.StringAlignment]::Center
    $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
    $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $canvas.Gfx.DrawString($label, $font, $textBrush, (New-Object System.Drawing.RectangleF(0, 0, $size, $size)), $fmt)
    $font.Dispose(); $fmt.Dispose(); $textBrush.Dispose()

    Save-Canvas -canvas $canvas -name $name
}

Create-Badge -name "badge_common.png" -r 148 -g 160 -b 178 -label "C"
Create-Badge -name "badge_uncommon.png" -r 78 -g 176 -b 112 -label "U"
Create-Badge -name "badge_rare.png" -r 68 -g 120 -b 236 -label "R"
Create-Badge -name "badge_legendary.png" -r 236 -g 170 -b 55 -label "L"

function Create-Icon([string]$name, [int]$r, [int]$g, [int]$b, [string]$kind) {
    $size = 96
    $canvas = New-Canvas -width $size -height $size
    $canvas.Gfx.Clear([System.Drawing.Color]::Transparent)

    $bg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(215, 18, 24, 36))
    $canvas.Gfx.FillEllipse($bg, 6, 6, 84, 84)
    $bg.Dispose()

    $shape = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, $r, $g, $b))
    if ($kind -eq "atk") {
        $canvas.Gfx.FillPolygon($shape, @(
            (New-Object System.Drawing.Point(48,14)),
            (New-Object System.Drawing.Point(72,60)),
            (New-Object System.Drawing.Point(56,60)),
            (New-Object System.Drawing.Point(62,84)),
            (New-Object System.Drawing.Point(38,52)),
            (New-Object System.Drawing.Point(52,52))
        ))
    } elseif ($kind -eq "def") {
        $canvas.Gfx.FillPolygon($shape, @(
            (New-Object System.Drawing.Point(48,16)),
            (New-Object System.Drawing.Point(76,28)),
            (New-Object System.Drawing.Point(70,62)),
            (New-Object System.Drawing.Point(48,84)),
            (New-Object System.Drawing.Point(26,62)),
            (New-Object System.Drawing.Point(20,28))
        ))
    } else {
        $canvas.Gfx.FillEllipse($shape, 22, 18, 52, 52)
        $core = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $canvas.Gfx.FillEllipse($core, 38, 34, 20, 20)
        $core.Dispose()
    }
    $shape.Dispose()

    Save-Canvas -canvas $canvas -name $name
}

Create-Icon -name "icon_attack.png" -r 238 -g 96 -b 88 -kind "atk"
Create-Icon -name "icon_defense.png" -r 90 -g 170 -b 235 -kind "def"
Create-Icon -name "icon_power.png" -r 238 -g 190 -b 90 -kind "pow"

# Opaque stat-panel background (replaceable asset for bottom 30% area)
$panelW = 480
$panelH = 220
$panel = New-Canvas -width $panelW -height $panelH
Fill-VerticalGradient -gfx $panel.Gfx -width $panelW -height $panelH `
    -topColor ([System.Drawing.Color]::FromArgb(255, 14, 20, 34)) `
    -bottomColor ([System.Drawing.Color]::FromArgb(255, 8, 12, 22))
for ($i = 0; $i -lt 26; $i++) {
    $x = Get-Random -Minimum 0 -Maximum $panelW
    $y = Get-Random -Minimum 0 -Maximum $panelH
    $rw = Get-Random -Minimum 20 -Maximum 88
    $rh = Get-Random -Minimum 2 -Maximum 6
    $lineBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb((Get-Random -Minimum 14 -Maximum 38), 120, 170, 255))
    $panel.Gfx.FillRectangle($lineBrush, $x, $y, $rw, $rh)
    $lineBrush.Dispose()
}
$panelLine = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(90, 100, 150, 235), 2)
$panel.Gfx.DrawLine($panelLine, 16, 26, $panelW - 16, 26)
$panel.Gfx.DrawLine($panelLine, 16, 110, $panelW - 16, 110)
$panelLine.Dispose()
Save-Canvas -canvas $panel -name "panel_stats_bg.png"

Write-Output "Generated placeholders in $assetsDir"
