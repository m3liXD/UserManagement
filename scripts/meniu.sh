#!/bin/bash


# ---- functie pt afisarea meniului in diferite culori ----
print_rainbow() {
    local text="$1"
    local colors=(31 33 32 36 34 35)
    local color_idx=0

    for (( i=0; i<${#text}; i++ )); do
        local char="${text:$i:1}"
        if [[ "$char" == " " ]]; then
            echo -ne " "
        else
            echo -ne "\e[1;${colors[$color_idx]}m$char"
            color_idx=$(( (color_idx + 1) % ${#colors[@]} ))
        fi
    done

    echo -e "\e[0m"
}


clear

DIRECTOR_ORIGINAL=$(pwd)
cd "$DIRECTOR_ORIGINAL" || exit

declare -ga UTILIZATORI_INREGISTRATI=()

FISIER_REGISTRU="$DIRECTOR_ORIGINAL/registru_utilizatori.csv"

export DIRECTOR_ORIGINAL


source creare.sh
source operatiuni.sh
source raport.sh
source archery.sh


optiuni=(
    "1. Creare utilizator"   # 0
    "2. Login"               # 1
    "3. Logout"              # 2
    "4. Status"              # 3
    "5. Generare raport"     # 4
    "6. 🏹 Archery"          # 5
    "7. Ieșire"              # 6
)

selectie=0

# tput civis = cursor invisible, tput cnorm = cursor normal
tput civis

# daca utilizatorul apasa Ctrl+C, restauram cursorul inainte de iesire
trap "tput cnorm; clear; exit" SIGINT SIGTERM


while true; do

    while true; do
        clear
        cd "$DIRECTOR_ORIGINAL" || exit
        echo ""

        print_rainbow "    ███╗   ███╗███████╗███╗   ██╗██╗██╗   ██╗"
        print_rainbow "    ████╗ ████║██╔════╝████╗  ██║██║██║   ██║"
        print_rainbow "    ██╔████╔██║█████╗  ██╔██╗ ██║██║██║   ██║"
        print_rainbow "    ██║╚██╔╝██║██╔══╝  ██║╚██╗██║██║██║   ██║"
        print_rainbow "    ██║ ╚═╝ ██║███████╗██║ ╚████║██║╚██████╔╝"
        print_rainbow "    ╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝╚═╝ ╚═════╝ "
        echo ""
        print_rainbow "       === Sistem de Gestiune Utilizatori ==="
        echo ""

        
        if [ "${#UTILIZATORI_INREGISTRATI[@]}" -gt 0 ]; then
            echo -e "       \e[2;37mActivi: ${UTILIZATORI_INREGISTRATI[*]}\e[0m"
        else
            echo -e "       \e[2;37mNiciun utilizator autentificat\e[0m"
        fi
        echo ""

        
        for i in "${!optiuni[@]}"; do
            if [ "$i" -eq "$selectie" ]; then
                echo -e "      \e[1;32m🚀 \e[1;37m\e[45m ${optiuni[$i]} \e[0m"
            else
                echo -e "         \e[1;37m${optiuni[$i]}\e[0m"
            fi
        done

        echo ""
        print_rainbow "[ ↑/↓: Navigare | ENTER: Selectare ]"

        # -r = no backslash -s = silent, -n1 = exact 1 caracter
        read -rsn1 tasta

        if [[ "$tasta" == $'\e' ]]; then
            # ESC prefix = tasta speciala (sageata genereaza ESC + [ + A/B)
            read -rsn2 tasta2

            if [[ "$tasta2" == "[A" ]]; then
                ((selectie--))
                # navigare circulara la capete
                [ "$selectie" -lt 0 ] && selectie=$(( ${#optiuni[@]} - 1 ))

            elif [[ "$tasta2" == "[B" ]]; then
                ((selectie++))
                [ "$selectie" -ge "${#optiuni[@]}" ] && selectie=0
            fi

        elif [[ -z "$tasta" ]]; then
            break   # ENTER
        fi
    done

    tput cnorm
    clear

    
    case "$selectie" in

        0)  
            print_rainbow "---[ CREARE UTILIZATOR NOU ]---"; echo ""
            read -p "Nume utilizator: " NUME_REG
            DUPA_CREARE="menu"
            creeare "$NUME_REG"
            creare_status=$?   

            
            if [ "$creare_status" -eq 0 ] && [ "$DUPA_CREARE" == "login" ]; then
                clear
                print_rainbow "---[ LOGIN ]---"; echo ""
                login "$NUME_REG"
            fi
            ;;

        1)  
            print_rainbow "---[ LOGIN ]---"; echo ""
            read -p "Nume utilizator: " NUME_LOGIN
            login "$NUME_LOGIN"
            ;;

        2)  
            print_rainbow "---[ LOGOUT ]---"; echo ""
            read -p "Nume utilizator: " NUME_LOGOUT
            logout "$NUME_LOGOUT"
            ;;

        3)  
            status_users
            ;;

        4)  
            print_rainbow "---[ GENERARE RAPORT ]---"; echo ""
            read -p "Nume utilizator: " NUME_RAPORT
            generare_raport_utilizator "$NUME_RAPORT"
            ;;

        5)  
            archery_menu
            tput civis
            continue
            ;;

        6)  
            print_rainbow "La revedere! O zi superbă!"
            tput cnorm; clear; exit 0
            ;;
    esac

    echo ""
    echo -e "\e[1;36m[ Apasă orice tastă pentru a reveni la meniu... ]\e[0m"
    read -rsn1
    tput civis
done

tput cnorm
clear
