#!/bin/bash


FISIER_REGISTRU="$DIRECTOR_ORIGINAL/registru_utilizatori.csv"
DIRECTOR_PARINTE="."


# ---- functii ajutatoare pt o vizualizare imbunatatita ----

info()        { echo -e "\e[1;32m  ✔  \e[0;32m$1\e[0m"; }
eroare()      { echo -e "\e[1;31m  ✘  \e[0;31m$1\e[0m" >&2; }
avertisment() { echo -e "\e[1;33m  ⚠  \e[0;33m$1\e[0m"; }
separator()   { echo -e "\e[2;37m  ────────────────────────────────────────\e[0m"; }
pas()         { echo -e "\e[1;36m  ◆  \e[0;36m$1\e[0m"; }

# ---- functie pt desenarea meniului dupa ce-am creat utilizatorul/dupa login ----

_draw_post_menu() {
    local sel="$1"
    shift
    local opts=("$@")
    local start_row
    start_row=$(tput lines)
    # calculam linia de start: ne pozitionam sus, nu la capatul ecranului
    # folosim o ancora fixa — linia curenta minus inaltimea meniului

    echo -e "\e[1;37m  Ce doriți să faceți acum?\e[0m\e[K"
    echo -e "\e[K"   # linie goala curata

    for i in "${!opts[@]}"; do
        if [ "$i" -eq "$sel" ]; then
            echo -e "      \e[1;32m→ \e[1;37m\e[45m ${opts[$i]} \e[0m\e[K"
        else
            echo -e "        \e[0;37m${opts[$i]}\e[0m\e[K"
        fi
    done
    echo -e "\e[K"   # linie goala curata la final
}

# ---- functie de navigare a meniului dupa login/dupa crearea utilizatorului ----

_navigate_post_menu() {
    local opts=("$@")
    local sel=0
    local nr_opts=${#opts[@]}
    # calculam cate linii ocupa meniul (titlu + linie goala + optiuni + linie goala)
    local menu_height=$(( nr_opts + 3 ))

    tput civis   # ascundem cursorul cat timp navigam

    # afisam meniul
    _draw_post_menu "$sel" "${opts[@]}"

    while true; do
        read -rsn1 k

        if [[ "$k" == $'\e' ]]; then
            read -rsn2 k2
            if [[ "$k2" == "[A" ]]; then
                (( sel-- ))
                [ "$sel" -lt 0 ] && sel=$(( nr_opts - 1 ))
            elif [[ "$k2" == "[B" ]]; then
                (( sel++ ))
                [ "$sel" -ge "$nr_opts" ] && sel=0
            fi

            
            tput cuu "$menu_height"
            _draw_post_menu "$sel" "${opts[@]}"

        elif [[ -z "$k" ]]; then
            # ENTER apasat — iesim
            break
        fi
    done

    tput cnorm
    POST_MENU_SEL=$sel   # comunicam alegerea inapoi catre apelant
}


# ---- functia de creare utilizator ----
creeare() {
    local UTILIZATOR="$1"
    DUPA_CREARE="menu"

    echo ""; separator
    echo -e "\e[1;37m      ÎNREGISTRARE UTILIZATOR NOU\e[0m"
    separator; echo ""

    # ---- validare username ----
    if [ -z "$UTILIZATOR" ]; then
        eroare "Niciun nume de utilizator furnizat."
        return 1
    fi

    # ---- permitem doar litere, cifre, underscore, punct, liniuta ----
    if [[ ! "$UTILIZATOR" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
        eroare "Numele '$UTILIZATOR' conține caractere invalide."
        avertisment "Sunt permise doar litere, cifre, _, . și -"
        return 1
    fi

    pas "Se verifică disponibilitatea numelui '$UTILIZATOR'..."

    # ---- initializare registru daca nu exista ----
    if [ ! -f "$FISIER_REGISTRU" ]; then
        avertisment "Registrul nu există. Se creează automat..."
        echo "Username,Email,Parola,ID,DirectorPath,LastLogin" > "$FISIER_REGISTRU"
        info "Registru inițializat."
    fi

    # grep -qE = cauta silentios cu regex, returneaza doar cod de exit
    if grep -qE "^\"?${UTILIZATOR}\"?," "$FISIER_REGISTRU"; then
        eroare "Utilizatorul '$UTILIZATOR' există deja în sistem."
        return 1
    fi
    info "Numele '$UTILIZATOR' este disponibil."; echo ""



    # ---- introducere email — cu maximum 3 incercari ----

    pas "Introducere adresă email:"
    local EMAIL
    local tentative_email=0

    while true; do
        ((tentative_email++))
        read -p "$(echo -e "  \e[0;37m→ Email: \e[0m")" EMAIL

        # regex validare email: user@domeniu.extensie
        if [[ "$EMAIL" =~ ^[a-zA-Z0-9._+%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            info "Email valid."
            break
        else
            eroare "Format invalid. Exemplu: utilizator@domeniu.com"
            [ "$tentative_email" -ge 3 ] && {
                avertisment "Prea multe încercări. Revenire la meniu."
                return 1
            }
        fi
    done; echo ""


    # ---- creare parola — cu confirmare si maximum 4 incercari ----

    pas "Setare parolă (minim 6 caractere):"
    local PAROLA CONFIRMARE_PAROLA
    local tentative_parola=0

    while true; do
        ((tentative_parola++))

        read -s -p "$(echo -e "  \e[0;37m→ Parolă: \e[0m")" PAROLA; echo
        read -s -p "$(echo -e "  \e[0;37m→ Confirmare: \e[0m")" CONFIRMARE_PAROLA; echo

        if [ -z "$PAROLA" ]; then
            eroare "Parola nu poate fi goală."
        elif [ "${#PAROLA}" -lt 6 ]; then
            eroare "Minim 6 caractere (${#PAROLA} introduse)."
        elif [ "$PAROLA" != "$CONFIRMARE_PAROLA" ]; then
            eroare "Parolele nu coincid."
        else
            info "Parolă setată."
            break
        fi

        [ "$tentative_parola" -ge 4 ] && {
            eroare "Prea multe încercări. Revenire la meniu."
            return 1
        }
        echo ""
    done; echo ""

    
    
    local PAROLA_CRIPTATA
    PAROLA_CRIPTATA=$(echo -n "$PAROLA" | sha256sum | cut -d' ' -f1)

    
    local ID_UNIC
    ID_UNIC=$(shuf -i 100000-999999 -n 1)

    
    local NUME_FOLDER="${UTILIZATOR// /_}"
    local DIRECTOR_PATH_UTILIZATOR="$DIRECTOR_PARINTE/$NUME_FOLDER"

    if [ -d "$DIRECTOR_PATH_UTILIZATOR" ]; then
        eroare "Există deja un director pentru '$UTILIZATOR'."
        return 1
    fi


    # fiecare user primeste: ./NumeUser/Home/
   
    pas "Se creează structura de directoare..."
    mkdir -p "$DIRECTOR_PATH_UTILIZATOR/Home" 2>/dev/null

    if [ $? -ne 0 ]; then
        eroare "Nu s-a putut crea directorul '$DIRECTOR_PATH_UTILIZATOR'."
        return 1
    fi
    info "Structura creată: $DIRECTOR_PATH_UTILIZATOR/Home"


    
    echo "\"$UTILIZATOR\",\"$EMAIL\",\"$PAROLA_CRIPTATA\",\"$ID_UNIC\",\"$DIRECTOR_PATH_UTILIZATOR\",\"\"" >> "$FISIER_REGISTRU"
    info "Datele au fost salvate în registru."


    echo ""; separator
    echo -e "\e[1;32m        CONT CREAT CU SUCCES!\e[0m"
    separator
    echo -e "  \e[0;37mUtilizator   \e[0m: \e[1;37m$UTILIZATOR\e[0m"
    echo -e "  \e[0;37mEmail        \e[0m: \e[1;37m$EMAIL\e[0m"
    echo -e "  \e[0;37mID Unic      \e[0m: \e[1;37m#$ID_UNIC\e[0m"
    echo -e "  \e[0;37mDirector     \e[0m: \e[1;37m$DIRECTOR_PATH_UTILIZATOR\e[0m"
    separator; echo ""


    _navigate_post_menu "1. Mergi la Login" "2. Înapoi la meniu"

    case "$POST_MENU_SEL" in
        0) DUPA_CREARE="login" ;;
        1) DUPA_CREARE="menu"  ;;
    esac

    return 0
}
