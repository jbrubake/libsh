# Initialization {{{1
#
__color__="FG BG FX"

# Functions to set colors and attributes {{{1
#
#  FX bold: sets bold attribute
#  FG 1: sets foreground color to ANSI color 1
#  BG 1: sets background color to ANSI color 1
#
# These functions automatically interpret escape
# sequences so you don't need to pass '-e' to echo
#
# Based on P. C. SHyamshankar's spectrum script
# for zsh <github.com/sykora>.
#
# Changed to use functions instead of hashes for speed
###################################################
color_FX() {
    case "$1" in
        reset)       printf "[0m"   ;;
        bold)        printf "[1m"   ;;
        nobold)      printf "[22m"  ;;
        dim)         printf "[2m"   ;;
        nodim)       printf "0m"    ;; # Unsupported
        italic)      printf "[3m"   ;;
        noitalic)    printf "[23m"  ;;
        underline)   printf "[4m"   ;;
        nounderline) printf "[24m"  ;;
        blink)       printf "[5m"   ;;
        fastblink)   printf "[6m"   ;;
        noblink)     printf "[25m"  ;;
        reverse)     printf "[7m"   ;;
        noreverse)   printf "[27m"  ;;
        hidden)      printf "[8m"   ;;
        nohidden)    printf "[28m"  ;;
        standout)    printf "[7m"   ;;
        nostandout)  printf "[27m"  ;;
        strikeout)   printf "[9m"   ;;
        nostrikeout) printf "[29m"  ;;

        fancyul)     printf "[4:1m" ;;
        dblfancyul)  printf "[4:2m" ;;
        undercurl)   printf "[4:3m" ;;
        dotfancyul)  printf "[4:4m" ;;
        dashfancyul) printf "[4:5m" ;;
        nofancyul)   printf "[4:0m" ;;

        *)           echo "";
    esac
}

if test "$( tput colors )" -ge 0; then
    # Expects: color number 0-255
    color_FG() {
        if [ $# -eq 1 ]; then
            echo "[38;5;$1m"
        elif [ $# -eq 3 ]; then
            echo "[38;2;$1;$2;$3m"
        fi
    }
    color_BG() {
        if [ $# -eq 1 ]; then
            echo "[48;5;$1m"
        elif [ $# -eq 3 ]; then
            echo "[48;2;$1;$2;$3m"
        fi
    }
else
    color_FG()  { :; }
    color_BG()  { :; }
fi

