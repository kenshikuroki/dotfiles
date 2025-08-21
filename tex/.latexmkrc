$latex = 'uplatex %O -kanji=utf8 -no-guess-input-enc -synctex=1 -interaction=nonstopmode %S';
$pdflatex = 'pdflatex %O -synctex=1 -interaction=nonstopmode %S';
$lualatex = 'lualatex %O -synctex=1 -interaction=nonstopmode %S';
$xelatex = 'xelatex %O -no-pdf -synctex=1 -shell-escape -interaction=nonstopmode %S';
# Biber, BibTeX のビルドコマンド
$biber = 'biber %O --bblencoding=utf8 -u -U --output_safechars %B';
$bibtex = 'upbibtex %O %B';
# makeindex のビルドコマンド
$makeindex = 'upmendex %O -o %D %S';
# dvipdf のビルドコマンド
$dvipdf = 'dvipdfmx %O -o %D %S';
# dvipd のビルドコマンド
$dvips = 'dvips %O -z -f %S | convbkmk -u > %D';
$ps2pdf = 'ps2pdf.exe %O %S %D';

# PDF の作成方法を指定するオプション
## $pdf_mode = 0; PDF を作成しない。
## $pdf_mode = 1; $pdflatex を利用して PDF を作成。
## $pdf_mode = 2; $ps2pdf を利用して .ps ファイルから PDF を作成。
## $pdf_mode = 3; $dvipdf を利用して .dvi ファイルから PDF を作成。
## $pdf_mode = 4; $lualatex を利用して .dvi ファイルから PDF を作成。
## $pdf_mode = 5; xdvipdfmx を利用して .xdv ファイルから PDF を作成。
$pdf_mode = 1;

# 中間ファイルを output ディレクトリに配置
$out_dir = 'output';
