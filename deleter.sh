#!/bin/bash

# --- Ayarlar ---
FORBIDDEN_PATHS=("/", "/home", "/usr", "/bin", "/sbin", "/etc", "/var", "/opt", "/root", "/boot", "/proc", "/sys", "/dev")
CURRENT_PATH=$(pwd)
CURSOR=0
OFFSET=0
SELECTED=()
MESSAGE=""

# Renkler
BOLD=$(tput bold)
REVERSE=$(tput rev)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
RESET=$(tput sgr0)

init_term() {
    stty -echo
    tput civis
    trap "stty echo; tput cnorm; clear; exit" EXIT
}

get_files() {
    # ls -F klasörlerin sonuna / ekler, mapfile bunları diziye aktarır
    mapfile -t FILES < <(ls -F --group-directories-first "$CURRENT_PATH" 2>/dev/null | sed 's/[*=>|]//g')
}

is_selected() {
    local item="$1"
    for s in "${SELECTED[@]}"; do
        [[ "$s" == "$item" ]] && return 0
    done
    return 1
}

toggle_selection() {
    local item="${FILES[$CURSOR]}"
    [[ -z "$item" ]] && return
    
    local found_idx=-1
    for i in "${!SELECTED[@]}"; do
        if [[ "${SELECTED[$i]}" == "$item" ]]; then
            found_idx=$i
            break
        fi
    done

    if [[ $found_idx -ge 0 ]]; then
        unset 'SELECTED[$found_idx]'
        SELECTED=("${SELECTED[@]}") 
    else
        SELECTED+=("$item")
    fi
}

draw() {
    clear
    local h=$(tput lines)
    local w=$(tput cols)
    local list_h=$((h - 6))

    echo -e "${CYAN}${BOLD}Dizin:${RESET} ${BLUE}$CURRENT_PATH${RESET}"
    echo -e "${YELLOW}BOŞLUK: İşaretle | Sağ/Enter: Gir | Sol/Back: Çık | D: Sil | Q: Kapat${RESET}"
    echo "--------------------------------------------------------------------------"

    for ((i=0; i<list_h; i++)); do
        local idx=$((OFFSET + i))
        if ((idx < ${#FILES[@]})); then
            local name="${FILES[$idx]}"
            local checkbox="[ ]"
            is_selected "$name" && checkbox="[x]"
            
            # Dosya tipine göre renk belirle
            local color=$WHITE
            if [[ "$name" == */ ]]; then color=$BLUE; 
            elif [[ "$name" == *.sh ]]; then color=$GREEN;
            elif [[ "$name" == *.zip ]] || [[ "$name" == *.tar* ]]; then color=$RED;
            elif [[ "$name" == *.jpg ]] || [[ "$name" == *.png ]]; then color=$MAGENTA;
            fi

            local line=" $checkbox $name"
            # Satırı genişliğe göre kırp
            line="${line:0:w-2}"

            if ((idx == CURSOR)); then
                # Highlight: Arkaplanı renkli, yazıyı siyah/ters yap
                echo -e "${REVERSE}${color}${line}$(printf '%*s' $((w-${#line})) "")${RESET}"
            else
                echo -e "${color}${line}${RESET}"
            fi
        else
            echo ""
        fi
    done

    tput cup $((h-3)) 0
    echo -e "${BOLD}Öğeler: ${#FILES[@]} | İşaretli (Silinecek): ${RED}${#SELECTED[@]}${RESET}"
    tput cup $((h-2)) 0
    [[ -n "$MESSAGE" ]] && echo -e "${YELLOW}${BOLD}>> $MESSAGE${RESET}"
}

init_term

while true; do
    get_files
    (( CURSOR >= ${#FILES[@]} )) && CURSOR=$(( ${#FILES[@]} - 1 ))
    (( CURSOR < 0 )) && CURSOR=0
    
    draw

    # IFS= boşluk karakterini yakalamak için kritik önemde
    IFS= read -rsn1 key
    
    # Escape dizileri (Ok tuşları)
    if [[ $key == $'\e' ]]; then
        read -rsn2 -t 0.01 key
    fi

    case "$key" in
        '[A'|'k') # Yukarı
            ((CURSOR > 0)) && ((CURSOR--))
            ;;
        '[B'|'j') # Aşağı
            ((CURSOR < ${#FILES[@]} - 1)) && ((CURSOR++))
            ;;
        '[C'|$'\x0a') # Sağ Ok veya Enter
            target="${FILES[$CURSOR]}"
            if [[ "$target" == */ ]]; then
                cd "$CURRENT_PATH/$target" 2>/dev/null && CURRENT_PATH=$(pwd)
                CURSOR=0; OFFSET=0; SELECTED=()
                MESSAGE=""
            fi
            ;;
        '[D'|$'\x7f') # Sol Ok veya Backspace
            cd .. 2>/dev/null && CURRENT_PATH=$(pwd)
            CURSOR=0; OFFSET=0; SELECTED=()
            MESSAGE=""
            ;;
        ' ') # Boşluk Tuşu (Seçim yapar)
            toggle_selection
            MESSAGE="Öğe işaretlendi/kaldırıldı."
            ;;
        'd'|'D') # Silme İşlemi
            if ((${#SELECTED[@]} == 0)); then
                MESSAGE="Silmek için önce BOŞLUK ile öğe seçmelisin!"
            else
                tput cup $(($(tput lines)-1)) 0
                echo -en "${RED}${BOLD}Seçili ${#SELECTED[@]} öğe kalıcı olarak silinsin mi? (y/n): ${RESET}"
                read -r -n1 confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    for item in "${SELECTED[@]}"; do
                        full_path=$(realpath "$CURRENT_PATH/$item")
                        # Koruma kontrolü
                        is_prot=false
                        for p in "${FORBIDDEN_PATHS[@]}"; do [[ "$full_path" == "$p" ]] && is_prot=true; done
                        
                        if $is_prot; then
                            MESSAGE="Kritik dizin engellendi: $item"
                        else
                            rm -rf "$full_path" 2>/dev/null
                        fi
                    done
                    SELECTED=()
                    MESSAGE="Seçilenler silindi."
                else
                    MESSAGE="İşlem iptal edildi."
                fi
            fi
            ;;
        'q'|'Q')
            exit 0
            ;;
    esac

    # Scroll (Kaydırma) hesaplama
    h=$(tput lines); list_h=$((h - 6))
    if ((CURSOR < OFFSET)); then OFFSET=$CURSOR
    elif ((CURSOR >= OFFSET + list_h)); then OFFSET=$((CURSOR - list_h + 1)); fi
done
