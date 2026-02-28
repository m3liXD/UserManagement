#!/bin/bash


FISIER_SCORURI_ARCHERY="${DIRECTOR_ORIGINAL:-$(pwd)}/scoruri_archery.csv"

# scurtaturi pentru coduri de culoare ANSI
C_R="\e[0m"; C_Y="\e[1;33m"; C_G="\e[1;32m"; C_RE="\e[1;31m"
C_C="\e[1;36m"; C_W="\e[1;37m"; C_D="\e[2;37m"; C_M="\e[1;35m"

sep() { echo -e "${C_D}  ────────────────────────────────────────${C_R}"; }

# ---- functie pentru gestionare scoruri ----
init_archery_scores() {
    # cream fisierul cu header daca lipseste sau e gol
    if [ ! -f "$FISIER_SCORURI_ARCHERY" ] || [ ! -s "$FISIER_SCORURI_ARCHERY" ]; then
        echo "Username,BestScore,TotalGames" > "$FISIER_SCORURI_ARCHERY"
    fi
}


# ---- functie pentru a afla cel mai bun scor ----
get_archery_best() {
    
    local u="$1"
    [ ! -f "$FISIER_SCORURI_ARCHERY" ] && echo "0" && return

    awk -F',' -v user="$u" '
        NR==1 { next }  # sarim peste header
        {
            u=$1; b=$2
            gsub(/"/, "", u)
            if (u == user) {
                gsub(/"/, "", b)
                print (b=="" ? 0 : b)
                exit
            }
        }
        END { if (NR<=1) print 0 }
    ' "$FISIER_SCORURI_ARCHERY" 2>/dev/null | head -1
}
# ---- functie pentru a salva scorul ----
save_archery_score() {
    
    local user="$1" new="$2"
    init_archery_scores

    local tmp; tmp="$(mktemp)"
    awk -F',' -v user="$user" -v newscore="$new" '
        BEGIN {
            OFS=","
            found=0
            old_best=0
            old_games=0
        }
        NR==1 {
            # punem din nou headerul
            print "Username","BestScore","TotalGames"
            next
        }
        {
            u=$1; b=$2; g=$3
            gsub(/"/, "", u); gsub(/"/, "", b); gsub(/"/, "", g)

            if (u == user) {
                found=1
                old_best = (b=="" ? 0 : b) + 0
                old_games = (g=="" ? 0 : g) + 0
                next   # scoatem linia veche din output
            }

            # rescriem linia standardizata (cu ghilimele)
            print "\"" u "\"","\"" (b==""?0:b) "\"","\"" (g==""?0:g) "\""
        }
        END {
            best = old_best
            if (newscore + 0 > best) best = newscore + 0
            games = old_games + 1

            # adaugam/actualizam user-ul (o singura linie per user)
            print "\"" user "\"","\"" best "\"","\"" games "\""
        }
    ' "$FISIER_SCORURI_ARCHERY" > "$tmp" && mv "$tmp" "$FISIER_SCORURI_ARCHERY"
}


# ---- configuratia tintei ----
ZONE_LABELS=("   " " 1 " " 2 " " 3 " "🎯 " " 3 " " 2 " " 1 " "   ")
ZONE_POINTS=(  0     10   20   30   100    30   20   10    0  )


# ---- functie pentru desenarea tintei ----
draw_target() {
    local needle="$1"
    echo -ne "  "
    for i in {0..8}; do
        if [ "$i" -eq "$needle" ]; then
            echo -ne "${C_Y}\e[7m ${ZONE_LABELS[$i]} ${C_R}"
        elif [ "$i" -eq 4 ]; then
            echo -ne "${C_RE}[${ZONE_LABELS[$i]}]${C_R}"
        else
            echo -ne "${C_D}|${ZONE_LABELS[$i]}|${C_R}"
        fi
    done
    echo ""
}


# ---- functie pentru a desena bara specifica tastei SPACE ----
draw_bar() {
    local pos="$1" maxpos="$2"
    local filled=$(( pos * 30 / maxpos ))
    echo -ne "  ${C_C}["
    for (( i=0; i<30; i++ )); do
        [ "$i" -lt "$filled" ] && echo -ne "${C_G}█" || echo -ne "${C_D}░"
    done
    echo -e "${C_C}]${C_R}  ${C_D}Apasa SPACE pentru a trage la tinta!${C_R}"
}


# ---- functia "main" a jocului , aici se intampla cele 5 runde + scor + variabila de vant
archery_game() {
    local player="$1"
    init_archery_scores
    local total=0 rounds=5
    local best; best=$(get_archery_best "$player")

    clear; echo ""; sep
    echo -e "${C_W}      🏹  ARCHERY — ${player}${C_R}"
    sep; echo ""
    echo -e "  ${C_D}5 incercari.Apasa SPACE pentru a trage!${C_R}"
    echo -e "  ${C_D}Vantul afecteaza directia sagetii, ai grija!${C_R}"
    echo ""; sleep 1.5

    stty -echo -icanon min 0 time 0

    for (( round=1; round<=rounds; round++ )); do

        # vant aleatoriu intre -2 si +2
        
        local wind=$(( RANDOM % 5 - 2 ))
        local wind_label=""
        [ "$wind" -lt 0 ] && wind_label="${C_C}← $(( wind * -1 ))${C_R}"
        [ "$wind" -gt 0 ] && wind_label="${C_C}→ ${wind}${C_R}"
        [ "$wind" -eq 0 ] && wind_label="${C_G}none${C_R}"

        local pos=0 direction=1 maxpos=40 holding=0 shoot_pos=-1

        while true; do
            # redesenam in loc (overwrite) ca sa evitam flickering
            tput cup 8 0
            echo -e "  ${C_W}Round ${round}/${rounds}   Score: ${C_G}${total}${C_R}   Wind: ${wind_label}      "
            echo ""
            draw_target "$(( pos * 8 / maxpos ))"
            echo ""
            draw_bar "$pos" "$maxpos"
            echo ""

            local k; k=$(dd if=/dev/stdin bs=1 count=1 2>/dev/null)

            if [[ "$k" == " " ]]; then
                holding=1
            elif [ "$holding" -eq 1 ] && [[ -z "$k" ]]; then
                shoot_pos=$(( pos * 8 / maxpos ))
                break
            fi

            # miscam acul si inversam directia la capete
            (( pos += direction ))
            [ "$pos" -ge "$maxpos" ] && direction=-1
            [ "$pos" -le 0 ]        && direction=1
            sleep 0.05
        done

        # Aplicam vantul si limitam la 0-8
        local adjusted=$(( shoot_pos + wind ))
        [ "$adjusted" -lt 0 ] && adjusted=0
        [ "$adjusted" -gt 8 ] && adjusted=8

        local pts=${ZONE_POINTS[$adjusted]}
        (( total += pts ))

        # Afisam rezultatul rundei
        tput cup 8 0
        echo -e "  ${C_W}Runda: ${round}/${rounds}   Scor: ${C_G}${total}${C_R}   Vant: ${wind_label}      "
        echo ""
        draw_target "$adjusted"
        echo -e "\n                                                  \n"

        if   [ "$pts" -eq 100 ]; then echo -e "  ${C_Y}🏹  LA FIX! +${pts} pts${C_R}                    "
        elif [ "$pts" -gt   0 ]; then echo -e "  ${C_G}🏹  Buna incercare! +${pts} pts${C_R}                   "
        else                          echo -e "  ${C_RE}🏹  Ai ratat! +0 pts${C_R}                            "
        fi
        sleep 1.2
    done

    stty echo icanon   # restauram terminalul la normal
    save_archery_score "$player" "$total"

    clear; echo ""; sep
    echo -e "${C_W}      🏹  SFARSITUL JOCULUI — ${player}${C_R}"
    sep; echo ""
    echo -e "  ${C_W}Scor final  ${C_R}: ${C_G}${total}${C_R}"
    local new_best; new_best=$(get_archery_best "$player")
    [ "$total" -ge "$new_best" ] && [ "$total" -gt 0 ] && \
        echo -e "  ${C_Y}  🏆 Nou record personal!${C_R}"
    echo -e "  ${C_W}Record       ${C_R}: ${C_M}${new_best}${C_R}"
    echo ""; sep; echo ""
}


# ---- clasamentul jucatorilor ----
archery_leaderboard() {
    clear; echo ""; sep
    echo -e "${C_W}      🏆  CLASAMENT ARCHERY${C_R}"; sep; echo ""

    if [ ! -f "$FISIER_SCORURI_ARCHERY" ] || \
       [ "$(wc -l < "$FISIER_SCORURI_ARCHERY")" -le 1 ]; then
        echo -e "  ${C_D}Niciun scor înregistrat.${C_R}"
    else
        echo -e "  ${C_W}  #    Jucător              Best    Jocuri${C_R}"
        echo -e "  ${C_D}  ───────────────────────────────────────${C_R}"

        
        local -a rows
        while IFS= read -r line; do
            rows+=("$line")
        done < <(
            tail -n +2 "$FISIER_SCORURI_ARCHERY" \
            | awk -F',' '{gsub(/"/,""); print $2 "	" $1 "	" $3}' \
            | sort -t$'	' -k1,1nr
        )

        local rank=1
        for row in "${rows[@]}"; do
            local b u g
            b=$(printf "%s" "$row" | cut -f1)
            u=$(printf "%s" "$row" | cut -f2)
            g=$(printf "%s" "$row" | cut -f3)

            local m="    "
            [ "$rank" -eq 1 ] && m="${C_Y}🥇  ${C_R}"
            [ "$rank" -eq 2 ] && m="${C_W}🥈  ${C_R}"
            [ "$rank" -eq 3 ] && m="🥉  "

            printf "  %b %-22s ${C_G}%-8s${C_R} %s jocuri
" "$m" "$u" "$b" "$g"
            (( rank++ ))
        done
    fi

    echo ""; sep; echo ""
    read -n1 -rsp "$(echo -e "  ${C_D}Apasă orice tastă...${C_R}")"
    echo ""
}


# ---- functia de meniu a jocului ----
archery_menu() {
    local opts=("1. Joacă" "2. 🏆 Clasament" "3. Înapoi")
    local sel=0

    tput civis

    while true; do
        while true; do
            clear; echo ""
            echo -e "${C_W}    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░${C_R}"
            echo -e "${C_W}    ░   ${C_Y}🏹  ARCHERY — Terminal Edition   ${C_W}░ ${C_R}"
            echo -e "${C_W}    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░${C_R}"; echo ""

            for i in "${!opts[@]}"; do
                [ "$i" -eq "$sel" ] \
                    && echo -e "      \e[1;32m🏹 ${C_W}\e[45m ${opts[$i]} \e[0m" \
                    || echo -e "         ${C_W}${opts[$i]}${C_R}"
            done; echo ""

            read -rsn1 k
            if [[ "$k" == $'\e' ]]; then
                read -rsn2 k2
                [[ "$k2" == "[A" ]] && (( sel-- ))
                [[ "$k2" == "[B" ]] && (( sel++ ))
                [ "$sel" -lt 0 ] && sel=$(( ${#opts[@]}-1 ))
                [ "$sel" -ge "${#opts[@]}" ] && sel=0
            elif [[ -z "$k" ]]; then
                break
            fi
        done

        tput cnorm

        case "$sel" in
            0)
                clear; echo ""
                read -p "$(echo -e "  ${C_C}Nume jucător: ${C_R}")" p
                if [ -n "$p" ]; then
                    archery_game "$p"
                else
                    echo -e "  ${C_RE}Niciun jucător specificat.${C_R}"
                fi
                read -n1 -rsp "$(echo -e "  ${C_D}Apasă orice tastă...${C_R}")"
                echo ""
                ;;
            1) archery_leaderboard ;;
            2) tput cnorm; return ;;
        esac

        tput civis
    done

    tput cnorm
}

