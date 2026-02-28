#!/bin/bash


FISIER_REGISTRU="$DIRECTOR_ORIGINAL/registru_utilizatori.csv"



# ---- functii ajutatoare pentru o vizualizare imbunatatita ----

info()        { echo -e "\e[1;32m  ✔  \e[0;32m$1\e[0m"; }
eroare()      { echo -e "\e[1;31m  ✘  \e[0;31m$1\e[0m" >&2; }
avertisment() { echo -e "\e[1;33m  ⚠  \e[0;33m$1\e[0m"; }
separator()   { echo -e "\e[2;37m  ────────────────────────────────────────\e[0m"; }
pas()         { echo -e "\e[1;36m  ◆  \e[0;36m$1\e[0m"; }


# ---- functie ajutatoare pt generarea raportului de utilizare ----
raport() {
    local user="$1"
    local user_director="$2"
    local fisier_raport="${user_director}/Home/raport_utilizare.txt"

    if [ ! -d "$user_director" ]; then
        eroare "Directorul utilizatorului '$user' nu există: $user_director"
        return 1
    fi

    local nr_fisiere nr_directoare dimensiune data_generare

    nr_fisiere=$(find "$user_director" -type f | wc -l)

    nr_directoare=$(find "$user_director" -type d | grep -vc "^${user_director}$")

    dimensiune=$(du -sk "$user_director" 2>/dev/null | cut -f1)
    data_generare=$(date "+%Y-%m-%d %H:%M:%S")

   
    {
        echo "╔══════════════════════════════════════════╗"
        echo "║         RAPORT DE UTILIZARE              ║"
        echo "╠══════════════════════════════════════════╣"
        echo "║  Utilizator   : $user                    ║"
        echo "║  Generat la   : $data_generare           ║"
        echo "╠══════════════════════════════════════════╣"
        echo "║  Fișiere      : $nr_fisiere              ║"
        echo "║  Directoare   : $nr_directoare           ║"
        echo "║  Dimensiune   : ${dimensiune} KB         ║"
        echo "╚══════════════════════════════════════════╝"
    } > "$fisier_raport"

    return 0
}


# ---- functie pt generare raport ----
generare_raport_utilizator() {
    local UTILIZATOR="$1"
    local gasit=0

    echo ""; separator
    echo -e "\e[1;37m      GENERARE RAPORT UTILIZATOR\e[0m"
    separator; echo ""

    if [ -z "$UTILIZATOR" ]; then
        eroare "Niciun utilizator specificat."
        return 1
    fi

    if [ ! -f "$FISIER_REGISTRU" ]; then
        eroare "Registrul de utilizatori nu există."
        return 1
    fi

    pas "Se caută utilizatorul '$UTILIZATOR'..."
    sleep 0.2

        
    local username email parola id director_path last_login
    while IFS=',' read -r username email parola id director_path last_login; do

    
        username=$(echo "$username" | sed 's/"//g')
        director_path=$(echo "$director_path" | sed 's/"//g')
        last_login=$(echo "$last_login" | sed 's/"//g')

        if [ "$username" == "$UTILIZATOR" ]; then
            gasit=1
            info "Utilizator găsit."; echo ""

            echo -e "  \e[0;37mDirector   \e[0m: \e[1;37m$director_path\e[0m"
            echo -e "  \e[0;37mUltim login\e[0m: \e[1;37m${last_login:-necunoscut}\e[0m"
            echo ""

            pas "Se generează raportul..."

            raport "$UTILIZATOR" "$director_path"
            local exit_code=$?

            if [ "$exit_code" -eq 0 ]; then
                local fisier_raport="${director_path}/Home/raport_utilizare.txt"
                echo ""
                info "Raportul a fost generat!"
                echo -e "  \e[0;37mLocație\e[0m: \e[1;37m$fisier_raport\e[0m"
                echo ""

    
                if [ -f "$fisier_raport" ]; then
                    separator
                    echo -e "\e[1;36m      PREVIZUALIZARE RAPORT\e[0m"
                    separator; echo ""
                    while IFS= read -r linie; do
                    echo -e "  \e[0;37m$linie\e[0m"
                    done < "$fisier_raport"
                    echo ""
                fi
            else
                eroare "Generarea raportului a eșuat."
                return 1
            fi

            break   
        fi

    done < "$FISIER_REGISTRU"

    if [ "$gasit" -eq 0 ]; then
        eroare "Utilizatorul '$UTILIZATOR' nu a fost găsit."
        avertisment "Verificați că numele este corect."
        echo ""
        return 1
    fi

    separator; echo ""
    return 0
}
