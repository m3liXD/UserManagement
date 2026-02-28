#!/bin/bash


cd "$DIRECTOR_ORIGINAL" || exit
FISIER_REGISTRU="$DIRECTOR_ORIGINAL/registru_utilizatori.csv"


# ---- functii ajutatoare pt o vizualizare imbunatatita ----
info()        { echo -e "\e[1;32m  ✔  \e[0;32m$1\e[0m"; }
eroare()      { echo -e "\e[1;31m  ✘  \e[0;31m$1\e[0m" >&2; }
avertisment() { echo -e "\e[1;33m  ⚠  \e[0;33m$1\e[0m"; }
separator()   { echo -e "\e[2;37m  ────────────────────────────────────────\e[0m"; }
pas()         { echo -e "\e[1;36m  ◆  \e[0;36m$1\e[0m"; }

progress_bar() {
    local msg="$1"
    echo -ne "  \e[0;35m$msg\e[0m "
    for i in {1..20}; do echo -ne "\e[1;35m█\e[0m"; sleep 0.03; done
    echo -e "  \e[1;32mGata!\e[0m"
}


# ---- crearea unui terminal interactiv pt fiecare utilizator in parte, fara posibilitatea accesarii altor directoare ----
launch_user_terminal() {
    local user="$1"
    local user_dir="$2"

    # rezolvam calea absoluta a directorului permis
    # realpath elimina simbolurile . si .. din cale
    local allowed_dir
    allowed_dir=$(realpath "$user_dir" 2>/dev/null || echo "$user_dir")

    # cream fisierul de configurare temporar
    # mktemp creeaza un fisier cu nume unic in /tmp — evita conflicte
    # daca mai multi utilizatori ruleaza simultan
    local tmp_rc
    tmp_rc=$(mktemp /tmp/meniu_rc_XXXXXX)

    
    cat > "$tmp_rc" << RCEOF
# incarcam profilul utilizatorului daca exista
[ -f ~/.bashrc ] && source ~/.bashrc 2>/dev/null

# mergem in directorul permis la start
cd "$allowed_dir"

# prompt personalizat: [username] /cale/curenta ❯
PS1="\[\e[1;33m\][$user]\[\e[0m\] \[\e[1;36m\]\w\[\e[0m\] \[\e[1;32m\]❯\[\e[0m\] "

# suprascriem functia cd pt a verifica ca ramanem in directorul permis
# cum functioneaza verificarea:
# 1. calculam calea absoluta a destinatiei cu realpath
# 2. verificam daca incepe cu calea directorului permis
#    (prin [[ "$dest" == "$allowed_dir"* ]])
# 3. daca da — permitem cd-ul nativ cu "builtin cd"
# 4. daca nu — afisam eroare si nu facem nimic
#
# "builtin cd" apeleaza cd-ul original al bash-ului,
# nu functia noastra (altfel am face recursie infinita)
cd() {
    local dest

    if [ -z "\$1" ]; then
        dest="$allowed_dir"
    else
        dest=\$(realpath "\$(pwd)/\$1" 2>/dev/null || echo "\$1")
    fi

    if [[ "\$dest" == "$allowed_dir" || "\$dest" == "$allowed_dir/"* ]]; then
        builtin cd "\$dest"
    else
        echo -e "\e[1;31m  ✘  Acces interzis! Nu poți ieși din directorul tău.\e[0m"
        echo -e "\e[2;37m     Director permis: $allowed_dir\e[0m"
    fi
}

# exportam functia ca sa fie disponibila in sub-procesele acestei sesiuni
export -f cd


echo ""
echo -e "\e[1;37m  ╔═══════════════════════════════════════════════════╗\e[0m"
echo -e "\e[1;37m  ║  \e[1;33mTerminal utilizator: $user                \e[1;37m"
echo -e "\e[1;37m  ║  \e[2;37mDirector: $allowed_dir                    \e[0m"
echo -e "\e[1;37m  ║  \e[2;37mNu poți naviga în afara acestui director. \e[0m"
echo -e "\e[1;37m  ║  \e[2;37mScrie 'exit' pentru a reveni la meniu.    \e[0m"
echo -e "\e[1;37m  ╚═══════════════════════════════════════════════════╝\e[0m"
echo ""
RCEOF

    # lansam bash interactiv cu fisierul nostru de configurare
    bash --rcfile "$tmp_rc" -i

    # ajungem aici doar dupa ce utilizatorul scrie "exit"
    rm -f "$tmp_rc"                   # stergem fisierul temporar
    cd "$DIRECTOR_ORIGINAL" || exit   # revenim la directorul scriptului
}



# ---- functia pt login ----
login() {
    local user="$1"
    local parola user_record stored_parola_criptata path_director parola_criptata_login timp

    echo ""; separator
    echo -e "\e[1;37m      AUTENTIFICARE\e[0m"
    separator; echo ""

    if [ -z "$user" ]; then
        eroare "Niciun utilizator specificat."
        return 1
    fi

    if [ ! -f "$FISIER_REGISTRU" ]; then
        eroare "Registrul nu există. Creați mai întâi un cont."
        return 1
    fi

    pas "Se caută utilizatorul '$user'..."
    sleep 0.2

    
    user_record=$(grep -E "^\"?${user}\"?," "$FISIER_REGISTRU")

    if [ -z "$user_record" ]; then
        eroare "Utilizatorul '$user' nu a fost găsit."
        avertisment "Verificați numele sau creați un cont nou."
        return 1
    fi
    info "Utilizator găsit."; echo ""

    
    stored_parola_criptata=$(echo "$user_record" | cut -d',' -f3 | sed 's/"//g')
    path_director=$(echo "$user_record" | cut -d',' -f5 | sed 's/"//g')

    if [ -z "$stored_parola_criptata" ] || [ -z "$path_director" ]; then
        eroare "Date corupte în registru pentru '$user'."
        return 1
    fi

    
    for logged_user in "${UTILIZATORI_INREGISTRATI[@]}"; do
        if [ "$logged_user" == "$user" ]; then
            avertisment "Utilizatorul '$user' este deja autentificat."
            _post_login_menu "$user" "$path_director"
            return 0
        fi
    done

    
    local tentative=0
    while true; do
        ((tentative++))
        read -s -p "$(echo -e "  \e[0;37m→ Parolă ($tentative/3): \e[0m")" parola; echo

        if [ -z "$parola" ]; then
            eroare "Parola nu poate fi goală."
            [ "$tentative" -ge 3 ] && break
            continue
        fi

        
        parola_criptata_login=$(echo -n "$parola" | sha256sum | cut -d' ' -f1)

        if [ "$parola_criptata_login" == "$stored_parola_criptata" ]; then
            echo ""
            progress_bar "Se încarcă sesiunea..."
            echo ""
            info "Autentificare reușită! Bun venit, \e[1;37m$user\e[0;32m!"

           
            if [ ! -d "$path_director" ]; then
                avertisment "Directorul home lipsește. Se recreează..."
                mkdir -p "$path_director/Home" \
                    && info "Director recreat." \
                    || eroare "Nu s-a putut crea."
            fi

            
            
            
            timp=$(date '+%Y-%m-%d %H:%M:%S')
            cd "$DIRECTOR_ORIGINAL" || true
            sed -i -E "/\"${user}\"/s/^(([^,]*,){5})[^,]*$/\1\"${timp}\"/" "$FISIER_REGISTRU"
            info "Ultima autentificare: $timp"

            
            UTILIZATORI_INREGISTRATI+=("$user")

            echo ""; separator
            echo -e "\e[1;32m        SESIUNE ACTIVĂ: $user\e[0m"
            separator; echo ""

            _post_login_menu "$user" "$path_director"
            return 0

        else
            eroare "Parolă incorectă."
            if [ "$tentative" -ge 3 ]; then
                echo ""; eroare "Prea multe încercări pentru '$user'."
                avertisment "Accesul a fost blocat temporar."
                echo ""
                return 1
            fi
        fi
    done

    return 1
}

# ---- functie care permite dupa login intoarcerea in meniul principal sau deschiderea terminalului propriu ----
_post_login_menu() {
    local user="$1"
    local user_dir="$2"
    local opts=("1. Deschide terminal în directorul tău" "2. Înapoi la meniu principal")

    
    
    _navigate_post_menu "${opts[@]}"

    case "$POST_MENU_SEL" in
        0)
            launch_user_terminal "$user" "$user_dir"
            echo ""; separator
            echo -e "\e[1;36m  Te-ai întors din terminalul lui $user.\e[0m"
            separator; echo ""
            # dupa ce utilizatorul iese din terminal, afisam meniul din nou
            _post_login_menu "$user" "$user_dir"
            ;;
        1)
            return   # revenim la meniu principal
            ;;
    esac
}


# ---- functie pt logout ----
logout() {
    local user="$1"
    local gasit=0
    local new_logged_in_users=()

    echo ""; separator
    echo -e "\e[1;37m      DECONECTARE\e[0m"
    separator; echo ""

    if [ -z "$user" ]; then
        eroare "Niciun utilizator specificat."
        return 1
    fi

    for users in "${UTILIZATORI_INREGISTRATI[@]}"; do
        if [ "$users" == "$user" ]; then
            gasit=1
        else
            new_logged_in_users+=("$users")
        fi
    done

    if [ "$gasit" -eq 1 ]; then
        UTILIZATORI_INREGISTRATI=("${new_logged_in_users[@]}")
        progress_bar "Se închide sesiunea..."
        echo ""
        info "Utilizatorul '\e[1;37m$user\e[0;32m' a fost deconectat."
        echo ""; separator; echo ""
        return 0
    else
        eroare "Utilizatorul '$user' nu este autentificat."
        avertisment "Utilizatori activi: ${UTILIZATORI_INREGISTRATI[*]:-niciunul}"
        echo ""
        return 1
    fi
}


# ---- functie pt a vedea statusul de autentificare al utilizatorilor ----
status_users() {
    echo ""; separator
    echo -e "\e[1;37m      UTILIZATORI ACTIVI\e[0m"
    separator; echo ""

    local count="${#UTILIZATORI_INREGISTRATI[@]}"

    if [ "$count" -eq 0 ]; then
        echo -e "  \e[2;37m  Niciun utilizator autentificat momentan.\e[0m"
        echo -e "  \e[2;37m  Folosiți 'Login' pentru a vă autentifica.\e[0m"
    else
        echo -e "  \e[0;37mSesiuni active: \e[1;32m$count\e[0m"; echo ""
        local idx=1
        for u in "${UTILIZATORI_INREGISTRATI[@]}"; do
            echo -e "  \e[1;32m  $idx.\e[0m \e[1;37m$u\e[0m"
            ((idx++))
        done
    fi

    echo ""; separator; echo ""
}
