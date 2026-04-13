Add-Type -AssemblyName System.Drawing
$W=1024;$H=500
$bmp=New-Object -TypeName System.Drawing.Bitmap -ArgumentList @($W,$H,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g=[System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

function New-RoundedPath([int]$x,[int]$y,[int]$w,[int]$h,[int]$r){
    $p=New-Object -TypeName System.Drawing.Drawing2D.GraphicsPath
    $p.AddArc($x,$y,($r*2),($r*2),180,90)
    $p.AddArc(($x+$w-$r*2),$y,($r*2),($r*2),270,90)
    $p.AddArc(($x+$w-$r*2),($y+$h-$r*2),($r*2),($r*2),0,90)
    $p.AddArc($x,($y+$h-$r*2),($r*2),($r*2),90,90)
    $p.CloseFigure();return $p
}
function Draw-Oval($gfx,[int]$cx,[int]$cy,[int]$r,[int]$a,[int]$cr,[int]$cg,[int]$cb){
    $col=[System.Drawing.Color]::FromArgb($a,$cr,$cg,$cb)
    $b=New-Object -TypeName System.Drawing.SolidBrush -ArgumentList @($col)
    $gfx.FillEllipse($b,($cx-$r),($cy-$r),($r*2),($r*2));$b.Dispose()
}

$pt1=[System.Drawing.PointF]::new([float]0,[float]0)
$pt2=[System.Drawing.PointF]::new([float]$W,[float]$H)
$c1=[System.Drawing.Color]::FromArgb(255,82,16,102)
$c2=[System.Drawing.Color]::FromArgb(255,122,38,148)
$bgB=New-Object -TypeName System.Drawing.Drawing2D.LinearGradientBrush -ArgumentList @($pt1,$pt2,$c1,$c2)
$g.FillRectangle($bgB,0,0,$W,$H);$bgB.Dispose()

Draw-Oval $g  75  55  95 38 165 80 185
Draw-Oval $g 170 285 158 30 160 70 178
Draw-Oval $g 920 -20 125 48 185 185 192
Draw-Oval $g 875 430 145 42 105 105 112

$pb=New-Object -TypeName System.Drawing.SolidBrush -ArgumentList @([System.Drawing.Color]::FromArgb(255,158,52,188))
$g.FillEllipse($pb,42,157,256,256);$pb.Dispose()

$lb=New-Object -TypeName System.Drawing.SolidBrush -ArgumentList @([System.Drawing.Color]::FromArgb(255,48,118,38))
$lpts=@([System.Drawing.PointF]::new([float]155,[float]157),[System.Drawing.PointF]::new([float]170,[float]115),[System.Drawing.PointF]::new([float]187,[float]157))
$g.FillPolygon($lb,$lpts);$lb.Dispose()

$ckPen=New-Object -TypeName System.Drawing.Pen -ArgumentList @([System.Drawing.Color]::White,[float]20)
$ckPen.StartCap=[System.Drawing.Drawing2D.LineCap]::Round
$ckPen.EndCap=[System.Drawing.Drawing2D.LineCap]::Round
$ckPen.LineJoin=[System.Drawing.Drawing2D.LineJoin]::Round
$ckPts=@([System.Drawing.PointF]::new([float]102,[float]292),[System.Drawing.PointF]::new([float]148,[float]342),[System.Drawing.PointF]::new([float]248,[float]228))
$g.DrawLines($ckPen,$ckPts);$ckPen.Dispose()

$white=New-Object -TypeName System.Drawing.SolidBrush -ArgumentList @([System.Drawing.Color]::White)
$dim=New-Object -TypeName System.Drawing.SolidBrush -ArgumentList @([System.Drawing.Color]::FromArgb(200,255,255,255))
$tx=[float]375

$fT=New-Object -TypeName System.Drawing.Font -ArgumentList @("Arial",[float]62,[System.Drawing.FontStyle]::Bold)
$g.DrawString("GoShopping",$fT,$white,$tx,[float]68);$fT.Dispose()

$jpSubtitle=[string]::new([char[]]@(0x5BB6,0x65CF,0x306E,0x8CB7,0x3044,0x7269,0x30EA,0x30B9,0x30C8,0x3092,0x3001,0x3082,0x3063,0x3068,0x304B,0x3093,0x305F,0x3093,0x306B,0x3002))
$jpSz=24.0
do {
    $fJP=New-Object -TypeName System.Drawing.Font -ArgumentList @("Meiryo",[float]$jpSz,[System.Drawing.FontStyle]::Regular)
    $measJP=$g.MeasureString($jpSubtitle,$fJP)
    if(($tx+$measJP.Width) -le ($W-20)){break}
    $fJP.Dispose();$jpSz-=0.5
} while($jpSz -gt 14)
$g.DrawString($jpSubtitle,$fJP,$white,$tx,[float]162);$fJP.Dispose()

$fEN=New-Object -TypeName System.Drawing.Font -ArgumentList @("Arial",[float]17,[System.Drawing.FontStyle]::Regular)
$g.DrawString("Share your shopping list with family",$fEN,$dim,$tx,[float]210);$fEN.Dispose()

$chk=[string]::new([char[]]@(0x2713))
$b1=$chk+" "+[string]::new([char[]]@(0x30EA,0x30A2,0x30EB,0x30BF,0x30A4,0x30E0,0x540C,0x671F))
$b2=$chk+" QR"+[string]::new([char[]]@(0x62DB,0x5F85))
$b3=$chk+" "+[string]::new([char[]]@(0x30DB,0x30EF,0x30A4,0x30C8,0x30DC,0x30FC,0x30C9))
$badges=@($b1,$b2,$b3)

$badgeFontSz=17.0;$padX=14;$padY=8;$gap=10
do {
    $fB=New-Object -TypeName System.Drawing.Font -ArgumentList @("Meiryo",[float]$badgeFontSz,[System.Drawing.FontStyle]::Regular)
    $totalW=[float]0
    foreach($badge in $badges){$sz=$g.MeasureString($badge,$fB);$totalW+=$sz.Width+$padX*2+2}
    $totalW+=($badges.Count-1)*$gap
    if(($tx+$totalW) -le ($W-20)){break}
    $fB.Dispose();$badgeFontSz-=0.5
} while($badgeFontSz -gt 10)

$bFill=[System.Drawing.Color]::FromArgb(55,255,255,255)
$bBord=[System.Drawing.Color]::FromArgb(155,255,255,255)
$bx=$tx;$by=[float]292
foreach($badge in $badges){
    $sz=$g.MeasureString($badge,$fB)
    $bw=[int]($sz.Width+$padX*2+2);$bh=[int]($sz.Height+$padY*2+2);$rad=[int]($bh/2)
    $path=New-RoundedPath ([int]$bx) ([int]$by) $bw $bh $rad
    $fB2=New-Object -TypeName System.Drawing.SolidBrush -ArgumentList @($bFill)
    $g.FillPath($fB2,$path);$fB2.Dispose()
    $outP=New-Object -TypeName System.Drawing.Pen -ArgumentList @($bBord,[float]1.5)
    $g.DrawPath($outP,$path);$outP.Dispose();$path.Dispose()
    $g.DrawString($badge,$fB,$white,[float]($bx+$padX),[float]($by+$padY))
    $bx+=$bw+$gap
}
$fB.Dispose();$white.Dispose();$dim.Dispose();$g.Dispose()
$out="C:\FlutterProject\go_shop\play_store_feature_graphic.png"
$bmp.Save($out,[System.Drawing.Imaging.ImageFormat]::Png);$bmp.Dispose()
Write-Host "Done"